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

  group('ExtensionBuildTarget', () {
    test('serializes and deserializes correctly with all fields', () {
      const target = ExtensionBuildTarget(
        description: 'A custom Linux build target.',
        name: 'custom-linux-build',
      );

      final Map<String, Object?> map = target.toMap();
      expect(map[ExtensionBuildTarget.nameKey], 'custom-linux-build');
      expect(map[ExtensionBuildTarget.descriptionKey], 'A custom Linux build target.');

      final parsed = ExtensionBuildTarget.fromJson(map);
      expect(parsed, equals(target));
      expect(parsed.hashCode, equals(target.hashCode));
      expect(parsed.toString(), contains('custom-linux-build'));
    });

    test('deserializes with default empty strings when fields are missing', () {
      final parsed = ExtensionBuildTarget.fromJson(const <String, Object?>{});
      expect(parsed.name, isEmpty);
      expect(parsed.description, isEmpty);
    });

    test('listFromJson handles valid and invalid lists', () {
      final validJson = <String, Object?>{
        'name': 'custom-linux-build',
        'description': 'A custom Linux build target.',
      };

      final List<ExtensionBuildTarget> targets = ExtensionBuildTarget.listFromJson(<Object?>[
        validJson,
      ]);
      expect(targets, hasLength(1));
      expect(targets.first.name, 'custom-linux-build');
      expect(targets.first.description, 'A custom Linux build target.');

      expect(ExtensionBuildTarget.listFromJson(null), isEmpty);
      expect(ExtensionBuildTarget.listFromJson('invalid'), isEmpty);
    });

    test('equality and hashCode distinguish different targets', () {
      const target1 = ExtensionBuildTarget(description: 'Target 1', name: 'target-1');
      const target2 = ExtensionBuildTarget(description: 'Target 2', name: 'target-2');

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

      final parsed = ExtensionBuildResult.fromJson(map);
      expect(parsed, equals(result));
      expect(parsed.hashCode, equals(result.hashCode));
      expect(parsed.toString(), contains('success: true'));
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
      const result1 = ExtensionBuildResult(success: true);
      const result2 = ExtensionBuildResult(success: false, errorMessage: 'Failed');

      expect(result1, isNot(equals(result2)));
      expect(result1.hashCode, isNot(equals(result2.hashCode)));
    });
  });
}
