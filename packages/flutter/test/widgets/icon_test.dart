// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Can set opacity for an Icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const IconTheme(
        data: const IconThemeData(
          color: const Color(0xFF666666),
          opacity: 0.5
        ),
        child: const Icon(const IconData(0xd0a0, fontFamily: 'Arial'))
      )
    );
    final RichText text = tester.widget(find.byType(RichText));
    expect(text.text.style.color, const Color(0xFF666666).withOpacity(0.5));
  });

  testWidgets('Icon sizing - no theme, default size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const Icon(null),
      ),
    );

    final RenderBox renderObject = tester.renderObject(find.byType(Icon));
    expect(renderObject.size, equals(const Size.square(24.0)));
  });

  testWidgets('Icon sizing - no theme, explicit size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const Icon(
          null,
          size: 96.0,
        ),
      ),
    );

    final RenderBox renderObject = tester.renderObject(find.byType(Icon));
    expect(renderObject.size, equals(const Size.square(96.0)));
  });

  testWidgets('Icon sizing - sized theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const IconTheme(
          data: const IconThemeData(size: 36.0),
          child: const Icon(null),
        ),
      ),
    );

    final RenderBox renderObject = tester.renderObject(find.byType(Icon));
    expect(renderObject.size, equals(const Size.square(36.0)));
  });

  testWidgets('Icon sizing - sized theme, explicit size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const IconTheme(
          data: const IconThemeData(size: 36.0),
          child: const Icon(
            null,
            size: 48.0,
          ),
        ),
      )
    );

    final RenderBox renderObject = tester.renderObject(find.byType(Icon));
    expect(renderObject.size, equals(const Size.square(48.0)));
  });

  testWidgets('Icon sizing - sizeless theme, default size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const IconTheme(
          data: const IconThemeData(),
          child: const Icon(null),
        ),
      ),
    );

    final RenderBox renderObject = tester.renderObject(find.byType(Icon));
    expect(renderObject.size, equals(const Size.square(24.0)));
  });


  testWidgets('Icon with custom font', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const Icon(const IconData(0x41, fontFamily: 'Roboto')),
      ),
    );

    final RichText richText = tester.firstWidget(find.byType(RichText));
    expect(richText.text.style.fontFamily, equals('Roboto'));
  });
}
