import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';
import 'package:flutter/material.dart';

void main() {
  test("Simple string", () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new MarkdownBody(data: "Hello"));

      Iterable<Widget> widgets = tester.widgets;
      _expectWidgetTypes(widgets, <Type>[MarkdownBody, Column, Container, Padding, RichText]);
      _expectTextStrings(widgets, <String>["Hello"]);
    });
  });

  test("Header", () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new MarkdownBody(data: "# Header"));

      Iterable<Widget> widgets = tester.widgets;
      _expectWidgetTypes(widgets, <Type>[MarkdownBody, Column, Container, Padding, RichText]);
      _expectTextStrings(widgets, <String>["Header"]);
    });
  });

  test("Empty string", () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new MarkdownBody(data: ""));

      Iterable<Widget> widgets = tester.widgets;
      _expectWidgetTypes(widgets, <Type>[MarkdownBody, Column]);
    });
  });

  test("Ordered list", () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new MarkdownBody(data: "1. Item 1\n1. Item 2\n2. Item 3"));

      Iterable<Widget> widgets = tester.widgets;
      _expectTextStrings(widgets, <String>[
        "1.",
        "Item 1",
        "2.",
        "Item 2",
        "3.",
        "Item 3"]
      );
    });
  });

  test("Unordered list", () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new MarkdownBody(data: "- Item 1\n- Item 2\n- Item 3"));

      Iterable<Widget> widgets = tester.widgets;
      _expectTextStrings(widgets, <String>[
        "•",
        "Item 1",
        "•",
        "Item 2",
        "•",
        "Item 3"]
      );
    });
  });

  test("Scrollable wrapping", () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Markdown(data: ""));

      List<Widget> widgets = tester.widgets.toList();
      _expectWidgetTypes(widgets.take(2), <Type>[
        Markdown,
        ScrollableViewport,
      ]);
      _expectWidgetTypes(widgets.reversed.take(3).toList().reversed, <Type>[
        Padding,
        MarkdownBody,
        Column
      ]);
    });
  });

  test("Links", () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Markdown(data: "[Link Text](href)"));

      RichText textWidget = tester.widgets.firstWhere((Widget widget) => widget is RichText);
      TextSpan span = textWidget.text;

      expect(span.children[0].recognizer.runtimeType, equals(TapGestureRecognizer));
    });
  });

  test("Changing config - data", () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Markdown(data: "Data1"));
      _expectTextStrings(tester.widgets, <String>["Data1"]);

      String stateBefore = WidgetFlutterBinding.instance.renderViewElement.toStringDeep();
      tester.pumpWidget(new Markdown(data: "Data1"));
      String stateAfter = WidgetFlutterBinding.instance.renderViewElement.toStringDeep();
      expect(stateBefore, equals(stateAfter));

      tester.pumpWidget(new Markdown(data: "Data2"));
      _expectTextStrings(tester.widgets, <String>["Data2"]);
    });
  });

  test("Changing config - style", () {
    testWidgets((WidgetTester tester) {
      ThemeData theme = new ThemeData.light();

      MarkdownStyle style1 = new MarkdownStyle.defaultFromTheme(theme);
      MarkdownStyle style2 = new MarkdownStyle.largeFromTheme(theme);

      tester.pumpWidget(new Markdown(data: "Test", markdownStyle: style1));

      String stateBefore = WidgetFlutterBinding.instance.renderViewElement.toStringDeep();
      tester.pumpWidget(new Markdown(data: "Test", markdownStyle: style2));
      String stateAfter = WidgetFlutterBinding.instance.renderViewElement.toStringDeep();
      expect(stateBefore, isNot(stateAfter));
    });
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
  String text = span.text ?? "";
  if (span.children != null) {
    for (TextSpan child in span.children) {
      text += _extractTextFromTextSpan(child);
    }
  }
  return text;
}
