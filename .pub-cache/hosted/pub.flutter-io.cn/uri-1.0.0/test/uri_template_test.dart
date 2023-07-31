// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library uri.uri_template_test;

import 'package:test/test.dart';
import 'package:uri/uri.dart';

void main() {
  group('UriTemplate', () {
    test('should have a working equals method', () {
      final a1 = UriTemplate('a');
      final a2 = UriTemplate('a');
      final b1 = UriTemplate('b');
      expect(a1, equals(a2));
      expect(a2, equals(a1));
      expect(a1, isNot(b1));
    });

    test('should have a working hashCode', () {
      final a = UriTemplate('a');
      final b = UriTemplate('b');
      expect(a.hashCode, isPositive);
      // here we assume that the hashCode is reasonable and changes
      // for a single character.
      expect(a.hashCode, isNot(b.hashCode));
    });
  });
}
