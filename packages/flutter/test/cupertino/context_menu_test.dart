// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';

void main() {
  group('ContextMenuRoute', () {
    group('getEndRect', () {
      const Rect parent = Rect.fromLTWH(
        0.0,
        0.0,
        500.0,
        500.0,
      );

      group('when given a landscape child', () {
        Rect child;
        setUp(() {
          child = const Rect.fromLTWH(
            100.0,
            100.0,
            200.0,
            50.0,
          );
        });

        test('fits child into parent', () {
          final Rect end = ContextMenuRoute.getEndRect(child, parent);
          expect(end.width, moreOrLessEquals(parent.width));
          expect(end.height, lessThan(parent.height));
          // It's not necessarily true that end's top/left/right/bottom fit
          // inside of parent, because end is calculated expecting to have
          // transform's center alignment applied to it.
        });
      });

      group('when given a portrait child', () {
        Rect child;
        setUp(() {
          child = const Rect.fromLTWH(
            100.0,
            100.0,
            50.0,
            200.0,
          );
        });

        test('fits child into parent accounting for topInset', () {
          final Rect end = ContextMenuRoute.getEndRect(child, parent);
          expect(end.width, lessThan(parent.width));
          expect(end.height, lessThan(parent.height));
          expect(end.top, greaterThanOrEqualTo(parent.top));
          expect(end.left, greaterThanOrEqualTo(parent.left));
          expect(end.right, lessThanOrEqualTo(parent.right));
          expect(end.bottom, lessThanOrEqualTo(parent.bottom));
        });
      });
    });
  });
}
