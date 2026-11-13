// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/depfile.dart';
import 'package:flutter_tools/src/build_system/targets/assets.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';
import '../../../src/package_config.dart';

void main() {
  late Environment environment;
  late FileSystem fileSystem;
  late BufferLogger logger;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    environment = Environment.test(
      fileSystem.currentDirectory,
      processManager: FakeProcessManager.any(),
      artifacts: Artifacts.test(),
      fileSystem: fileSystem,
      logger: logger,
      platform: FakePlatform(),
      defines: <String, String>{kBuildMode: BuildMode.debug.cliName},
    );
    fileSystem.file(environment.buildDir.childFile('app.dill')).createSync(recursive: true);
    fileSystem
        .file(environment.buildDir.childFile('native_assets.json'))
        .createSync(recursive: true);
    fileSystem
        .file('packages/flutter_tools/lib/src/build_system/targets/assets.dart')
        .createSync(recursive: true);
    fileSystem.file('assets/foo/bar.png').createSync(recursive: true);
    fileSystem.file('assets/wildcard/#bar.png').createSync(recursive: true);
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('''
name: example

flutter:
  assets:
    - assets/foo/bar.png
    - assets/wildcard/
''');
  });

  testWithoutContext('includes LICENSE file inputs in dependencies', () async {
    writePackageConfigFiles(
      directory: fileSystem.currentDirectory,
      mainLibName: 'example',
      packages: <String, String>{'foo': 'bar'},
    );
    fileSystem.file('bar/LICENSE')
      ..createSync(recursive: true)
      ..writeAsStringSync('THIS IS A LICENSE');

    await const CopyAssets().build(environment);

    final File depfile = environment.buildDir.childFile('flutter_assets.d');

    expect(depfile, exists);

    final Depfile dependencies = environment.depFileService.parse(depfile);

    expect(
      dependencies.inputs.firstWhereOrNull((File file) => file.path == '/bar/LICENSE'),
      isNotNull,
    );
  });

  testWithoutContext('Copies files to correct asset directory', () async {
    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');
    await const CopyAssets().build(environment);

    expect(
      fileSystem.file('${environment.buildDir.path}/flutter_assets/FontManifest.json'),
      exists,
    );
    expect(fileSystem.file('${environment.buildDir.path}/flutter_assets/NOTICES.Z'), exists);
    // See https://github.com/flutter/flutter/issues/35293
    expect(
      fileSystem.file('${environment.buildDir.path}/flutter_assets/assets/foo/bar.png'),
      exists,
    );
    // See https://github.com/flutter/flutter/issues/46163
    expect(
      fileSystem.file('${environment.buildDir.path}/flutter_assets/assets/wildcard/%23bar.png'),
      exists,
    );
  });

  group(
    "Only copies assets with a flavor if the assets' flavor matches the flavor in the environment",
    () {
      testWithoutContext('When the environment does not have a flavor defined', () async {
        fileSystem.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync('''
  name: example
  flutter:
    assets:
      - assets/common/
      - path: assets/vanilla/
        flavors:
          - vanilla
      - path: assets/strawberry/
        flavors:
          - strawberry
  ''');
        writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');

        fileSystem.file('assets/common/image.png').createSync(recursive: true);
        fileSystem.file('assets/vanilla/ice-cream.png').createSync(recursive: true);
        fileSystem.file('assets/strawberry/ice-cream.png').createSync(recursive: true);

        await const CopyAssets().build(environment);

        expect(
          fileSystem.file('${environment.buildDir.path}/flutter_assets/assets/common/image.png'),
          exists,
        );
        expect(
          fileSystem.file(
            '${environment.buildDir.path}/flutter_assets/assets/vanilla/ice-cream.png',
          ),
          isNot(exists),
        );
        expect(
          fileSystem.file(
            '${environment.buildDir.path}/flutter_assets/assets/strawberry/ice-cream.png',
          ),
          isNot(exists),
        );
        expect(logger.traceText, contains('Skipping assets entry "assets/vanilla/ice-cream.png"'));
        expect(
          logger.traceText,
          contains('Skipping assets entry "assets/strawberry/ice-cream.png"'),
        );
        expect(
          logger.traceText,
          isNot(contains('Skipping assets entry "assets/common/image.png"')),
        );
      });

      testWithoutContext('When the environment has a flavor defined', () async {
        environment.defines[kFlavor] = 'strawberry';
        fileSystem.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync('''
  name: example
  flutter:
    assets:
      - assets/common/
      - path: assets/vanilla/
        flavors:
          - vanilla
      - path: assets/strawberry/
        flavors:
          - strawberry
  ''');
        writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');

        fileSystem.file('assets/common/image.png').createSync(recursive: true);
        fileSystem.file('assets/vanilla/ice-cream.png').createSync(recursive: true);
        fileSystem.file('assets/strawberry/ice-cream.png').createSync(recursive: true);

        await const CopyAssets().build(environment);

        expect(
          fileSystem.file('${environment.buildDir.path}/flutter_assets/assets/common/image.png'),
          exists,
        );
        expect(
          fileSystem.file(
            '${environment.buildDir.path}/flutter_assets/assets/vanilla/ice-cream.png',
          ),
          isNot(exists),
        );
        expect(
          fileSystem.file(
            '${environment.buildDir.path}/flutter_assets/assets/strawberry/ice-cream.png',
          ),
          exists,
        );
        expect(logger.traceText, contains('Skipping assets entry "assets/vanilla/ice-cream.png"'));
        expect(
          logger.traceText,
          isNot(contains('Skipping assets entry "assets/strawberry/ice-cream.png"')),
        );
      });
    },
  );

  group("Only compiles shaders with a flavor if the shaders' flavor matches the flavor in the environment", () {
    testWithoutContext('When the environment does not have a flavor defined', () async {
      // Re-create the environment with the correct process manager for this test.
      environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: FakeProcessManager.any(),
        artifacts: Artifacts.test(),
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
        defines: <String, String>{kBuildMode: BuildMode.debug.cliName},
      );

      final artifacts = Artifacts.test();
      final String impellercPath = artifacts.getHostArtifact(HostArtifact.impellerc).path;
      fileSystem.file(impellercPath).createSync(recursive: true);

      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('''
name: example
flutter:
  shaders:
    - shaders/common.frag
    - path: shaders/premium.frag
      flavors:
        - premium
''');
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');

      fileSystem.file('shaders/common.frag').createSync(recursive: true);
      fileSystem.file('shaders/premium.frag').createSync(recursive: true);

      // Manually create expected output files since FakeProcessManager.any() won't create them
      fileSystem
          .file('${environment.buildDir.path}/flutter_assets/shaders/common.frag')
          .createSync(recursive: true);

      await const CopyAssets().build(environment);

      expect(
        fileSystem.file('${environment.buildDir.path}/flutter_assets/shaders/common.frag'),
        exists,
      );
      expect(
        fileSystem.file('${environment.buildDir.path}/flutter_assets/shaders/premium.frag'),
        isNot(exists),
      );
    });

    testWithoutContext('When the environment has a matching flavor defined', () async {
      // Re-create the environment with the correct process manager for this test.
      environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: FakeProcessManager.any(),
        artifacts: Artifacts.test(),
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
        defines: <String, String>{kBuildMode: BuildMode.debug.cliName},
      );

      final artifacts = Artifacts.test();
      final String impellercPath = artifacts.getHostArtifact(HostArtifact.impellerc).path;
      fileSystem.file(impellercPath).createSync(recursive: true);

      environment.defines[kFlavor] = 'premium';
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('''
name: example
flutter:
  shaders:
    - shaders/common.frag
    - path: shaders/premium.frag
      flavors:
        - premium
''');
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');

      fileSystem.file('shaders/common.frag').createSync(recursive: true);
      fileSystem.file('shaders/premium.frag').createSync(recursive: true);

      // Manually create expected output files since FakeProcessManager.any() won't create them
      fileSystem
          .file('${environment.buildDir.path}/flutter_assets/shaders/common.frag')
          .createSync(recursive: true);
      fileSystem
          .file('${environment.buildDir.path}/flutter_assets/shaders/premium.frag')
          .createSync(recursive: true);

      await const CopyAssets().build(environment);

      expect(
        fileSystem.file('${environment.buildDir.path}/flutter_assets/shaders/common.frag'),
        exists,
      );
      expect(
        fileSystem.file('${environment.buildDir.path}/flutter_assets/shaders/premium.frag'),
        exists,
      );
    });

    testWithoutContext('When the environment has a mismatching flavor defined', () async {
      // Re-create the environment with the correct process manager for this test.
      environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: FakeProcessManager.any(),
        artifacts: Artifacts.test(),
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
        defines: <String, String>{kBuildMode: BuildMode.debug.cliName},
      );

      final artifacts = Artifacts.test();
      final String impellercPath = artifacts.getHostArtifact(HostArtifact.impellerc).path;
      fileSystem.file(impellercPath).createSync(recursive: true);

      environment.defines[kFlavor] = 'free'; // Mismatch
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('''
name: example
flutter:
  shaders:
    - shaders/common.frag
    - path: shaders/premium.frag
      flavors:
        - premium
''');
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');

      fileSystem.file('shaders/common.frag').createSync(recursive: true);
      fileSystem.file('shaders/premium.frag').createSync(recursive: true);

      // Manually create expected output files for the ones that SHOULD exist
      fileSystem
          .file('${environment.buildDir.path}/flutter_assets/shaders/common.frag')
          .createSync(recursive: true);

      await const CopyAssets().build(environment);

      expect(
        fileSystem.file('${environment.buildDir.path}/flutter_assets/shaders/common.frag'),
        exists,
      );
      expect(
        fileSystem.file('${environment.buildDir.path}/flutter_assets/shaders/premium.frag'),
        isNot(exists),
      );
    });
  });

  testWithoutContext('transforms assets declared with transformers', () async {
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <Pattern>[
          Artifacts.test().getArtifactPath(Artifact.engineDartBinary),
          'run',
          'my_capitalizer_transformer',
          RegExp('--input=.*'),
          RegExp('--output=.*'),
          '-a',
          '-b',
          '--color',
          'green',
        ],
        onRun: (List<String> args) {
          final ArgResults parsedArgs =
              (ArgParser()
                    ..addOption('input')
                    ..addOption('output')
                    ..addOption('color')
                    ..addFlag('aaa', abbr: 'a')
                    ..addFlag('bbb', abbr: 'b'))
                  .parse(args);

          expect(parsedArgs['aaa'], true);
          expect(parsedArgs['bbb'], true);
          expect(parsedArgs['color'], 'green');

          final File input = fileSystem.file(parsedArgs['input'] as String);
          expect(input, exists);
          final String inputContents = input.readAsStringSync();
          expect(inputContents, 'abc');
          fileSystem.file(parsedArgs['output'])
            ..createSync()
            ..writeAsStringSync(inputContents.toUpperCase());
        },
      ),
    ]);
    final environment = Environment.test(
      fileSystem.currentDirectory,
      processManager: processManager,
      artifacts: Artifacts.test(),
      fileSystem: fileSystem,
      logger: logger,
      platform: FakePlatform(),
      defines: <String, String>{kBuildMode: BuildMode.debug.cliName},
    );

    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('''
name: example
flutter:
  assets:
    - path: input.txt
      transformers:
        - package: my_capitalizer_transformer
          args: ["-a", "-b", "--color", "green"]
''');

    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');

    fileSystem.file('input.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('abc');

    await const CopyAssets().build(environment);

    expect(logger.errorText, isEmpty);
    expect(processManager, hasNoRemainingExpectations);
    expect(fileSystem.file('${environment.buildDir.path}/flutter_assets/input.txt'), exists);
  });

  testWithoutContext('transforms shaders declared with transformers before compilation', () async {
    final artifacts = Artifacts.test();
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <Pattern>[
          artifacts.getArtifactPath(Artifact.engineDartBinary),
          'run',
          'my_capitalizer_transformer',
          RegExp('--input=.*'),
          RegExp('--output=.*'),
        ],
        onRun: (List<String> args) {
          final ArgResults parsedArgs =
              (ArgParser()
                    ..addOption('input')
                    ..addOption('output'))
                  .parse(args);

          final File input = fileSystem.file(parsedArgs['input'] as String);
          expect(input, exists);
          expect(input.readAsStringSync(), 'abc');

          fileSystem.file(parsedArgs['output'])
            ..createSync(recursive: true)
            ..writeAsStringSync('ABC');
        },
      ),
      FakeCommand(
        command: <Pattern>[
          RegExp(r'.*impellerc.*'),
          // Match the 11 arguments generated by ShaderCompiler.compileShader.
          ...List<Pattern>.filled(11, RegExp(r'.*')),
        ],
        onRun: (List<String> args) {
          String? inputPath;
          String? outputPath;
          String? outputSpirvPath;
          for (final arg in args) {
            if (arg.startsWith('--input=')) {
              inputPath = arg.substring('--input='.length);
            } else if (arg.startsWith('--sl=')) {
              outputPath = arg.substring('--sl='.length);
            } else if (arg.startsWith('--spirv=')) {
              outputSpirvPath = arg.substring('--spirv='.length);
            }
          }

          expect(inputPath, isNotNull);
          expect(outputPath, isNotNull);
          expect(outputSpirvPath, isNotNull);

          final File input = fileSystem.file(inputPath);
          expect(input, exists);
          expect(input.readAsStringSync(), 'ABC');

          fileSystem.file(outputPath).createSync(recursive: true);
          fileSystem.file(outputSpirvPath).createSync(recursive: true);
        },
      ),
    ]);
    final environment = Environment.test(
      fileSystem.currentDirectory,
      processManager: processManager,
      artifacts: artifacts,
      fileSystem: fileSystem,
      logger: logger,
      platform: FakePlatform(),
      defines: <String, String>{kBuildMode: BuildMode.debug.cliName},
    );

    final String impellercPath = artifacts.getHostArtifact(HostArtifact.impellerc).path;
    fileSystem.file(impellercPath).createSync(recursive: true);

    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('''
name: example
flutter:
  shaders:
    - path: shaders/test.frag
      transformers:
        - package: my_capitalizer_transformer
''');

    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');

    fileSystem.file('shaders/test.frag')
      ..createSync(recursive: true)
      ..writeAsStringSync('abc');

    await const CopyAssets().build(environment);

    expect(logger.errorText, isEmpty);
    expect(processManager, hasNoRemainingExpectations);
    expect(
      fileSystem.file('${environment.buildDir.path}/flutter_assets/shaders/test.frag'),
      exists,
    );
  });

  testWithoutContext('exits tool if an asset transformation fails', () async {
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <Pattern>[
          Artifacts.test().getArtifactPath(Artifact.engineDartBinary),
          'run',
          'my_transformer',
          RegExp('--input=.*'),
          RegExp('--output=.*'),
          '-a',
          '-b',
          '--color',
          'green',
        ],
        exitCode: 1,
      ),
    ]);
    final environment = Environment.test(
      fileSystem.currentDirectory,
      processManager: processManager,
      artifacts: Artifacts.test(),
      fileSystem: fileSystem,
      logger: logger,
      platform: FakePlatform(),
      defines: <String, String>{kBuildMode: BuildMode.debug.cliName},
    );

    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('''
name: example
flutter:
  assets:
    - path: input.txt
      transformers:
        - package: my_transformer
          args: ["-a", "-b", "--color", "green"]
''');

    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');

    await fileSystem.file('input.txt').create(recursive: true);

    await expectToolExitLater(
      const CopyAssets().build(environment),
      startsWith('User-defined transformation of asset "input.txt" failed.\n'),
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext(
    'asset transformation, per each asset, uses unique paths for temporary files',
    () async {
      final inputFilePaths = <String>[];
      final outputFilePaths = <String>[];

      final transformerCommand = FakeCommand(
        command: <Pattern>[
          Artifacts.test().getArtifactPath(Artifact.engineDartBinary),
          'run',
          'my_capitalizer_transformer',
          RegExp('--input=.*'),
          RegExp('--output=.*'),
        ],
        onRun: (List<String> args) {
          final ArgResults parsedArgs =
              (ArgParser()
                    ..addOption('input')
                    ..addOption('output'))
                  .parse(args);

          final input = parsedArgs['input'] as String;
          final output = parsedArgs['output'] as String;

          inputFilePaths.add(input);
          outputFilePaths.add(output);

          fileSystem.file(output)
            ..createSync()
            ..writeAsStringSync('foo');
        },
      );

      final processManager = FakeProcessManager.list(<FakeCommand>[
        transformerCommand,
        transformerCommand,
      ]);
      final environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: processManager,
        artifacts: Artifacts.test(),
        fileSystem: fileSystem,
        logger: logger,
        platform: FakePlatform(numberOfProcessors: 64),
        defines: <String, String>{kBuildMode: BuildMode.debug.cliName},
      );

      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('''
  name: example
  flutter:
    assets:
      - path: input.txt
        transformers:
          - package: my_capitalizer_transformer
  ''');

      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');

      fileSystem.file('input.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('abc');

      fileSystem.directory('2x').childFile('input.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('def');

      await const CopyAssets().build(environment);

      expect(inputFilePaths.toSet(), hasLength(inputFilePaths.length));
      expect(outputFilePaths.toSet(), hasLength(outputFilePaths.length));
      expect(processManager, hasNoRemainingExpectations);
    },
  );

  group('platform-specific assets', () {
    /// All supported platforms that should be validated.
    const kValidPluginPlatforms = <String>{'android', 'ios', 'web', 'windows', 'linux', 'macos'};

    TargetPlatform targetFor(String platform) =>
        TargetPlatform.values.firstWhere((p) => p.osName == platform);

    /// Writes a `pubspec.yaml` with an asset, optionally restricted to
    /// certain [platforms], then runs the build for [targetPlatform] and
    /// returns whether the asset was bundled.
    ///
    /// This helper reflects how Flutter decides which assets to include
    /// depending on the `platforms:` key in `pubspec.yaml`.
    Future<bool> setupAndBuildPlatformAsset(String platform, TargetPlatform targetPlatform) async {
      final filePath = 'assets/test-$platform.txt';

      final pubspec = platform.isEmpty
          ? '''
name: example
flutter:
  assets:
    - path: $filePath
'''
          : '''
name: example
flutter:
  assets:
    - path: $filePath
      platforms:
        - $platform
''';

      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(pubspec);
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');
      fileSystem.file(filePath).createSync(recursive: true);

      await const CopyAssets().build(environment, targetPlatform: targetPlatform);

      final File file = fileSystem.file('${environment.buildDir.path}/flutter_assets/$filePath');
      return file.existsSync();
    }

    group('includes assets only for matching platform', () {
      for (final platform in kValidPluginPlatforms) {
        testWithoutContext(platform, () async {
          final TargetPlatform targetPlatform = targetFor(platform);
          final bool didInclude = await setupAndBuildPlatformAsset(platform, targetPlatform);

          expect(didInclude, isTrue, reason: 'Expected asset for $platform to be included');
        });
      }
    });

    group('skips assets for non-matching platform', () {
      for (final platform in kValidPluginPlatforms) {
        testWithoutContext(platform, () async {
          final TargetPlatform targetPlatform = platform == 'android'
              ? TargetPlatform.ios
              : TargetPlatform.android;
          final bool didInclude = await setupAndBuildPlatformAsset(platform, targetPlatform);

          expect(
            didInclude,
            isFalse,
            reason: 'Expected asset for $platform to be skipped when target is $targetPlatform',
          );
          expect(logger.traceText, contains('Skipping assets entry "assets/test-$platform.txt"'));
        });
      }
    });

    group('includes assets for all platforms when no restriction is set', () {
      for (final platform in kValidPluginPlatforms) {
        testWithoutContext(platform, () async {
          final TargetPlatform targetPlatform = targetFor(platform);
          final bool didInclude = await setupAndBuildPlatformAsset('', targetPlatform);

          expect(
            didInclude,
            isTrue,
            reason:
                'Expected asset to be included for all platforms when no platforms are specified (platform: $platform)',
          );
        });
      }
    });

    group('includes assets only for declared multiple platforms', () {
      for (final platform in kValidPluginPlatforms) {
        testWithoutContext(platform, () async {
          const filePath = 'assets/test-multi.txt';
          final targetPlatforms = <String>['android', 'ios'];

          fileSystem.file('pubspec.yaml')
            ..createSync()
            ..writeAsStringSync('''
name: example
flutter:
  assets:
    - path: $filePath
      platforms: [${targetPlatforms.join(',')}]
''');

          writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');
          fileSystem.file(filePath).createSync(recursive: true);

          final TargetPlatform targetPlatform = targetFor(platform);

          await const CopyAssets().build(environment, targetPlatform: targetPlatform);

          final File bundledFile = fileSystem.file(
            '${environment.buildDir.path}/flutter_assets/$filePath',
          );

          final bool exists = bundledFile.existsSync();

          if (targetPlatforms.contains(platform)) {
            expect(exists, isTrue, reason: 'Expected asset to be included for $platform');
          } else {
            expect(exists, isFalse, reason: 'Expected asset to be skipped for $platform');
          }
        });
      }
    });
  });

  testWithoutContext('Uses processors~/2 to transform assets', () async {
    const assetsToTransform = 5;

    final inputFilePaths = <String>[];
    final outputFilePaths = <String>[];
    final markTransformDone = Completer<void>();
    var totalTransformsRunning = 0;

    final transformerCommand = FakeCommand(
      command: <Pattern>[
        Artifacts.test().getArtifactPath(Artifact.engineDartBinary),
        'run',
        'my_capitalizer_transformer',
        RegExp('--input=.*'),
        RegExp('--output=.*'),
      ],
      onRun: (List<String> args) {
        totalTransformsRunning++;
        final ArgResults parsedArgs =
            (ArgParser()
                  ..addOption('input')
                  ..addOption('output'))
                .parse(args);

        final input = parsedArgs['input'] as String;
        final output = parsedArgs['output'] as String;

        inputFilePaths.add(input);
        outputFilePaths.add(output);

        fileSystem.file(output)
          ..createSync()
          ..writeAsStringSync('foo');
      },
      completer: markTransformDone,
    );

    final processManager = FakeProcessManager.list(
      List<FakeCommand>.filled(assetsToTransform, transformerCommand, growable: true),
    );
    final environment = Environment.test(
      fileSystem.currentDirectory,
      processManager: processManager,
      artifacts: Artifacts.test(),
      fileSystem: fileSystem,
      logger: logger,
      platform: FakePlatform(numberOfProcessors: 4),
      defines: <String, String>{kBuildMode: BuildMode.debug.cliName},
    );

    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('''
  name: example
  flutter:
    assets:
      - path: input.txt
        transformers:
          - package: my_capitalizer_transformer
  ''');

    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');

    fileSystem.file('input.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('abc');

    for (var i = 0; i < assetsToTransform - 1; i++) {
      fileSystem.directory('${i + 2}x').childFile('input.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('def');
    }

    final Future<void> waitFor = const CopyAssets().build(environment);
    await pumpEventQueue();
    expect(
      totalTransformsRunning,
      2,
      reason: 'Only 2 transforms should be running at a time (4 ~/ 2)',
    );
    markTransformDone.complete();
    await waitFor;

    expect(inputFilePaths, hasLength(5));
    expect(outputFilePaths, hasLength(5));
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Throws exception if pubspec contains missing files', () async {
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('''
name: example

flutter:
  assets:
    - assets/foo/bar2.png

''');

    expect(() async => const CopyAssets().build(environment), throwsException);
  });
}
