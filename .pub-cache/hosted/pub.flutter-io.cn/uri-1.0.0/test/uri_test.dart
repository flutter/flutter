// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library uri.uri_test;

import 'package:test/test.dart';
import 'package:uri/uri.dart';

void main() {
  group('UriMatch', () {
    test('should implement equals and hashCode', () {
      final match1 = UriMatch(
          TestUriPattern(123), Uri.parse('abc'), {'a': 'b'}, Uri.parse('bc'));

      final match2 = UriMatch(
          TestUriPattern(123), Uri.parse('abc'), {'a': 'b'}, Uri.parse('bc'));
      expect(match1.hashCode, match2.hashCode);
      expect(match1, match2);

      final match3 = UriMatch(
          TestUriPattern(456), Uri.parse('abc'), {'a': 'b'}, Uri.parse('bc'));
      expect(match1.hashCode, isNot(match3.hashCode));
      expect(match1, isNot(match3));

      final match4 = UriMatch(
          TestUriPattern(123), Uri.parse('abd'), {'a': 'b'}, Uri.parse('bc'));
      expect(match1.hashCode, isNot(match4.hashCode));
      expect(match1, isNot(match4));

      final match5 = UriMatch(
          TestUriPattern(123), Uri.parse('abc'), {'c': 'b'}, Uri.parse('bc'));
      expect(match1.hashCode, isNot(match5.hashCode));
      expect(match1, isNot(match5));

      final match6 = UriMatch(
          TestUriPattern(123), Uri.parse('abc'), {'a': 'b'}, Uri.parse('bd'));
      expect(match1.hashCode, isNot(match6.hashCode));
      expect(match1, isNot(match6));
    });
  });
}

class TestUriPattern extends UriPattern {
  @override
  final int hashCode;

  TestUriPattern(this.hashCode);

  @override
  UriMatch? match(Uri uri) => null;

  // ignore: hash_and_equals
  @override
  bool operator ==(Object object) => hashCode == object.hashCode;

  @override
  Uri expand(Map<String, Object> parameters) => throw UnimplementedError();
}
