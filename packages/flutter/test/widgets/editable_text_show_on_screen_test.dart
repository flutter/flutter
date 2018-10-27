// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';


void main() {
  const TextStyle textStyle = TextStyle();
  const Color cursorColor = Color.fromARGB(0xFF, 0xFF, 0x00, 0x00);

  testWidgets('tapping on a partly visible editable brings it fully on screen', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: Container(
          height: 300.0,
          child: ListView(
            controller: scrollController,
            children: <Widget>[
              EditableText(
                controller: controller,
                focusNode: focusNode,
                style: textStyle,
                cursorColor: cursorColor,
              ),
              Container(
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

  testWidgets('tapping on a partly visible editable brings it fully on screen with scrollInsets', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: Container(
          height: 300.0,
          child: ListView(
            controller: scrollController,
            children: <Widget>[
              Container(
                height: 200.0,
              ),
              EditableText(
                scrollPadding: const EdgeInsets.all(50.0),
                controller: controller,
                focusNode: focusNode,
                style: textStyle,
                cursorColor: cursorColor,
              ),
              Container(
                height: 850.0,
              ),
            ],
          ),
        ),
      ),
    ));

    // Scroll the EditableText half off screen.
    final RenderBox render = tester.renderObject(find.byType(EditableText));
    scrollController.jumpTo(200 + render.size.height / 2);
    await tester.pumpAndSettle();
    expect(scrollController.offset, 200 + render.size.height / 2);

    await tester.showKeyboard(find.byType(EditableText));
    await tester.pumpAndSettle();
    // Container above the text is 200 in height, the scrollInsets are 50
    // Tolerance of 5 units (The actual value was 152.0 in the current tests instead of 150.0)
    expect(scrollController.offset, lessThan(200.0 - 50.0 + 5.0));
    expect(scrollController.offset, greaterThan(200.0 - 50.0 - 5.0));
  });

  testWidgets('editable comes back on screen when entering text while it is off-screen', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController(initialScrollOffset: 100.0);
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: Container(
          height: 300.0,
          child: ListView(
            controller: scrollController,
            children: <Widget>[
              Container(
                height: 350.0,
              ),
              EditableText(
                controller: controller,
                focusNode: focusNode,
                style: textStyle,
                cursorColor: cursorColor,
              ),
              Container(
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

  testWidgets('entering text does not scroll when scrollPhysics.allowImplicitScrolling = false', (WidgetTester tester) async {
    // regression test for https://github.com/flutter/flutter/issues/19523

    final ScrollController scrollController = ScrollController(initialScrollOffset: 100.0);
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: Container(
          height: 300.0,
          child: ListView(
            physics: const NoImplicitScrollPhysics(),
            controller: scrollController,
            children: <Widget>[
              Container(
                height: 350.0,
              ),
              EditableText(
                controller: controller,
                focusNode: focusNode,
                style: textStyle,
                cursorColor: cursorColor,
              ),
              Container(
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

    // Entering text brings it not back on screen.
    tester.testTextInput.enterText('Hello');
    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
    expect(find.byType(EditableText), findsNothing);
  });

  testWidgets('entering text does not scroll a sourrounding PageView', (WidgetTester tester) async {
    // regression test for https://github.com/flutter/flutter/issues/19523

    final TextEditingController textController = TextEditingController();
    final PageController pageController = PageController(initialPage: 1);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: PageView(
          controller: pageController,
          children: <Widget>[
            Container(
              color: Colors.red,
            ),
            Container(
              child: TextField(
                controller: textController,
              ),
              color: Colors.green,
            ),
            Container(
              color: Colors.red,
            ),
          ],
        ),
      ),
    ));

    await tester.showKeyboard(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(textController.text, '');
    tester.testTextInput.enterText('H');
    final int frames = await tester.pumpAndSettle();

    // The text input should not trigger any animations, which would indicate
    // that the surrounding PageView is incorrectly scrolling back-and-forth.
    expect(frames, 1);

    expect(textController.text, 'H');
  });

  testWidgets('focused multi-line editable scrolls caret back into view when typing', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();
    controller.text = 'Start\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nEnd';

    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: Container(
          height: 300.0,
          child: ListView(
            controller: scrollController,
            children: <Widget>[
              EditableText(
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
    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: textToEnter,
      selection: TextSelection.collapsed(offset: textToEnter.length),
    ));
    await tester.pumpAndSettle();

    // Caret scrolls into view.
    expect(find.byType(EditableText), findsOneWidget);
    expect(render.size.height, greaterThan(500.0));
    expect(scrollController.offset, greaterThan(0.0));
  });

  testWidgets('scrolls into view with scrollInserts after the keyboard pops up', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();

    const Key container = Key('container');

    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 300.0,
          child: ListView(
            controller: scrollController,
            children: <Widget>[
              Container(
                key: container,
                height: 200.0,
              ),
              EditableText(
                scrollPadding: const EdgeInsets.only(bottom: 300.0),
                controller: controller,
                focusNode: focusNode,
                style: textStyle,
                cursorColor: cursorColor,
              ),
              Container(
                height: 400.0,
              ),
            ],
          ),
        ),
      ),
    ));

    expect(scrollController.offset, 0.0);

    await tester.showKeyboard(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(scrollController.offset, greaterThan(0.0));
    expect(find.byKey(container), findsNothing);
  });
}

class NoImplicitScrollPhysics extends AlwaysScrollableScrollPhysics {
  const NoImplicitScrollPhysics({ ScrollPhysics parent }) : super(parent: parent);

  @override
  bool get allowImplicitScrolling => false;

  @override
  NoImplicitScrollPhysics applyTo(ScrollPhysics ancestor) {
    return NoImplicitScrollPhysics(parent: buildParent(ancestor));
  }
}
