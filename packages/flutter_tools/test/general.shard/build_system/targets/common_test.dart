// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/build_system/targets/ios.dart';
import 'package:flutter_tools/src/compile.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fake_process_manager.dart';

const String kBoundaryKey = '4d2d9609-c662-4571-afde-31410f96caa6';
const String kElfAot = '--snapshot_kind=app-aot-elf';
const String kAssemblyAot = '--snapshot_kind=app-aot-assembly';

final Platform macPlatform = FakePlatform(operatingSystem: 'macos', environment: <String, String>{});
void main() {
  late FakeProcessManager processManager;
  late Environment androidEnvironment;
  late Environment iosEnvironment;
  late Artifacts artifacts;
  late FileSystem fileSystem;
  late Logger logger;

  setUp(() {
    processManager = FakeProcessManager.empty();
    logger = BufferLogger.test();
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    androidEnvironment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kBuildMode: BuildMode.profile.cliName,
        kTargetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
      },
      inputs: <String, String>{},
      artifacts: artifacts,
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    androidEnvironment.buildDir.createSync(recursive: true);
    iosEnvironment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kBuildMode: BuildMode.profile.cliName,
        kTargetPlatform: getNameForTargetPlatform(TargetPlatform.ios),
      },
      inputs: <String, String>{},
      artifacts: artifacts,
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    iosEnvironment.buildDir.createSync(recursive: true);
  });

  testWithoutContext('KernelSnapshotProgram throws error if missing build mode', () async {
    androidEnvironment.defines.remove(kBuildMode);
    expect(
      const KernelSnapshotProgram().build(androidEnvironment),
      throwsA(isA<MissingDefineException>()));
  });

  const String emptyNativeAssets = '''
format-version:
  - 1
  - 0
  - 0
native-assets: {}
''';

  const String nonEmptyNativeAssets = '''
format-version:
  - 1
  - 0
  - 0
native-assets:
  macos_arm64:
    package:my_package/my_package_bindings_generated.dart:
      - absolute
      - my_package.framework/my_package
''';

  testWithoutContext('KernelSnapshotProgram handles null result from kernel compilation', () async {
    fileSystem.file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"configVersion": 2, "packages":[]}');
    final String build = androidEnvironment.buildDir.path;
    final String flutterPatchedSdkPath = artifacts.getArtifactPath(
      Artifact.flutterPatchedSdkPath,
      platform: TargetPlatform.android_arm,
      mode: BuildMode.profile,
    );
    processManager.addCommands(<FakeCommand>[
      FakeCommand(command: <String>[
        artifacts.getArtifactPath(Artifact.engineDartAotRuntime),
        artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
        '--sdk-root',
        '$flutterPatchedSdkPath/',
        '--target=flutter',
        '--no-print-incremental-dependencies',
        ...buildModeOptions(BuildMode.profile, <String>[]),
        '--track-widget-creation',
        '--aot',
        '--tfa',
        '--target-os',
        'android',
        '--packages',
        '/.dart_tool/package_config.json',
        '--output-dill',
        '$build/program.dill',
        '--depfile',
        '$build/kernel_snapshot_program.d',
        '--verbosity=error',
        'file:///lib/main.dart',
      ], exitCode: 1),
    ]);

    await expectLater(() => const KernelSnapshotProgram().build(androidEnvironment), throwsException);
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('KernelSnapshotProgram does use track widget creation on profile builds', () async {
    fileSystem.file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"configVersion": 2, "packages":[]}');
    final String build = androidEnvironment.buildDir.path;
    final String flutterPatchedSdkPath = artifacts.getArtifactPath(
      Artifact.flutterPatchedSdkPath,
      platform: TargetPlatform.android_arm,
      mode: BuildMode.profile,
    );
    processManager.addCommands(<FakeCommand>[
      FakeCommand(command: <String>[
        artifacts.getArtifactPath(Artifact.engineDartAotRuntime),
        artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
        '--sdk-root',
        '$flutterPatchedSdkPath/',
        '--target=flutter',
        '--no-print-incremental-dependencies',
        ...buildModeOptions(BuildMode.profile, <String>[]),
        '--track-widget-creation',
        '--aot',
        '--tfa',
        '--target-os',
        'android',
        '--packages',
        '/.dart_tool/package_config.json',
        '--output-dill',
        '$build/program.dill',
        '--depfile',
        '$build/kernel_snapshot_program.d',
        '--verbosity=error',
        'file:///lib/main.dart',
      ], stdout: 'result $kBoundaryKey\n$kBoundaryKey\n$kBoundaryKey $build/program.dill 0\n'),
    ]);

    await const KernelSnapshotProgram().build(androidEnvironment);

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('KernelSnapshotProgram correctly handles an empty string in ExtraFrontEndOptions', () async {
    fileSystem.file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"configVersion": 2, "packages":[]}');
    final String build = androidEnvironment.buildDir.path;
    final String flutterPatchedSdkPath = artifacts.getArtifactPath(
      Artifact.flutterPatchedSdkPath,
      platform: TargetPlatform.android_arm,
      mode: BuildMode.profile,
    );
    processManager.addCommands(<FakeCommand>[
      FakeCommand(command: <String>[
        artifacts.getArtifactPath(Artifact.engineDartAotRuntime),
        artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
        '--sdk-root',
        '$flutterPatchedSdkPath/',
        '--target=flutter',
        '--no-print-incremental-dependencies',
        ...buildModeOptions(BuildMode.profile, <String>[]),
        '--track-widget-creation',
        '--aot',
        '--tfa',
        '--target-os',
        'android',
        '--packages',
        '/.dart_tool/package_config.json',
        '--output-dill',
        '$build/program.dill',
        '--depfile',
        '$build/kernel_snapshot_program.d',
        '--verbosity=error',
        'file:///lib/main.dart',
      ], stdout: 'result $kBoundaryKey\n$kBoundaryKey\n$kBoundaryKey $build/program.dill 0\n'),
    ]);

    await const KernelSnapshotProgram()
      .build(androidEnvironment..defines[kExtraFrontEndOptions] = '');

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('KernelSnapshotProgram correctly forwards FrontendServerStarterPath', () async {
    fileSystem.file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"configVersion": 2, "packages":[]}');
    final String build = androidEnvironment.buildDir.path;
    final String flutterPatchedSdkPath = artifacts.getArtifactPath(
      Artifact.flutterPatchedSdkPath,
      platform: TargetPlatform.android_arm,
      mode: BuildMode.profile,
    );
    processManager.addCommands(<FakeCommand>[
      FakeCommand(command: <String>[
        artifacts.getArtifactPath(Artifact.engineDartBinary),
        'path/to/frontend_server_starter.dart',
        '--sdk-root',
        '$flutterPatchedSdkPath/',
        '--target=flutter',
        '--no-print-incremental-dependencies',
        ...buildModeOptions(BuildMode.profile, <String>[]),
        '--track-widget-creation',
        '--aot',
        '--tfa',
        '--target-os',
        'android',
        '--packages',
        '/.dart_tool/package_config.json',
        '--output-dill',
        '$build/program.dill',
        '--depfile',
        '$build/kernel_snapshot_program.d',
        '--verbosity=error',
        'file:///lib/main.dart',
      ], stdout: 'result $kBoundaryKey\n$kBoundaryKey\n$kBoundaryKey $build/program.dill 0\n'),
    ]);

    await const KernelSnapshotProgram()
      .build(androidEnvironment..defines[kFrontendServerStarterPath] = 'path/to/frontend_server_starter.dart');

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('KernelSnapshotProgram correctly forwards ExtraFrontEndOptions', () async {
    fileSystem.file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"configVersion": 2, "packages":[]}');
    final String build = androidEnvironment.buildDir.path;
    final String flutterPatchedSdkPath = artifacts.getArtifactPath(
      Artifact.flutterPatchedSdkPath,
      platform: TargetPlatform.android_arm,
      mode: BuildMode.profile,
    );
    processManager.addCommands(<FakeCommand>[
      FakeCommand(command: <String>[
        artifacts.getArtifactPath(Artifact.engineDartAotRuntime),
        artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
        '--sdk-root',
        '$flutterPatchedSdkPath/',
        '--target=flutter',
        '--no-print-incremental-dependencies',
        ...buildModeOptions(BuildMode.profile, <String>[]),
        '--track-widget-creation',
        '--aot',
        '--tfa',
        '--target-os',
        'android',
        '--packages',
        '/.dart_tool/package_config.json',
        '--output-dill',
        '$build/program.dill',
        '--depfile',
        '$build/kernel_snapshot_program.d',
        '--verbosity=error',
        'foo',
        'bar',
        'file:///lib/main.dart',
      ], stdout: 'result $kBoundaryKey\n$kBoundaryKey\n$kBoundaryKey $build/program.dill 0\n'),
    ]);

    await const KernelSnapshotProgram()
      .build(androidEnvironment..defines[kExtraFrontEndOptions] = 'foo,bar');

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('KernelSnapshotProgram can disable track-widget-creation on debug builds', () async {
    fileSystem.file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"configVersion": 2, "packages":[]}');

    final String build = androidEnvironment.buildDir.path;
    final String flutterPatchedSdkPath = artifacts.getArtifactPath(
      Artifact.flutterPatchedSdkPath,
      platform: TargetPlatform.android_arm,
      mode: BuildMode.debug,
    );
    processManager.addCommands(<FakeCommand>[
      FakeCommand(command: <String>[
        artifacts.getArtifactPath(Artifact.engineDartAotRuntime),
        artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
        '--sdk-root',
        '$flutterPatchedSdkPath/',
        '--target=flutter',
        '--no-print-incremental-dependencies',
        ...buildModeOptions(BuildMode.debug, <String>[]),
        '--no-link-platform',
        '--packages',
        '/.dart_tool/package_config.json',
        '--output-dill',
        '$build/program.dill',
        '--depfile',
        '$build/kernel_snapshot_program.d',
        '--incremental',
        '--initialize-from-dill',
        '$build/program.dill',
        '--verbosity=error',
        'file:///lib/main.dart',
      ], stdout: 'result $kBoundaryKey\n$kBoundaryKey\n$kBoundaryKey $build/program.dill 0\n'),
    ]);

    await const KernelSnapshotProgram().build(androidEnvironment
      ..defines[kBuildMode] = BuildMode.debug.cliName
      ..defines[kTrackWidgetCreation] = 'false');

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('KernelSnapshotProgram forces platform linking on debug for darwin target platforms', () async {
    fileSystem.file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"configVersion": 2, "packages":[]}');
    final String build = androidEnvironment.buildDir.path;
    final String flutterPatchedSdkPath = artifacts.getArtifactPath(
      Artifact.flutterPatchedSdkPath,
      platform: TargetPlatform.darwin,
      mode: BuildMode.debug,
    );
    processManager.addCommands(<FakeCommand>[
      FakeCommand(command: <String>[
        artifacts.getArtifactPath(Artifact.engineDartAotRuntime),
        artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
        '--sdk-root',
        '$flutterPatchedSdkPath/',
        '--target=flutter',
        '--no-print-incremental-dependencies',
        ...buildModeOptions(BuildMode.debug, <String>[]),
        '--packages',
        '/.dart_tool/package_config.json',
        '--output-dill',
        '$build/program.dill',
        '--depfile',
        '$build/kernel_snapshot_program.d',
        '--incremental',
        '--initialize-from-dill',
        '$build/program.dill',
        '--verbosity=error',
        'file:///lib/main.dart',
      ], stdout: 'result $kBoundaryKey\n$kBoundaryKey\n$kBoundaryKey $build/program.dill 0\n'),
    ]);

    await const KernelSnapshotProgram().build(androidEnvironment
      ..defines[kTargetPlatform]  = getNameForTargetPlatform(TargetPlatform.darwin)
      ..defines[kBuildMode] = BuildMode.debug.cliName
      ..defines[kTrackWidgetCreation] = 'false'
    );

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('KernelSnapshotProgram does use track widget creation on debug builds', () async {
    fileSystem.file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"configVersion": 2, "packages":[]}');
    final Environment testEnvironment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kBuildMode: BuildMode.debug.cliName,
        kTargetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
      },
      processManager: processManager,
      artifacts: artifacts,
      fileSystem: fileSystem,
      logger: logger,
    );
    final String build = testEnvironment.buildDir.path;
    final String flutterPatchedSdkPath = artifacts.getArtifactPath(
      Artifact.flutterPatchedSdkPath,
      platform: TargetPlatform.android_arm,
      mode: BuildMode.debug,
    );
    processManager.addCommands(<FakeCommand>[
      FakeCommand(command: <String>[
        artifacts.getArtifactPath(Artifact.engineDartAotRuntime),
        artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
        '--sdk-root',
        '$flutterPatchedSdkPath/',
        '--target=flutter',
        '--no-print-incremental-dependencies',
        ...buildModeOptions(BuildMode.debug, <String>[]),
        '--track-widget-creation',
        '--no-link-platform',
        '--packages',
        '/.dart_tool/package_config.json',
        '--output-dill',
        '$build/program.dill',
        '--depfile',
        '$build/kernel_snapshot_program.d',
        '--incremental',
        '--initialize-from-dill',
        '$build/program.dill',
        '--verbosity=error',
        'file:///lib/main.dart',
      ], stdout: 'result $kBoundaryKey\n$kBoundaryKey\n$kBoundaryKey /build/653e11a8e6908714056a57cd6b4f602a/program.dill 0\n'),
    ]);

    await const KernelSnapshotProgram().build(testEnvironment);

    expect(processManager, hasNoRemainingExpectations);
  });

  for (final BuildMode buildMode in <BuildMode>[BuildMode.debug, BuildMode.release]) {
    for (final bool empty in <bool>[true, false]) {
      final String testName = empty ? 'empty' : 'non empty';
      testWithoutContext('KernelSnapshotNativeAssets ${buildMode.name} $testName', () async {
        fileSystem.file('.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('{"configVersion": 2, "packages":[]}');
        androidEnvironment.buildDir.childFile('native_assets.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(empty ? emptyNativeAssets : nonEmptyNativeAssets);
        final String build = androidEnvironment.buildDir.path;
        final String flutterPatchedSdkPath = artifacts.getArtifactPath(
          Artifact.flutterPatchedSdkPath,
          platform: TargetPlatform.darwin,
          mode: buildMode,
        );
        processManager.addCommands(<FakeCommand>[
          if (!empty)
            FakeCommand(command: <String>[
              artifacts.getArtifactPath(Artifact.engineDartAotRuntime),
              artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk),
              '--sdk-root',
              '$flutterPatchedSdkPath/',
              '--target=flutter',
              '--no-print-incremental-dependencies',
              ...buildModeOptions(buildMode, <String>[]),
              '--no-link-platform',
              if (buildMode == BuildMode.release) ...<String>['--aot', '--tfa'],
              '--packages',
              '/.dart_tool/package_config.json',
              '--output-dill',
              '$build/native_assets.dill',
              '--native-assets',
              '$build/native_assets.yaml',
              '--verbosity=error',
              '--native-assets-only',
            ], stdout: 'result $kBoundaryKey\n$kBoundaryKey\n$kBoundaryKey $build/app.dill 0\n'),
        ]);

        await const KernelSnapshotNativeAssets().build(androidEnvironment
          ..defines[kTargetPlatform]  = getNameForTargetPlatform(TargetPlatform.darwin)
          ..defines[kBuildMode] = buildMode.cliName
        );

        expect(processManager, hasNoRemainingExpectations);
      });
    }
  }

  for (final bool empty in <bool>[true, false]) {
    final String testName = empty ? 'empty' : 'non empty';
    testWithoutContext('KernelSnapshot native assets $testName', () async {
      const List<int> programDillBytes = <int>[1, 2, 3, 4];
      androidEnvironment.buildDir.childFile('program.dill')
        ..createSync(recursive: true)
        ..writeAsBytesSync(programDillBytes);
      final List<int> nativeAssetsDillBytes = empty ? <int>[] : <int>[5, 6, 7, 8];
      androidEnvironment.buildDir.childFile('native_assets.dill')
        ..createSync(recursive: true)
        ..writeAsBytesSync(nativeAssetsDillBytes);

      await const KernelSnapshot().build(androidEnvironment);

      expect(
        androidEnvironment.buildDir.childFile('app.dill').readAsBytesSync(),
        equals(<int>[...programDillBytes, ...nativeAssetsDillBytes]),
      );
    });
  }

  testUsingContext('AotElfProfile Produces correct output directory', () async {
    final String build = androidEnvironment.buildDir.path;
    processManager.addCommands(<FakeCommand>[
      FakeCommand(command: <String>[
        artifacts.getArtifactPath(
          Artifact.genSnapshot,
          platform: TargetPlatform.android_arm,
          mode: BuildMode.profile,
        ),
        '--deterministic',
        kElfAot,
        '--elf=$build/app.so',
        '--strip',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        '$build/app.dill',
      ]),
    ]);
    androidEnvironment.buildDir.childFile('app.dill').createSync(recursive: true);

    await const AotElfProfile(TargetPlatform.android_arm).build(androidEnvironment);

    expect(processManager, hasNoRemainingExpectations);
  });

  testUsingContext('AotElfRelease configures gen_snapshot with code size directory', () async {
    androidEnvironment.defines[kCodeSizeDirectory] = 'code_size_1';
    final String build = androidEnvironment.buildDir.path;
    processManager.addCommands(<FakeCommand>[
      FakeCommand(command: <String>[
        artifacts.getArtifactPath(
          Artifact.genSnapshot,
          platform: TargetPlatform.android_arm,
          mode: BuildMode.profile,
        ),
        '--deterministic',
        '--write-v8-snapshot-profile-to=code_size_1/snapshot.android-arm.json',
        '--trace-precompiler-to=code_size_1/trace.android-arm.json',
        kElfAot,
        '--elf=$build/app.so',
        '--strip',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        '$build/app.dill',
      ]),
    ]);
    androidEnvironment.buildDir.childFile('app.dill').createSync(recursive: true);

    await const AotElfRelease(TargetPlatform.android_arm).build(androidEnvironment);

    expect(processManager, hasNoRemainingExpectations);
  });

  testUsingContext('AotElfProfile throws error if missing build mode', () async {
    androidEnvironment.defines.remove(kBuildMode);

    expect(const AotElfProfile(TargetPlatform.android_arm).build(androidEnvironment),
      throwsA(isA<MissingDefineException>()));
  });

  testUsingContext('AotElfProfile throws error if missing target platform', () async {
    androidEnvironment.defines.remove(kTargetPlatform);

    expect(const AotElfProfile(TargetPlatform.android_arm).build(androidEnvironment),
      throwsA(isA<MissingDefineException>()));
  });

  testUsingContext('AotAssemblyProfile throws error if missing build mode', () async {
    iosEnvironment.defines.remove(kBuildMode);

    expect(const AotAssemblyProfile().build(iosEnvironment),
      throwsA(isA<MissingDefineException>()));
  }, overrides: <Type, Generator>{
    Platform: () => macPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });


  testUsingContext('AotAssemblyProfile throws error if missing target platform', () async {
    iosEnvironment.defines.remove(kTargetPlatform);

    expect(const AotAssemblyProfile().build(iosEnvironment),
      throwsA(isA<MissingDefineException>()));
  }, overrides: <Type, Generator>{
    Platform: () => macPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('AotAssemblyProfile throws error if built for non-iOS platform', () async {
    expect(const AotAssemblyProfile().build(androidEnvironment), throwsException);
  }, overrides: <Type, Generator>{
    Platform: () => macPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('AotAssemblyRelease configures gen_snapshot with code size directory', () async {
    iosEnvironment.defines[kCodeSizeDirectory] = 'code_size_1';
    iosEnvironment.defines[kIosArchs] = 'arm64';
    iosEnvironment.defines[kSdkRoot] = 'path/to/iPhoneOS.sdk';
    final String build = iosEnvironment.buildDir.path;
    processManager.addCommands(<FakeCommand>[
      FakeCommand(command: <String>[
        // This path is not known by the cache due to the iOS gen_snapshot split.
        'Artifact.genSnapshot.TargetPlatform.ios.profile_arm64',
        '--deterministic',
        '--write-v8-snapshot-profile-to=code_size_1/snapshot.arm64.json',
        '--trace-precompiler-to=code_size_1/trace.arm64.json',
        kAssemblyAot,
        '--assembly=$build/arm64/snapshot_assembly.S',
        '$build/app.dill',
      ]),
      FakeCommand(command: <String>[
        'xcrun',
        'cc',
        '-arch',
        'arm64',
        '-miphoneos-version-min=12.0',
        '-isysroot',
        'path/to/iPhoneOS.sdk',
        '-c',
        '$build/arm64/snapshot_assembly.S',
        '-o',
        '$build/arm64/snapshot_assembly.o',
      ]),
      FakeCommand(command: <String>[
        'xcrun',
        'clang',
        '-arch',
        'arm64',
        '-miphoneos-version-min=12.0',
        '-isysroot',
        'path/to/iPhoneOS.sdk',
        '-dynamiclib',
        '-Xlinker',
        '-rpath',
        '-Xlinker',
        '@executable_path/Frameworks',
        '-Xlinker',
        '-rpath',
        '-Xlinker',
        '@loader_path/Frameworks',
        '-fapplication-extension',
        '-install_name',
        '@rpath/App.framework/App',
        '-o',
        '$build/arm64/App.framework/App',
        '$build/arm64/snapshot_assembly.o',
      ]),
      FakeCommand(command: <String>[
        'xcrun',
        'dsymutil',
        '-o',
        '$build/arm64/App.framework.dSYM',
        '$build/arm64/App.framework/App',
      ]),
      FakeCommand(command: <String>[
        'xcrun',
        'strip',
        '-x',
        '$build/arm64/App.framework/App',
        '-o',
        '$build/arm64/App.framework/App',
      ]),
      FakeCommand(command: <String>[
        'lipo',
        '$build/arm64/App.framework/App',
        '-create',
        '-output',
        '$build/App.framework/App',
      ]),
    ]);

    await const AotAssemblyProfile().build(iosEnvironment);

    expect(processManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    Platform: () => macPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('kExtraGenSnapshotOptions passes values to gen_snapshot', () async {
    androidEnvironment.defines[kExtraGenSnapshotOptions] = 'foo,bar,baz=2';
    androidEnvironment.defines[kBuildMode] = BuildMode.profile.cliName;
    final String build = androidEnvironment.buildDir.path;

    processManager.addCommands(<FakeCommand>[
      FakeCommand(command: <String>[
        artifacts.getArtifactPath(
          Artifact.genSnapshot,
          platform: TargetPlatform.android_arm,
          mode: BuildMode.profile,
        ),
        '--deterministic',
        'foo',
        'bar',
        'baz=2',
        kElfAot,
        '--elf=$build/app.so',
        '--strip',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        '$build/app.dill',
      ]),
    ]);

    await const AotElfRelease(TargetPlatform.android_arm).build(androidEnvironment);

    expect(processManager, hasNoRemainingExpectations);
  });
}
