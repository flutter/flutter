// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/web/devfs_config.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('parse', () {
    test('returns HttpsConfig when both paths are provided', () {
      final HttpsConfig result = HttpsConfig.parse('/path/to/cert', '/path/to/key')!;
      expect(result.certPath, '/path/to/cert');
      expect(result.certKeyPath, '/path/to/key');
    });

    test('returns null when both paths are null', () {
      final HttpsConfig? result = HttpsConfig.parse(null, null);
      expect(result, isNull);
    });

    test('throws ArgumentError when only one field is provided', () {
      expect(() => HttpsConfig.parse('/path/to/cert', null), throwsArgumentError);
      expect(() => HttpsConfig.parse(null, '/path/to/key'), throwsArgumentError);
    });

    test('throws ArgumentError when the field is the wrong type', () {
      expect(() => HttpsConfig.parse(1, '/path/to/key'), throwsArgumentError);
      expect(() => HttpsConfig.parse('/path/to/cert', 1), throwsArgumentError);
    });
  });

  group('fromYaml', () {
    test('fromYaml throws an ArgumentError if cert-path is not defined', () {
      expect(
        () => HttpsConfig.fromYaml(loadYaml('cert-key-path: /path/to/key') as YamlMap),
        throwsArgumentError,
      );
    });

    test('fromYaml throws an ArgumentError if cert-key-path is not defined', () {
      expect(
        () => HttpsConfig.fromYaml(loadYaml('cert-path: /path/to/cert') as YamlMap),
        throwsArgumentError,
      );
    });

    test(
      'fromYaml creates an HttpsConfig object when both certificate and key paths are provided',
      () {
        final https = HttpsConfig.fromYaml(
          loadYaml('''
cert-path: /path/to/cert
cert-key-path: /path/to/key''')
              as YamlMap,
        );

        expect(https.certPath, '/path/to/cert');
        expect(https.certKeyPath, '/path/to/key');
      },
    );
  });
}
