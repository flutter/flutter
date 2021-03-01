// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart=2.12

import 'package:ui/src/engine.dart';
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('PathRef.getRRect with radius', () {
    final SurfacePath path = SurfacePath();
    final RRect rrect = RRect.fromLTRBR(0, 0, 10, 10, Radius.circular(2));
    path.addRRect(rrect);
    expect(path.toRoundedRect(), rrect);
  });

  test('PathRef.getRRect with radius larger than rect', () {
    final SurfacePath path = SurfacePath();
    final RRect rrect = RRect.fromLTRBR(0, 0, 10, 10, Radius.circular(20));
    path.addRRect(rrect);
    expect(
      path.toRoundedRect(),
      // Path.addRRect will correct the radius to fit the dimensions, so when
      // extracting the rrect out of the path we don't get the original.
      RRect.fromLTRBR(0, 0, 10, 10, Radius.circular(5)),
    );
  });

  test('PathRef.getRRect with zero radius', () {
    final SurfacePath path = SurfacePath();
    final RRect rrect = RRect.fromLTRBR(0, 0, 10, 10, Radius.circular(0));
    path.addRRect(rrect);
    expect(path.toRoundedRect(), isNull);
    expect(path.toRect(), rrect.outerRect);
  });

  test('PathRef.getRRect elliptical', () {
    final SurfacePath path = SurfacePath();
    final RRect rrect = RRect.fromLTRBR(0, 0, 10, 10, Radius.elliptical(2, 4));
    path.addRRect(rrect);
    expect(path.toRoundedRect(), rrect);
  });

  test('PathRef.getRRect elliptical zero x', () {
    final SurfacePath path = SurfacePath();
    final RRect rrect = RRect.fromLTRBR(0, 0, 10, 10, Radius.elliptical(0, 3));
    path.addRRect(rrect);
    expect(path.toRoundedRect(), isNull);
    expect(path.toRect(), rrect.outerRect);
  });

  test('PathRef.getRRect elliptical zero y', () {
    final SurfacePath path = SurfacePath();
    final RRect rrect = RRect.fromLTRBR(0, 0, 10, 10, Radius.elliptical(3, 0));
    path.addRRect(rrect);
    expect(path.toRoundedRect(), isNull);
    expect(path.toRect(), rrect.outerRect);
  });

  test('PathRef.getRRect with nearly zero corner', () {
    final SurfacePath path = SurfacePath();
    final RRect original = RRect.fromLTRBR(0, 0, 10, 10, Radius.elliptical(0.00000001, 5));
    path.addRRect(original);
    expect(path.toRoundedRect(), original);
  });
}
