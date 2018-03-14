// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Request focus shows keyboard', (WidgetTester tester) async {
    final FocusNode focusNode = new FocusNode();

    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Center(
            child: new TextField(
              focusNode: focusNode,
            ),
          ),
        ),
      ),
    );

    expect(tester.testTextInput.isVisible, isFalse);

    FocusScope.of(tester.element(find.byType(TextField))).requestFocus(focusNode);
    await tester.idle();

    expect(tester.testTextInput.isVisible, isTrue);

    await tester.pumpWidget(new Container());

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('Autofocus shows keyboard', (WidgetTester tester) async {
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.pumpWidget(
      new MaterialApp(
        home: const Material(
          child: const Center(
            child: const TextField(
              autofocus: true,
            ),
          ),
        ),
      ),
    );

    expect(tester.testTextInput.isVisible, isTrue);

    await tester.pumpWidget(new Container());

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('Tap shows keyboard', (WidgetTester tester) async {
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.pumpWidget(
      new MaterialApp(
        home: const Material(
          child: const Center(
            child: const TextField(),
          ),
        ),
      ),
    );

    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byType(TextField));
    await tester.idle();

    expect(tester.testTextInput.isVisible, isTrue);

    tester.testTextInput.hide();

    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byType(TextField));
    await tester.idle();

    expect(tester.testTextInput.isVisible, isTrue);

    await tester.pumpWidget(new Container());

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('Dialog interaction', (WidgetTester tester) async {
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.pumpWidget(
      new MaterialApp(
        home: const Material(
          child: const Center(
            child: const TextField(
              autofocus: true,
            ),
          ),
        ),
      ),
    );

    expect(tester.testTextInput.isVisible, isTrue);

    final BuildContext context = tester.element(find.byType(TextField));

    showDialog<Null>(
      context: context,
      builder: (BuildContext context) => const SimpleDialog(title: const Text('Dialog')),
    );

    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);

    Navigator.of(tester.element(find.text('Dialog'))).pop();
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byType(TextField));
    await tester.idle();

    expect(tester.testTextInput.isVisible, isTrue);

    await tester.pumpWidget(new Container());

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('Focus triggers keep-alive', (WidgetTester tester) async {
    final FocusNode focusNode = new FocusNode();

    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new ListView(
            children: <Widget>[
              new TextField(
                focusNode: focusNode,
              ),
              new Container(
                height: 1000.0,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);

    FocusScope.of(tester.element(find.byType(TextField))).requestFocus(focusNode);
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.drag(find.byType(ListView), const Offset(0.0, -1000.0));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);

    focusNode.unfocus();
    await tester.pump();

    expect(find.byType(TextField), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('Focus keep-alive works with GlobalKey reparenting', (WidgetTester tester) async {
    final FocusNode focusNode = new FocusNode();

    Widget makeTest(String prefix) {
      return new MaterialApp(
        home: new Material(
          child: new ListView(
            children: <Widget>[
              new TextField(
                focusNode: focusNode,
                decoration: new InputDecoration(
                  prefixText: prefix,
                ),
              ),
              new Container(
                height: 1000.0,
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(makeTest(null));
    FocusScope.of(tester.element(find.byType(TextField))).requestFocus(focusNode);
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0.0, -1000.0));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    await tester.pumpWidget(makeTest('test'));
    await tester.pump(); // in case the AutomaticKeepAlive widget thinks it needs a cleanup frame
    expect(find.byType(TextField), findsOneWidget);
  });
}
