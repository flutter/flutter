// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockOnPressedFunction implements Function {
  int called = 0;

  void call() {
    called++;
  }
}

void main() {
  MockOnPressedFunction mockOnPressedFunction;

  setUp(() {
    mockOnPressedFunction = new MockOnPressedFunction();
  });

  testWidgets('test default icon buttons are sized up to 48', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new IconButton(
            onPressed: mockOnPressedFunction,
            icon: const Icon(Icons.link),
          ),
        ),
      ),
    );

    final RenderBox iconButton = tester.renderObject(find.byType(IconButton));
    expect(iconButton.size, const Size(48.0, 48.0));

    await tester.tap(find.byType(IconButton));
    expect(mockOnPressedFunction.called, 1);
  });

  testWidgets('test small icons are sized up to 48dp', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new IconButton(
            iconSize: 10.0,
            onPressed: mockOnPressedFunction,
            icon: const Icon(Icons.link),
          ),
        ),
      ),
    );

    final RenderBox iconButton = tester.renderObject(find.byType(IconButton));
    expect(iconButton.size, const Size(48.0, 48.0));
  });

  testWidgets('test icons can be small when total size is >48dp', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new IconButton(
            iconSize: 10.0,
            padding: const EdgeInsets.all(30.0),
            onPressed: mockOnPressedFunction,
            icon: const Icon(Icons.link),
          ),
        ),
      ),
    );

    final RenderBox iconButton = tester.renderObject(find.byType(IconButton));
    expect(iconButton.size, const Size(70.0, 70.0));
  });

  testWidgets('test default icon buttons are constrained', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new IconButton(
            padding: EdgeInsets.zero,
            onPressed: mockOnPressedFunction,
            icon: const Icon(Icons.ac_unit),
            iconSize: 80.0,
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(IconButton));
    expect(box.size, const Size(80.0, 80.0));
  });

  testWidgets(
    'test default icon buttons can be stretched if specified',
    (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget> [
            new IconButton(
              onPressed: mockOnPressedFunction,
              icon: const Icon(Icons.ac_unit),
            ),
          ],
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(IconButton));
    expect(box.size, const Size(48.0, 600.0));
  });

  testWidgets('test default padding', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new IconButton(
            onPressed: mockOnPressedFunction,
            icon: const Icon(Icons.ac_unit),
            iconSize: 80.0,
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(IconButton));
    expect(box.size, const Size(96.0, 96.0));
  });

  testWidgets('test tooltip', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Center(
            child: new IconButton(
              onPressed: mockOnPressedFunction,
              icon: const Icon(Icons.ac_unit),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsNothing);

    // Clear the widget tree.
    await tester.pumpWidget(new Container(key: new UniqueKey()));

    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Center(
            child: new IconButton(
              onPressed: mockOnPressedFunction,
              icon: const Icon(Icons.ac_unit),
              tooltip: 'Test tooltip',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsOneWidget);
    expect(find.byTooltip('Test tooltip'), findsOneWidget);

    await tester.tap(find.byTooltip('Test tooltip'));
    expect(mockOnPressedFunction.called, 1);
  });

  testWidgets('IconButton AppBar size', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Scaffold(
        appBar: new AppBar(
          actions: <Widget>[
            new IconButton(
              padding: EdgeInsets.zero,
              onPressed: mockOnPressedFunction,
              icon: const Icon(Icons.ac_unit),
            ),
          ],
        ),
      ),
    );

    final RenderBox barBox = tester.renderObject(find.byType(AppBar));
    final RenderBox iconBox = tester.renderObject(find.byType(IconButton));
    expect(iconBox.size.height, equals(barBox.size.height));
  });
}
