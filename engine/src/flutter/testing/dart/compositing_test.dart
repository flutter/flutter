// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show Float64List;
import 'dart:ui';

import 'package:test/test.dart';

void main() {
  test('pushTransform validates the matrix', () {
    final SceneBuilder builder = SceneBuilder();
    final Float64List matrix4 = Float64List.fromList(<double>[
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ]);
    expect(builder.pushTransform(matrix4), isNotNull);

    final Float64List matrix4WrongLength = Float64List.fromList(<double>[
      1, 0, 0, 0,
      0, 1, 0,
      0, 0, 1, 0,
      0, 0, 0,
    ]);
    expect(
      () => builder.pushTransform(matrix4WrongLength),
      throwsA(const TypeMatcher<AssertionError>()),
    );

    final Float64List matrix4NaN = Float64List.fromList(<double>[
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, double.nan,
    ]);
    expect(
      () => builder.pushTransform(matrix4NaN),
      throwsA(const TypeMatcher<AssertionError>()),
    );

    final Float64List matrix4Infinity = Float64List.fromList(<double>[
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, double.infinity,
    ]);
    expect(
      () => builder.pushTransform(matrix4NaN),
      throwsA(const TypeMatcher<AssertionError>()),
    );
  });
}
