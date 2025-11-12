// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/web/devfs_config.dart';
import 'package:test/test.dart';

void main() {
  group('HttpsConfig.parse', () {
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
}
