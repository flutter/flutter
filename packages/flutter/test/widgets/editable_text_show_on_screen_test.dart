// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';


void main() {
  const TextStyle textStyle = const TextStyle();
  const Color cursorColor = const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00);

  testWidgets('tapping on a partly visible editable brings it fully on screen', (WidgetTester tester) async {
    final ScrollController scrollController = new ScrollController();
    final TextEditingController controller = new TextEditingController();
    final FocusNode focusNode = new FocusNode();

    await tester.pumpWidget(new MaterialApp(
      home: new Center(
        child: new Container(
          height: 300.0,
          child: new ListView(
            controller: scrollController,
            children: <Widget>[
              new EditableText(
                controller: controller,
                focusNode: focusNode,
                style: textStyle,
                cursorColor: cursorColor,
              ),
              new Container(
                height: 350.0,
              ),
            ],
          ),
        ),
      ),
    ));

    // Scroll the EditableText half off screen.
    final RenderBox render = tester.renderObject(find.byType(EditableText));
    scrollController.jumpTo(render.size.height / 2);
    await tester.pumpAndSettle();
    expect(scrollController.offset, render.size.height / 2);

    await tester.showKeyboard(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
  });

  testWidgets('editable comes back on screen when entering text while it is off-screen', (WidgetTester tester) async {
    final ScrollController scrollController = new ScrollController(initialScrollOffset: 100.0);
    final TextEditingController controller = new TextEditingController();
    final FocusNode focusNode = new FocusNode();

    await tester.pumpWidget(new MaterialApp(
      home: new Center(
        child: new Container(
          height: 300.0,
          child: new ListView(
            controller: scrollController,
            children: <Widget>[
              new Container(
                height: 350.0,
              ),
              new EditableText(
                controller: controller,
                focusNode: focusNode,
                style: textStyle,
                cursorColor: cursorColor,
              ),
              new Container(
                height: 350.0,
              ),
            ],
          ),
        ),
      ),
    ));

    // Focus the EditableText and scroll it off screen.
    await tester.showKeyboard(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isTrue);
    scrollController.jumpTo(0.0);
    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
    expect(find.byType(EditableText), findsNothing);

    // Entering text brings it back on screen.
    tester.testTextInput.enterText('Hello');
    await tester.pumpAndSettle();
    expect(scrollController.offset, greaterThan(0.0));
    expect(find.byType(EditableText), findsOneWidget);
  });

  testWidgets('focused multi-line editable scrolls caret back into view when typing', (WidgetTester tester) async {
    final ScrollController scrollController = new ScrollController();
    final TextEditingController controller = new TextEditingController();
    final FocusNode focusNode = new FocusNode();
    controller.text = 'Start\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nEnd';

    await tester.pumpWidget(new MaterialApp(
      home: new Center(
        child: new Container(
          height: 300.0,
          child: new ListView(
            controller: scrollController,
            children: <Widget>[
              new EditableText(
                maxLines: null, // multi-line
                controller: controller,
                focusNode: focusNode,
                style: textStyle,
                cursorColor: cursorColor,
              ),
            ],
          ),
        ),
      ),
    ));

    // Bring keyboard up and verify that end of EditableText is not on screen.
    await tester.showKeyboard(find.byType(EditableText));
    await tester.pumpAndSettle();
    scrollController.jumpTo(0.0);
    await tester.pumpAndSettle();
    final RenderBox render = tester.renderObject(find.byType(EditableText));
    expect(render.size.height, greaterThan(500.0));
    expect(scrollController.offset, 0.0);

    // Enter text at end, which is off-screen.
    final String textToEnter = '${controller.text} HELLO';
    tester.testTextInput.updateEditingValue(new TextEditingValue(
      text: textToEnter,
      selection: new TextSelection.collapsed(offset: textToEnter.length),
    ));
    await tester.pumpAndSettle();

    // Caret scrolls into view.
    expect(find.byType(EditableText), findsOneWidget);
    expect(render.size.height, greaterThan(500.0));
    expect(scrollController.offset, greaterThan(0.0));
  });
}
