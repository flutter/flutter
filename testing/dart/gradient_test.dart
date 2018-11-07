// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show Float64List;
import 'dart:ui';

import 'package:test/test.dart';

void main() {
  test('Gradient.radial with no focal point', () {
    expect(
      new Gradient.radial(
          Offset.zero,
          null,
          <Color>[const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)],
          <double>[0.0, 1.0],
          TileMode.mirror),
      isNotNull,
    );
  });

  // this is just a radial gradient, focal point is discarded.
  test('radial center and focal == Offset.zero and focalRadius == 0.0 is ok',
      () {
    expect(
        () => new Gradient.radial(
              Offset.zero,
              0.0,
              <Color>[const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)],
              <double>[0.0, 1.0],
              TileMode.mirror,
              null,
              Offset.zero,
              0.0,
            ),
        isNotNull);
  });

  test('radial center != focal and focalRadius == 0.0 is ok', () {
    expect(
        () => new Gradient.radial(
              Offset.zero,
              0.0,
              <Color>[const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)],
              <double>[0.0, 1.0],
              TileMode.mirror,
              null,
              const Offset(2.0, 2.0),
              0.0,
            ),
        isNotNull);
  });

  // this would result in div/0 on skia side.
  test('radial center and focal == Offset.zero and focalRadius != 0.0 assert',
      () {
    expect(
      () => new Gradient.radial(
            Offset.zero,
            0.0,
            <Color>[const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)],
            <double>[0.0, 1.0],
            TileMode.mirror,
            null,
            Offset.zero,
            1.0,
          ),
      throwsA(const isInstanceOf<AssertionError>()),
    );
  });
}
