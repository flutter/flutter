// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../base/build.dart';
import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/process.dart';
import '../../base/process_manager.dart';
import '../../build_info.dart';
import '../../macos/xcode.dart';
import '../build_system.dart';
import '../exceptions.dart';
import 'dart.dart';

/// Supports compiling a dart kernel file to an assembly file.
///
/// If more than one iOS arch is provided, then this rule will
/// produce a universal binary.
abstract class AotAssemblyBase extends Target {
  const AotAssemblyBase();

  @override
  Future<void> build(Environment environment) async {
    final AOTSnapshotter snapshotter = AOTSnapshotter(reportTimings: false);
    final String buildOutputPath = environment.buildDir.path;
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'aot_assembly');
    }
    if (environment.defines[kTargetPlatform] == null) {
      throw MissingDefineException(kTargetPlatform, 'aot_assembly');
    }
    final bool bitcode = environment.defines[kBitcodeFlag] == 'true';
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final TargetPlatform targetPlatform = getTargetPlatformForName(environment.defines[kTargetPlatform]);
    final List<DarwinArch> iosArchs = environment.defines[kIosArchs]?.split(',')?.map(getIOSArchForName)?.toList()
        ?? <DarwinArch>[DarwinArch.arm64];
    if (targetPlatform != TargetPlatform.ios) {
      throw Exception('aot_assembly is only supported for iOS applications');
    }

    // If we're building for a single architecture (common), then skip the lipo.
    if (iosArchs.length == 1) {
      final int snapshotExitCode = await snapshotter.build(
        platform: targetPlatform,
        buildMode: buildMode,
        mainPath: environment.buildDir.childFile('app.dill').path,
        packagesPath: environment.projectDir.childFile('.packages').path,
        outputPath: environment.outputDir.path,
        darwinArch: iosArchs.single,
        bitcode: bitcode,
      );
      if (snapshotExitCode != 0) {
        throw Exception('AOT snapshotter exited with code $snapshotExitCode');
      }
    } else {
      // If we're building multiple iOS archs the binaries need to be lipo'd
      // together.
      final List<Future<int>> pending = <Future<int>>[];
      for (DarwinArch iosArch in iosArchs) {
        pending.add(snapshotter.build(
          platform: targetPlatform,
          buildMode: buildMode,
          mainPath: environment.buildDir.childFile('app.dill').path,
          packagesPath: environment.projectDir.childFile('.packages').path,
          outputPath: fs.path.join(buildOutputPath, getNameForDarwinArch(iosArch)),
          darwinArch: iosArch,
          bitcode: bitcode,
        ));
      }
      final List<int> results = await Future.wait(pending);
      if (results.any((int result) => result != 0)) {
        throw Exception('AOT snapshotter exited with code ${results.join()}');
      }
      final ProcessResult result = await processManager.run(<String>[
        'lipo',
        ...iosArchs.map((DarwinArch iosArch) =>
            fs.path.join(buildOutputPath, getNameForDarwinArch(iosArch), 'App.framework', 'App')),
        '-create',
        '-output',
        fs.path.join(environment.outputDir.path, 'App.framework', 'App'),
      ]);
      if (result.exitCode != 0) {
        throw Exception('lipo exited with code ${result.exitCode}');
      }
    }
  }
}

/// Generate an assembly target from a dart kernel file in release mode.
class AotAssemblyRelease extends AotAssemblyBase {
  const AotAssemblyRelease();

  @override
  String get name => 'aot_assembly_release';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/ios.dart'),
    Source.pattern('{BUILD_DIR}/app.dill'),
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.skyEnginePath),
    Source.artifact(Artifact.genSnapshot,
      platform: TargetPlatform.ios,
      mode: BuildMode.release,
    ),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/App.framework/App'),
  ];

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];
}


/// Generate an assembly target from a dart kernel file in profile mode.
class AotAssemblyProfile extends AotAssemblyBase {
  const AotAssemblyProfile();

  @override
  String get name => 'aot_assembly_profile';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/ios.dart'),
    Source.pattern('{BUILD_DIR}/app.dill'),
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.skyEnginePath),
    Source.artifact(Artifact.genSnapshot,
      platform: TargetPlatform.ios,
      mode: BuildMode.profile,
    ),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/App.framework/App'),
  ];

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];
}

/// Create an App.framework for debug iOS targets.
///
/// This framework needs to exist for the Xcode project to link/bundle,
/// but it isn't actually executed. To generate something valid, we compile a trivial
/// constant.
Future<RunResult> createStubAppFramework(Directory appFrameworkDirectory) async {
  File outputFile;
  try {
    if (!appFrameworkDirectory.existsSync()) {
      appFrameworkDirectory.createSync(recursive: true);
    }

    outputFile = appFrameworkDirectory.childFile('App');
    outputFile.createSync(recursive: true);
  } catch (e) {
    throwToolExit('Failed to create App.framework stub at ${appFrameworkDirectory.path}');
  }

  final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_stub_source.');
  try {
    final File stubSource = tempDir.childFile('debug_app.cc')
      ..writeAsStringSync(r'''
  static const int Moo = 88;
  ''');

    return await xcode.clang(<String>[
      '-x',
      'c',
      stubSource.path,
      '-dynamiclib',
      '-Xlinker', '-rpath', '-Xlinker', '@executable_path/Frameworks',
      '-Xlinker', '-rpath', '-Xlinker', '@loader_path/Frameworks',
      '-install_name', '@rpath/App.framework/App',
      '-o', outputFile.path,
    ]);
  } finally {
    try {
      tempDir.deleteSync(recursive: true);
    } on FileSystemException catch (_) {
      // Best effort. Sometimes we can't delete things from system temp.
    }
  }
}
