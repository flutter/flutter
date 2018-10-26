// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

class MockOnPressedFunction implements Function {
  int called = 0;

  void call() {
    called++;
  }
}

void main() {
  MockOnPressedFunction mockOnPressedFunction;

  setUp(() {
    mockOnPressedFunction = MockOnPressedFunction();
  });

  testWidgets('test default icon buttons are sized up to 48', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
          child: IconButton(
            onPressed: mockOnPressedFunction,
            icon: const Icon(Icons.link),
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
      wrap(
          child: IconButton(
            iconSize: 10.0,
            onPressed: mockOnPressedFunction,
            icon: const Icon(Icons.link),
          ),
      ),
    );

    final RenderBox iconButton = tester.renderObject(find.byType(IconButton));
    expect(iconButton.size, const Size(48.0, 48.0));
  });

  testWidgets('test icons can be small when total size is >48dp', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
          child: IconButton(
            iconSize: 10.0,
            padding: const EdgeInsets.all(30.0),
            onPressed: mockOnPressedFunction,
            icon: const Icon(Icons.link),
          ),
      ),
    );

    final RenderBox iconButton = tester.renderObject(find.byType(IconButton));
    expect(iconButton.size, const Size(70.0, 70.0));
  });

  testWidgets('test default icon buttons are constrained', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: mockOnPressedFunction,
            icon: const Icon(Icons.ac_unit),
            iconSize: 80.0,
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
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget> [
              IconButton(
                onPressed: mockOnPressedFunction,
                icon: const Icon(Icons.ac_unit),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(IconButton));
    expect(box.size, const Size(48.0, 600.0));
  });

  testWidgets('test default padding', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
          child: IconButton(
            onPressed: mockOnPressedFunction,
            icon: const Icon(Icons.ac_unit),
            iconSize: 80.0,
          ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(IconButton));
    expect(box.size, const Size(96.0, 96.0));
  });

  testWidgets('test tooltip', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: IconButton(
              onPressed: mockOnPressedFunction,
              icon: const Icon(Icons.ac_unit),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsNothing);

    // Clear the widget tree.
    await tester.pumpWidget(Container(key: UniqueKey()));

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: IconButton(
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
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: mockOnPressedFunction,
                icon: const Icon(Icons.ac_unit),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox barBox = tester.renderObject(find.byType(AppBar));
    final RenderBox iconBox = tester.renderObject(find.byType(IconButton));
    expect(iconBox.size.height, equals(barBox.size.height));
  });

  // This test is very similar to the '...explicit splashColor and highlightColor' test
  // in buttons_test.dart. If you change this one, you may want to also change that one.
  testWidgets('IconButton with explicit splashColor and highlightColor', (WidgetTester tester) async {
    const Color directSplashColor = Color(0xFF00000F);
    const Color directHighlightColor = Color(0xFF0000F0);

    Widget buttonWidget = wrap(
        child: IconButton(
          icon: const Icon(Icons.android),
          splashColor: directSplashColor,
          highlightColor: directHighlightColor,
          onPressed: () { /* enable the button */ },
        ),
    );

    await tester.pumpWidget(
      Theme(
        data: ThemeData(),
        child: buttonWidget,
      ),
    );

    final Offset center = tester.getCenter(find.byType(IconButton));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start gesture
    await tester.pump(const Duration(milliseconds: 200)); // wait for splash to be well under way

    expect(
      Material.of(tester.element(find.byType(IconButton))),
      paints
        ..circle(color: directSplashColor)
        ..circle(color: directHighlightColor)
    );

    const Color themeSplashColor1 = Color(0xFF000F00);
    const Color themeHighlightColor1 = Color(0xFF00FF00);

    buttonWidget = wrap(
        child: IconButton(
          icon: const Icon(Icons.android),
          onPressed: () { /* enable the button */ },
        ),
    );

    await tester.pumpWidget(
      Theme(
        data: ThemeData(
          highlightColor: themeHighlightColor1,
          splashColor: themeSplashColor1,
        ),
        child: buttonWidget,
      ),
    );

    expect(
      Material.of(tester.element(find.byType(IconButton))),
      paints
        ..circle(color: themeSplashColor1)
        ..circle(color: themeHighlightColor1)
    );

    const Color themeSplashColor2 = Color(0xFF002200);
    const Color themeHighlightColor2 = Color(0xFF001100);

    await tester.pumpWidget(
      Theme(
        data: ThemeData(
          highlightColor: themeHighlightColor2,
          splashColor: themeSplashColor2,
        ),
        child: buttonWidget, // same widget, so does not get updated because of us
      ),
    );

    expect(
      Material.of(tester.element(find.byType(IconButton))),
      paints
        ..circle(color: themeSplashColor2)
        ..circle(color: themeHighlightColor2)
    );

    await gesture.up();
  });

  testWidgets('IconButton Semantics (enabled)', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      wrap(
        child: IconButton(
          onPressed: mockOnPressedFunction,
          icon: const Icon(Icons.link, semanticLabel: 'link'),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          rect: Rect.fromLTRB(0.0, 0.0, 48.0, 48.0),
          actions: <SemanticsAction>[
            SemanticsAction.tap
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isEnabled,
            SemanticsFlag.isButton
          ],
          label: 'link',
        )
      ]
    ), ignoreId: true, ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('IconButton Semantics (disabled)', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      wrap(
        child: const IconButton(
          onPressed: null,
          icon: Icon(Icons.link, semanticLabel: 'link'),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics.rootChild(
            rect: Rect.fromLTRB(0.0, 0.0, 48.0, 48.0),
            flags: <SemanticsFlag>[
              SemanticsFlag.hasEnabledState,
              SemanticsFlag.isButton
            ],
            label: 'link',
          )
        ]
    ), ignoreId: true, ignoreTransform: true));

    semantics.dispose();
  });
}

Widget wrap({ Widget child }) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Material(
      child: Center(child: child),
    ),
  );
}
