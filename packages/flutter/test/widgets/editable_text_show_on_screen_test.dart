// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

class _TestSliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TestSliverPersistentHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.child,
    this.vsync = const TestVSync(),
    this.showOnScreenConfiguration = const PersistentHeaderShowOnScreenConfiguration(),
  });

  final Widget child;

  @override
  final double maxExtent;

  @override
  final double minExtent;

  @override
  final TickerProvider? vsync;

  @override
  final PersistentHeaderShowOnScreenConfiguration showOnScreenConfiguration;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(_TestSliverPersistentHeaderDelegate oldDelegate) => true;
}

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
                backgroundCursorColor: Colors.grey,
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
                backgroundCursorColor: Colors.grey,
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
                backgroundCursorColor: Colors.grey,
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
                backgroundCursorColor: Colors.grey,
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

  testWidgets('entering text does not scroll a surrounding PageView', (WidgetTester tester) async {
    // regression test for https://github.com/flutter/flutter/issues/19523

    final TextEditingController textController = TextEditingController();
    final PageController pageController = PageController(initialPage: 1);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
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
          ),
        ),
      ),
    );

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
                backgroundCursorColor: Colors.grey,
                maxLines: null, // multiline
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
                backgroundCursorColor: Colors.grey,
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

  testWidgets(
    'A pinned persistent header should not scroll when its descendant EditableText gains focus',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/25507.
      ScrollController controller;
      final TextEditingController textEditingController = TextEditingController();
      final FocusNode focusNode = FocusNode();

      const Key headerKey = Key('header');
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              height: 600.0,
              width: 600.0,
              child: CustomScrollView(
                controller: controller = ScrollController(initialScrollOffset: 0),
                slivers: List<Widget>.generate(50, (int i) {
                  return i == 10
                  ? SliverPersistentHeader(
                    pinned: true,
                    floating: false,
                    delegate: _TestSliverPersistentHeaderDelegate(
                      minExtent: 50,
                      maxExtent: 50,
                      child: Container(
                        alignment: Alignment.topCenter,
                        child: EditableText(
                          key: headerKey,
                          backgroundCursorColor: Colors.grey,
                          controller: textEditingController,
                          focusNode: focusNode,
                          style: textStyle,
                          cursorColor: cursorColor,
                        ),
                      ),
                    ),
                  )
                  : SliverToBoxAdapter(
                    child: Container(
                      height: 100.0,
                      child: Text('Tile $i'),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      );

      // The persistent header should now be pinned at the top.
      controller.jumpTo(100.0 * 15);
      await tester.pumpAndSettle();
      expect(controller.offset, 100.0 * 15);

      focusNode.requestFocus();
      await tester.pumpAndSettle();
      // The scroll offset should remain the same.
      expect(controller.offset, 100.0 * 15);
  });

  testWidgets(
    'A pinned persistent header should not scroll when its descendant EditableText gains focus (no animation)',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/25507.
      ScrollController controller;
      final TextEditingController textEditingController = TextEditingController();
      final FocusNode focusNode = FocusNode();

      const Key headerKey = Key('header');
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              height: 600.0,
              width: 600.0,
              child: CustomScrollView(
                controller: controller = ScrollController(initialScrollOffset: 0),
                slivers: List<Widget>.generate(50, (int i) {
                  return i == 10
                    ? SliverPersistentHeader(
                      pinned: true,
                      floating: false,
                      delegate: _TestSliverPersistentHeaderDelegate(
                        minExtent: 50,
                        maxExtent: 50,
                        vsync: null,
                        child: Container(
                          alignment: Alignment.topCenter,
                          child: EditableText(
                            key: headerKey,
                            backgroundCursorColor: Colors.grey,
                            controller: textEditingController,
                            focusNode: focusNode,
                            style: textStyle,
                            cursorColor: cursorColor,
                          ),
                        ),
                      ),
                    )
                    : SliverToBoxAdapter(
                      child: Container(
                        height: 100.0,
                        child: Text('Tile $i'),
                      ),
                    );
                }),
              ),
            ),
          ),
        ),
      );

      // The persistent header should now be pinned at the top.
      controller.jumpTo(100.0 * 15);
      await tester.pumpAndSettle();
      expect(controller.offset, 100.0 * 15);

      focusNode.requestFocus();
      await tester.pumpAndSettle();
      // The scroll offset should remain the same.
      expect(controller.offset, 100.0 * 15);
  });
}

class NoImplicitScrollPhysics extends AlwaysScrollableScrollPhysics {
  const NoImplicitScrollPhysics({ ScrollPhysics? parent }) : super(parent: parent);

  @override
  bool get allowImplicitScrolling => false;

  @override
  NoImplicitScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return NoImplicitScrollPhysics(parent: buildParent(ancestor));
  }
}
