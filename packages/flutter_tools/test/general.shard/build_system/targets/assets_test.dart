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
import 'package:flutter_tools/src/isolated/native_assets/dart_hook_result.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';
import '../../../src/fakes.dart';
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
      featureFlags: TestFeatureFlags(),
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

  test('includes LICENSE file inputs in dependencies', () async {
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

  test('Copies files to correct asset directory', () async {
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
      test('When the environment does not have a flavor defined', () async {
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

      test('When the environment has a flavor defined', () async {
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
    test('When the environment does not have a flavor defined', () async {
      // Re-create the environment with the correct process manager for this test.
      environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: FakeProcessManager.any(),
        artifacts: Artifacts.test(),
        featureFlags: TestFeatureFlags(),
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

    test('When the environment has a matching flavor defined', () async {
      // Re-create the environment with the correct process manager for this test.
      environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: FakeProcessManager.any(),
        artifacts: Artifacts.test(),
        featureFlags: TestFeatureFlags(),
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

    test('When the environment has a mismatching flavor defined', () async {
      // Re-create the environment with the correct process manager for this test.
      environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: FakeProcessManager.any(),
        artifacts: Artifacts.test(),
        featureFlags: TestFeatureFlags(),
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

  test('transforms assets declared with transformers', () async {
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
      featureFlags: TestFeatureFlags(),
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

  test('transforms shaders declared with transformers before compilation', () async {
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
      featureFlags: TestFeatureFlags(),
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

  test('exits tool if an asset transformation fails', () async {
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
      featureFlags: TestFeatureFlags(),
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

  test('asset transformation, per each asset, uses unique paths for temporary files', () async {
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
      featureFlags: TestFeatureFlags(),
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
  });

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
        test(platform, () async {
          final TargetPlatform targetPlatform = targetFor(platform);
          final bool didInclude = await setupAndBuildPlatformAsset(platform, targetPlatform);

          expect(didInclude, isTrue, reason: 'Expected asset for $platform to be included');
        });
      }
    });

    group('skips assets for non-matching platform', () {
      for (final platform in kValidPluginPlatforms) {
        test(platform, () async {
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
        test(platform, () async {
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
        test(platform, () async {
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

  test('Uses processors~/2 to transform assets', () async {
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
      featureFlags: TestFeatureFlags(),
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

  test('Throws exception if pubspec contains missing files', () async {
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

  // Regression test for https://github.com/flutter/flutter/issues/141626.
  group('dependency pubspec changes', () {
    for (final style in <FileSystemStyle>[FileSystemStyle.posix, FileSystemStyle.windows]) {
      final styleName = style == FileSystemStyle.windows ? 'windows' : 'posix';
      test(
        'rebuilds asset bundle when a dependency pubspec adds an asset between builds ($styleName)',
        () async {
          final testFileSystem = MemoryFileSystem.test(style: style);
          final testPlatform = FakePlatform(
            operatingSystem: style == FileSystemStyle.windows ? 'windows' : 'linux',
          );
          final testEnvironment = Environment.test(
            testFileSystem.currentDirectory,
            processManager: FakeProcessManager.any(),
            artifacts: Artifacts.test(),
            featureFlags: TestFeatureFlags(),
            fileSystem: testFileSystem,
            logger: logger,
            platform: testPlatform,
            defines: <String, String>{kBuildMode: BuildMode.debug.cliName},
          );

          testFileSystem.file('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
name: example
dependencies:
  my_package:
    path: my_package
dev_dependencies:
  dev_package:
    path: dev_package
''');
          testFileSystem.file(testFileSystem.path.join('my_package', 'pubspec.yaml'))
            ..createSync(recursive: true)
            ..writeAsStringSync('name: my_package\n');
          testFileSystem.file(testFileSystem.path.join('dev_package', 'pubspec.yaml'))
            ..createSync(recursive: true)
            ..writeAsStringSync('name: dev_package\n');
          writePackageConfigFiles(
            directory: testFileSystem.currentDirectory,
            mainLibName: 'example',
            packages: <String, String>{'my_package': 'my_package', 'dev_package': 'dev_package'},
            dependencies: <String>['my_package'],
            devDependencies: <String>['dev_package'],
          );

          final buildSystem = FlutterBuildSystem(
            fileSystem: testFileSystem,
            logger: logger,
            platform: testPlatform,
          );

          final BuildResult firstBuild = await buildSystem.build(
            const _StandaloneCopyAssets(),
            testEnvironment,
          );
          expect(firstBuild.success, isTrue);
          expect(firstBuild.performance['copy_assets']!.skipped, isFalse);

          final Depfile firstDepfile = testEnvironment.depFileService.parse(
            testEnvironment.buildDir.childFile('flutter_assets.d'),
          );
          final Set<String> firstInputPaths = firstDepfile.inputs
              .map((File file) => testEnvironment.fileSystem.path.canonicalize(file.path))
              .toSet();
          expect(
            firstInputPaths,
            contains(
              testEnvironment.fileSystem.path.canonicalize(
                testFileSystem.path.join('my_package', 'pubspec.yaml'),
              ),
            ),
          );
          expect(
            firstInputPaths,
            isNot(
              contains(
                testEnvironment.fileSystem.path.canonicalize(
                  testFileSystem.path.join('dev_package', 'pubspec.yaml'),
                ),
              ),
            ),
          );

          final BuildResult unchangedBuild = await buildSystem.build(
            const _StandaloneCopyAssets(),
            testEnvironment,
          );
          expect(unchangedBuild.success, isTrue);
          expect(unchangedBuild.performance['copy_assets']!.skipped, isTrue);

          testFileSystem.file(testFileSystem.path.join('my_package', 'lib', 'my_script.js'))
            ..createSync(recursive: true)
            ..writeAsStringSync('console.log("hello");');
          testFileSystem
              .file(testFileSystem.path.join('my_package', 'pubspec.yaml'))
              .writeAsStringSync('''
name: my_package
flutter:
  assets:
    - lib/my_script.js
''');

          final BuildResult updatedBuild = await buildSystem.build(
            const _StandaloneCopyAssets(),
            testEnvironment,
          );
          expect(updatedBuild.success, isTrue);
          expect(updatedBuild.performance['copy_assets']!.skipped, isFalse);
          expect(
            testEnvironment.buildDir
                .childDirectory('flutter_assets')
                .childFile('packages/my_package/lib/my_script.js'),
            exists,
          );
        },
      );
    }
  });

  test('deduplicates mixed-case Windows input paths while preserving wildcard sentinels', () async {
    final winFs = MemoryFileSystem.test(style: FileSystemStyle.windows);
    final winEnv = Environment.test(
      winFs.currentDirectory,
      processManager: FakeProcessManager.any(),
      artifacts: Artifacts.test(),
      featureFlags: TestFeatureFlags(),
      fileSystem: winFs,
      logger: logger,
      platform: FakePlatform(operatingSystem: 'windows'),
      defines: <String, String>{kBuildMode: BuildMode.debug.cliName},
    );
    winFs.file(r'assets\wildcard\item.png').createSync(recursive: true);
    winFs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('''
name: example
flutter:
  assets:
    - assets/wildcard/
''');
    writePackageConfigFiles(directory: winFs.currentDirectory, mainLibName: 'example');

    final Directory outputDir = winEnv.buildDir.childDirectory('flutter_assets')
      ..createSync(recursive: true);
    final Depfile depfile = await copyAssets(
      winEnv,
      outputDir,
      dartHookResult: DartHooksResult.empty(),
      targetPlatform: TargetPlatform.windows_x64,
      buildMode: BuildMode.debug,
      additionalInputs: <File>[winFs.file(r'C:\PUBSPEC.YAML')],
    );

    final List<String> canonicalInputs = depfile.inputs
        .map((File file) => winFs.path.canonicalize(file.path))
        .toList();
    expect(
      canonicalInputs.where((String p) => p == winFs.path.canonicalize('pubspec.yaml')),
      hasLength(1),
    );
    expect(
      depfile.inputs.any((File file) => file.path.contains('DOES_NOT_EXIST_RERUN_FOR_WILDCARD')),
      isTrue,
    );
  });
}

// Runs CopyAssets in isolation without LinkHooks/KernelSnapshot dependencies
// or SDK/build-dir Source inputs that are absent in the in-memory file system.
class _StandaloneCopyAssets extends CopyAssets {
  const _StandaloneCopyAssets();

  @override
  List<Target> get dependencies => const <Target>[];

  @override
  List<Source> get inputs => const <Source>[];
}
