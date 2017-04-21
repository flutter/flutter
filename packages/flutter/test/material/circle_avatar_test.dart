// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CircleAvatar with background color', (WidgetTester tester) async {
    final Color backgroundColor = Colors.blue.shade400;
    await tester.pumpWidget(
      new Center(
        child: new CircleAvatar(
          backgroundColor: backgroundColor,
          radius: 50.0,
          child: const Text('Z'),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(CircleAvatar));
    expect(box.size.width, equals(100.0));
    expect(box.size.height, equals(100.0));
    final RenderDecoratedBox child = box.child;
    final BoxDecoration decoration = child.decoration;
    expect(decoration.backgroundColor, equals(backgroundColor));

    final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    expect(paragraph.text.style.color, equals(Colors.white));
  });

  testWidgets('CircleAvatar with foreground color', (WidgetTester tester) async {
    final Color foregroundColor = Colors.red.shade100;
    await tester.pumpWidget(
      new Center(
        child: new CircleAvatar(
          foregroundColor: foregroundColor,
          child: const Text('Z'),
        ),
      ),
    );

    final ThemeData fallback = new ThemeData.fallback();

    final RenderConstrainedBox box = tester.renderObject(find.byType(CircleAvatar));
    expect(box.size.width, equals(40.0));
    expect(box.size.height, equals(40.0));
    final RenderDecoratedBox child = box.child;
    final BoxDecoration decoration = child.decoration;
    expect(decoration.backgroundColor, equals(fallback.primaryColor));

    final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    expect(paragraph.text.style.color, equals(foregroundColor));
  });

  testWidgets('CircleAvatar with theme', (WidgetTester tester) async {
    final ThemeData theme = new ThemeData(
      primaryColor: Colors.grey.shade100,
      primaryColorBrightness: Brightness.light,
    );
    await tester.pumpWidget(
      new Theme(
        data: theme,
        child: const Center(
          child: const CircleAvatar(
            child: const Text('Z'),
          ),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(CircleAvatar));
    final RenderDecoratedBox child = box.child;
    final BoxDecoration decoration = child.decoration;
    expect(decoration.backgroundColor, equals(theme.primaryColor));

    final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    expect(paragraph.text.style.color, equals(theme.primaryTextTheme.title.color));
  });
}
