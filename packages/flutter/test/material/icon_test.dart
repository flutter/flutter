// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      new Center(
        child: new IconTheme(
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
      new Center(
        child: new IconTheme(
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
      new Center(
        child: new IconTheme(
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
