// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  const Rect rect = Rect.fromLTWH(100, 100, 200, 500);
  const Offset outsideTopLeft = Offset(50, 50);
  const Offset outsideLeft = Offset(50, 200);
  const Offset outsideBottomLeft = Offset(50, 700);
  const Offset outsideTop = Offset(200, 50);
  const Offset outsideTopRight = Offset(350, 50);
  const Offset outsideRight = Offset(350, 200);
  const Offset outsideBottomRight = Offset(350, 700);
  const Offset outsideBottom = Offset(200, 700);
  const Offset center = Offset(150, 300);

  group('selection utils', () {
    test('selectionBasedOnRect works', () {
      expect(
        SelectionUtil.selectionBasedOnRect(rect, outsideTopLeft),
        SelectionResult.previous,
      );
      expect(
        SelectionUtil.selectionBasedOnRect(rect, outsideLeft),
        SelectionResult.previous,
      );
      expect(
        SelectionUtil.selectionBasedOnRect(rect, outsideBottomLeft),
        SelectionResult.next,
      );
      expect(
        SelectionUtil.selectionBasedOnRect(rect, outsideTop),
        SelectionResult.previous,
      );
      expect(
        SelectionUtil.selectionBasedOnRect(rect, outsideTopRight),
        SelectionResult.previous,
      );
      expect(
        SelectionUtil.selectionBasedOnRect(rect, outsideRight),
        SelectionResult.next,
      );
      expect(
        SelectionUtil.selectionBasedOnRect(rect, outsideBottomRight),
        SelectionResult.next,
      );
      expect(
        SelectionUtil.selectionBasedOnRect(rect, outsideBottom),
        SelectionResult.next,
      );
      expect(
        SelectionUtil.selectionBasedOnRect(rect, center),
        SelectionResult.previous,
      );
    });

    test('adjustDragOffset works', () {
      // ltr
      expect(SelectionUtil.adjustDragOffset(rect, outsideTopLeft), rect.topLeft);
      expect(SelectionUtil.adjustDragOffset(rect, outsideLeft), rect.topLeft);
      expect(SelectionUtil.adjustDragOffset(rect, outsideBottomLeft), rect.bottomRight);
      expect(SelectionUtil.adjustDragOffset(rect, outsideTop), rect.topLeft);
      expect(SelectionUtil.adjustDragOffset(rect, outsideTopRight), rect.topLeft);
      expect(SelectionUtil.adjustDragOffset(rect, outsideRight), rect.bottomRight);
      expect(SelectionUtil.adjustDragOffset(rect, outsideBottomRight), rect.bottomRight);
      expect(SelectionUtil.adjustDragOffset(rect, outsideBottom), rect.bottomRight);
      expect(SelectionUtil.adjustDragOffset(rect, center), center);
      // rtl
      expect(SelectionUtil.adjustDragOffset(rect, outsideTopLeft, direction: TextDirection.rtl), rect.topRight);
      expect(SelectionUtil.adjustDragOffset(rect, outsideLeft, direction: TextDirection.rtl), rect.topRight);
      expect(SelectionUtil.adjustDragOffset(rect, outsideBottomLeft, direction: TextDirection.rtl), rect.bottomLeft);
      expect(SelectionUtil.adjustDragOffset(rect, outsideTop, direction: TextDirection.rtl), rect.topRight);
      expect(SelectionUtil.adjustDragOffset(rect, outsideTopRight, direction: TextDirection.rtl), rect.topRight);
      expect(SelectionUtil.adjustDragOffset(rect, outsideRight, direction: TextDirection.rtl), rect.bottomLeft);
      expect(SelectionUtil.adjustDragOffset(rect, outsideBottomRight, direction: TextDirection.rtl), rect.bottomLeft);
      expect(SelectionUtil.adjustDragOffset(rect, outsideBottom, direction: TextDirection.rtl), rect.bottomLeft);
      expect(SelectionUtil.adjustDragOffset(rect, center, direction: TextDirection.rtl), center);
    });
  });
}
