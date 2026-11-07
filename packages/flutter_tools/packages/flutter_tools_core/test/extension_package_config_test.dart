// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExtensionPackageConfig', () {
    test('serializes and deserializes correctly with all fields', () {
      final config = ExtensionPackageConfig(
        name: 'my_custom_ext',
        entrypoint: 'bin/custom_entry.dart',
        hostPlatforms: const <String>{'Linux', 'MacOS'},
        services: const <String>{'diagnostics', 'config', 'build', 'template'},
        buildTargets: const <String>{'custom-build'},
        targetPlatforms: const <String>{'custom_linux'},
      );

      expect(config.hostPlatforms, const <String>{'linux', 'macos'});
      expect(config.supportsHostPlatform('LINUX'), isTrue);
      expect(config.supportsHostPlatform('windows'), isFalse);

      final Map<String, Object?> map = config.toMap();
      expect(map[ExtensionPackageConfig.nameKey], 'my_custom_ext');
      expect(map[ExtensionPackageConfig.entrypointKey], 'bin/custom_entry.dart');
      expect(
        map[ExtensionPackageConfig.hostPlatformsKey],
        unorderedEquals(const <String>['linux', 'macos']),
      );
      expect(
        map[ExtensionPackageConfig.servicesKey],
        unorderedEquals(const <String>['diagnostics', 'config', 'build', 'template']),
      );
      expect(map[ExtensionPackageConfig.buildTargetsKey], const <String>['custom-build']);
      expect(map[ExtensionPackageConfig.targetPlatformsKey], const <String>['custom_linux']);

      final String encoded = jsonEncode(map);
      final parsed = ExtensionPackageConfig.fromMap(
        jsonDecode(encoded) as Map<String, Object?>,
        packageName: 'my_custom_ext',
      );
      expect(parsed, equals(config));
      expect(parsed.hashCode, equals(config.hashCode));
      expect(parsed.toString(), contains('my_custom_ext'));
      expect(parsed.toString(), contains('bin/custom_entry.dart'));
    });

    test('applies default entrypoint and allows omitted or empty services', () {
      final config = ExtensionPackageConfig.fromMap(const <String, Object?>{
        ExtensionPackageConfig.nameKey: 'minimal_ext',
      });

      expect(config.name, 'minimal_ext');
      expect(config.entrypoint, 'bin/minimal_ext.dart');
      expect(config.hostPlatforms, isEmpty);
      expect(config.supportsHostPlatform('windows'), isTrue);
      expect(config.services, isEmpty);
      expect(config.buildTargets, isEmpty);
      expect(config.targetPlatforms, isEmpty);

      final emptyServicesConfig = ExtensionPackageConfig.fromMap(const <String, Object?>{
        ExtensionPackageConfig.nameKey: 'minimal_ext',
        ExtensionPackageConfig.servicesKey: <String>[],
      });
      expect(emptyServicesConfig, equals(config));
    });

    test('trims list entries', () {
      final config = ExtensionPackageConfig.fromMap(const <String, Object?>{
        ExtensionPackageConfig.nameKey: 'my_ext',
        ExtensionPackageConfig.servicesKey: <String>[' diagnostics ', 'build'],
        ExtensionPackageConfig.targetPlatformsKey: <String>[' custom_os '],
      });

      expect(config.services, const <String>{'diagnostics', 'build'});
      expect(config.targetPlatforms, const <String>{'custom_os'});
    });

    test('constructor trims string list entries', () {
      final config = ExtensionPackageConfig(
        name: 'my_ext',
        services: const <String>[' diagnostics ', 'build '],
        hostPlatforms: const <String>[' Linux '],
        buildTargets: const <String>[' custom-build '],
      );

      expect(config.services, const <String>{'diagnostics', 'build'});
      expect(config.hostPlatforms, const <String>{'linux'});
      expect(config.buildTargets, const <String>{'custom-build'});
    });

    test('throws FormatException when services contains empty string elements', () {
      expect(
        () => ExtensionPackageConfig.fromMap(const <String, Object?>{
          ExtensionPackageConfig.nameKey: 'my_ext',
          ExtensionPackageConfig.servicesKey: <String>['diagnostics', '  '],
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException on invalid or mismatched fields', () {
      expect(
        () => ExtensionPackageConfig.fromMap(const <String, Object?>{
          ExtensionPackageConfig.servicesKey: <String>['diagnostics'],
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionPackageConfig.fromMap(const <String, Object?>{
          ExtensionPackageConfig.servicesKey: <String>['diagnostics'],
        }, packageName: 'inferred_ext'),
        throwsFormatException,
      );
      expect(
        () => ExtensionPackageConfig.fromMap(const <String, Object?>{
          ExtensionPackageConfig.nameKey: 'wrong_name',
          ExtensionPackageConfig.servicesKey: <String>['diagnostics'],
        }, packageName: 'expected_name'),
        throwsFormatException,
      );
      expect(
        () => ExtensionPackageConfig.fromMap(const <String, Object?>{
          ExtensionPackageConfig.nameKey: 'my_ext',
          ExtensionPackageConfig.entrypointKey: '',
          ExtensionPackageConfig.servicesKey: <String>['diagnostics'],
        }),
        throwsFormatException,
      );
      for (final invalidEntrypoint in const <String>[
        '../outside.dart',
        'bin/../../outside.dart',
        '%2e%2e/outside.dart',
        'bin/%2e%2e/outside.dart',
        './inside.dart',
        'bin/./inside.dart',
        '/abs/path.dart',
        'file:///abs/path.dart',
        'https://example.com/ext.dart',
        'bin/my_ext.dart?foo=bar',
        'bin/my_ext.dart#frag',
        r'bin\my_ext.dart',
        'bin/not_a_dart_file.txt',
        'bin/.dart',
        '.dart',
      ]) {
        expect(
          () => ExtensionPackageConfig.fromMap(<String, Object?>{
            ExtensionPackageConfig.nameKey: 'my_ext',
            ExtensionPackageConfig.entrypointKey: invalidEntrypoint,
            ExtensionPackageConfig.servicesKey: const <String>['diagnostics'],
          }),
          throwsFormatException,
          reason: 'Expected "$invalidEntrypoint" to be rejected',
        );
      }
      for (final invalidPlatform in const <String>[
        'Invalid-Name',
        '123abc',
        'projectName',
        'custom-linux',
      ]) {
        expect(
          () => ExtensionPackageConfig.fromMap(<String, Object?>{
            ExtensionPackageConfig.nameKey: 'my_ext',
            ExtensionPackageConfig.targetPlatformsKey: <Object?>[invalidPlatform],
            ExtensionPackageConfig.servicesKey: const <String>['diagnostics'],
          }),
          throwsA(
            isA<FormatException>().having(
              (FormatException e) => e.message,
              'message',
              'Extension config.yaml "${ExtensionPackageConfig.targetPlatformsKey}" entries must be '
                  'lowercase snake_case identifiers starting with a letter (e.g. "custom_os"), '
                  'got: "$invalidPlatform".',
            ),
          ),
        );
      }
      expect(
        () => ExtensionPackageConfig.fromMap(const <String, Object?>{
          ExtensionPackageConfig.nameKey: 'my_ext',
          ExtensionPackageConfig.servicesKey: 'not-a-list',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionPackageConfig.fromMap(const <String, Object?>{
          ExtensionPackageConfig.nameKey: 'my_ext',
          ExtensionPackageConfig.servicesKey: <Object?>['diagnostics', 42],
        }),
        throwsFormatException,
      );
    });

    test('equality and hashCode compare Set contents unordered', () {
      final base = ExtensionPackageConfig(
        name: 'ext',
        services: const <String>{'a', 'b'},
        targetPlatforms: const <String>{'p1', 'p2'},
      );
      final reordered = ExtensionPackageConfig(
        name: 'ext',
        services: const <String>{'b', 'a'},
        targetPlatforms: const <String>{'p2', 'p1'},
      );
      final differentPlatforms = ExtensionPackageConfig(
        name: 'ext',
        services: const <String>{'a', 'b'},
        targetPlatforms: const <String>{'p1'},
      );

      expect(base, equals(reordered));
      expect(base.hashCode, equals(reordered.hashCode));
      expect(base, isNot(equals(differentPlatforms)));
    });
  });
}
