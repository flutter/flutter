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
        supportedPlatforms: const <String>{'Linux', 'MacOS'},
        services: const <String>{'diagnostics', 'config', 'build', 'template'},
        buildTargets: const <String>{'custom-build'},
        templates: const <String>{'custom-app'},
        platforms: const <String>{'custom_linux'},
      );

      expect(config.supportedPlatforms, const <String>{'linux', 'macos'});
      expect(config.supportsHostPlatform('LINUX'), isTrue);
      expect(config.supportsHostPlatform('windows'), isFalse);

      final Map<String, Object?> map = config.toMap();
      expect(map[ExtensionPackageConfig.nameKey], 'my_custom_ext');
      expect(map[ExtensionPackageConfig.protocolVersionKey], 1);
      expect(map[ExtensionPackageConfig.entrypointKey], 'bin/custom_entry.dart');
      expect(
        map[ExtensionPackageConfig.supportedPlatformsKey],
        unorderedEquals(const <String>['linux', 'macos']),
      );
      expect(
        map[ExtensionPackageConfig.servicesKey],
        unorderedEquals(const <String>['diagnostics', 'config', 'build', 'template']),
      );
      expect(map[ExtensionPackageConfig.buildTargetsKey], const <String>['custom-build']);
      expect(map[ExtensionPackageConfig.templatesKey], const <String>['custom-app']);
      expect(map[ExtensionPackageConfig.platformsKey], const <String>['custom_linux']);

      final String encoded = jsonEncode(map);
      final parsed = ExtensionPackageConfig.fromMap(
        jsonDecode(encoded) as Map<Object?, Object?>,
        packageName: 'my_custom_ext',
      );
      expect(parsed, equals(config));
      expect(parsed.hashCode, equals(config.hashCode));
      expect(parsed.toString(), contains('my_custom_ext'));
      expect(parsed.toString(), contains('bin/custom_entry.dart'));
    });

    test('applies default protocolVersion and entrypoint when omitted', () {
      final config = ExtensionPackageConfig.fromMap(const <String, Object?>{
        ExtensionPackageConfig.nameKey: 'minimal_ext',
      });

      expect(config.name, 'minimal_ext');
      expect(config.protocolVersion, ExtensionPackageConfig.currentProtocolVersion);
      expect(config.entrypoint, 'bin/minimal_ext.dart');
      expect(config.supportedPlatforms, isEmpty);
      expect(config.supportsHostPlatform('windows'), isTrue);
      expect(config.services, isEmpty);
      expect(config.buildTargets, isEmpty);
      expect(config.templates, isEmpty);
      expect(config.platforms, isEmpty);
    });

    test('falls back to packageName when name key is omitted', () {
      final config = ExtensionPackageConfig.fromMap(
        const <String, Object?>{},
        packageName: 'inferred_ext',
      );

      expect(config.name, 'inferred_ext');
      expect(config.entrypoint, 'bin/inferred_ext.dart');
    });

    test('throws FormatException on invalid or mismatched fields', () {
      expect(
        () => ExtensionPackageConfig.fromMap(const <String, Object?>{}),
        throwsFormatException,
      );
      expect(
        () => ExtensionPackageConfig.fromMap(const <String, Object?>{
          ExtensionPackageConfig.nameKey: 'wrong_name',
        }, packageName: 'expected_name'),
        throwsFormatException,
      );
      expect(
        () => ExtensionPackageConfig.fromMap(const <String, Object?>{
          ExtensionPackageConfig.nameKey: 'my_ext',
          ExtensionPackageConfig.protocolVersionKey: '1',
        }),
        throwsFormatException,
      );
      expect(
        () => ExtensionPackageConfig.fromMap(const <String, Object?>{
          ExtensionPackageConfig.nameKey: 'my_ext',
          ExtensionPackageConfig.entrypointKey: '',
        }),
        throwsFormatException,
      );
      for (final invalidEntrypoint in const <String>[
        '../outside.dart',
        'bin/../../outside.dart',
        '/abs/path.dart',
        'file:///abs/path.dart',
        r'bin\my_ext.dart',
      ]) {
        expect(
          () => ExtensionPackageConfig.fromMap(<String, Object?>{
            ExtensionPackageConfig.nameKey: 'my_ext',
            ExtensionPackageConfig.entrypointKey: invalidEntrypoint,
          }),
          throwsFormatException,
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
            ExtensionPackageConfig.platformsKey: <Object?>[invalidPlatform],
          }),
          throwsFormatException,
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
        platforms: const <String>{'p1', 'p2'},
      );
      final reordered = ExtensionPackageConfig(
        name: 'ext',
        services: const <String>{'b', 'a'},
        platforms: const <String>{'p2', 'p1'},
      );
      final differentPlatforms = ExtensionPackageConfig(
        name: 'ext',
        services: const <String>{'a', 'b'},
        platforms: const <String>{'p1'},
      );

      expect(base, equals(reordered));
      expect(base.hashCode, equals(reordered.hashCode));
      expect(base, isNot(equals(differentPlatforms)));
    });
  });
}
