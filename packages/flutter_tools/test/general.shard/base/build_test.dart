// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const FakeCommand kARMCheckCommand = FakeCommand(
  command: <String>[
    'sysctl',
    'hw.optional.arm64',
  ],
  exitCode: 1,
);

const FakeCommand kSdkPathCommand = FakeCommand(
  command: <String>[
    'xcrun',
    '--sdk',
    'iphoneos',
    '--show-sdk-path'
  ]
);

const List<String> kDefaultClang = <String>[
  '-miphoneos-version-min=8.0',
  '-dynamiclib',
  '-Xlinker',
  '-rpath',
  '-Xlinker',
  '@executable_path/Frameworks',
  '-Xlinker',
  '-rpath',
  '-Xlinker',
  '@loader_path/Frameworks',
  '-install_name',
  '@rpath/App.framework/App',
  '-isysroot',
  '',
  '-o',
  'build/foo/App.framework/App',
  'build/foo/snapshot_assembly.o',
];

const List<String> kBitcodeClang = <String>[
  '-miphoneos-version-min=8.0',
  '-dynamiclib',
  '-Xlinker',
  '-rpath',
  '-Xlinker',
  '@executable_path/Frameworks',
  '-Xlinker',
  '-rpath',
  '-Xlinker',
  '@loader_path/Frameworks',
  '-install_name',
  '@rpath/App.framework/App',
  '-fembed-bitcode',
  '-isysroot',
  '',
  '-o',
  'build/foo/App.framework/App',
  'build/foo/snapshot_assembly.o',
];

void main() {
  group('SnapshotType', () {
    test('throws, if build mode is null', () {
      expect(
        () => SnapshotType(TargetPlatform.android_x64, null),
        throwsA(anything),
      );
    });
    test('does not throw, if target platform is null', () {
      expect(() => SnapshotType(null, BuildMode.release), returnsNormally);
    });
  });

  group('GenSnapshot', () {
    GenSnapshot genSnapshot;
    MockArtifacts mockArtifacts;
    FakeProcessManager processManager;
    BufferLogger logger;

    setUp(() async {
      mockArtifacts = MockArtifacts();
      logger = BufferLogger.test();
      processManager = FakeProcessManager.list(<  FakeCommand>[]);
      genSnapshot = GenSnapshot(
        artifacts: mockArtifacts,
        logger: logger,
        processManager: processManager,
      );
      when(mockArtifacts.getArtifactPath(
        any,
        platform: anyNamed('platform'),
        mode: anyNamed('mode'),
      )).thenReturn('gen_snapshot');
    });

    testWithoutContext('android_x64', () async {
      processManager.addCommand(const FakeCommand(
        command: <String>['gen_snapshot', '--additional_arg']
      ));

      final int result = await genSnapshot.run(
        snapshotType: SnapshotType(TargetPlatform.android_x64, BuildMode.release),
        darwinArch: null,
        additionalArgs: <String>['--additional_arg'],
      );
      expect(result, 0);
    });

    testWithoutContext('iOS armv7', () async {
      processManager.addCommand(const FakeCommand(
        command: <String>['gen_snapshot_armv7', '--additional_arg']
      ));

      final int result = await genSnapshot.run(
        snapshotType: SnapshotType(TargetPlatform.ios, BuildMode.release),
        darwinArch: DarwinArch.armv7,
        additionalArgs: <String>['--additional_arg'],
      );
      expect(result, 0);
    });

    testWithoutContext('iOS arm64', () async {
      processManager.addCommand(const FakeCommand(
        command: <String>['gen_snapshot_arm64', '--additional_arg']
      ));

      final int result = await genSnapshot.run(
        snapshotType: SnapshotType(TargetPlatform.ios, BuildMode.release),
        darwinArch: DarwinArch.arm64,
        additionalArgs: <String>['--additional_arg'],
      );
      expect(result, 0);
    });

    testWithoutContext('--strip filters error output from gen_snapshot', () async {
        processManager.addCommand(FakeCommand(
        command: const <String>['gen_snapshot', '--strip'],
        stderr: 'ABC\n${GenSnapshot.kIgnoredWarnings.join('\n')}\nXYZ\n'
      ));

      final int result = await genSnapshot.run(
        snapshotType: SnapshotType(TargetPlatform.android_x64, BuildMode.release),
        darwinArch: null,
        additionalArgs: <String>['--strip'],
      );

      expect(result, 0);
      expect(logger.errorText, contains('ABC'));
      for (final String ignoredWarning in GenSnapshot.kIgnoredWarnings)  {
        expect(logger.errorText, isNot(contains(ignoredWarning)));
      }
      expect(logger.errorText, contains('XYZ'));
    });
  });

  group('AOTSnapshotter', () {
    MemoryFileSystem fileSystem;
    AOTSnapshotter snapshotter;
    MockArtifacts mockArtifacts;
    FakeProcessManager processManager;
    Logger logger;

    setUp(() async {
      final Platform platform = FakePlatform(operatingSystem: 'macos');
      logger = BufferLogger.test();
      fileSystem = MemoryFileSystem.test();
      mockArtifacts = MockArtifacts();
      processManager = FakeProcessManager.list(<FakeCommand>[]);
      snapshotter = AOTSnapshotter(
        fileSystem: fileSystem,
        logger: logger,
        xcode: Xcode(
          fileSystem: fileSystem,
          logger: logger,
          platform: FakePlatform(operatingSystem: 'macos'),
          processManager: processManager,
          xcodeProjectInterpreter: XcodeProjectInterpreter(
            platform: platform,
            processManager: processManager,
            logger: logger,
            fileSystem: fileSystem,
            terminal: Terminal.test(),
            usage: Usage.test(),
          ),
        ),
        artifacts: mockArtifacts,
        processManager: processManager,
      );
      when(mockArtifacts.getArtifactPath(
        Artifact.genSnapshot,
        platform: anyNamed('platform'),
        mode: anyNamed('mode')),
      ).thenReturn('gen_snapshot');
    });

    testWithoutContext('does not build iOS with debug build mode', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');

      expect(await snapshotter.build(
        platform: TargetPlatform.ios,
        darwinArch: DarwinArch.arm64,
        buildMode: BuildMode.debug,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        bitcode: false,
        splitDebugInfo: null,
        dartObfuscation: false,
      ), isNot(equals(0)));
    });

    testWithoutContext('does not build android-arm with debug build mode', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');

      expect(await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.debug,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        bitcode: false,
        splitDebugInfo: null,
        dartObfuscation: false,
      ), isNot(0));
    });

    testWithoutContext('does not build android-arm64 with debug build mode', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');

      expect(await snapshotter.build(
        platform: TargetPlatform.android_arm64,
        buildMode: BuildMode.debug,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        bitcode: false,
        splitDebugInfo: null,
        dartObfuscation: false,
      ), isNot(0));
    });

    testWithoutContext('builds iOS with bitcode', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      final String assembly = fileSystem.path.join(outputPath, 'snapshot_assembly.S');
      processManager.addCommand(FakeCommand(
        command: <String>[
          'gen_snapshot_armv7',
          '--deterministic',
          '--snapshot_kind=app-aot-assembly',
          '--assembly=$assembly',
          '--strip',
          '--no-sim-use-hardfp',
          '--no-use-integer-division',
          '--no-causal-async-stacks',
          '--lazy-async-stacks',
          'main.dill',
        ]
      ));
      processManager.addCommand(kARMCheckCommand);
      processManager.addCommand(kSdkPathCommand);
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'xcrun',
          'cc',
          '-arch',
          'armv7',
          '-isysroot',
          '',
          '-fembed-bitcode',
          '-c',
          'build/foo/snapshot_assembly.S',
          '-o',
          'build/foo/snapshot_assembly.o',
        ]
      ));
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'xcrun',
          'clang',
          '-arch',
          'armv7',
          ...kBitcodeClang,
        ]
      ));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.profile,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        darwinArch: DarwinArch.armv7,
        bitcode: true,
        splitDebugInfo: null,
        dartObfuscation: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager.hasRemainingExpectations, false);
    });

    testWithoutContext('builds iOS armv7 snapshot with dwarStackTraces', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      final String assembly = fileSystem.path.join(outputPath, 'snapshot_assembly.S');
      final String debugPath = fileSystem.path.join('foo', 'app.ios-armv7.symbols');
        processManager.addCommand(FakeCommand(
        command: <String>[
          'gen_snapshot_armv7',
          '--deterministic',
          '--snapshot_kind=app-aot-assembly',
          '--assembly=$assembly',
          '--strip',
          '--no-sim-use-hardfp',
          '--no-use-integer-division',
          '--no-causal-async-stacks',
          '--lazy-async-stacks',
          '--dwarf-stack-traces',
          '--save-debugging-info=$debugPath',
          'main.dill',
        ]
      ));
      processManager.addCommand(kARMCheckCommand);
      processManager.addCommand(kSdkPathCommand);
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'xcrun',
          'cc',
          '-arch',
          'armv7',
          '-isysroot',
          '',
          '-c',
          'build/foo/snapshot_assembly.S',
          '-o',
          'build/foo/snapshot_assembly.o',
        ]
      ));
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'xcrun',
          'clang',
          '-arch',
          'armv7',
          ...kDefaultClang,
        ]
      ));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.profile,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        darwinArch: DarwinArch.armv7,
        bitcode: false,
        splitDebugInfo: 'foo',
        dartObfuscation: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager.hasRemainingExpectations, false);
    });

    testWithoutContext('builds iOS armv7 snapshot with obfuscate', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      final String assembly = fileSystem.path.join(outputPath, 'snapshot_assembly.S');
      processManager.addCommand(FakeCommand(
        command: <String>[
          'gen_snapshot_armv7',
          '--deterministic',
          '--snapshot_kind=app-aot-assembly',
          '--assembly=$assembly',
          '--strip',
          '--no-sim-use-hardfp',
          '--no-use-integer-division',
          '--no-causal-async-stacks',
          '--lazy-async-stacks',
          '--obfuscate',
          'main.dill',
        ]
      ));
      processManager.addCommand(kARMCheckCommand);
      processManager.addCommand(kSdkPathCommand);
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'xcrun',
          'cc',
          '-arch',
          'armv7',
          '-isysroot',
          '',
          '-c',
          'build/foo/snapshot_assembly.S',
          '-o',
          'build/foo/snapshot_assembly.o',
        ]
      ));
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'xcrun',
          'clang',
          '-arch',
          'armv7',
          ...kDefaultClang,
        ]
      ));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.profile,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        darwinArch: DarwinArch.armv7,
        bitcode: false,
        splitDebugInfo: null,
        dartObfuscation: true,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager.hasRemainingExpectations, false);
    });


    testWithoutContext('builds iOS armv7 snapshot', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      processManager.addCommand(FakeCommand(
        command: <String>[
          'gen_snapshot_armv7',
          '--deterministic',
          '--snapshot_kind=app-aot-assembly',
          '--assembly=${fileSystem.path.join(outputPath, 'snapshot_assembly.S')}',
          '--strip',
          '--no-sim-use-hardfp',
          '--no-use-integer-division',
          '--no-causal-async-stacks',
          '--lazy-async-stacks',
          'main.dill',
        ]
      ));
      processManager.addCommand(kARMCheckCommand);
      processManager.addCommand(kSdkPathCommand);
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'xcrun',
          'cc',
          '-arch',
          'armv7',
          '-isysroot',
          '',
          '-c',
          'build/foo/snapshot_assembly.S',
          '-o',
          'build/foo/snapshot_assembly.o',
        ]
      ));
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'xcrun',
          'clang',
          '-arch',
          'armv7',
          ...kDefaultClang,
        ]
      ));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        darwinArch: DarwinArch.armv7,
        bitcode: false,
        splitDebugInfo: null,
        dartObfuscation: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager.hasRemainingExpectations, false);
    });

    testWithoutContext('builds iOS arm64 snapshot', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      processManager.addCommand(FakeCommand(
        command: <String>[
          'gen_snapshot_arm64',
          '--deterministic',
          '--snapshot_kind=app-aot-assembly',
          '--assembly=${fileSystem.path.join(outputPath, 'snapshot_assembly.S')}',
          '--strip',
          '--no-causal-async-stacks',
          '--lazy-async-stacks',
          'main.dill',
        ]
      ));
      processManager.addCommand(kARMCheckCommand);
      processManager.addCommand(kSdkPathCommand);
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'xcrun',
          'cc',
          '-arch',
          'arm64',
          '-isysroot',
          '',
          '-c',
          'build/foo/snapshot_assembly.S',
          '-o',
          'build/foo/snapshot_assembly.o',
        ]
      ));
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'xcrun',
          'clang',
          '-arch',
          'arm64',
          ...kDefaultClang,
        ]
      ));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        darwinArch: DarwinArch.arm64,
        bitcode: false,
        splitDebugInfo: null,
        dartObfuscation: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager.hasRemainingExpectations, false);
    });

    testWithoutContext('builds shared library for android-arm (32bit)', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gen_snapshot',
          '--deterministic',
          '--snapshot_kind=app-aot-elf',
          '--elf=build/foo/app.so',
          '--strip',
          '--no-sim-use-hardfp',
          '--no-use-integer-division',
          '--no-causal-async-stacks',
          '--lazy-async-stacks',
          'main.dill',
        ]
      ));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        bitcode: false,
        splitDebugInfo: null,
        dartObfuscation: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager.hasRemainingExpectations, false);
    });

    testWithoutContext('builds shared library for android-arm with dwarf stack traces', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      final String debugPath = fileSystem.path.join('foo', 'app.android-arm.symbols');
      processManager.addCommand(FakeCommand(
        command: <String>[
          'gen_snapshot',
          '--deterministic',
          '--snapshot_kind=app-aot-elf',
          '--elf=build/foo/app.so',
          '--strip',
          '--no-sim-use-hardfp',
          '--no-use-integer-division',
          '--no-causal-async-stacks',
          '--lazy-async-stacks',
          '--dwarf-stack-traces',
          '--save-debugging-info=$debugPath',
          'main.dill',
        ]
      ));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        bitcode: false,
        splitDebugInfo: 'foo',
        dartObfuscation: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager.hasRemainingExpectations, false);
    });

    testWithoutContext('builds shared library for android-arm with obfuscate', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gen_snapshot',
          '--deterministic',
          '--snapshot_kind=app-aot-elf',
          '--elf=build/foo/app.so',
          '--strip',
          '--no-sim-use-hardfp',
          '--no-use-integer-division',
          '--no-causal-async-stacks',
          '--lazy-async-stacks',
          '--obfuscate',
          'main.dill',
        ]
      ));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        bitcode: false,
        splitDebugInfo: null,
        dartObfuscation: true,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager.hasRemainingExpectations, false);
    });

    testWithoutContext('builds shared library for android-arm without dwarf stack traces due to empty string', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gen_snapshot',
          '--deterministic',
          '--snapshot_kind=app-aot-elf',
          '--elf=build/foo/app.so',
          '--strip',
          '--no-sim-use-hardfp',
          '--no-use-integer-division',
          '--no-causal-async-stacks',
          '--lazy-async-stacks',
          'main.dill',
        ]
      ));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        bitcode: false,
        splitDebugInfo: '',
        dartObfuscation: false,
      );

      expect(genSnapshotExitCode, 0);
       expect(processManager.hasRemainingExpectations, false);
    });

    testWithoutContext('builds shared library for android-arm64', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gen_snapshot',
          '--deterministic',
          '--snapshot_kind=app-aot-elf',
          '--elf=build/foo/app.so',
          '--strip',
          '--no-causal-async-stacks',
          '--lazy-async-stacks',
          'main.dill',
        ]
      ));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm64,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        bitcode: false,
        splitDebugInfo: null,
        dartObfuscation: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager.hasRemainingExpectations, false);
    });
  });
}

class MockArtifacts extends Mock implements Artifacts {}
