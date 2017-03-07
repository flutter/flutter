// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Simple string', (WidgetTester tester) async {
      await tester.pumpWidget(new MarkdownBody(data: 'Hello'));

      final Iterable<Widget> widgets = tester.allWidgets;
      _expectWidgetTypes(widgets, <Type>[MarkdownBody, Column, Container, Padding, RichText]);
      _expectTextStrings(widgets, <String>['Hello']);
  });

  testWidgets('Header', (WidgetTester tester) async {
      await tester.pumpWidget(new MarkdownBody(data: '# Header'));

      final Iterable<Widget> widgets = tester.allWidgets;
      _expectWidgetTypes(widgets, <Type>[MarkdownBody, Column, Container, Padding, RichText]);
      _expectTextStrings(widgets, <String>['Header']);
  });

  testWidgets('Empty string', (WidgetTester tester) async {
      await tester.pumpWidget(new MarkdownBody(data: ''));

      final Iterable<Widget> widgets = tester.allWidgets;
      _expectWidgetTypes(widgets, <Type>[MarkdownBody, Column]);
  });

  testWidgets('Ordered list', (WidgetTester tester) async {
      await tester.pumpWidget(new MarkdownBody(data: '1. Item 1\n1. Item 2\n2. Item 3'));

      final Iterable<Widget> widgets = tester.allWidgets;
      _expectTextStrings(widgets, <String>[
        '1.',
        'Item 1',
        '2.',
        'Item 2',
        '3.',
        'Item 3']
      );
  });

  testWidgets('Unordered list', (WidgetTester tester) async {
      await tester.pumpWidget(new MarkdownBody(data: '- Item 1\n- Item 2\n- Item 3'));

      final Iterable<Widget> widgets = tester.allWidgets;
      _expectTextStrings(widgets, <String>[
        '•',
        'Item 1',
        '•',
        'Item 2',
        '•',
        'Item 3']
      );
  });

  testWidgets('Scrollable wrapping', (WidgetTester tester) async {
      await tester.pumpWidget(new Markdown(data: ''));

      final List<Widget> widgets = tester.allWidgets.toList();
      _expectWidgetTypes(widgets.take(2), <Type>[
        Markdown,
        SingleChildScrollView,
      ]);
      _expectWidgetTypes(widgets.reversed.take(3).toList().reversed, <Type>[
        Padding,
        MarkdownBody,
        Column
      ]);
  });

  testWidgets('Links', (WidgetTester tester) async {
      await tester.pumpWidget(new Markdown(data: '[Link Text](href)'));

      final RichText textWidget = tester.allWidgets.firstWhere((Widget widget) => widget is RichText);
      final TextSpan span = textWidget.text;

      expect(span.children[0].recognizer.runtimeType, equals(TapGestureRecognizer));
  });

  testWidgets('HTML tag ignored ', (WidgetTester tester) async {
    final List<String> mdData = <String>[
      'Line 1\n<p>HTML content</p>\nLine 2',
      'Line 1\n<!-- HTML\n comment\n ignored --><\nLine 2'
    ];

    for (String mdLine in mdData) {
      await tester.pumpWidget(new MarkdownBody(data: mdLine));

          final Iterable<Widget> widgets = tester.allWidgets;
          _expectTextStrings(widgets, <String>['Line 1', 'Line 2']);
    }
  });

  testWidgets('Less than', (WidgetTester tester) async {
      final String mdLine = 'Line 1 <\n\nc < c c\n\n< Line 2';
      await tester.pumpWidget(new MarkdownBody(data: mdLine));

      final Iterable<Widget> widgets = tester.allWidgets;
      _expectTextStrings(widgets, <String>['Line 1 &lt;','c &lt; c c','&lt; Line 2']);
  });

  testWidgets('Changing config - data', (WidgetTester tester) async {
      await tester.pumpWidget(new Markdown(data: 'Data1'));
      _expectTextStrings(tester.allWidgets, <String>['Data1']);

      final String stateBefore = WidgetsBinding.instance.renderViewElement.toStringDeep();
      await tester.pumpWidget(new Markdown(data: 'Data1'));
      final String stateAfter = WidgetsBinding.instance.renderViewElement.toStringDeep();
      expect(stateBefore, equals(stateAfter));

      await tester.pumpWidget(new Markdown(data: 'Data2'));
      _expectTextStrings(tester.allWidgets, <String>['Data2']);
  });

  testWidgets('Changing config - style', (WidgetTester tester) async {
      final ThemeData theme = new ThemeData.light();

      final MarkdownStyle style1 = new MarkdownStyle.defaultFromTheme(theme);
      final MarkdownStyle style2 = new MarkdownStyle.largeFromTheme(theme);

      await tester.pumpWidget(new Markdown(data: 'Test', markdownStyle: style1));

      final String stateBefore = WidgetsBinding.instance.renderViewElement.toStringDeep();
      await tester.pumpWidget(new Markdown(data: 'Test', markdownStyle: style2));
      final String stateAfter = WidgetsBinding.instance.renderViewElement.toStringDeep();
      expect(stateBefore, isNot(stateAfter));
  });
}

void _expectWidgetTypes(Iterable<Widget> widgets, List<Type> expected) {
  final List<Type> actual = widgets.map((Widget w) => w.runtimeType).toList();
  expect(actual, expected);
}

void _expectTextStrings(Iterable<Widget> widgets, List<String> strings) {
  int currentString = 0;
  for (Widget widget in widgets) {
    if (widget is RichText) {
      final TextSpan span = widget.text;
      final String text = _extractTextFromTextSpan(span);
      expect(text, equals(strings[currentString]));
      currentString += 1;
    }
  }
}

String _extractTextFromTextSpan(TextSpan span) {
  String text = span.text ?? '';
  if (span.children != null) {
    for (TextSpan child in span.children) {
      text += _extractTextFromTextSpan(child);
    }
  }
  return text;
}
