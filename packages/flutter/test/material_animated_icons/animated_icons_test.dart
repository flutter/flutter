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

  testWidgets('IconTheme size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: const IconTheme(
          data: const IconThemeData(
            color: const Color(0xFF666666),
            size: 12.0,
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
    customPaint.painter.paint(canvas, const Size(12.0, 12.0));
    // arrow_menu default size is 48x48 so we expect it to be scaled by 0.25.
    verify(canvas.scale(0.25, 0.25));
  });

  testWidgets('size overridesIconTheme size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: const IconTheme(
          data: const IconThemeData(
            color: const Color(0xFF666666),
            size: 12.0,
          ),
          child: const AnimatedIcon(
            progress: const AlwaysStoppedAnimation<double>(0.0),
            icon: AnimatedIcons.arrow_menu,
            size: 96.0,
          )
        ),
      ),
    );
    final CustomPaint customPaint = tester.widget(find.byType(CustomPaint));
    final MockCanvas canvas = new MockCanvas();
    customPaint.painter.paint(canvas, const Size(12.0, 12.0));
    // arrow_menu default size is 48x48 so we expect it to be scaled by 2.
    verify(canvas.scale(2.0, 2.0));
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
