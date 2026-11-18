// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('BuildMode', () {
    test('fromCliName parses valid build modes and throws on invalid mode', () {
      expect(BuildMode.fromCliName('debug'), BuildMode.debug);
      expect(BuildMode.fromCliName('profile'), BuildMode.profile);
      expect(BuildMode.fromCliName('release'), BuildMode.release);
      expect(BuildMode.fromCliName('jit_release'), BuildMode.jitRelease);
      expect(() => BuildMode.fromCliName('invalid'), throwsArgumentError);
    });

    test('properties and formatting getters return expected values', () {
      expect(BuildMode.debug.isRelease, isFalse);
      expect(BuildMode.debug.isJit, isTrue);
      expect(BuildMode.debug.isPrecompiled, isFalse);
      expect(BuildMode.debug.cliName, 'debug');
      expect(BuildMode.debug.uppercaseName, 'Debug');
      expect(BuildMode.debug.friendlyName, 'debug');
      expect(BuildMode.debug.uppercaseFriendlyName, 'Debug');
      expect(BuildMode.debug.toString(), 'debug');

      expect(BuildMode.profile.isRelease, isFalse);
      expect(BuildMode.profile.isJit, isFalse);
      expect(BuildMode.profile.isPrecompiled, isTrue);
      expect(BuildMode.profile.cliName, 'profile');
      expect(BuildMode.profile.uppercaseName, 'Profile');

      expect(BuildMode.release.isRelease, isTrue);
      expect(BuildMode.release.isJit, isFalse);
      expect(BuildMode.release.isPrecompiled, isTrue);
      expect(BuildMode.release.cliName, 'release');
      expect(BuildMode.release.uppercaseName, 'Release');

      expect(BuildMode.jitRelease.isRelease, isTrue);
      expect(BuildMode.jitRelease.isJit, isTrue);
      expect(BuildMode.jitRelease.isPrecompiled, isFalse);
      expect(BuildMode.jitRelease.cliName, 'jit_release');
      expect(BuildMode.jitRelease.uppercaseName, 'Jit_release');
      expect(BuildMode.jitRelease.friendlyName, 'jit release');
      expect(BuildMode.jitRelease.uppercaseFriendlyName, 'Jit release');
      expect(BuildMode.jitRelease.toString(), 'jit_release');
    });
  });

  group('ExtensionSource', () {
    test('pattern, artifact, and hostArtifact serialize and deserialize', () {
      final patternSource = ExtensionSource.pattern('{PROJECT_DIR}/pubspec.yaml', optional: true);
      expect(ExtensionSource.fromJson(patternSource.toMap()), equals(patternSource));
      expect(patternSource.toString(), contains('{PROJECT_DIR}/pubspec.yaml'));

      const artifactSource = ExtensionSource.artifact(
        BuiltInArtifacts.genSnapshot,
        mode: .release,
        platform: 'linux-x64',
      );
      expect(ExtensionSource.fromJson(artifactSource.toMap()), equals(artifactSource));
      expect(artifactSource.toString(), contains('genSnapshot'));

      const hostArtifactSource = ExtensionSource.hostArtifact(BuiltInHostArtifacts.impellerc);
      expect(ExtensionSource.fromJson(hostArtifactSource.toMap()), equals(hostArtifactSource));
      expect(hostArtifactSource.toString(), contains('impellerc'));
    });

    test('ExtensionSource.pattern asserts when pattern does not start with valid directory placeholder', () {
      expect(() => ExtensionSource.pattern('relative/path.txt'), throwsA(isA<AssertionError>()));
      expect(
        () => ExtensionSource.pattern('{PROJECT_DIR}foo/bar.dart'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('fromJson throws FormatException on invalid type or missing fields', () {
      expect(() => ExtensionSource.fromJson(const <String, Object?>{}), throwsFormatException);
      expect(
        () => ExtensionSource.fromJson(const <String, Object?>{'type': 'unknown'}),
        throwsFormatException,
      );
      expect(
        () => ExtensionSource.fromJson(const <String, Object?>{'type': 'pattern'}),
        throwsFormatException,
      );
      expect(
        () => ExtensionSource.fromJson(const <String, Object?>{'type': 'artifact'}),
        throwsFormatException,
      );
      expect(
        () => ExtensionSource.fromJson(const <String, Object?>{
          'type': 'artifact',
          'artifact': 'genSnapshot',
          'mode': 'invalid_mode',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionSource.fromJson(const <String, Object?>{'type': 'host_artifact'}),
        throwsFormatException,
      );
    });

    test(
      'ExtensionPatternSource.parse parses valid patterns and throws FormatException on invalid',
      () {
        expect(ExtensionPatternSource.parse('{PROJECT_DIR}'), '{PROJECT_DIR}');
        expect(
          ExtensionPatternSource.parse('{PROJECT_DIR}/lib/main.dart'),
          '{PROJECT_DIR}/lib/main.dart',
        );
        expect(
          () => ExtensionPatternSource.parse('{PROJECT_DIR}foo/bar.dart'),
          throwsFormatException,
        );
        expect(() => ExtensionPatternSource.parse('relative/path/to/file'), throwsFormatException);
      },
    );

    test('fromJson throws FormatException when pattern does not start with valid directory placeholder followed by slash', () {
      expect(
        () => ExtensionSource.fromJson(const <String, Object?>{
          'type': 'pattern',
          'value': 'relative/path/to/file',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionSource.fromJson(const <String, Object?>{
          'type': 'pattern',
          'value': '{PROJECT_DIR}foo/bar.dart',
        }),
        throwsFormatException,
      );
    });
  });

  group('ExtensionBuildTarget', () {
    test('serializes and deserializes correctly with all fields', () {
      final target = ExtensionBuildTarget(
        description: 'A custom Linux build target.',
        name: 'custom-linux-build',
        targetPlatforms: const <String>{'linux-x64', 'linux-arm64'},
        artifacts: const <ExtensionArtifact>{
          BuiltInArtifacts.icuData,
          BuiltInArtifacts.genSnapshot,
        },
        flags: const <ExtensionFlag>[ExtensionFlag(help: 'Sign package', name: 'sign')],
        hostArtifacts: const <ExtensionHostArtifact>{BuiltInHostArtifacts.impellerc},
        options: const <ExtensionOption>[ExtensionOption(help: 'Output format', name: 'format')],
        outputDir: '{OUTPUT_DIR}/linux',
        supportedBuildModes: const <BuildMode>{.debug, .release},
        supportsFlavors: true,
        supportsSizeAnalysis: true,
      );

      final Map<String, Object?> map = target.toMap();
      expect(map[ExtensionBuildTarget.nameKey], 'custom-linux-build');
      expect(
        map[ExtensionBuildTarget.targetPlatformsKey],
        equals(<String>['linux-x64', 'linux-arm64']),
      );
      expect(map[ExtensionBuildTarget.descriptionKey], 'A custom Linux build target.');
      expect(map[ExtensionBuildTarget.artifactsKey], equals(<String>['icuData', 'genSnapshot']));
      expect(map[ExtensionBuildTarget.hostArtifactsKey], equals(<String>['impellerc']));
      expect(map[ExtensionBuildTarget.outputDirKey], '{OUTPUT_DIR}/linux');
      expect(
        map[ExtensionBuildTarget.supportedBuildModesKey],
        equals(<String>['debug', 'release']),
      );
      expect(map[ExtensionBuildTarget.supportsFlavorsKey], isTrue);
      expect(map[ExtensionBuildTarget.supportsSizeAnalysisKey], isTrue);

      final parsed = ExtensionBuildTarget.fromJson(map);
      expect(parsed, equals(target));
      expect(parsed.hashCode, equals(target.hashCode));
      expect(parsed.flags, hasLength(1));
      expect(parsed.options, hasLength(1));
      expect(parsed.toString(), contains('custom-linux-build'));
      expect(parsed.toString(), contains('outputDir: {OUTPUT_DIR}/linux'));
    });

    test('deserializes with defaults when optional fields are missing', () {
      final parsed = ExtensionBuildTarget.fromJson(const <String, Object?>{
        'description': 'A custom Linux build target.',
        'name': 'custom-linux-build',
        'outputDir': '{OUTPUT_DIR}/linux',
      });
      expect(parsed.name, 'custom-linux-build');
      expect(parsed.targetPlatforms, isEmpty);
      expect(parsed.description, 'A custom Linux build target.');
      expect(parsed.artifacts, isEmpty);
      expect(parsed.flags, isEmpty);
      expect(parsed.options, isEmpty);
      expect(parsed.hostArtifacts, isEmpty);
      expect(parsed.supportedBuildModes, equals(const <BuildMode>{.debug, .profile, .release}));
      expect(parsed.supportsFlavors, isFalse);
      expect(parsed.supportsSizeAnalysis, isFalse);
      expect(parsed.outputDir, '{OUTPUT_DIR}/linux');
    });

    test('supports platform-agnostic target with empty targetPlatforms', () {
      final target = ExtensionBuildTarget(
        description: 'A platform-agnostic build target.',
        name: 'custom-agnostic-build',
        outputDir: '{OUTPUT_DIR}/agnostic',
      );
      expect(target.targetPlatforms, isEmpty);

      final Map<String, Object?> map = target.toMap();
      expect(map.containsKey(ExtensionBuildTarget.targetPlatformsKey), isFalse);

      final parsed = ExtensionBuildTarget.fromJson(map);
      expect(parsed, equals(target));
      expect(parsed.targetPlatforms, isEmpty);
      expect(parsed.hashCode, equals(target.hashCode));
    });

    test('validates targetPlatforms and supportedBuildModes', () {
      expect(
        () => ExtensionBuildTarget(
          description: 'Empty platform in targetPlatforms',
          name: 'custom-empty-platform',
          outputDir: '{OUTPUT_DIR}/invalid',
          targetPlatforms: const <String>{'linux-x64', ''},
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ExtensionBuildTarget(
          description: 'Empty supportedBuildModes',
          name: 'custom-empty-modes',
          outputDir: '{OUTPUT_DIR}/invalid',
          supportedBuildModes: const <BuildMode>{},
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ExtensionBuildTarget.fromJson(const <String, Object?>{
          'description': 'Invalid targetPlatforms',
          'name': 'custom-invalid',
          'outputDir': '{OUTPUT_DIR}/invalid',
          'targetPlatforms': <Object?>['linux-x64', ''],
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildTarget.fromJson(const <String, Object?>{
          'description': 'Empty supportedBuildModes',
          'name': 'custom-invalid',
          'outputDir': '{OUTPUT_DIR}/invalid',
          'supportedBuildModes': <Object?>[],
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildTarget.fromJson(const <String, Object?>{
          'description': 'Invalid supportedBuildModes element',
          'name': 'custom-invalid',
          'outputDir': '{OUTPUT_DIR}/invalid',
          'supportedBuildModes': <Object?>['not-a-mode'],
        }),
        throwsFormatException,
      );
    });

    test('fromJson throws FormatException on missing required fields or malformed fields', () {
      final validRequired = <String, Object?>{
        'description': 'A custom Linux build target.',
        'name': 'custom-linux-build',
        'outputDir': '{OUTPUT_DIR}/linux',
      };
      expect(() => ExtensionBuildTarget.fromJson(const <String, Object?>{}), throwsFormatException);
      expect(
        () =>
            ExtensionBuildTarget.fromJson(<String, Object?>{...validRequired, 'description': null}),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildTarget.fromJson(<String, Object?>{...validRequired, 'name': null}),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildTarget.fromJson(<String, Object?>{
          ...validRequired,
          'targetPlatforms': 123,
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildTarget.fromJson(<String, Object?>{...validRequired, 'outputDir': null}),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildTarget.fromJson(<String, Object?>{...validRequired, 'outputDir': 123}),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildTarget.fromJson(<String, Object?>{
          ...validRequired,
          'artifacts': const <Object?>[123],
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildTarget.fromJson(<String, Object?>{
          ...validRequired,
          'artifacts': 'invalid',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildTarget.fromJson(<String, Object?>{
          ...validRequired,
          'hostArtifacts': const <Object?>[123],
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildTarget.fromJson(<String, Object?>{
          ...validRequired,
          'hostArtifacts': 'invalid',
        }),
        throwsFormatException,
      );
    });

    test('fromJson throws FormatException when fields have invalid types', () {
      expect(
        () => ExtensionBuildTarget.fromJson(const <String, Object?>{
          ExtensionBuildTarget.nameKey: 123,
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildTarget.fromJson(const <String, Object?>{
          ExtensionBuildTarget.descriptionKey: false,
        }),
        throwsFormatException,
      );
    });

    test('listFromJson handles valid and invalid lists', () {
      final validJson = <String, Object?>{
        'name': 'custom-linux-build',
        'outputDir': '{OUTPUT_DIR}/linux',
        'targetPlatforms': const <String>['linux-x64'],
        'description': 'A custom Linux build target.',
      };

      final List<ExtensionBuildTarget> targets = ExtensionBuildTarget.listFromJson(<Object?>[
        validJson,
      ]);
      expect(targets, hasLength(1));
      expect(targets.first.name, 'custom-linux-build');
      expect(targets.first.outputDir, '{OUTPUT_DIR}/linux');
      expect(targets.first.targetPlatforms, equals(const <String>{'linux-x64'}));
      expect(targets.first.description, 'A custom Linux build target.');

      expect(ExtensionBuildTarget.listFromJson(null), isEmpty);
      expect(ExtensionBuildTarget.listFromJson('invalid'), isEmpty);
    });

    test('isValidName validates target names', () {
      expect(ExtensionBuildTarget.isValidName('linux'), isTrue);
      expect(ExtensionBuildTarget.isValidName('custom-apk'), isTrue);
      expect(ExtensionBuildTarget.isValidName('target_name-123'), isTrue);
      expect(ExtensionBuildTarget.isValidName(''), isFalse);
      expect(ExtensionBuildTarget.isValidName('123target'), isFalse);
      expect(ExtensionBuildTarget.isValidName('target name'), isFalse);
      expect(ExtensionBuildTarget.isValidName('Target'), isFalse);
      expect(ExtensionBuildTarget.isValidName('-target'), isFalse);
      expect(ExtensionBuildTarget.isValidName('_target'), isFalse);
    });

    test('constructor asserts on invalid name', () {
      expect(
        () => ExtensionBuildTarget(
          description: 'A test target',
          name: 'Invalid-Name',
          outputDir: '{OUTPUT_DIR}',
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () =>
            ExtensionBuildTarget(description: 'A test target', name: '', outputDir: '{OUTPUT_DIR}'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('fromJson throws FormatException on invalid target name', () {
      final validJson = <String, Object?>{
        'name': 'custom-linux-build',
        'outputDir': '{OUTPUT_DIR}/linux',
        'description': 'A custom Linux build target.',
      };
      expect(
        () =>
            ExtensionBuildTarget.fromJson(<String, Object?>{...validJson, 'name': 'Invalid Name'}),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildTarget.fromJson(<String, Object?>{...validJson, 'name': ''}),
        throwsFormatException,
      );
    });

    test('equality and hashCode distinguish different targets and ignore artifact set order', () {
      final target1 = ExtensionBuildTarget(
        description: 'Target 1',
        name: 'target-1',
        outputDir: '{OUTPUT_DIR}/target-1',
        targetPlatforms: const <String>{'linux-x64'},
        artifacts: const <ExtensionArtifact>{
          BuiltInArtifacts.icuData,
          BuiltInArtifacts.genSnapshot,
        },
      );
      final target1Reordered = ExtensionBuildTarget(
        description: 'Target 1',
        name: 'target-1',
        outputDir: '{OUTPUT_DIR}/target-1',
        targetPlatforms: const <String>{'linux-x64'},
        artifacts: const <ExtensionArtifact>{
          BuiltInArtifacts.genSnapshot,
          BuiltInArtifacts.icuData,
        },
      );
      final target2 = ExtensionBuildTarget(
        description: 'Target 2',
        name: 'target-2',
        outputDir: '{OUTPUT_DIR}/target-2',
        targetPlatforms: const <String>{'linux-x64'},
      );

      expect(target1, equals(target1Reordered));
      expect(target1.hashCode, equals(target1Reordered.hashCode));
      expect(target1, isNot(equals(target2)));
      expect(target1.hashCode, isNot(equals(target2.hashCode)));
    });
  });

  group('ExtensionAssembleTarget', () {
    test('serializes and deserializes correctly with all fields', () {
      final target = ExtensionAssembleTarget(
        description: 'A custom Linux assemble target.',
        name: 'custom-linux-assemble-only-debug',
        targetPlatform: 'linux-x64',
        dependencies: const <String>[BuiltInTargets.copyAssets],
        depfiles: const <String>['custom_linux.d'],
        inputs: <ExtensionSource>[
          ExtensionSource.pattern('{PROJECT_DIR}/pubspec.yaml'),
          const ExtensionSource.artifact(BuiltInArtifacts.icuData),
        ],
        outputs: <ExtensionSource>[ExtensionSource.pattern('{OUTPUT_DIR}/bundle/*')],
      );

      final Map<String, Object?> map = target.toMap();
      expect(map[ExtensionAssembleTarget.nameKey], 'custom-linux-assemble-only-debug');
      expect(map[ExtensionAssembleTarget.targetPlatformKey], 'linux-x64');
      expect(map[ExtensionAssembleTarget.descriptionKey], 'A custom Linux assemble target.');
      expect(
        map[ExtensionAssembleTarget.dependenciesKey],
        equals(<String>[BuiltInTargets.copyAssets]),
      );
      expect(map[ExtensionAssembleTarget.depfilesKey], equals(<String>['custom_linux.d']));

      final parsed = ExtensionAssembleTarget.fromJson(map);
      expect(parsed, equals(target));
      expect(parsed.hashCode, equals(target.hashCode));
      expect(parsed.toString(), contains('custom-linux-assemble-only-debug'));
      expect(parsed.toString(), contains('depfiles: [custom_linux.d]'));
    });

    test('deserializes with defaults when optional fields are missing', () {
      final parsed = ExtensionAssembleTarget.fromJson(const <String, Object?>{
        'description': 'A custom Linux assemble target.',
        'name': 'custom-linux-assemble-only-debug',
        'targetPlatform': 'linux-x64',
      });
      expect(parsed.name, 'custom-linux-assemble-only-debug');
      expect(parsed.targetPlatform, 'linux-x64');
      expect(parsed.description, 'A custom Linux assemble target.');
      expect(parsed.dependencies, isEmpty);
      expect(parsed.depfiles, isEmpty);
      expect(parsed.inputs, isEmpty);
      expect(parsed.outputs, isEmpty);
      expect(parsed.toMap().containsKey(ExtensionAssembleTarget.depfilesKey), isFalse);
    });

    test('fromJson throws FormatException on missing required fields or malformed fields', () {
      final validRequired = <String, Object?>{
        'description': 'A custom Linux assemble target.',
        'name': 'custom-linux-assemble-only-debug',
        'targetPlatform': 'linux-x64',
      };
      expect(
        () => ExtensionAssembleTarget.fromJson(const <String, Object?>{}),
        throwsFormatException,
      );
      expect(
        () => ExtensionAssembleTarget.fromJson(<String, Object?>{
          ...validRequired,
          'description': null,
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionAssembleTarget.fromJson(<String, Object?>{...validRequired, 'name': null}),
        throwsFormatException,
      );
      expect(
        () => ExtensionAssembleTarget.fromJson(<String, Object?>{
          ...validRequired,
          'targetPlatform': null,
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionAssembleTarget.fromJson(<String, Object?>{
          ...validRequired,
          'dependencies': const <Object?>[123],
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionAssembleTarget.fromJson(<String, Object?>{
          ...validRequired,
          'dependencies': 'invalid',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionAssembleTarget.fromJson(<String, Object?>{
          ...validRequired,
          'depfiles': const <Object?>[123],
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionAssembleTarget.fromJson(<String, Object?>{
          ...validRequired,
          'depfiles': 'invalid',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionAssembleTarget.fromJson(<String, Object?>{
          ...validRequired,
          'depfiles': const <Object?>[''],
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionAssembleTarget.fromJson(<String, Object?>{
          ...validRequired,
          'depfiles': const <Object?>['../escape.d'],
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionAssembleTarget.fromJson(<String, Object?>{
          ...validRequired,
          'depfiles': const <Object?>['/abs/file.d'],
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionAssembleTarget.fromJson(<String, Object?>{
          ...validRequired,
          'depfiles': const <Object?>[r'sub\file.d'],
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionAssembleTarget.fromJson(<String, Object?>{
          ...validRequired,
          'inputs': const <Object?>['not-a-map'],
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionAssembleTarget.fromJson(<String, Object?>{
          ...validRequired,
          'inputs': 'invalid',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionAssembleTarget.fromJson(<String, Object?>{
          ...validRequired,
          'outputs': const <Object?>['not-a-map'],
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionAssembleTarget.fromJson(<String, Object?>{
          ...validRequired,
          'outputs': 'invalid',
        }),
        throwsFormatException,
      );
    });

    test('listFromJson handles valid and invalid lists', () {
      final validJson = <String, Object?>{
        'name': 'custom-linux-assemble-only-debug',
        'targetPlatform': 'linux-x64',
        'description': 'A custom Linux assemble target.',
      };

      final List<ExtensionAssembleTarget> targets = ExtensionAssembleTarget.listFromJson(<Object?>[
        validJson,
      ]);
      expect(targets, hasLength(1));
      expect(targets.first.name, 'custom-linux-assemble-only-debug');
      expect(targets.first.targetPlatform, 'linux-x64');
      expect(targets.first.description, 'A custom Linux assemble target.');

      expect(ExtensionAssembleTarget.listFromJson(null), isEmpty);
      expect(ExtensionAssembleTarget.listFromJson('invalid'), isEmpty);
    });

    test('isValidDepfileName and constructor assert validate depfile names', () {
      expect(ExtensionAssembleTarget.isValidDepfileName('custom_linux.d'), isTrue);
      expect(ExtensionAssembleTarget.isValidDepfileName(''), isFalse);
      expect(ExtensionAssembleTarget.isValidDepfileName('.'), isFalse);
      expect(ExtensionAssembleTarget.isValidDepfileName('..'), isFalse);
      expect(ExtensionAssembleTarget.isValidDepfileName('sub/file.d'), isFalse);
      expect(ExtensionAssembleTarget.isValidDepfileName(r'sub\file.d'), isFalse);
      expect(
        () => ExtensionAssembleTarget(
          description: 'Target 1',
          name: 'target-1',
          targetPlatform: 'linux-x64',
          depfiles: const <String>['../escape.d'],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equality and hashCode distinguish different targets', () {
      final target1 = ExtensionAssembleTarget(
        description: 'Target 1',
        name: 'target-1',
        targetPlatform: 'linux-x64',
      );
      final target2 = ExtensionAssembleTarget(
        description: 'Target 2',
        name: 'target-2',
        targetPlatform: 'linux-x64',
      );

      expect(target1, isNot(equals(target2)));
      expect(target1.hashCode, isNot(equals(target2.hashCode)));
    });
  });

  group('ExtensionBuildResult', () {
    test('serializes and deserializes with default and custom fields', () {
      final result = ExtensionBuildResult(
        aotSnapshotFileName: 'app.so',
        bundleDirectoryUri: Uri.directory('/path/to/bundle'),
        executableUri: Uri.file('/path/to/bundle/app'),
      );

      final Map<String, Object?> map = result.toMap();
      expect(map[ExtensionBuildResult.aotSnapshotFileNameKey], 'app.so');
      expect(map[ExtensionBuildResult.bundleDirectoryUriKey], 'file:///path/to/bundle/');
      expect(map[ExtensionBuildResult.executableUriKey], 'file:///path/to/bundle/app');

      final parsed = ExtensionBuildResult.fromJson(map);
      expect(parsed, equals(result));
      expect(parsed.hashCode, equals(result.hashCode));
      expect(parsed.toString(), contains('app.so'));
      expect(parsed.toString(), contains('file:///path/to/bundle/app'));

      const defaultResult = ExtensionBuildResult();
      expect(defaultResult.aotSnapshotFileName, 'libapp.so');
      expect(defaultResult.bundleDirectoryUri, isNull);
      expect(defaultResult.executableUri, isNull);
      expect(ExtensionBuildResult.fromJson(const <String, Object?>{}), equals(defaultResult));

      // Bundle directory executable URIs (such as macOS/iOS .app bundles) are accepted by isValidArtifactUri.
      final bundleExecutableResult = ExtensionBuildResult.fromJson(const <String, Object?>{
        'executableUri': 'file:///path/to/MyApp.app/',
      });
      expect(bundleExecutableResult.executableUri, Uri.parse('file:///path/to/MyApp.app/'));
    });

    test('fromJson validates executableUri, bundleDirectoryUri, and aotSnapshotFileName', () {
      expect(
        () => ExtensionBuildResult.fromJson(const <String, Object?>{
          'executableUri': 'relative/path/app',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildResult.fromJson(const <String, Object?>{
          'executableUri': 'https://example.com/app',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildResult.fromJson(const <String, Object?>{'executableUri': 'file:///'}),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildResult.fromJson(const <String, Object?>{'executableUri': 123}),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildResult.fromJson(const <String, Object?>{
          'bundleDirectoryUri': 'file:///path/without/trailing/slash',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildResult.fromJson(const <String, Object?>{
          'bundleDirectoryUri': 'relative/bundle/',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildResult.fromJson(const <String, Object?>{'aotSnapshotFileName': ''}),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildResult.fromJson(const <String, Object?>{
          'aotSnapshotFileName': 'lib/libapp.so',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildResult.fromJson(const <String, Object?>{
          'aotSnapshotFileName': r'lib\libapp.so',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildResult.fromJson(const <String, Object?>{'aotSnapshotFileName': 42}),
        throwsFormatException,
      );
    });

    test('equality and hashCode distinguish different results', () {
      const result1 = ExtensionBuildResult();
      const result2 = ExtensionBuildResult(aotSnapshotFileName: 'custom.so');

      expect(result1, isNot(equals(result2)));
      expect(result1.hashCode, isNot(equals(result2.hashCode)));
    });
  });

  group('ExtensionFlag and ExtensionOption', () {
    test('ExtensionFlag serializes, deserializes, and implements equality and hashCode', () {
      const flag = ExtensionFlag(
        help: 'Enable custom bundling.',
        name: 'bundle-custom',
        defaultsTo: true,
        deprecated: 'Use --new-bundle instead.',
        hide: true,
        negatable: false,
      );
      final Map<String, Object?> map = flag.toMap();
      expect(map[ExtensionFlag.nameKey], 'bundle-custom');
      expect(map[ExtensionFlag.helpKey], 'Enable custom bundling.');
      expect(map[ExtensionFlag.defaultsToKey], isTrue);
      expect(map[ExtensionFlag.deprecatedKey], 'Use --new-bundle instead.');
      expect(map[ExtensionFlag.hideKey], isTrue);
      expect(map[ExtensionFlag.negatableKey], isFalse);

      final parsed = ExtensionFlag.fromJson(map);
      expect(parsed, equals(flag));
      expect(parsed.hashCode, equals(flag.hashCode));
      expect(parsed.toString(), contains('bundle-custom'));

      const defaultFlag = ExtensionFlag(help: 'Default flag', name: 'default-flag');
      expect(defaultFlag.defaultsTo, isFalse);
      expect(defaultFlag.deprecated, isNull);
      expect(defaultFlag.hide, isFalse);
      expect(defaultFlag.negatable, isTrue);
      expect(ExtensionFlag.fromJson(defaultFlag.toMap()), equals(defaultFlag));
      expect(defaultFlag, isNot(equals(flag)));
    });

    test('ExtensionFlag.fromJson and listFromJson validate input', () {
      expect(
        () => ExtensionFlag.fromJson(const <String, Object?>{'name': '', 'help': 'h'}),
        throwsFormatException,
      );
      expect(
        () => ExtensionFlag.fromJson(const <String, Object?>{
          'name': 'flag',
          'help': 'h',
          'defaultsTo': 'yes',
        }),
        throwsFormatException,
      );
      expect(
        () =>
            ExtensionFlag.fromJson(const <String, Object?>{'name': 'flag', 'help': 'h', 'hide': 1}),
        throwsFormatException,
      );
      expect(ExtensionFlag.listFromJson(null), isEmpty);
      expect(() => ExtensionFlag.listFromJson('invalid'), throwsFormatException);
      expect(() => ExtensionFlag.listFromJson(<Object?>[123]), throwsFormatException);
    });

    test('ExtensionOption serializes, deserializes, and implements equality and hashCode', () {
      const option = ExtensionOption(
        help: 'Select compression format.',
        name: 'compression',
        allowed: <String>['gzip', 'xz'],
        allowedHelp: <String, String>{'gzip': 'Fast compression', 'xz': 'High ratio'},
        defaultsTo: 'gzip',
        deprecated: 'Use --archive-format instead.',
        hide: true,
        mandatory: true,
        valueHelp: 'format',
      );
      final Map<String, Object?> map = option.toMap();
      expect(map[ExtensionOption.nameKey], 'compression');
      expect(map[ExtensionOption.helpKey], 'Select compression format.');
      expect(map[ExtensionOption.allowedKey], equals(const <String>['gzip', 'xz']));
      expect(
        map[ExtensionOption.allowedHelpKey],
        equals(const <String, String>{'gzip': 'Fast compression', 'xz': 'High ratio'}),
      );
      expect(map[ExtensionOption.defaultsToKey], 'gzip');
      expect(map[ExtensionOption.deprecatedKey], 'Use --archive-format instead.');
      expect(map[ExtensionOption.hideKey], isTrue);
      expect(map[ExtensionOption.mandatoryKey], isTrue);
      expect(map[ExtensionOption.valueHelpKey], 'format');

      final parsed = ExtensionOption.fromJson(map);
      expect(parsed, equals(option));
      expect(parsed.hashCode, equals(option.hashCode));
      expect(parsed.toString(), contains('compression'));

      const defaultOption = ExtensionOption(help: 'Default option', name: 'default-option');
      expect(defaultOption.hide, isFalse);
      expect(defaultOption.mandatory, isFalse);
      expect(defaultOption.defaultsTo, isNull);
      expect(defaultOption.deprecated, isNull);
      expect(defaultOption.allowed, isNull);
      expect(ExtensionOption.fromJson(defaultOption.toMap()), equals(defaultOption));
      expect(defaultOption, isNot(equals(option)));
    });

    test('ExtensionOption.fromJson and listFromJson validate input', () {
      expect(
        () => ExtensionOption.fromJson(const <String, Object?>{'name': '', 'help': 'h'}),
        throwsFormatException,
      );
      expect(
        () => ExtensionOption.fromJson(const <String, Object?>{
          'name': 'opt',
          'help': 'h',
          'mandatory': 'yes',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionOption.fromJson(const <String, Object?>{
          'name': 'opt',
          'help': 'h',
          'allowedHelp': 'not-a-map',
        }),
        throwsFormatException,
      );
      expect(ExtensionOption.listFromJson(null), isEmpty);
      expect(() => ExtensionOption.listFromJson('invalid'), throwsFormatException);
      expect(() => ExtensionOption.listFromJson(<Object?>[123]), throwsFormatException);
    });
  });

  group('ExtensionBuildContext and ExtensionAssembleContext', () {
    test('ExtensionBuildContext serializes, deserializes, and checks equality', () {
      final context = ExtensionBuildContext(
        buildMode: .release,
        flutterRoot: Uri.parse('file:///flutter/'),
        mainPath: '/project/lib/main.dart',
        outputDir: Uri.parse('file:///project/build/custom/'),
        projectRoot: Uri.parse('file:///project/'),
        resolvedArtifacts: const <String, String>{'icuData': '/flutter/icudtl.dat'},
        trackWidgetCreation: false,
        treeShakeIcons: true,
        buildFlags: const <String, bool>{'sign': true},
        buildName: '1.2.3',
        buildNumber: '45',
        buildOptions: const <String, String>{'format': 'ipk'},
        codeSizeDirectory: Uri.parse('file:///project/build/code_size/'),
        configuration: const <String, Object?>{'enable-custom': true, 'sdk-path': '/opt/sdk'},
        dartDefines: const <String, String>{'API_URL': 'https://example.com'},
        dartObfuscation: true,
        extraFrontEndOptions: const <String>['--enable-experiment=test'],
        extraGenSnapshotOptions: const <String>['--deterministic'],
        flavor: 'prod',
        splitDebugInfo: Uri.parse('file:///project/build/symbols/'),
        targetDeviceId: 'device-123',
        targetPlatform: 'linux-arm64',
      );

      final Map<String, Object?> map = context.toMap();
      final parsed = ExtensionBuildContext.fromJson(map);
      expect(parsed, equals(context));
      expect(parsed.hashCode, equals(context.hashCode));
      expect(parsed.toString(), contains('ExtensionBuildContext('));
    });

    test('ExtensionBuildContext.fromJson validates directory URIs, buildOptions, configuration, and required bools', () {
      final validBaseMap = <String, Object?>{
        'buildMode': 'debug',
        'dartObfuscation': false,
        'flutterRoot': 'file:///flutter/',
        'mainPath': '/project/lib/main.dart',
        'outputDir': 'file:///project/build/',
        'projectRoot': 'file:///project/',
        'resolvedArtifacts': const <String, Object?>{},
        'trackWidgetCreation': true,
        'treeShakeIcons': false,
      };
      expect(
        () => ExtensionBuildContext.fromJson(<String, Object?>{
          ...validBaseMap,
          'codeSizeDirectory': 'http://example.com/size/',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildContext.fromJson(<String, Object?>{
          ...validBaseMap,
          'codeSizeDirectory': 'file:///project/size_no_slash',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildContext.fromJson(<String, Object?>{
          ...validBaseMap,
          'splitDebugInfo': 'file:///project/symbols_no_slash',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildContext.fromJson(<String, Object?>{
          ...validBaseMap,
          'splitDebugInfo': 'relative/symbols/',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildContext.fromJson(<String, Object?>{
          ...validBaseMap,
          'buildOptions': const <String, Object?>{'format': null},
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildContext.fromJson(<String, Object?>{
          ...validBaseMap,
          'configuration': const <String, Object?>{'unset': null},
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildContext.fromJson(<String, Object?>{
          ...validBaseMap,
          'configuration': const <String, Object?>{'count': 42},
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildContext.fromJson(<String, Object?>{
          ...validBaseMap,
          'trackWidgetCreation': null,
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildContext.fromJson(<String, Object?>{
          ...validBaseMap,
          'treeShakeIcons': null,
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildContext.fromJson(<String, Object?>{
          ...validBaseMap,
          'dartObfuscation': null,
        }),
        throwsFormatException,
      );
    });

    test('ExtensionAssembleContext serializes, deserializes, and checks equality', () {
      final context = ExtensionAssembleContext(
        buildDir: Uri.parse('file:///project/.dart_tool/flutter_build/1234/'),
        buildMode: .debug,
        flutterRoot: Uri.parse('file:///flutter/'),
        mainPath: '/project/lib/main.dart',
        outputDir: Uri.parse('file:///project/build/'),
        projectRoot: Uri.parse('file:///project/'),
        resolvedArtifacts: const <String, String>{},
        trackWidgetCreation: true,
        treeShakeIcons: false,
        configuration: const <String, Object?>{'enable-custom': false, 'custom-opt': 'val'},
        dartDefines: const <String, String>{'FOO': 'bar'},
        extraDefines: const <String, String>{'CustomDefine': '42'},
        flavor: 'dev',
        targetPlatform: 'linux-x64',
      );

      final Map<String, Object?> map = context.toMap();
      final parsed = ExtensionAssembleContext.fromJson(map);
      expect(parsed, equals(context));
      expect(parsed.hashCode, equals(context.hashCode));
      expect(parsed.toString(), contains('ExtensionAssembleContext('));
      expect(parsed.extraDefines, equals(const <String, String>{'CustomDefine': '42'}));
    });
  });
}
