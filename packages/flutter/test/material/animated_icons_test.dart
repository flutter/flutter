// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math show pi;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../widgets/semantics_tester.dart';

class MockCanvas extends Mock implements Canvas {}

void main() {
  testWidgets('IconTheme color', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: IconTheme(
          data: IconThemeData(
            color: Color(0xFF666666),
          ),
          child: AnimatedIcon(
            progress: AlwaysStoppedAnimation<double>(0.0),
            icon: AnimatedIcons.arrow_menu,
          )
        ),
      ),
    );
    final CustomPaint customPaint = tester.widget(find.byType(CustomPaint));
    final MockCanvas canvas = MockCanvas();
    customPaint.painter.paint(canvas, const Size(48.0, 48.0));
    verify(canvas.drawPath(any, argThat(hasColor(0xFF666666))));
  });

  testWidgets('IconTheme opacity', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: IconTheme(
          data: IconThemeData(
            color: Color(0xFF666666),
            opacity: 0.5,
          ),
          child: AnimatedIcon(
            progress: AlwaysStoppedAnimation<double>(0.0),
            icon: AnimatedIcons.arrow_menu,
          )
        ),
      ),
    );
    final CustomPaint customPaint = tester.widget(find.byType(CustomPaint));
    final MockCanvas canvas = MockCanvas();
    customPaint.painter.paint(canvas, const Size(48.0, 48.0));
    verify(canvas.drawPath(any, argThat(hasColor(0x80666666))));
  });

  testWidgets('color overrides IconTheme color', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: IconTheme(
          data: IconThemeData(
            color: Color(0xFF666666),
          ),
          child: AnimatedIcon(
            progress: AlwaysStoppedAnimation<double>(0.0),
            icon: AnimatedIcons.arrow_menu,
            color: Color(0xFF0000FF),
          )
        ),
      ),
    );
    final CustomPaint customPaint = tester.widget(find.byType(CustomPaint));
    final MockCanvas canvas = MockCanvas();
    customPaint.painter.paint(canvas, const Size(48.0, 48.0));
    verify(canvas.drawPath(any, argThat(hasColor(0xFF0000FF))));
  });

  testWidgets('IconTheme size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: IconTheme(
          data: IconThemeData(
            color: Color(0xFF666666),
            size: 12.0,
          ),
          child: AnimatedIcon(
            progress: AlwaysStoppedAnimation<double>(0.0),
            icon: AnimatedIcons.arrow_menu,
          )
        ),
      ),
    );
    final CustomPaint customPaint = tester.widget(find.byType(CustomPaint));
    final MockCanvas canvas = MockCanvas();
    customPaint.painter.paint(canvas, const Size(12.0, 12.0));
    // arrow_menu default size is 48x48 so we expect it to be scaled by 0.25.
    verify(canvas.scale(0.25, 0.25));
  });

  testWidgets('size overridesIconTheme size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: IconTheme(
          data: IconThemeData(
            color: Color(0xFF666666),
            size: 12.0,
          ),
          child: AnimatedIcon(
            progress: AlwaysStoppedAnimation<double>(0.0),
            icon: AnimatedIcons.arrow_menu,
            size: 96.0,
          )
        ),
      ),
    );
    final CustomPaint customPaint = tester.widget(find.byType(CustomPaint));
    final MockCanvas canvas = MockCanvas();
    customPaint.painter.paint(canvas, const Size(12.0, 12.0));
    // arrow_menu default size is 48x48 so we expect it to be scaled by 2.
    verify(canvas.scale(2.0, 2.0));
  });

  testWidgets('Semantic label', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedIcon(
          progress: AlwaysStoppedAnimation<double>(0.0),
          icon: AnimatedIcons.arrow_menu,
          size: 96.0,
          semanticLabel: 'a label',
        ),
      ),
    );

    expect(semantics, includesNodeWith(label: 'a label'));

    semantics.dispose();
  });

  testWidgets('Inherited text direction rtl', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: IconTheme(
          data: IconThemeData(
            color: Color(0xFF666666),
          ),
          child: AnimatedIcon(
            progress: AlwaysStoppedAnimation<double>(0.0),
            icon: AnimatedIcons.arrow_menu,
          )
        ),
      ),
    );
    final CustomPaint customPaint = tester.widget(find.byType(CustomPaint));
    final MockCanvas canvas = MockCanvas();
    customPaint.painter.paint(canvas, const Size(48.0, 48.0));
    verifyInOrder(<void>[
      canvas.rotate(math.pi),
      canvas.translate(-48.0, -48.0)
    ]);
  });

  testWidgets('Inherited text direction ltr', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: IconTheme(
          data: IconThemeData(
            color: Color(0xFF666666),
          ),
          child: AnimatedIcon(
            progress: AlwaysStoppedAnimation<double>(0.0),
            icon: AnimatedIcons.arrow_menu,
          )
        ),
      ),
    );
    final CustomPaint customPaint = tester.widget(find.byType(CustomPaint));
    final MockCanvas canvas = MockCanvas();
    customPaint.painter.paint(canvas, const Size(48.0, 48.0));
    verifyNever(canvas.rotate(any));
    verifyNever(canvas.translate(any, any));
  });

  testWidgets('Inherited text direction overridden', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: IconTheme(
          data: IconThemeData(
            color: Color(0xFF666666),
          ),
          child: AnimatedIcon(
            progress: AlwaysStoppedAnimation<double>(0.0),
            icon: AnimatedIcons.arrow_menu,
            textDirection: TextDirection.rtl,
          )
        ),
      ),
    );
    final CustomPaint customPaint = tester.widget(find.byType(CustomPaint));
    final MockCanvas canvas = MockCanvas();
    customPaint.painter.paint(canvas, const Size(48.0, 48.0));
    verifyInOrder(<void>[
      canvas.rotate(math.pi),
      canvas.translate(-48.0, -48.0)
    ]);
  });
}

PaintColorMatcher hasColor(int color) {
  return PaintColorMatcher(color);
}

class PaintColorMatcher extends Matcher {
  const PaintColorMatcher(this.expectedColor);

  final int expectedColor;

  @override
  Description describe(Description description) =>
    description.add('color was not $expectedColor');

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    final Paint actualPaint = item;
    return actualPaint.color == Color(expectedColor);
  }
}
