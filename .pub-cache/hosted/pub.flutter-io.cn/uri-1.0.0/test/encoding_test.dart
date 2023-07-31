// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library uri.encoding_test;

import 'package:test/test.dart';
import 'package:uri/src/encoding.dart';

void main() {
  group('pctEncode allow reserved', () {
    test('should encode % chars, but preserve pct-encoded triplets', () {
      expect(pctEncode('%25', reservedTable, allowPctTriplets: true), '%25');
      expect(pctEncode('%', reservedTable, allowPctTriplets: true), '%25');
      expect(
          pctEncode('%%25', reservedTable, allowPctTriplets: true), '%25%25');
      expect(
          pctEncode('%25%2', reservedTable, allowPctTriplets: true), '%25%252');
    });

    test('should allow reserved chars', () {
      // general delimiters
      expect(pctEncode(':/?#[]@', reservedTable), ':/?#[]@');
      // sub delimiters
      expect(pctEncode(r"!$&'()*+,;=", reservedTable), r"!$&'()*+,;=");
    });

    test('should allow unreserved chars', () {
      expect(pctEncode('-._~', reservedTable), '-._~');
    });
  });

  group('pctEncode allow unreserved', () {
    test('should encode % chars, including pct-encoded triplets', () {
      expect(pctEncode('%25', unreservedTable), '%2525');
      expect(pctEncode('%', unreservedTable), '%25');
      expect(pctEncode('%%25', unreservedTable), '%25%2525');
      expect(pctEncode('%25%2', unreservedTable), '%2525%252');
    });

    test('should encode reserved chars', () {
      // general delimiters
      expect(pctEncode(':/?#[]@', unreservedTable), '%3A%2F%3F%23%5B%5D%40');
      // sub delimiters
      expect(pctEncode(r"!$&'()*+,;=", unreservedTable),
          '%21%24%26%27%28%29%2A%2B%2C%3B%3D');
    });

    test('should allow unreserved chars', () {
      expect(pctEncode('-._~', unreservedTable), '-._~');
    });
  });
}
