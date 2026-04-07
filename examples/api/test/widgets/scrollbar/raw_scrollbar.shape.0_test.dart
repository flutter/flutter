// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/scrollbar/raw_scrollbar.shape.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('The thumb shape is a stadium border', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.ShapeExampleApp());

    expect(find.byType(RawScrollbar), findsOne);
    expect(find.byType(ListView), findsOne);

    expect(find.text('0'), findsOne);
    expect(find.text('1'), findsOne);
    expect(find.text('4'), findsOne);

    await tester.pumpAndSettle();

    expect(
      find.byType(RawScrollbar),
      paints
        // Scrollbar thumb background fill.
        ..rrect(
          rrect: RRect.fromLTRBR(
            785.0,
            0.0,
            800.0,
            180.0,
            const Radius.circular(7.5),
          ),
          style: PaintingStyle.fill,
          color: Colors.blue,
        )
        // Scrollbar thumb border.
        ..rrect(
          rrect: RRect.fromLTRBR(
            786.5,
            1.5,
            798.5,
            178.5,
            const Radius.circular(6),
          ),
          style: PaintingStyle.stroke,
          strokeWidth: 3.0,
          color: Colors.brown,
        ),
    );
  });
}
