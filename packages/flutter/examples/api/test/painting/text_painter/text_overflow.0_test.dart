// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_api_samples/painting/text_painter/text_overflow.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The paragraph the sample truncates, picked out of the other paragraphs on
  // the screen (the app bar title and the button labels) by its content.
  String renderedText(WidgetTester tester) {
    return tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .firstWhere((RenderParagraph paragraph) {
          return paragraph.text.toPlainText().endsWith('summary.txt');
        })
        .debugRenderedText;
  }

  testWidgets('The ellipsis moves when the overflow mode changes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.ExampleApp());

    // ellipsisStart drops the front of the path and keeps the file name.
    expect(renderedText(tester), startsWith('…'));
    expect(renderedText(tester), endsWith('.txt'));

    await tester.tap(find.text('ellipsisMiddle'));
    await tester.pumpAndSettle();
    // ellipsisMiddle keeps the root of the path as well as the file name.
    expect(renderedText(tester), startsWith('/Users'));
    expect(renderedText(tester), endsWith('.txt'));
    expect(renderedText(tester), contains('…'));

    await tester.tap(find.text('ellipsis'));
    await tester.pumpAndSettle();
    // The engine adds the trailing ellipsis while painting, so the text that
    // is laid out is still the whole path.
    expect(renderedText(tester), startsWith('/Users'));
    expect(renderedText(tester), isNot(contains('…')));
  });

  testWidgets('Narrowing the box keeps less of the text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.ExampleApp());
    final int atFullWidth = renderedText(tester).length;

    await tester.drag(
      find.textContaining('Drag to resize'),
      const Offset(-100.0, 0.0),
    );
    await tester.pumpAndSettle();

    expect(renderedText(tester).length, lessThan(atFullWidth));
    expect(renderedText(tester), startsWith('…'));
    expect(renderedText(tester), endsWith('.txt'));
  });
}
