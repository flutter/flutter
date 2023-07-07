// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$SetOptions', () {
    test('throws if no options are provided', () {
      expect(SetOptions.new, throwsAssertionError);
    });

    test('throws if mergeFields contains invalid values', () {
      expect(() => SetOptions(mergeFields: [123]), throwsAssertionError);
      expect(() => SetOptions(mergeFields: [{}]), throwsAssertionError);
    });

    test('throws if merge is set with mergeFields', () {
      expect(
        () => SetOptions(merge: true, mergeFields: ['123']),
        throwsAssertionError,
      );
      expect(
        () => SetOptions(merge: false, mergeFields: ['123']),
        throwsAssertionError,
      );
    });

    test('mergeFields are set as a [FieldPath] & preserve current FieldPaths',
        () {
      expect(
        SetOptions(
          mergeFields: [
            'foo.bar',
            FieldPath(const ['foo', 'bar', 'baz'])
          ],
        ).mergeFields,
        equals(
          [
            FieldPath(const ['foo', 'bar']),
            FieldPath(const ['foo', 'bar', 'baz']),
          ],
        ),
      );
    });
  });
}
