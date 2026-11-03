// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/macos/xcode.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart' show FakeToolContext;

void main() {
  const kWhichSysctlCommand = FakeCommand(command: <String>['which', 'sysctl']);

  // x64 host.
  const kx64CheckCommand = FakeCommand(
    command: <String>['sysctl', 'hw.optional.arm64'],
    exitCode: 1,
  );
  group('GenSnapshot', () {
    late GenSnapshot genSnapshot;
    late Artifacts artifacts;
    late FakeProcessManager processManager;
    late BufferLogger logger;

    setUp(() async {
      artifacts = Artifacts.test();
      logger = BufferLogger.test();
      processManager = FakeProcessManager.list(<FakeCommand>[]);
      genSnapshot = GenSnapshot(
        artifacts: artifacts,
        logger: logger,
        processManager: processManager,
      );
    });

    testWithoutContext('android_x64', () async {
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            artifacts.getArtifactPath(
              Artifact.genSnapshot,
              platform: TargetPlatform.android_x64,
              mode: BuildMode.release,
            ),
            '--additional_arg',
          ],
        ),
      );

      final int result = await genSnapshot.run(
        snapshotType: SnapshotType(TargetPlatform.android_x64, BuildMode.release),
        additionalArgs: <String>['--additional_arg'],
      );
      expect(result, 0);
    });

    testWithoutContext('iOS arm64', () async {
      final String genSnapshotPath = artifacts.getArtifactPath(
        Artifact.genSnapshotArm64,
        platform: TargetPlatform.ios,
        mode: BuildMode.release,
      );
      processManager.addCommand(
        FakeCommand(command: <String>[genSnapshotPath, '--additional_arg']),
      );

      final int result = await genSnapshot.run(
        snapshotType: SnapshotType(TargetPlatform.ios, BuildMode.release),
        cpuArch: CpuArch.arm64,
        additionalArgs: <String>['--additional_arg'],
      );
      expect(result, 0);
    });

    testWithoutContext('--strip filters error output from gen_snapshot', () async {
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            artifacts.getArtifactPath(
              Artifact.genSnapshot,
              platform: TargetPlatform.android_x64,
              mode: BuildMode.release,
            ),
            '--strip',
          ],
          stderr: 'ABC\n${GenSnapshot.kIgnoredWarnings.join('\n')}\nXYZ\n',
        ),
      );

      final int result = await genSnapshot.run(
        snapshotType: SnapshotType(TargetPlatform.android_x64, BuildMode.release),
        additionalArgs: <String>['--strip'],
      );

      expect(result, 0);
      expect(logger.errorText, contains('ABC'));
      for (final String ignoredWarning in GenSnapshot.kIgnoredWarnings) {
        expect(logger.errorText, isNot(contains(ignoredWarning)));
      }
      expect(logger.errorText, contains('XYZ'));
    });

    testWithoutContext(
      'filters the second line of a two-line warning only after its first line',
      () async {
        const elfWarning =
            'Warning: The generated ELF library contains unobfuscated DWARF debugging information.';
        final MapEntry<String, String> peCoffWarning =
            GenSnapshot.kIgnoredTwoLineWarnings.entries.single;
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              artifacts.getArtifactPath(
                Artifact.genSnapshot,
                platform: TargetPlatform.windows_x64,
                mode: BuildMode.release,
              ),
            ],
            stderr:
                'ABC\n'
                '${peCoffWarning.key}\n'
                '${peCoffWarning.value}\n'
                '$elfWarning\n'
                '${peCoffWarning.value}\n'
                'XYZ\n',
          ),
        );

        final int result = await genSnapshot.run(
          snapshotType: SnapshotType(TargetPlatform.windows_x64, BuildMode.release),
        );

        expect(result, 0);
        expect(logger.errorText, 'ABC\n$elfWarning\n${peCoffWarning.value}\nXYZ\n');
      },
    );
  });

  group('AOTSnapshotter', () {
    late MemoryFileSystem fileSystem;
    late AOTSnapshotter snapshotter;
    late Artifacts artifacts;
    late FakeProcessManager processManager;

    setUp(() async {
      fileSystem = MemoryFileSystem.test();
      fileSystem.file(r'C:\VS\link.exe').createSync(recursive: true);
      artifacts = Artifacts.test();
      processManager = FakeProcessManager.empty();
      snapshotter = AOTSnapshotter(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        xcode: Xcode.test(toolContext: FakeToolContext.macosHost(processManager: processManager)),
        artifacts: artifacts,
        processManager: processManager,
        windowsLinkerPath: r'C:\VS\link.exe',
      );
    });

    testWithoutContext('does not build iOS with debug build mode', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');

      expect(
        await snapshotter.build(
          platform: TargetPlatform.ios,
          cpuArch: CpuArch.arm64,
          sdkRoot: 'path/to/sdk',
          buildMode: BuildMode.debug,
          mainPath: 'main.dill',
          outputPath: outputPath,
          dartObfuscation: false,
        ),
        isNot(equals(0)),
      );
    });

    testWithoutContext('does not build android-arm with debug build mode', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');

      expect(
        await snapshotter.build(
          platform: TargetPlatform.android_arm,
          buildMode: BuildMode.debug,
          mainPath: 'main.dill',
          outputPath: outputPath,
          dartObfuscation: false,
        ),
        isNot(0),
      );
    });

    testWithoutContext('does not build android-arm64 with debug build mode', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');

      expect(
        await snapshotter.build(
          platform: TargetPlatform.android_arm64,
          buildMode: BuildMode.debug,
          mainPath: 'main.dill',
          outputPath: outputPath,
          dartObfuscation: false,
        ),
        isNot(0),
      );
    });

    testWithoutContext('builds iOS snapshot with dwarfStackTraces', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      final String debugPath = fileSystem.path.join('foo', 'app.ios-arm64.symbols');
      final String genSnapshotPath = artifacts.getArtifactPath(
        Artifact.genSnapshotArm64,
        platform: TargetPlatform.ios,
        mode: BuildMode.profile,
      );
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            genSnapshotPath,
            '--deterministic',
            '--snapshot_kind=app-aot-macho-dylib',
            '--macho=$outputPath/App.framework/App',
            '--macho-object=$outputPath/app.o',
            '--macho-min-os-version=15.0',
            '--macho-rpath=@executable_path/Frameworks,@loader_path/Frameworks',
            '--macho-install-name=@rpath/App.framework/App',
            '--dwarf-stack-traces',
            '--resolve-dwarf-paths',
            '--save-debugging-info=$debugPath',
            'main.dill',
          ],
        ),
        kWhichSysctlCommand,
        kx64CheckCommand,
        FakeCommand(
          command: <String>[
            'xcrun',
            'dsymutil',
            '-o',
            '$outputPath/App.framework.dSYM',
            '$outputPath/App.framework/App',
          ],
        ),
        FakeCommand(
          command: <String>[
            'xcrun',
            'strip',
            '-x',
            '$outputPath/App.framework/App',
            '-o',
            '$outputPath/App.framework/App',
          ],
        ),
      ]);

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.profile,
        mainPath: 'main.dill',
        outputPath: outputPath,
        cpuArch: CpuArch.arm64,
        sdkRoot: 'path/to/sdk',
        splitDebugInfo: 'foo',
        dartObfuscation: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('builds iOS snapshot with obfuscate', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      final String genSnapshotPath = artifacts.getArtifactPath(
        Artifact.genSnapshotArm64,
        platform: TargetPlatform.ios,
        mode: BuildMode.profile,
      );
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            genSnapshotPath,
            '--deterministic',
            '--snapshot_kind=app-aot-macho-dylib',
            '--macho=$outputPath/App.framework/App',
            '--macho-object=$outputPath/app.o',
            '--macho-min-os-version=15.0',
            '--macho-rpath=@executable_path/Frameworks,@loader_path/Frameworks',
            '--macho-install-name=@rpath/App.framework/App',
            '--obfuscate',
            'main.dill',
          ],
        ),
        kWhichSysctlCommand,
        kx64CheckCommand,
        FakeCommand(
          command: <String>[
            'xcrun',
            'dsymutil',
            '-o',
            '$outputPath/App.framework.dSYM',
            '$outputPath/App.framework/App',
          ],
        ),
        FakeCommand(
          command: <String>[
            'xcrun',
            'strip',
            '-x',
            '$outputPath/App.framework/App',
            '-o',
            '$outputPath/App.framework/App',
          ],
        ),
      ]);

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.profile,
        mainPath: 'main.dill',
        outputPath: outputPath,
        cpuArch: CpuArch.arm64,
        sdkRoot: 'path/to/sdk',
        dartObfuscation: true,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('builds iOS snapshot', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      final String genSnapshotPath = artifacts.getArtifactPath(
        Artifact.genSnapshotArm64,
        platform: TargetPlatform.ios,
        mode: BuildMode.release,
      );
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            genSnapshotPath,
            '--deterministic',
            '--snapshot_kind=app-aot-macho-dylib',
            '--macho=$outputPath/App.framework/App',
            '--macho-object=$outputPath/app.o',
            '--macho-min-os-version=15.0',
            '--macho-rpath=@executable_path/Frameworks,@loader_path/Frameworks',
            '--macho-install-name=@rpath/App.framework/App',
            'main.dill',
          ],
        ),
        kWhichSysctlCommand,
        kx64CheckCommand,
        FakeCommand(
          command: <String>[
            'xcrun',
            'dsymutil',
            '-o',
            '$outputPath/App.framework.dSYM',
            '$outputPath/App.framework/App',
          ],
        ),
        FakeCommand(
          command: <String>[
            'xcrun',
            'strip',
            '-x',
            '$outputPath/App.framework/App',
            '-o',
            '$outputPath/App.framework/App',
          ],
        ),
      ]);

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        outputPath: outputPath,
        cpuArch: CpuArch.arm64,
        sdkRoot: 'path/to/sdk',
        dartObfuscation: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('builds shared library for android-arm (32bit)', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            artifacts.getArtifactPath(
              Artifact.genSnapshot,
              platform: TargetPlatform.android_arm,
              mode: BuildMode.release,
            ),
            '--deterministic',
            '--snapshot_kind=app-aot-elf',
            '--elf=build/foo/app.so',
            '--no-use-integer-division',
            'main.dill',
          ],
        ),
      );

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        outputPath: outputPath,
        dartObfuscation: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('builds shared library for android-arm with dwarf stack traces', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      final String debugPath = fileSystem.path.join('foo', 'app.android-arm.symbols');
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            artifacts.getArtifactPath(
              Artifact.genSnapshot,
              platform: TargetPlatform.android_arm,
              mode: BuildMode.release,
            ),
            '--deterministic',
            '--snapshot_kind=app-aot-elf',
            '--elf=build/foo/app.so',
            '--no-use-integer-division',
            '--dwarf-stack-traces',
            '--resolve-dwarf-paths',
            '--save-debugging-info=$debugPath',
            'main.dill',
          ],
        ),
      );

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        outputPath: outputPath,
        splitDebugInfo: 'foo',
        dartObfuscation: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('builds shared library for android-arm with obfuscate', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            artifacts.getArtifactPath(
              Artifact.genSnapshot,
              platform: TargetPlatform.android_arm,
              mode: BuildMode.release,
            ),
            '--deterministic',
            '--snapshot_kind=app-aot-elf',
            '--elf=build/foo/app.so',
            '--no-use-integer-division',
            '--obfuscate',
            'main.dill',
          ],
        ),
      );

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        outputPath: outputPath,
        dartObfuscation: true,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext(
      'builds shared library for android-arm without dwarf stack traces due to empty string',
      () async {
        final String outputPath = fileSystem.path.join('build', 'foo');
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              artifacts.getArtifactPath(
                Artifact.genSnapshot,
                platform: TargetPlatform.android_arm,
                mode: BuildMode.release,
              ),
              '--deterministic',
              '--snapshot_kind=app-aot-elf',
              '--elf=build/foo/app.so',
              '--no-use-integer-division',
              'main.dill',
            ],
          ),
        );

        final int genSnapshotExitCode = await snapshotter.build(
          platform: TargetPlatform.android_arm,
          buildMode: BuildMode.release,
          mainPath: 'main.dill',
          outputPath: outputPath,
          splitDebugInfo: '',
          dartObfuscation: false,
        );

        expect(genSnapshotExitCode, 0);
        expect(processManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext('builds shared library for android-arm64', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            artifacts.getArtifactPath(
              Artifact.genSnapshot,
              platform: TargetPlatform.android_arm64,
              mode: BuildMode.release,
            ),
            '--deterministic',
            '--snapshot_kind=app-aot-elf',
            '--elf=build/foo/app.so',
            'main.dill',
          ],
        ),
      );

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm64,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        outputPath: outputPath,
        dartObfuscation: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('builds PE library and PDB for windows-x64', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      final String pdbPath = fileSystem.path.join(outputPath, 'app.pdb');
      fileSystem.file(pdbPath).createSync(recursive: true);

      processManager
        ..addCommand(
          FakeCommand(
            command: <String>[
              artifacts.getArtifactPath(
                Artifact.genSnapshot,
                platform: TargetPlatform.windows_x64,
                mode: BuildMode.release,
              ),
              '--deterministic',
              '--snapshot_kind=app-aot-pecoff-obj',
              '--coff=build/foo/app.o',
              '--strip',
              'main.dill',
            ],
          ),
        )
        ..addCommand(
          FakeCommand(
            command: const <String>[
              r'C:\VS\link.exe',
              '/NOLOGO',
              '/DLL',
              '/NOENTRY',
              '/MACHINE:X64',
              '/DEBUG',
              '/INCREMENTAL:NO',
              '/Brepro',
              '/OUT:build/foo/app.so',
              '/PDB:build/foo/app.pdb',
              '/PDBALTPATH:%_PDB%',
              '/EXPORT:_kDartSnapshotData,DATA',
              '/EXPORT:_kDartSnapshotText,DATA',
              'build/foo/app.o',
            ],
            onRun: (_) {
              // The linker would update the previous PDB instead of
              // replacing it.
              expect(fileSystem.file(pdbPath).existsSync(), false);
            },
          ),
        );

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.windows_x64,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        outputPath: outputPath,
        dartObfuscation: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('builds windows-x64 split debug info PDB outside output path', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      final String splitDebugInfoPath = fileSystem.path.join('build', 'symbols');
      final String stalePdbPath = fileSystem.path.join(outputPath, 'app.pdb');
      fileSystem.file(stalePdbPath).createSync(recursive: true);
      final String pdbPath = fileSystem.path.join(splitDebugInfoPath, 'app.windows-x64.pdb');
      fileSystem.file(pdbPath).createSync(recursive: true);

      processManager
        ..addCommand(
          FakeCommand(
            command: <String>[
              artifacts.getArtifactPath(
                Artifact.genSnapshot,
                platform: TargetPlatform.windows_x64,
                mode: BuildMode.release,
              ),
              '--deterministic',
              '--snapshot_kind=app-aot-pecoff-obj',
              '--coff=build/foo/app.o',
              '--dwarf-stack-traces',
              '--resolve-dwarf-paths',
              '--obfuscate',
              'main.dill',
            ],
          ),
        )
        ..addCommand(
          FakeCommand(
            command: const <String>[
              r'C:\VS\link.exe',
              '/NOLOGO',
              '/DLL',
              '/NOENTRY',
              '/MACHINE:X64',
              '/DEBUG',
              '/INCREMENTAL:NO',
              '/Brepro',
              '/OUT:build/foo/app.so',
              '/PDB:build/symbols/app.windows-x64.pdb',
              '/PDBALTPATH:%_PDB%',
              '/EXPORT:_kDartSnapshotData,DATA',
              '/EXPORT:_kDartSnapshotText,DATA',
              'build/foo/app.o',
            ],
            onRun: (_) {
              expect(fileSystem.file(pdbPath).existsSync(), false);
            },
          ),
        );

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.windows_x64,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        outputPath: outputPath,
        splitDebugInfo: splitDebugInfoPath,
        dartObfuscation: true,
      );

      expect(genSnapshotExitCode, 0);
      expect(fileSystem.file(stalePdbPath).existsSync(), false);
      expect(fileSystem.directory(splitDebugInfoPath).existsSync(), true);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('fails when the Visual Studio linker does not exist', () async {
      final logger = BufferLogger.test();
      final snapshotter = AOTSnapshotter(
        fileSystem: fileSystem,
        logger: logger,
        xcode: Xcode.test(toolContext: FakeToolContext.macosHost(processManager: processManager)),
        artifacts: artifacts,
        processManager: processManager,
        windowsLinkerPath: r'C:\VS\does-not-exist\link.exe',
      );
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            artifacts.getArtifactPath(
              Artifact.genSnapshot,
              platform: TargetPlatform.windows_x64,
              mode: BuildMode.release,
            ),
            '--deterministic',
            '--snapshot_kind=app-aot-pecoff-obj',
            '--coff=build/foo/app.o',
            '--strip',
            'main.dill',
          ],
        ),
      );

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.windows_x64,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        outputPath: fileSystem.path.join('build', 'foo'),
        dartObfuscation: false,
      );

      expect(genSnapshotExitCode, 1);
      expect(logger.errorText, contains('Unable to find Visual Studio link.exe'));
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('--no-strip in extraGenSnapshotOptions suppresses --strip', () async {
      final String outputPath = fileSystem.path.join('build', 'foo');
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            artifacts.getArtifactPath(
              Artifact.genSnapshot,
              platform: TargetPlatform.android_arm64,
              mode: BuildMode.release,
            ),
            '--deterministic',
            '--snapshot_kind=app-aot-elf',
            '--elf=build/foo/app.so',
            'main.dill',
          ],
        ),
      );

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm64,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        outputPath: outputPath,
        dartObfuscation: false,
        extraGenSnapshotOptions: const <String>['--no-strip'],
      );

      expect(genSnapshotExitCode, 0);
      expect(processManager, hasNoRemainingExpectations);
    });
  });
}
