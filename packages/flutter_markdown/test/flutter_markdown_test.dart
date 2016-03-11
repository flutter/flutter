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

      List<Element> elements = _listElements(tester);
      _expectWidgetTypes(elements, <Type>[MarkdownBody, Column, Container, Padding, RichText]);
      _expectTextStrings(elements, <String>["Hello"]);
    });
  });

  test("Header", () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new MarkdownBody(data: "# Header"));

      List<Element> elements = _listElements(tester);
      _expectWidgetTypes(elements, <Type>[MarkdownBody, Column, Container, Padding, RichText]);
      _expectTextStrings(elements, <String>["Header"]);
    });
  });

  test("Empty string", () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new MarkdownBody(data: ""));

      List<Element> elements = _listElements(tester);
      _expectWidgetTypes(elements, <Type>[MarkdownBody, Column]);
    });
  });

  test("Ordered list", () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new MarkdownBody(data: "1. Item 1\n1. Item 2\n2. Item 3"));

      List<Element> elements = _listElements(tester);
      _expectTextStrings(elements, <String>[
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

      List<Element> elements = _listElements(tester);
      _expectTextStrings(elements, <String>[
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

      List<Element> elements = _listElements(tester);
      _expectWidgetTypes(elements, <Type>[
        Markdown,
        ScrollableViewport,
        null, null, null, null, null, // ScrollableViewport internals
        Padding,
        MarkdownBody,
        Column
      ]);
    });
  });

  test("Links", () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Markdown(data: "[Link Text](href)"));

      Element textElement = tester.findElement((Element element) => element.widget is RichText);
      RichText textWidget = textElement.widget;
      TextSpan span = textWidget.text;

      expect(span.children[0].recognizer.runtimeType, equals(TapGestureRecognizer));
    });
  });

  test("Changing config - data", () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Markdown(data: "Data1"));
      _expectTextStrings(_listElements(tester), <String>["Data1"]);

      String stateBefore = WidgetFlutterBinding.instance.renderViewElement.toStringDeep();
      tester.pumpWidget(new Markdown(data: "Data1"));
      String stateAfter = WidgetFlutterBinding.instance.renderViewElement.toStringDeep();
      expect(stateBefore, equals(stateAfter));

      tester.pumpWidget(new Markdown(data: "Data2"));
      _expectTextStrings(_listElements(tester), <String>["Data2"]);
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

List<Element> _listElements(WidgetTester tester) {
  List<Element> elements = <Element>[];
  tester.walkElements((Element element) {
    elements.add(element);
  });
  return elements;
}

void _expectWidgetTypes(List<Element> elements, List<Type> types) {
  expect(elements.length, equals(types.length));
  for (int i = 0; i < elements.length; i += 1) {
    Element element = elements[i];
    Type type = types[i];
    if (type == null) continue;
    expect(element.widget.runtimeType, equals(type));
  }
}

void _expectTextStrings(List<Element> elements, List<String> strings) {
  int currentString = 0;
  for (Element element in elements) {
    Widget widget = element.widget;
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
