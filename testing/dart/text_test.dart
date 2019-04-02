// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:test/test.dart';

void main() {
  group('FontWeight.lerp', () {
    test('works with non-null values', () {
      expect(FontWeight.lerp(FontWeight.w400, FontWeight.w600, .5), equals(FontWeight.w500));
    });

    test('returns null if a and b are null', () {
      expect(FontWeight.lerp(null, null, 0), isNull);
    });

    test('returns FontWeight.w400 if a is null', () {
      expect(FontWeight.lerp(null, FontWeight.w400, 0), equals(FontWeight.w400));
    });

    test('returns FontWeight.w400 if b is null', () {
      expect(FontWeight.lerp(FontWeight.w400, null, 1), equals(FontWeight.w400));
    });
  });
}
