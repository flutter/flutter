// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExtensionPlatformTemplate', () {
    test('round-trips JSON serialization and equality', () {
      final Uri uri = Uri.parse('package:my_ext/templates/app');
      final template = ExtensionPlatformTemplate(templateUri: uri);
      final Map<String, Object?> map = template.toMap();

      expect(map, equals(<String, Object?>{'templateUri': 'package:my_ext/templates/app'}));
      final deserialized = ExtensionPlatformTemplate.fromJson(map);
      expect(deserialized, equals(template));
      expect(deserialized.hashCode, equals(template.hashCode));
      expect(
        deserialized.toString(),
        equals('ExtensionPlatformTemplate(templateUri: package:my_ext/templates/app)'),
      );
    });

    test('rejects invalid templateUri in constructor and fromJson', () {
      const invalidUris = <String>[
        'file:///tmp/templates/app',
        'https://example.com/templates/app',
        'package:my_ext',
        'package:my_ext/',
        'package:my_ext/templates/app/',
        'package:/my_ext/templates',
        'package://host/my_ext/templates',
        'package:my_ext//templates',
        'package:my_ext/../templates',
        'package:my_ext/templates?foo=bar',
        'package:my_ext/templates#frag',
      ];
      for (final raw in invalidUris) {
        expect(
          () => ExtensionPlatformTemplate(templateUri: Uri.parse(raw)),
          throwsArgumentError,
          reason: 'Constructor should reject "$raw"',
        );
        expect(
          () => ExtensionPlatformTemplate.fromJson(<String, Object?>{
            ExtensionPlatformTemplate.templateUriKey: raw,
          }),
          throwsFormatException,
          reason: 'fromJson should reject "$raw"',
        );
      }

      expect(
        () => ExtensionPlatformTemplate.fromJson(const <String, Object?>{}),
        throwsFormatException,
      );
      expect(
        () => ExtensionPlatformTemplate.fromJson(const <String, Object?>{
          ExtensionPlatformTemplate.templateUriKey: 123,
        }),
        throwsFormatException,
      );
    });
  });
}
