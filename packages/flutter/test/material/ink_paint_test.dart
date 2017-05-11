// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Does the ink widget render a border radius', (WidgetTester tester) async {
    final Color highlightColor = const Color(0xAAFF0000);
    final Color splashColor = const Color(0xAA0000FF);
    final BorderRadius borderRadius = new BorderRadius.circular(6.0);

    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new Container(
            width: 200.0,
            height: 60.0,
            child: new InkWell(
              borderRadius: borderRadius,
              highlightColor: highlightColor,
              splashColor: splashColor,
              onTap: () { },
            ),
          ),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.byType(InkWell));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start gesture
    await tester.pump(const Duration(milliseconds: 200)); // wait for splash to be well under way

    final RenderBox box = Material.of(tester.element(find.byType(InkWell))) as dynamic;
    expect(
      box,
      paints
        ..clipRRect(rrect: new RRect.fromLTRBR(300.0, 270.0, 500.0, 330.0, const Radius.circular(6.0)))
        ..circle(x: 400.0, y: 300.0, radius: 21.0, color: splashColor)
        ..rrect(
          rrect: new RRect.fromLTRBR(300.0, 270.0, 500.0, 330.0, const Radius.circular(6.0)),
          color: highlightColor,
        )
    );

    await gesture.up();
  });
}
