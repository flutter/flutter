// Copyright 2018 the Dart project authors.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:visibility_detector/visibility_detector.dart';

void _expectVisibility(Rect widgetBounds, Rect clipRect,
    Rect expectedVisibleBounds, double expectedVisibleFraction) {
  final info = VisibilityInfo.fromRects(
      key: UniqueKey(), widgetBounds: widgetBounds, clipRect: clipRect);
  expect(info.size, widgetBounds.size);
  expect(info.visibleBounds, expectedVisibleBounds);
  expect(info.visibleFraction, expectedVisibleFraction);
}

void main() {
  const clipRect = Rect.fromLTWH(100, 200, 300, 400);

  group('VisibilityInfo', () {
    test('Computes not visible', () {
      const widgetBounds = Rect.fromLTWH(15, 25, 10, 20);
      const expectedVisibleBounds = Rect.zero;
      _expectVisibility(widgetBounds, clipRect, expectedVisibleBounds, 0);
    });

    test('Computes fully visible', () {
      const widgetBounds = Rect.fromLTWH(115, 225, 10, 20);
      const expectedVisibleBounds = Rect.fromLTWH(0, 0, 10, 20);
      _expectVisibility(widgetBounds, clipRect, expectedVisibleBounds, 1);
    });

    test('Computes partially visible (1 edge offscreen)', () {
      const widgetBounds = Rect.fromLTWH(115, 195, 10, 20);
      const expectedVisibleBounds = Rect.fromLTWH(0, 5, 10, 15);
      _expectVisibility(widgetBounds, clipRect, expectedVisibleBounds, 0.75);
    });

    test('Computes partially visible (2 edges offscreen)', () {
      const widgetBounds = Rect.fromLTWH(99, 195, 10, 20);
      const expectedVisibleBounds = Rect.fromLTWH(1, 5, 9, 15);
      _expectVisibility(widgetBounds, clipRect, expectedVisibleBounds, 0.675);
    });

    test('Computes partially visible (3 edges offscreen)', () {
      const widgetBounds = Rect.fromLTWH(99, 195, 500, 20);
      const expectedVisibleBounds = Rect.fromLTWH(1, 5, 300, 15);
      _expectVisibility(widgetBounds, clipRect, expectedVisibleBounds, 0.45);
    });

    test('Computes partially visible (4 edges offscreen)', () {
      const widgetBounds = Rect.fromLTWH(99, 195, 500, 600);
      const expectedVisibleBounds = Rect.fromLTWH(1, 5, 300, 400);
      _expectVisibility(widgetBounds, clipRect, expectedVisibleBounds, 0.4);
    });

    test('Computes ~0% visibility as 0%', () {
      const widgetBounds = Rect.fromLTWH(100, 599, 300, 400);
      const expectedVisibleBounds = Rect.fromLTWH(0, 0, 300, 1);
      _expectVisibility(widgetBounds, clipRect, expectedVisibleBounds, 0);
    });

    test('Computes ~100% visibility as 100%', () {
      const widgetBounds = Rect.fromLTWH(100, 200, 300, 399);
      const expectedVisibleBounds = Rect.fromLTWH(0, 0, 300, 399);
      _expectVisibility(widgetBounds, clipRect, expectedVisibleBounds, 1);
    });
  });
}
