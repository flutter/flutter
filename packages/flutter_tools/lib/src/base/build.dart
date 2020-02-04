// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../compile.dart';
import '../dart/package_map.dart';
import '../globals.dart' as globals;
import '../macos/xcode.dart';
import '../project.dart';
import '../reporting/reporting.dart';

import 'context.dart';
import 'file_system.dart';
import 'process.dart';

GenSnapshot get genSnapshot => context.get<GenSnapshot>();

/// A snapshot build configuration.
class SnapshotType {
  SnapshotType(this.platform, this.mode)
    : assert(mode != null);

  final TargetPlatform platform;
  final BuildMode mode;

  @override
  String toString() => '$platform $mode';
}

/// Interface to the gen_snapshot command-line tool.
class GenSnapshot {
  const GenSnapshot();

  static String getSnapshotterPath(SnapshotType snapshotType) {
    return globals.artifacts.getArtifactPath(
        Artifact.genSnapshot, platform: snapshotType.platform, mode: snapshotType.mode);
  }

  Future<int> run({
    @required SnapshotType snapshotType,
    DarwinArch darwinArch,
    Iterable<String> additionalArgs = const <String>[],
  }) {
    final List<String> args = <String>[
      ...additionalArgs,
    ];

    String snapshotterPath = getSnapshotterPath(snapshotType);

    // iOS has a separate gen_snapshot for armv7 and arm64 in the same,
    // directory. So we need to select the right one.
    if (snapshotType.platform == TargetPlatform.ios) {
      snapshotterPath += '_' + getNameForDarwinArch(darwinArch);
    }

    StringConverter outputFilter;
    if (additionalArgs.contains('--strip')) {
      // Filter out gen_snapshot's warning message about stripping debug symbols
      // from ELF library snapshots.
      const String kStripWarning = 'Warning: Generating ELF library without DWARF debugging information.';
      const String kAssemblyStripWarning = 'Warning: Generating assembly code without DWARF debugging information.';
      outputFilter = (String line) => line != kStripWarning && line != kAssemblyStripWarning ? line : null;
    }

    return processUtils.stream(
      <String>[snapshotterPath, ...args],
      mapFunction: outputFilter,
    );
  }
}

class AOTSnapshotter {
  AOTSnapshotter({this.reportTimings = false});

  /// If true then AOTSnapshotter would report timings for individual building
  /// steps (Dart front-end parsing and snapshot generation) in a stable
  /// machine readable form. See [AOTSnapshotter._timedStep].
  final bool reportTimings;

  /// Builds an architecture-specific ahead-of-time compiled snapshot of the specified script.
  Future<int> build({
    @required TargetPlatform platform,
    @required BuildMode buildMode,
    @required String mainPath,
    @required String packagesPath,
    @required String outputPath,
    DarwinArch darwinArch,
    List<String> extraGenSnapshotOptions = const <String>[],
    @required bool bitcode,
    bool quiet = false,
  }) async {
    if (bitcode && platform != TargetPlatform.ios) {
      globals.printError('Bitcode is only supported for iOS.');
      return 1;
    }

    if (!_isValidAotPlatform(platform, buildMode)) {
      globals.printError('${getNameForTargetPlatform(platform)} does not support AOT compilation.');
      return 1;
    }
    // TODO(cbracken): replace IOSArch with TargetPlatform.ios_{armv7,arm64}.
    assert(platform != TargetPlatform.ios || darwinArch != null);

    final PackageMap packageMap = PackageMap(packagesPath);
    final String packageMapError = packageMap.checkValid();
    if (packageMapError != null) {
      globals.printError(packageMapError);
      return 1;
    }

    final Directory outputDir = globals.fs.directory(outputPath);
    outputDir.createSync(recursive: true);

    final String skyEnginePkg = _getPackagePath(packageMap, 'sky_engine');
    final String uiPath = globals.fs.path.join(skyEnginePkg, 'lib', 'ui', 'ui.dart');
    final String vmServicePath = globals.fs.path.join(skyEnginePkg, 'sdk_ext', 'vmservice_io.dart');

    final List<String> inputPaths = <String>[uiPath, vmServicePath, mainPath];
    final Set<String> outputPaths = <String>{};
    final List<String> genSnapshotArgs = <String>[
      '--deterministic',
    ];
    if (extraGenSnapshotOptions != null && extraGenSnapshotOptions.isNotEmpty) {
      globals.printTrace('Extra gen_snapshot options: $extraGenSnapshotOptions');
      genSnapshotArgs.addAll(extraGenSnapshotOptions);
    }

    final String assembly = globals.fs.path.join(outputDir.path, 'snapshot_assembly.S');
    if (platform == TargetPlatform.ios || platform == TargetPlatform.darwin_x64) {
      // Assembly AOT snapshot.
      outputPaths.add(assembly);
      genSnapshotArgs.add('--snapshot_kind=app-aot-assembly');
      genSnapshotArgs.add('--assembly=$assembly');
      genSnapshotArgs.add('--strip');
    } else {
      final String aotSharedLibrary = globals.fs.path.join(outputDir.path, 'app.so');
      outputPaths.add(aotSharedLibrary);
      genSnapshotArgs.add('--snapshot_kind=app-aot-elf');
      genSnapshotArgs.add('--elf=$aotSharedLibrary');
      genSnapshotArgs.add('--strip');
    }

    if (platform == TargetPlatform.android_arm || darwinArch == DarwinArch.armv7) {
      // Use softfp for Android armv7 devices.
      // This is the default for armv7 iOS builds, but harmless to set.
      // TODO(cbracken): eliminate this when we fix https://github.com/flutter/flutter/issues/17489
      genSnapshotArgs.add('--no-sim-use-hardfp');

      // Not supported by the Pixel in 32-bit mode.
      genSnapshotArgs.add('--no-use-integer-division');
    }

    // Optimization arguments.
    genSnapshotArgs.addAll(<String>[
      // Faster async/await
      '--no-causal-async-stacks',
      '--lazy-async-stacks',
    ]);

    genSnapshotArgs.add(mainPath);

    // TODO(jonahwilliams): fully remove input checks once all callers are
    // using assemble.
    final Iterable<String> missingInputs = inputPaths.where((String p) => !globals.fs.isFileSync(p));
    if (missingInputs.isNotEmpty) {
      globals.printTrace('Missing input files: $missingInputs from $inputPaths');
    }

    final SnapshotType snapshotType = SnapshotType(platform, buildMode);
    final int genSnapshotExitCode =
      await _timedStep('snapshot(CompileTime)', 'aot-snapshot',
        () => genSnapshot.run(
      snapshotType: snapshotType,
      additionalArgs: genSnapshotArgs,
      darwinArch: darwinArch,
    ));
    if (genSnapshotExitCode != 0) {
      globals.printError('Dart snapshot generator failed with exit code $genSnapshotExitCode');
      return genSnapshotExitCode;
    }

    // Write path to gen_snapshot, since snapshots have to be re-generated when we roll
    // the Dart SDK.
    // TODO(jonahwilliams): remove when all callers are using assemble.
    final String genSnapshotPath = GenSnapshot.getSnapshotterPath(snapshotType);
    outputDir.childFile('gen_snapshot.d').writeAsStringSync('gen_snapshot.d: $genSnapshotPath\n');

    // On iOS and macOS, we use Xcode to compile the snapshot into a dynamic library that the
    // end-developer can link into their app.
    if (platform == TargetPlatform.ios || platform == TargetPlatform.darwin_x64) {
      final RunResult result = await _buildFramework(
        appleArch: darwinArch,
        isIOS: platform == TargetPlatform.ios,
        assemblyPath: assembly,
        outputPath: outputDir.path,
        bitcode: bitcode,
        quiet: quiet,
      );
      if (result.exitCode != 0) {
        return result.exitCode;
      }
    }
    return 0;
  }

  /// Builds an iOS or macOS framework at [outputPath]/App.framework from the assembly
  /// source at [assemblyPath].
  Future<RunResult> _buildFramework({
    @required DarwinArch appleArch,
    @required bool isIOS,
    @required String assemblyPath,
    @required String outputPath,
    @required bool bitcode,
    @required bool quiet
  }) async {
    final String targetArch = getNameForDarwinArch(appleArch);
    if (!quiet) {
      globals.printStatus('Building App.framework for $targetArch...');
    }

    final List<String> commonBuildOptions = <String>[
      '-arch', targetArch,
      if (isIOS)
        '-miphoneos-version-min=8.0',
    ];

    const String embedBitcodeArg = '-fembed-bitcode';
    final String assemblyO = globals.fs.path.join(outputPath, 'snapshot_assembly.o');
    List<String> isysrootArgs;
    if (isIOS) {
      final String iPhoneSDKLocation = await globals.xcode.sdkLocation(SdkType.iPhone);
      if (iPhoneSDKLocation != null) {
        isysrootArgs = <String>['-isysroot', iPhoneSDKLocation];
      }
    }
    final RunResult compileResult = await globals.xcode.cc(<String>[
      '-arch', targetArch,
      if (isysrootArgs != null) ...isysrootArgs,
      if (bitcode) embedBitcodeArg,
      '-c',
      assemblyPath,
      '-o',
      assemblyO,
    ]);
    if (compileResult.exitCode != 0) {
      globals.printError('Failed to compile AOT snapshot. Compiler terminated with exit code ${compileResult.exitCode}');
      return compileResult;
    }

    final String frameworkDir = globals.fs.path.join(outputPath, 'App.framework');
    globals.fs.directory(frameworkDir).createSync(recursive: true);
    final String appLib = globals.fs.path.join(frameworkDir, 'App');
    final List<String> linkArgs = <String>[
      ...commonBuildOptions,
      '-dynamiclib',
      '-Xlinker', '-rpath', '-Xlinker', '@executable_path/Frameworks',
      '-Xlinker', '-rpath', '-Xlinker', '@loader_path/Frameworks',
      '-install_name', '@rpath/App.framework/App',
      if (bitcode) embedBitcodeArg,
      if (isysrootArgs != null) ...isysrootArgs,
      '-o', appLib,
      assemblyO,
    ];
    final RunResult linkResult = await globals.xcode.clang(linkArgs);
    if (linkResult.exitCode != 0) {
      globals.printError('Failed to link AOT snapshot. Linker terminated with exit code ${compileResult.exitCode}');
    }
    return linkResult;
  }

  /// Compiles a Dart file to kernel.
  ///
  /// Returns the output kernel file path, or null on failure.
  Future<String> compileKernel({
    @required TargetPlatform platform,
    @required BuildMode buildMode,
    @required String mainPath,
    @required String packagesPath,
    @required String outputPath,
    @required bool trackWidgetCreation,
    @required List<String> dartDefines,
    List<String> extraFrontEndOptions = const <String>[],
  }) async {
    final FlutterProject flutterProject = FlutterProject.current();
    final Directory outputDir = globals.fs.directory(outputPath);
    outputDir.createSync(recursive: true);

    globals.printTrace('Compiling Dart to kernel: $mainPath');

    if ((extraFrontEndOptions != null) && extraFrontEndOptions.isNotEmpty) {
      globals.printTrace('Extra front-end options: $extraFrontEndOptions');
    }

    final String depfilePath = globals.fs.path.join(outputPath, 'kernel_compile.d');
    final KernelCompiler kernelCompiler = await kernelCompilerFactory.create(flutterProject);
    final CompilerOutput compilerOutput =
      await _timedStep('frontend(CompileTime)', 'aot-kernel',
        () => kernelCompiler.compile(
      sdkRoot: globals.artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath, mode: buildMode),
      mainPath: mainPath,
      packagesPath: packagesPath,
      outputFilePath: getKernelPathForTransformerOptions(
        globals.fs.path.join(outputPath, 'app.dill'),
        trackWidgetCreation: trackWidgetCreation,
      ),
      depFilePath: depfilePath,
      extraFrontEndOptions: extraFrontEndOptions,
      linkPlatformKernelIn: true,
      aot: true,
      buildMode: buildMode,
      trackWidgetCreation: trackWidgetCreation,
      dartDefines: dartDefines,
    ));

    // Write path to frontend_server, since things need to be re-generated when that changes.
    final String frontendPath = globals.artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk);
    globals.fs.directory(outputPath).childFile('frontend_server.d').writeAsStringSync('frontend_server.d: $frontendPath\n');

    return compilerOutput?.outputFilename;
  }

  bool _isValidAotPlatform(TargetPlatform platform, BuildMode buildMode) {
    if (buildMode == BuildMode.debug) {
      return false;
    }
    return const <TargetPlatform>[
      TargetPlatform.android_arm,
      TargetPlatform.android_arm64,
      TargetPlatform.android_x64,
      TargetPlatform.ios,
      TargetPlatform.darwin_x64,
    ].contains(platform);
  }

  String _getPackagePath(PackageMap packageMap, String package) {
    return globals.fs.path.dirname(globals.fs.path.fromUri(packageMap.map[package]));
  }

  /// This method is used to measure duration of an action and emit it into
  /// verbose output from flutter_tool for other tools (e.g. benchmark runner)
  /// to find.
  /// Important: external performance tracking tools expect format of this
  /// output to be stable.
  Future<T> _timedStep<T>(String marker, String analyticsVar, FutureOr<T> Function() action) async {
    final Stopwatch sw = Stopwatch()..start();
    final T value = await action();
    if (reportTimings) {
      globals.printStatus('$marker: ${sw.elapsedMilliseconds} ms.');
    }
    flutterUsage.sendTiming('build', analyticsVar, Duration(milliseconds: sw.elapsedMilliseconds));
    return value;
  }
}
