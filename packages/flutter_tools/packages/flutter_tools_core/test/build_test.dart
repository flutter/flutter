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
        targetPlatform: 'linux-x64',
        artifacts: const <ExtensionArtifact>{
          BuiltInArtifacts.icuData,
          BuiltInArtifacts.genSnapshot,
        },
        hostArtifacts: const <ExtensionHostArtifact>{BuiltInHostArtifacts.impellerc},
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
      final target = ExtensionBuildTarget(
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
      final target1 = ExtensionBuildTarget(
        description: 'Target 1',
        name: 'target-1',
        outputDir: '{OUTPUT_DIR}/target-1',
        targetPlatform: 'linux-x64',
        artifacts: const <ExtensionArtifact>{
          BuiltInArtifacts.icuData,
          BuiltInArtifacts.genSnapshot,
        },
      );
      final target1Reordered = ExtensionBuildTarget(
        description: 'Target 1',
        name: 'target-1',
        outputDir: '{OUTPUT_DIR}/target-1',
        targetPlatform: 'linux-x64',
        artifacts: const <ExtensionArtifact>{
          BuiltInArtifacts.genSnapshot,
          BuiltInArtifacts.icuData,
        },
      );
      final target2 = ExtensionBuildTarget(
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

  group('BuildFlag and BuildOption', () {
    test('BuildFlag serializes, deserializes, and implements equality and hashCode', () {
      const flag = BuildFlag(
        help: 'Enable custom bundling.',
        name: 'bundle-custom',
        abbr: 'b',
        defaultsTo: true,
        negatable: false,
      );
      final Map<String, Object?> map = flag.toMap();
      expect(map[BuildFlag.nameKey], 'bundle-custom');
      expect(map[BuildFlag.helpKey], 'Enable custom bundling.');
      expect(map[BuildFlag.abbrKey], 'b');
      expect(map[BuildFlag.defaultsToKey], isTrue);
      expect(map[BuildFlag.negatableKey], isFalse);

      final parsed = BuildFlag.fromJson(map);
      expect(parsed, equals(flag));
      expect(parsed.hashCode, equals(flag.hashCode));
      expect(parsed.toString(), contains('bundle-custom'));

      const defaultFlag = BuildFlag(help: 'Default flag', name: 'default-flag');
      expect(defaultFlag.defaultsTo, isFalse);
      expect(defaultFlag.negatable, isTrue);
      expect(defaultFlag.abbr, isNull);
      expect(BuildFlag.fromJson(defaultFlag.toMap()), equals(defaultFlag));
      expect(defaultFlag, isNot(equals(flag)));
    });

    test('BuildFlag.fromJson and listFromJson validate input', () {
      expect(
        () => BuildFlag.fromJson(const <String, Object?>{
          'name': '',
          'help': 'h',
          'defaultsTo': false,
          'negatable': true,
        }),
        throwsFormatException,
      );
      expect(
        () => BuildFlag.fromJson(const <String, Object?>{
          'name': 'flag',
          'help': 'h',
          'abbr': 'ab',
          'defaultsTo': false,
          'negatable': true,
        }),
        throwsFormatException,
      );
      expect(
        () => BuildFlag.fromJson(const <String, Object?>{
          'name': 'flag',
          'help': 'h',
          'negatable': true,
        }),
        throwsFormatException,
      );
      expect(
        () => BuildFlag.fromJson(const <String, Object?>{
          'name': 'flag',
          'help': 'h',
          'defaultsTo': false,
        }),
        throwsFormatException,
      );
      expect(BuildFlag.listFromJson(null), isEmpty);
      expect(() => BuildFlag.listFromJson('invalid'), throwsFormatException);
      expect(() => BuildFlag.listFromJson(<Object?>[123]), throwsFormatException);
    });

    test('BuildOption serializes, deserializes, and implements equality and hashCode', () {
      const option = BuildOption(
        help: 'Select compression format.',
        name: 'compression',
        abbr: 'c',
        allowed: <String>['gzip', 'xz'],
        allowedHelp: <String, String>{'gzip': 'Fast compression', 'xz': 'High ratio'},
        defaultsTo: 'gzip',
        mandatory: true,
        valueHelp: 'format',
      );
      final Map<String, Object?> map = option.toMap();
      expect(map[BuildOption.nameKey], 'compression');
      expect(map[BuildOption.helpKey], 'Select compression format.');
      expect(map[BuildOption.abbrKey], 'c');
      expect(map[BuildOption.allowedKey], equals(const <String>['gzip', 'xz']));
      expect(
        map[BuildOption.allowedHelpKey],
        equals(const <String, String>{'gzip': 'Fast compression', 'xz': 'High ratio'}),
      );
      expect(map[BuildOption.defaultsToKey], 'gzip');
      expect(map[BuildOption.mandatoryKey], isTrue);
      expect(map[BuildOption.valueHelpKey], 'format');

      final parsed = BuildOption.fromJson(map);
      expect(parsed, equals(option));
      expect(parsed.hashCode, equals(option.hashCode));
      expect(parsed.toString(), contains('compression'));

      const defaultOption = BuildOption(help: 'Default option', name: 'default-option');
      expect(defaultOption.mandatory, isFalse);
      expect(defaultOption.defaultsTo, isNull);
      expect(defaultOption.allowed, isNull);
      expect(BuildOption.fromJson(defaultOption.toMap()), equals(defaultOption));
      expect(defaultOption, isNot(equals(option)));
    });

    test('BuildOption.fromJson and listFromJson validate input', () {
      expect(
        () => BuildOption.fromJson(const <String, Object?>{
          'name': '',
          'help': 'h',
          'mandatory': false,
        }),
        throwsFormatException,
      );
      expect(
        () => BuildOption.fromJson(const <String, Object?>{
          'name': 'opt',
          'help': 'h',
          'abbr': 'ab',
          'mandatory': false,
        }),
        throwsFormatException,
      );
      expect(
        () => BuildOption.fromJson(const <String, Object?>{'name': 'opt', 'help': 'h'}),
        throwsFormatException,
      );
      expect(
        () => BuildOption.fromJson(const <String, Object?>{
          'name': 'opt',
          'help': 'h',
          'mandatory': false,
          'allowedHelp': 'not-a-map',
        }),
        throwsFormatException,
      );
      expect(BuildOption.listFromJson(null), isEmpty);
      expect(() => BuildOption.listFromJson('invalid'), throwsFormatException);
      expect(() => BuildOption.listFromJson(<Object?>[123]), throwsFormatException);
    });

    test('ExtensionBuildTarget supports buildFlags, buildOptions, and targetPlatforms', () {
      final target = ExtensionBuildTarget(
        description: 'Multi-arch target',
        name: 'custom-multi',
        outputDir: '{OUTPUT_DIR}/{TARGET_PLATFORM}/{BUILD_MODE}',
        targetPlatform: 'linux-x64',
        targetPlatforms: const <String>{'linux-x64', 'linux-arm64'},
        buildFlags: const <BuildFlag>[BuildFlag(help: 'Sign package', name: 'sign')],
        buildOptions: const <BuildOption>[BuildOption(help: 'Output format', name: 'format')],
      );
      expect(target.targetPlatforms, equals(const <String>{'linux-x64', 'linux-arm64'}));

      final parsed = ExtensionBuildTarget.fromJson(target.toMap());
      expect(parsed, equals(target));
      expect(parsed.hashCode, equals(target.hashCode));
      expect(parsed.buildFlags, hasLength(1));
      expect(parsed.buildOptions, hasLength(1));
      expect(parsed.targetPlatforms, equals(const <String>{'linux-x64', 'linux-arm64'}));

      final singlePlatformTarget = ExtensionBuildTarget(
        description: 'Single-arch target',
        name: 'custom-single',
        outputDir: '{OUTPUT_DIR}/single',
        targetPlatform: 'linux-x64',
      );
      expect(singlePlatformTarget.targetPlatforms, equals(const <String>{'linux-x64'}));

      final agnosticTarget = ExtensionBuildTarget(
        description: 'Agnostic target',
        name: 'custom-agnostic',
        outputDir: '{OUTPUT_DIR}/agnostic',
      );
      expect(agnosticTarget.targetPlatforms, isEmpty);

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
          description: 'Mismatched targetPlatform and targetPlatforms',
          name: 'custom-mismatch',
          outputDir: '{OUTPUT_DIR}/invalid',
          targetPlatform: 'linux-x64',
          targetPlatforms: const <String>{'linux-arm64'},
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
          'description': 'Mismatched targetPlatform and targetPlatforms',
          'name': 'custom-mismatch',
          'outputDir': '{OUTPUT_DIR}/invalid',
          'targetPlatform': 'linux-x64',
          'targetPlatforms': <Object?>['linux-arm64'],
        }),
        throwsFormatException,
      );
    });
  });

  group('ExtensionBuildContext and ExtensionAssembleContext', () {
    test('ExtensionBuildContext serializes, deserializes, and checks equality', () {
      final context = ExtensionBuildContext(
        buildMode: .release,
        flutterRoot: Uri.parse('file:///flutter/'),
        mainPath: 'lib/main.dart',
        outputDir: Uri.parse('file:///project/build/custom/'),
        projectRoot: Uri.parse('file:///project/'),
        resolvedArtifacts: const <String, String>{'icuData': '/flutter/icudtl.dat'},
        trackWidgetCreation: false,
        treeShakeIcons: true,
        buildFlags: const <String, bool>{'sign': true},
        buildName: '1.2.3',
        buildNumber: '45',
        buildOptions: const <String, String?>{'format': 'ipk', 'optional-opt': null},
        codeSizeDirectory: Uri.parse('file:///project/build/code_size/'),
        configuration: const <String, String?>{'enable-custom': 'true', 'sdk-path': '/opt/sdk'},
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

    test('ExtensionBuildContext validates directory file: URIs and required bools', () {
      expect(
        () => ExtensionBuildContext(
          buildMode: .debug,
          flutterRoot: Uri.parse('file:///flutter/'),
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('file:///project/build/'),
          projectRoot: Uri.parse('file:///project/'),
          resolvedArtifacts: const <String, String>{},
          trackWidgetCreation: true,
          treeShakeIcons: false,
          codeSizeDirectory: Uri.parse('http://example.com/size/'),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ExtensionBuildContext(
          buildMode: .debug,
          flutterRoot: Uri.parse('file:///flutter/'),
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('file:///project/build/'),
          projectRoot: Uri.parse('file:///project/'),
          resolvedArtifacts: const <String, String>{},
          trackWidgetCreation: true,
          treeShakeIcons: false,
          codeSizeDirectory: Uri.parse('file:///project/code_size_without_slash'),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ExtensionBuildContext(
          buildMode: .debug,
          flutterRoot: Uri.parse('file:///flutter/'),
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('file:///project/build/'),
          projectRoot: Uri.parse('file:///project/'),
          resolvedArtifacts: const <String, String>{},
          trackWidgetCreation: true,
          treeShakeIcons: false,
          splitDebugInfo: Uri.parse('file:///project/symbols_without_slash'),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ExtensionBuildContext(
          buildMode: .debug,
          flutterRoot: Uri.parse('file:///flutter/'),
          mainPath: 'lib/main.dart',
          outputDir: Uri.parse('file:///project/build/'),
          projectRoot: Uri.parse('file:///project/'),
          resolvedArtifacts: const <String, String>{},
          trackWidgetCreation: true,
          treeShakeIcons: false,
          splitDebugInfo: Uri.parse('relative/symbols/'),
        ),
        throwsA(isA<AssertionError>()),
      );
      final validBaseMap = <String, Object?>{
        'buildMode': 'debug',
        'dartObfuscation': false,
        'flutterRoot': 'file:///flutter/',
        'mainPath': 'lib/main.dart',
        'outputDir': 'file:///project/build/',
        'projectRoot': 'file:///project/',
        'resolvedArtifacts': const <String, Object?>{},
        'trackWidgetCreation': true,
        'treeShakeIcons': false,
      };
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
        mainPath: 'lib/main.dart',
        outputDir: Uri.parse('file:///project/build/'),
        projectRoot: Uri.parse('file:///project/'),
        resolvedArtifacts: const <String, String>{},
        trackWidgetCreation: true,
        treeShakeIcons: false,
        configuration: const <String, String?>{'custom-opt': 'val'},
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
