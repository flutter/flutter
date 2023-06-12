// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:mime/src/default_extension_map.dart';
import 'package:test/test.dart';

void main() {
  group('defaultExtensionMap', () {
    test('keys are lowercase', () {
      for (final key in defaultExtensionMap.keys) {
        expect(key, equals(key.toLowerCase()));
      }
    });
  });
}
