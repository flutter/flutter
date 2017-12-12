// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material_animated_icons.dart';
import 'package:mockito/mockito.dart';

class MockCanvas extends Mock implements Canvas {}

void main() {
  testWidgets('IconTheme color', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: const IconTheme(
          data: const IconThemeData(
            color: const Color(0xFF666666),
          ),
          child: const AnimatedIcon(
            progress: const AlwaysStoppedAnimation<double>(0.0),
            icon: AnimatedIcons.arrow_menu,
          )
        ),
      ),
    );
    final CustomPaint customPaint = tester.widget(find.byType(CustomPaint));
    final MockCanvas canvas = new MockCanvas();
    customPaint.painter.paint(canvas, const Size(48.0, 48.0));
    verify(canvas.drawPath(any, paintColorMatcher(0xFF666666)));
  });

  testWidgets('color overrides IconTheme color', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: const IconTheme(
          data: const IconThemeData(
            color: const Color(0xFF666666),
          ),
          child: const AnimatedIcon(
            progress: const AlwaysStoppedAnimation<double>(0.0),
            icon: AnimatedIcons.arrow_menu,
            color: const Color(0xFF0000FF),
          )
        ),
      ),
    );
    final CustomPaint customPaint = tester.widget(find.byType(CustomPaint));
    final MockCanvas canvas = new MockCanvas();
    customPaint.painter.paint(canvas, const Size(48.0, 48.0));
    verify(canvas.drawPath(any, paintColorMatcher(0xFF0000FF)));
  });
}

dynamic paintColorMatcher(int color) {
  return new PaintpaintColorMatcher(color);
}

class PaintpaintColorMatcher extends Matcher {
  const PaintpaintColorMatcher(this.expectedColor);

  final int expectedColor;

  @override
  Description describe(Description description) =>
    description.add('color was not $expectedColor');

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    final Paint actualPaint = item;
    return actualPaint.color == new Color(expectedColor);
  }
}
