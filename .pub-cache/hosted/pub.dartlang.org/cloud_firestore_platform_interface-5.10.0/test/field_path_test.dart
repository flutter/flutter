// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/internal/field_path_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$FieldPath', () {
    test('equality', () {
      expect(FieldPath(const ['foo']), equals(FieldPath(const ['foo'])));
      expect(FieldPath(const ['foo', 'bar']),
          equals(FieldPath(const ['foo', 'bar'])));
      expect(FieldPath(const ['foo', 'bar']),
          equals(FieldPath.fromString('foo.bar')));
    });

    test('throws is invalid path is provided', () {
      expect(() => FieldPath(const []), throwsAssertionError);
    });

    test('returns a [List] of components', () {
      expect(FieldPath(const ['foo']).components, equals(const ['foo']));
      expect(
          FieldPath(const ['foo.bar']).components, equals(const ['foo.bar']));
      expect(FieldPath(const ['foo.bar', 'baz']).components,
          equals(const ['foo.bar', 'baz']));
    });

    test('returns a [FieldPathType] for a documentId', () {
      expect(FieldPath.documentId, equals(FieldPathType.documentId));
    });

    group('.fromString()', () {
      test('does not allow invalid string field paths', () {
        expect(() => FieldPath.fromString('.'), throwsAssertionError);
        expect(() => FieldPath.fromString('.foo'), throwsAssertionError);
        expect(() => FieldPath.fromString('foo.'), throwsAssertionError);
        expect(() => FieldPath.fromString('.foo.'), throwsAssertionError);
        expect(() => FieldPath.fromString('foo..bar'), throwsAssertionError);
        expect(() => FieldPath.fromString('foo~'), throwsAssertionError);
        expect(() => FieldPath.fromString('foo*'), throwsAssertionError);
        expect(() => FieldPath.fromString('foo/'), throwsAssertionError);
        expect(() => FieldPath.fromString('foo['), throwsAssertionError);
        expect(() => FieldPath.fromString('foo]'), throwsAssertionError);
      });

      test('creates a [FieldPath]', () {
        expect(FieldPath.fromString('foo.bar.baz'), isA<FieldPath>());
        expect(FieldPath.fromString('foo.bar.baz').components,
            equals(['foo', 'bar', 'baz']));
      });
    });
  });
}
