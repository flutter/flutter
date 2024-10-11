// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ShapeBoundary - OffsetBoundaryProvider', (WidgetTester tester) async {
    ShapeBoundaryRegulator<Offset>? boundary;
    await tester.pumpWidget(
      Container(
        margin: const EdgeInsets.only(top: 100, left: 100),
        alignment: Alignment.topLeft,
        child: PointBoundaryRegulatorProvider(
          child: SizedBox(
            width: 100,
            height: 100,
            child: Builder(
              builder: (BuildContext context) {
                boundary = PointBoundaryRegulatorProvider.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    expect(boundary, isNotNull);
    expect(boundary!.isWithinBoundary(const Offset(50, 50)), isFalse);
    expect(boundary!.isWithinBoundary(const Offset(150, 150)), isTrue);
    expect(boundary!.nearestPositionWithinBoundary(const Offset(50, 50)), const Offset(100, 100));
    expect(boundary!.nearestPositionWithinBoundary(const Offset(150, 150)), const Offset(150, 150));
  });

  testWidgets('ShapeBoundary - RectBoundaryProvider', (WidgetTester tester) async {
    ShapeBoundaryRegulator<Rect>? boundary;
    await tester.pumpWidget(
      Container(
        margin: const EdgeInsets.only(top: 100, left: 100),
        alignment: Alignment.topLeft,
        child: RectBoundaryRegulatorProvider(
          child: SizedBox(
            width: 100,
            height: 100,
            child: Builder(
              builder: (BuildContext context) {
                boundary = RectBoundaryRegulatorProvider.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    expect(boundary, isNotNull);
    expect(boundary!.isWithinBoundary(const Rect.fromLTWH(50, 50, 20, 20)), isFalse);
    expect(boundary!.isWithinBoundary(const Rect.fromLTWH(100, 100, 20, 20)), isTrue);
    expect(boundary!.nearestPositionWithinBoundary(const Rect.fromLTWH(50, 50, 20, 20)), const Rect.fromLTWH(100, 100, 20, 20));
    expect(boundary!.nearestPositionWithinBoundary(const Rect.fromLTWH(150, 150, 20, 20)), const Rect.fromLTWH(150, 150, 20, 20));
  });
}
