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

      Iterable<Widget> widgets = tester.allWidgets;
      _expectWidgetTypes(widgets, <Type>[MarkdownBody, Column, Container, Padding, RichText]);
      _expectTextStrings(widgets, <String>['Hello']);
  });

  testWidgets('Header', (WidgetTester tester) async {
      await tester.pumpWidget(new MarkdownBody(data: '# Header'));

      Iterable<Widget> widgets = tester.allWidgets;
      _expectWidgetTypes(widgets, <Type>[MarkdownBody, Column, Container, Padding, RichText]);
      _expectTextStrings(widgets, <String>['Header']);
  });

  testWidgets('Empty string', (WidgetTester tester) async {
      await tester.pumpWidget(new MarkdownBody(data: ''));

      Iterable<Widget> widgets = tester.allWidgets;
      _expectWidgetTypes(widgets, <Type>[MarkdownBody, Column]);
  });

  testWidgets('Ordered list', (WidgetTester tester) async {
      await tester.pumpWidget(new MarkdownBody(data: '1. Item 1\n1. Item 2\n2. Item 3'));

      Iterable<Widget> widgets = tester.allWidgets;
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

      Iterable<Widget> widgets = tester.allWidgets;
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

      List<Widget> widgets = tester.allWidgets.toList();
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

      RichText textWidget = tester.allWidgets.firstWhere((Widget widget) => widget is RichText);
      TextSpan span = textWidget.text;

      expect(span.children[0].recognizer.runtimeType, equals(TapGestureRecognizer));
  });

  testWidgets('Changing config - data', (WidgetTester tester) async {
      await tester.pumpWidget(new Markdown(data: 'Data1'));
      _expectTextStrings(tester.allWidgets, <String>['Data1']);

      String stateBefore = WidgetsBinding.instance.renderViewElement.toStringDeep();
      await tester.pumpWidget(new Markdown(data: 'Data1'));
      String stateAfter = WidgetsBinding.instance.renderViewElement.toStringDeep();
      expect(stateBefore, equals(stateAfter));

      await tester.pumpWidget(new Markdown(data: 'Data2'));
      _expectTextStrings(tester.allWidgets, <String>['Data2']);
  });

  testWidgets('Changing config - style', (WidgetTester tester) async {
      ThemeData theme = new ThemeData.light();

      MarkdownStyle style1 = new MarkdownStyle.defaultFromTheme(theme);
      MarkdownStyle style2 = new MarkdownStyle.largeFromTheme(theme);

      await tester.pumpWidget(new Markdown(data: 'Test', markdownStyle: style1));

      String stateBefore = WidgetsBinding.instance.renderViewElement.toStringDeep();
      await tester.pumpWidget(new Markdown(data: 'Test', markdownStyle: style2));
      String stateAfter = WidgetsBinding.instance.renderViewElement.toStringDeep();
      expect(stateBefore, isNot(stateAfter));
  });
}

void _expectWidgetTypes(Iterable<Widget> widgets, List<Type> expected) {
  List<Type> actual = widgets.map((Widget w) => w.runtimeType).toList();
  expect(actual, expected);
}

void _expectTextStrings(Iterable<Widget> widgets, List<String> strings) {
  int currentString = 0;
  for (Widget widget in widgets) {
    if (widget is RichText) {
      TextSpan span = widget.text;
      String text = _extractTextFromTextSpan(span);
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
