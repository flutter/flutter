// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/ui.dart';

import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUiTest();

  test('Gradient.radial with no focal point', () {
    expect(
      Gradient.radial(
          Offset.zero,
          5.0,
          <Color>[const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)],
          <double>[0.0, 1.0],
          TileMode.mirror),
      isNotNull,
    );
  }, skip: isSkwasm);

  // this is just a radial gradient, focal point is discarded.
  test('radial center and focal == Offset.zero and focalRadius == 0.0 is ok',
      () {
    expect(
        () => Gradient.radial(
              Offset.zero,
              0.0,
              <Color>[const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)],
              <double>[0.0, 1.0],
              TileMode.mirror,
              null,
              Offset.zero,
            ),
        isNotNull);
  }, skip: isSkwasm);

  test('radial center != focal and focalRadius == 0.0 is ok', () {
    expect(
        () => Gradient.radial(
              Offset.zero,
              0.0,
              <Color>[const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)],
              <double>[0.0, 1.0],
              TileMode.mirror,
              null,
              const Offset(2.0, 2.0),
            ),
        isNotNull);
  }, skip: isSkwasm);

  // this would result in div/0 on skia side.
  test('radial center and focal == Offset.zero and focalRadius != 0.0 assert',
      () {
    expect(
      () => Gradient.radial(
            Offset.zero,
            0.0,
            <Color>[const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)],
            <double>[0.0, 1.0],
            TileMode.mirror,
            null,
            Offset.zero,
            1.0,
          ),
      throwsA(const TypeMatcher<AssertionError>()),
    );
  }, skip: isSkwasm);
}
