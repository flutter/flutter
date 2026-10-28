// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExtensionPackageConfig', () {
    test('round-trips via toMap and fromJson and supports equality', () {
      final config = ExtensionPackageConfig(
        name: 'custom_embedder',
        entrypoint: 'bin/custom_embedder.dart',
        supportedPlatforms: const <String>{'Linux', 'macOS'},
        services: const <String>{'device', 'build'},
        buildTargets: const <String>{'custom_bundle'},
        templates: const <String>{'custom_app'},
        platforms: const <String>{'custom_os'},
      );

      final Map<String, Object?> serialized = config.toMap();
      final deserialized = ExtensionPackageConfig.fromJson(serialized);

      expect(deserialized, equals(config));
      expect(deserialized.hashCode, equals(config.hashCode));
      expect(deserialized.toString(), contains('name: custom_embedder'));
      expect(deserialized.supportedPlatforms, const <String>{'linux', 'macos'});
    });

    test('applies default entrypoint, protocolVersion, and supportedPlatforms', () {
      final config = ExtensionPackageConfig.fromJson(const <String, Object?>{
        'name': 'demo_ext',
        'services': <String>['diagnostics'],
      });

      expect(config.name, 'demo_ext');
      expect(config.protocolVersion, ExtensionPackageConfig.currentProtocolVersion);
      expect(config.entrypoint, 'bin/demo_ext.dart');
      expect(config.supportedPlatforms, ExtensionPackageConfig.defaultSupportedPlatforms);
      expect(config.services, const <String>{'diagnostics'});
      expect(config.buildTargets, isEmpty);
      expect(config.templates, isEmpty);
      expect(config.platforms, isEmpty);
    });

    test('throws FormatException on invalid name, entrypoint, or empty services', () {
      expect(
        () => ExtensionPackageConfig.fromJson(const <String, Object?>{
          'name': '   ',
          'services': <String>['device'],
        }),
        throwsFormatException,
      );

      expect(
        () => ExtensionPackageConfig.fromJson(const <String, Object?>{
          'name': 'wrong_name',
          'services': <String>['device'],
        }, packageName: 'expected_name'),
        throwsFormatException,
      );

      expect(
        () => ExtensionPackageConfig.fromJson(const <String, Object?>{
          'name': 'demo_ext',
          'entrypoint': '../escape.dart',
          'services': <String>['device'],
        }),
        throwsFormatException,
      );

      expect(
        () => ExtensionPackageConfig.fromJson(const <String, Object?>{
          'name': 'demo_ext',
          'services': <String>[],
        }),
        throwsFormatException,
      );
    });
  });
}
