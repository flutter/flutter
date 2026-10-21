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
      const patternSource = ExtensionSource.pattern('{PROJECT_DIR}/pubspec.yaml', optional: true);
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
      const target = ExtensionBuildTarget(
        description: 'A custom Linux build target.',
        name: 'custom-linux-build',
        targetPlatform: 'linux-x64',
        artifacts: <ExtensionArtifact>{BuiltInArtifacts.icuData, BuiltInArtifacts.genSnapshot},
        hostArtifacts: <ExtensionHostArtifact>{BuiltInHostArtifacts.impellerc},
        outputDir: '{OUTPUT_DIR}/linux',
      );

      final Map<String, Object?> map = target.toMap();
      expect(map[ExtensionBuildTarget.nameKey], 'custom-linux-build');
      expect(map[ExtensionBuildTarget.targetPlatformKey], 'linux-x64');
      expect(map[ExtensionBuildTarget.descriptionKey], 'A custom Linux build target.');
      expect(map[ExtensionBuildTarget.artifactsKey], equals(<String>['icuData', 'genSnapshot']));
      expect(map[ExtensionBuildTarget.hostArtifactsKey], equals(<String>['impellerc']));
      expect(map[ExtensionBuildTarget.outputDirKey], '{OUTPUT_DIR}/linux');

      final parsed = ExtensionBuildTarget.fromJson(map);
      expect(parsed, equals(target));
      expect(parsed.hashCode, equals(target.hashCode));
      expect(parsed.toString(), contains('custom-linux-build'));
      expect(parsed.toString(), contains('outputDir: {OUTPUT_DIR}/linux'));
    });

    test('deserializes with defaults when optional fields are missing', () {
      final parsed = ExtensionBuildTarget.fromJson(const <String, Object?>{
        'description': 'A custom Linux build target.',
        'name': 'custom-linux-build',
        'outputDir': '{OUTPUT_DIR}/linux',
        'targetPlatform': 'linux-x64',
      });
      expect(parsed.name, 'custom-linux-build');
      expect(parsed.targetPlatform, 'linux-x64');
      expect(parsed.description, 'A custom Linux build target.');
      expect(parsed.artifacts, isEmpty);
      expect(parsed.hostArtifacts, isEmpty);
      expect(parsed.outputDir, '{OUTPUT_DIR}/linux');
    });

    test('supports platform-agnostic target with null targetPlatform', () {
      const target = ExtensionBuildTarget(
        description: 'A platform-agnostic build target.',
        name: 'custom-agnostic-build',
        outputDir: '{OUTPUT_DIR}/agnostic',
      );
      expect(target.targetPlatform, isNull);

      final Map<String, Object?> map = target.toMap();
      expect(map.containsKey(ExtensionBuildTarget.targetPlatformKey), isFalse);

      final parsed = ExtensionBuildTarget.fromJson(map);
      expect(parsed, equals(target));
      expect(parsed.targetPlatform, isNull);
      expect(parsed.hashCode, equals(target.hashCode));
    });

    test('fromJson throws FormatException when targetPlatform is empty string', () {
      expect(
        () => ExtensionBuildTarget.fromJson(const <String, Object?>{
          'description': 'A custom build target.',
          'name': 'custom-build',
          'outputDir': '{OUTPUT_DIR}/custom',
          'targetPlatform': '',
        }),
        throwsFormatException,
      );
    });

    test('fromJson throws FormatException on missing required fields or malformed fields', () {
      final validRequired = <String, Object?>{
        'description': 'A custom Linux build target.',
        'name': 'custom-linux-build',
        'outputDir': '{OUTPUT_DIR}/linux',
        'targetPlatform': 'linux-x64',
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
          'targetPlatform': 123,
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
        'targetPlatform': 'linux-x64',
        'description': 'A custom Linux build target.',
      };

      final List<ExtensionBuildTarget> targets = ExtensionBuildTarget.listFromJson(<Object?>[
        validJson,
      ]);
      expect(targets, hasLength(1));
      expect(targets.first.name, 'custom-linux-build');
      expect(targets.first.outputDir, '{OUTPUT_DIR}/linux');
      expect(targets.first.targetPlatform, 'linux-x64');
      expect(targets.first.description, 'A custom Linux build target.');

      expect(ExtensionBuildTarget.listFromJson(null), isEmpty);
      expect(ExtensionBuildTarget.listFromJson('invalid'), isEmpty);
    });

    test('equality and hashCode distinguish different targets and ignore artifact set order', () {
      const target1 = ExtensionBuildTarget(
        description: 'Target 1',
        name: 'target-1',
        outputDir: '{OUTPUT_DIR}/target-1',
        targetPlatform: 'linux-x64',
        artifacts: <ExtensionArtifact>{BuiltInArtifacts.icuData, BuiltInArtifacts.genSnapshot},
      );
      const target1Reordered = ExtensionBuildTarget(
        description: 'Target 1',
        name: 'target-1',
        outputDir: '{OUTPUT_DIR}/target-1',
        targetPlatform: 'linux-x64',
        artifacts: <ExtensionArtifact>{BuiltInArtifacts.genSnapshot, BuiltInArtifacts.icuData},
      );
      const target2 = ExtensionBuildTarget(
        description: 'Target 2',
        name: 'target-2',
        outputDir: '{OUTPUT_DIR}/target-2',
        targetPlatform: 'linux-x64',
      );

      expect(target1, equals(target1Reordered));
      expect(target1.hashCode, equals(target1Reordered.hashCode));
      expect(target1, isNot(equals(target2)));
      expect(target1.hashCode, isNot(equals(target2.hashCode)));
    });
  });

  group('ExtensionAssembleTarget', () {
    test('serializes and deserializes correctly with all fields', () {
      const target = ExtensionAssembleTarget(
        description: 'A custom Linux assemble target.',
        name: 'custom-linux-assemble-only-debug',
        targetPlatform: 'linux-x64',
        dependencies: <String>[BuiltInTargets.copyAssets],
        depfiles: <String>['custom_linux.d'],
        inputs: <ExtensionSource>[
          ExtensionSource.pattern('{PROJECT_DIR}/pubspec.yaml'),
          ExtensionSource.artifact(BuiltInArtifacts.icuData),
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

    test('equality and hashCode distinguish different targets', () {
      const target1 = ExtensionAssembleTarget(
        description: 'Target 1',
        name: 'target-1',
        targetPlatform: 'linux-x64',
      );
      const target2 = ExtensionAssembleTarget(
        description: 'Target 2',
        name: 'target-2',
        targetPlatform: 'linux-x64',
      );

      expect(target1, isNot(equals(target2)));
      expect(target1.hashCode, isNot(equals(target2.hashCode)));
    });
  });

  group('ExtensionBuildResult', () {
    test('serializes and deserializes successful result without errorMessage', () {
      const result = ExtensionBuildResult(success: true);

      final Map<String, Object?> map = result.toMap();
      expect(map[ExtensionBuildResult.successKey], isTrue);
      expect(map.containsKey(ExtensionBuildResult.errorMessageKey), isFalse);
      expect(map.containsKey(ExtensionBuildResult.extraDefinesKey), isFalse);

      final parsed = ExtensionBuildResult.fromJson(map);
      expect(parsed, equals(result));
      expect(parsed.extraDefines, isEmpty);
      expect(parsed.hashCode, equals(result.hashCode));
      expect(parsed.toString(), contains('success: true'));
    });

    test('serializes and deserializes result with extraDefines', () {
      const result = ExtensionBuildResult(
        success: true,
        extraDefines: <String, String>{'FOO': 'bar', 'BAZ': 'qux'},
      );
      const resultReordered = ExtensionBuildResult(
        success: true,
        extraDefines: <String, String>{'BAZ': 'qux', 'FOO': 'bar'},
      );

      final Map<String, Object?> map = result.toMap();
      expect(
        map[ExtensionBuildResult.extraDefinesKey],
        equals(const <String, String>{'FOO': 'bar', 'BAZ': 'qux'}),
      );

      final parsed = ExtensionBuildResult.fromJson(map);
      expect(parsed, equals(result));
      expect(parsed, equals(resultReordered));
      expect(parsed.hashCode, equals(resultReordered.hashCode));
      expect(parsed.toString(), contains('extraDefines: {FOO: bar, BAZ: qux}'));
    });

    test('serializes and deserializes failed result with errorMessage', () {
      const result = ExtensionBuildResult(success: false, errorMessage: 'Compilation failed.');

      final Map<String, Object?> map = result.toMap();
      expect(map[ExtensionBuildResult.successKey], isFalse);
      expect(map[ExtensionBuildResult.errorMessageKey], 'Compilation failed.');

      final parsed = ExtensionBuildResult.fromJson(map);
      expect(parsed, equals(result));
      expect(parsed.hashCode, equals(result.hashCode));
      expect(parsed.toString(), contains('Compilation failed.'));
    });

    test('equality and hashCode distinguish different results', () {
      const result1 = ExtensionBuildResult(success: true, extraDefines: <String, String>{'A': '1'});
      const result2 = ExtensionBuildResult(success: false, errorMessage: 'Failed');
      const result3 = ExtensionBuildResult(success: true, extraDefines: <String, String>{'A': '2'});

      expect(result1, isNot(equals(result2)));
      expect(result1.hashCode, isNot(equals(result2.hashCode)));
      expect(result1, isNot(equals(result3)));
      expect(result1.hashCode, isNot(equals(result3.hashCode)));
    });

    test('fromJson throws FormatException when fields have invalid types', () {
      expect(
        () => ExtensionBuildResult.fromJson(const <String, Object?>{
          ExtensionBuildResult.successKey: 'yes',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildResult.fromJson(const <String, Object?>{
          ExtensionBuildResult.errorMessageKey: 404,
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildResult.fromJson(const <String, Object?>{
          ExtensionBuildResult.extraDefinesKey: 'not-a-map',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildResult.fromJson(const <String, Object?>{
          ExtensionBuildResult.extraDefinesKey: <Object?, Object?>{'key': 123},
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionBuildResult.fromJson(const <String, Object?>{
          ExtensionBuildResult.extraDefinesKey: <Object?, Object?>{123: 'value'},
        }),
        throwsFormatException,
      );
    });
  });
}
