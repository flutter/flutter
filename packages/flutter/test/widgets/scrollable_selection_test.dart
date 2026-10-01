// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'clipboard_utils.dart';
import 'editable_text_tester.dart' show testTextSelectionHandleControls;
import 'keyboard_utils.dart';
import 'two_dimensional_utils.dart';

Offset textOffsetToPosition(RenderParagraph paragraph, int offset) {
  const caret = Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);
  final Offset localOffset = paragraph.getOffsetForCaret(TextPosition(offset: offset), caret);
  return paragraph.localToGlobal(localOffset);
}

Offset globalize(Offset point, RenderBox box) {
  return box.localToGlobal(point);
}

// Drag-selects past the edge of a ListView nested in a PageView along [axis],
// and checks the ListView edge scrolls while the PageView stays on its page.
Future<void> selectPastNestedListEdge(WidgetTester tester, Axis axis) async {
  final pageController = PageController();
  addTearDown(pageController.dispose);
  final listController = ScrollController();
  addTearDown(listController.dispose);
  await tester.pumpWidget(
    TestWidgetsApp(
      home: SelectableRegion(
        selectionControls: testTextSelectionHandleControls,
        child: PageView(
          scrollDirection: axis,
          controller: pageController,
          children: <Widget>[
            ListView.builder(
              scrollDirection: axis,
              controller: listController,
              itemCount: 100,
              itemBuilder: (BuildContext context, int index) {
                return Center(child: Text('Item $index'));
              },
            ),
            const Center(child: Text('Second page')),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(pageController.page, 0.0);
  expect(listController.offset, 0.0);

  final RenderParagraph item0 = tester.renderObject<RenderParagraph>(
    find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
  );
  final Rect box = tester.getRect(find.byType(PageView));
  final target = axis == Axis.vertical
      ? Offset(box.center.dx, box.bottom + 40.0)
      : Offset(box.right + 40.0, box.center.dy);

  final TestGesture gesture = await tester.startGesture(
    textOffsetToPosition(item0, 2),
    kind: PointerDeviceKind.mouse,
  );
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(target);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));

  // The inner ListView edge scrolled, but the PageView did not flip pages.
  expect(listController.offset, greaterThan(0.0));
  expect(pageController.page, 0.0);
  expect(tester.takeException(), isNull);

  await gesture.up();
  await tester.pumpAndSettle();
}

const TextStyle _nestedFixtureTextStyle = TextStyle(fontSize: 14);
const Key _nestedScrollableKey = ValueKey<String>('nested scrollable');

Widget _nestedFixtureRow(String text) {
  return SizedBox(height: 20, child: Text(text, style: _nestedFixtureTextStyle));
}

// Pumps `SelectableRegion > CustomScrollView` with ten 'Above n' rows, then
// [nested] in a 300 tall box, then fifteen 'Below n' rows. Rows are 20 tall, so
// on the 800x600 test surface [nested] spans y 200..500 and the outer
// scrollable can scroll 200 pixels.
Future<void> _pumpNestedScrollableFixture(
  WidgetTester tester, {
  required ScrollController outerController,
  required Widget nested,
}) async {
  final focusNode = FocusNode();
  addTearDown(focusNode.dispose);
  await tester.pumpWidget(
    TestWidgetsApp(
      home: SelectableRegion(
        focusNode: focusNode,
        selectionControls: emptyTextSelectionControls,
        child: CustomScrollView(
          controller: outerController,
          slivers: <Widget>[
            for (var i = 0; i < 10; i += 1)
              SliverToBoxAdapter(child: _nestedFixtureRow('Above $i')),
            SliverToBoxAdapter(
              child: SizedBox(key: _nestedScrollableKey, height: 300, child: nested),
            ),
            for (var i = 0; i < 15; i += 1)
              SliverToBoxAdapter(child: _nestedFixtureRow('Below $i')),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// A two-dimensional scrollable of 200x200 'Cell r<y> c<x>' cells.
Widget _nestedTableView({
  required ScrollController verticalController,
  required ScrollController horizontalController,
  int maxYIndex = 99,
}) {
  // The table lays its cells out at 200x200 only under loose constraints.
  return Align(
    alignment: Alignment.topLeft,
    child: SimpleBuilderTableView(
      verticalDetails: ScrollableDetails.vertical(controller: verticalController),
      horizontalDetails: ScrollableDetails.horizontal(controller: horizontalController),
      delegate: TwoDimensionalChildBuilderDelegate(
        maxXIndex: 99,
        maxYIndex: maxYIndex,
        builder: (BuildContext context, ChildVicinity vicinity) {
          return Center(
            child: Text(
              'Cell r${vicinity.yIndex} c${vicinity.xIndex}',
              style: _nestedFixtureTextStyle,
            ),
          );
        },
      ),
    ),
  );
}

// A vertical list whose first child is a 100 tall horizontal list of 100 wide
// 'H n' items, followed by sixty 20 tall 'V n' rows. When [horizontalWidth] is
// given, the horizontal list is that wide and left aligned.
Widget _nestedListViews({
  required ScrollController verticalController,
  required ScrollController horizontalController,
  double? horizontalWidth,
}) {
  Widget horizontalList = SizedBox(
    height: 100,
    width: horizontalWidth,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      controller: horizontalController,
      itemCount: 100,
      itemBuilder: (BuildContext context, int index) {
        return SizedBox(width: 100, child: Text('H $index', style: _nestedFixtureTextStyle));
      },
    ),
  );
  if (horizontalWidth != null) {
    horizontalList = Align(alignment: Alignment.centerLeft, child: horizontalList);
  }
  return ListView(
    controller: verticalController,
    children: <Widget>[horizontalList, for (var i = 0; i < 60; i += 1) _nestedFixtureRow('V $i')],
  );
}

RenderParagraph _paragraphOf(WidgetTester tester, String text) {
  return tester.renderObject<RenderParagraph>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );
}

// A point inside [text], just after its second character.
Offset _insideText(WidgetTester tester, String text) {
  return textOffsetToPosition(_paragraphOf(tester, text), 2) + const Offset(0, 5);
}

// Expects every text built inside [of], on stage or in the cache extent, to be
// selected in full.
void _expectAllBuiltTextSelected(WidgetTester tester, Finder of) {
  final List<RenderParagraph> paragraphs = tester
      .renderObjectList<RenderParagraph>(
        find.descendant(
          of: of,
          matching: find.byType(RichText, skipOffstage: false),
          skipOffstage: false,
        ),
      )
      .toList();
  expect(paragraphs, isNotEmpty);
  for (final paragraph in paragraphs) {
    final String text = paragraph.text.toPlainText();
    expect(paragraph.selections, <TextSelection>[
      TextSelection(baseOffset: 0, extentOffset: text.length),
    ], reason: '"$text" should be selected in full');
  }
}

// The horizontal offset is null when it is not tracked.
typedef _ScrollOffsets = ({double outer, double vertical, double? horizontal});

// Pumps 40ms frames until [read] has returned the same offsets for 10
// consecutive frames, or 400 frames have passed, and returns every sample.
Future<List<_ScrollOffsets>> _pumpUntilScrollingStops(
  WidgetTester tester,
  _ScrollOffsets Function() read,
) async {
  final samples = <_ScrollOffsets>[read()];
  var stableFrames = 0;
  for (var i = 0; i < 400 && stableFrames < 10; i += 1) {
    await tester.pump(const Duration(milliseconds: 40));
    final _ScrollOffsets sample = read();
    stableFrames = sample == samples.last ? stableFrames + 1 : 0;
    samples.add(sample);
  }
  return samples;
}

// Drags in one jump from inside 'Above 8' to inside 'Below 1', across the
// nested scrollable built by _pumpNestedScrollableFixture, and expects the
// rows between and every text built in the nested scrollable to be selected.
Future<void> _dragAcrossNestedScrollableAndExpectItSelected(WidgetTester tester) async {
  final TestGesture gesture = await tester.startGesture(
    _insideText(tester, 'Above 8'),
    kind: ui.PointerDeviceKind.mouse,
  );
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(_insideText(tester, 'Below 1'));
  await tester.pumpAndSettle();
  await gesture.up();
  await tester.pumpAndSettle();

  expect(_paragraphOf(tester, 'Above 8').selections, <TextSelection>[
    const TextSelection(baseOffset: 2, extentOffset: 7),
  ]);
  expect(_paragraphOf(tester, 'Above 9').selections, <TextSelection>[
    const TextSelection(baseOffset: 0, extentOffset: 7),
  ]);
  _expectAllBuiltTextSelected(tester, find.byKey(_nestedScrollableKey));
  expect(_paragraphOf(tester, 'Below 0').selections, <TextSelection>[
    const TextSelection(baseOffset: 0, extentOffset: 7),
  ]);
  expect(_paragraphOf(tester, 'Below 1').selections, <TextSelection>[
    const TextSelection(baseOffset: 0, extentOffset: 2),
  ]);
  expect(_paragraphOf(tester, 'Below 2').selections, isEmpty);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mockClipboard = MockClipboard();

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      mockClipboard.handleMethodCall,
    );
    await Clipboard.setData(const ClipboardData(text: 'empty'));
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  testWidgets('mouse can select multiple widgets', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph1, 2),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();

    await gesture.moveTo(textOffsetToPosition(paragraph1, 4));
    await tester.pump();
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 4));

    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)),
    );
    await gesture.moveTo(textOffsetToPosition(paragraph2, 5));
    // Should select the rest of paragraph 1.
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 6));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 5));

    final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 3'), matching: find.byType(RichText)),
    );
    await gesture.moveTo(textOffsetToPosition(paragraph3, 3));
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 6));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 3));

    await gesture.up();
  });

  testWidgets('mouse can select multiple widgets - horizontal', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph1, 2),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();

    await gesture.moveTo(textOffsetToPosition(paragraph1, 4));
    await tester.pump();
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 4));

    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)),
    );
    await gesture.moveTo(textOffsetToPosition(paragraph2, 5) + const Offset(0, 5));
    // Should select the rest of paragraph 1.
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 6));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 5));

    await gesture.up();
  });

  testWidgets('mouse can select multiple widgets on double-click drag', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph1, 2),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();

    await gesture.up();
    await tester.pump();
    await gesture.down(textOffsetToPosition(paragraph1, 2));
    await tester.pumpAndSettle();
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 4));

    await gesture.moveTo(textOffsetToPosition(paragraph1, 4));
    await tester.pump();
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 5));

    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)),
    );
    await gesture.moveTo(textOffsetToPosition(paragraph2, 4));
    // Should select the rest of paragraph 1.
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 5));

    final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 3'), matching: find.byType(RichText)),
    );
    await gesture.moveTo(textOffsetToPosition(paragraph3, 3));
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 4));

    await gesture.up();
  });

  testWidgets('mouse can select multiple widgets on double-click drag - horizontal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph1, 2),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    await gesture.down(textOffsetToPosition(paragraph1, 2));
    await tester.pumpAndSettle();
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 4));

    await gesture.moveTo(textOffsetToPosition(paragraph1, 4));
    await tester.pump();
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 5));

    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)),
    );
    await gesture.moveTo(textOffsetToPosition(paragraph2, 5) + const Offset(0, 5));
    // Should select the rest of paragraph 1.
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));

    await gesture.up();
  });

  testWidgets('mouse can select multiple widgets on triple-click drag', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph1, 2),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    await gesture.down(textOffsetToPosition(paragraph1, 2));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    await gesture.down(textOffsetToPosition(paragraph1, 2));
    await tester.pumpAndSettle();
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));

    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)),
    );
    expect(paragraph2.selections.isEmpty, isTrue);
    await gesture.moveTo(textOffsetToPosition(paragraph2, 4));
    // Should select paragraph 2.
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));

    final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 3'), matching: find.byType(RichText)),
    );
    expect(paragraph3.selections.isEmpty, isTrue);
    await gesture.moveTo(textOffsetToPosition(paragraph3, 3));
    // Should select paragraph 3.
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));

    final RenderParagraph paragraph4 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 4'), matching: find.byType(RichText)),
    );
    expect(paragraph4.selections.isEmpty, isTrue);
    await gesture.moveTo(textOffsetToPosition(paragraph4, 3));
    // Should select paragraph 4.
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph4.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));

    await gesture.up();
  });

  testWidgets('mouse can select multiple widgets on triple-click drag - horizontal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph1, 2),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    await gesture.down(textOffsetToPosition(paragraph1, 2));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    await gesture.down(textOffsetToPosition(paragraph1, 2));
    await tester.pumpAndSettle();
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));

    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)),
    );
    expect(paragraph2.selections.isEmpty, isTrue);
    await gesture.moveTo(textOffsetToPosition(paragraph2, 5) + const Offset(0, 50));
    // Should select paragraph 2.
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));

    final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 2'), matching: find.byType(RichText)),
    );
    expect(paragraph3.selections.isEmpty, isTrue);
    await gesture.moveTo(textOffsetToPosition(paragraph3, 5) + const Offset(0, 50));
    // Should select paragraph 3.
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));

    await gesture.up();
  });

  testWidgets('select to scroll forward', (WidgetTester tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            controller: controller,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph1, 2),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    expect(controller.offset, 0.0);
    double previousOffset = controller.offset;

    // Scrollable only auto scroll if the drag passes the boundary.
    await gesture.moveTo(tester.getBottomRight(find.byType(ListView)) + const Offset(0, 20));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);
    previousOffset = controller.offset;

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);

    // Scroll to the end.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(controller.offset, 4200.0);
    final RenderParagraph paragraph99 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 99'), matching: find.byType(RichText)),
    );
    final RenderParagraph paragraph98 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 98'), matching: find.byType(RichText)),
    );
    final RenderParagraph paragraph97 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 97'), matching: find.byType(RichText)),
    );
    final RenderParagraph paragraph96 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 96'), matching: find.byType(RichText)),
    );
    expect(paragraph99.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));
    expect(paragraph98.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));
    expect(paragraph97.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));
    expect(paragraph96.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));

    await gesture.up();
  });

  testWidgets('select to scroll works for small scrollable', (WidgetTester tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: Scaffold(
            body: SizedBox(
              height: 10,
              child: ListView.builder(
                controller: controller,
                itemCount: 100,
                itemBuilder: (BuildContext context, int index) {
                  return Text('Item $index');
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph1, 2),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    expect(controller.offset, 0.0);
    double previousOffset = controller.offset;

    // Scrollable only auto scroll if the drag passes the boundary
    await gesture.moveTo(tester.getBottomRight(find.byType(ListView)) + const Offset(0, 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.offset > previousOffset, isTrue);
    previousOffset = controller.offset;

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.offset > previousOffset, isTrue);
    await gesture.up();

    // Shouldn't be stuck if gesture is up.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('select to scroll backward', (WidgetTester tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            controller: controller,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    controller.jumpTo(4000);
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    expect(controller.offset, 4000);
    double previousOffset = controller.offset;

    await gesture.moveTo(tester.getTopLeft(find.byType(ListView)) + const Offset(0, -20));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset < previousOffset, isTrue);
    previousOffset = controller.offset;

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset < previousOffset, isTrue);

    // Scroll to the beginning.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(controller.offset, 0.0);
    final RenderParagraph paragraph0 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
    );
    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)),
    );
    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 2'), matching: find.byType(RichText)),
    );
    final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 3'), matching: find.byType(RichText)),
    );
    expect(paragraph0.selections[0], const TextSelection(baseOffset: 6, extentOffset: 0));
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 6, extentOffset: 0));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 6, extentOffset: 0));
    expect(paragraph3.selections[0], const TextSelection(baseOffset: 6, extentOffset: 0));
  });

  testWidgets('select to scroll forward - horizontal', (WidgetTester tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            controller: controller,
            itemCount: 10,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph1, 2),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    expect(controller.offset, 0.0);
    double previousOffset = controller.offset;

    // Scrollable only auto scroll if the drag passes the boundary
    await gesture.moveTo(tester.getBottomRight(find.byType(ListView)) + const Offset(20, 0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);
    previousOffset = controller.offset;

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);

    // Scroll to the end.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(controller.offset, 2080.0);
    final RenderParagraph paragraph9 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 9'), matching: find.byType(RichText)),
    );
    final RenderParagraph paragraph8 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 8'), matching: find.byType(RichText)),
    );
    final RenderParagraph paragraph7 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 7'), matching: find.byType(RichText)),
    );
    expect(paragraph9.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph8.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph7.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));

    await gesture.up();
  });

  testWidgets('select to scroll backward - horizontal', (WidgetTester tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            controller: controller,
            itemCount: 10,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    controller.jumpTo(2080);
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    expect(controller.offset, 2080);
    double previousOffset = controller.offset;

    await gesture.moveTo(tester.getTopLeft(find.byType(ListView)) + const Offset(-10, 0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset < previousOffset, isTrue);
    previousOffset = controller.offset;

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset < previousOffset, isTrue);

    // Scroll to the beginning.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(controller.offset, 0.0);
    final RenderParagraph paragraph0 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
    );
    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)),
    );
    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 2'), matching: find.byType(RichText)),
    );
    expect(paragraph0.selections[0], const TextSelection(baseOffset: 6, extentOffset: 0));
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 6, extentOffset: 0));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 6, extentOffset: 0));

    await gesture.up();
  });

  testWidgets('preserve selection when out of view.', (WidgetTester tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            controller: controller,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );

    controller.jumpTo(2000);
    await tester.pumpAndSettle();
    expect(find.text('Item 50'), findsOneWidget);
    RenderParagraph paragraph50 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 50'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph50, 2),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(textOffsetToPosition(paragraph50, 4));
    await gesture.up();
    expect(paragraph50.selections[0], const TextSelection(baseOffset: 2, extentOffset: 4));

    controller.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Item 50'), findsNothing);

    controller.jumpTo(2000);
    await tester.pumpAndSettle();
    expect(find.text('Item 50'), findsOneWidget);
    paragraph50 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 50'), matching: find.byType(RichText)),
    );
    expect(paragraph50.selections[0], const TextSelection(baseOffset: 2, extentOffset: 4));

    controller.jumpTo(4000);
    await tester.pumpAndSettle();
    expect(find.text('Item 50'), findsNothing);

    controller.jumpTo(2000);
    await tester.pumpAndSettle();
    expect(find.text('Item 50'), findsOneWidget);
    paragraph50 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 50'), matching: find.byType(RichText)),
    );
    expect(paragraph50.selections[0], const TextSelection(baseOffset: 2, extentOffset: 4));
  });

  testWidgets(
    'can select all non-Apple',
    (WidgetTester tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(
            focusNode: node,
            selectionControls: materialTextSelectionControls,
            child: ListView.builder(
              itemCount: 100,
              itemBuilder: (BuildContext context, int index) {
                return Text('Item $index');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      node.requestFocus();
      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.keyA, control: true),
      );
      await tester.pump();

      for (var i = 0; i < 13; i += 1) {
        final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: find.text('Item $i'), matching: find.byType(RichText)),
        );
        expect(
          paragraph.selections[0],
          TextSelection(baseOffset: 0, extentOffset: 'Item $i'.length),
        );
      }
      expect(find.text('Item 13'), findsNothing);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.android,
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.fuchsia,
    }),
  );

  testWidgets(
    'can select all - Apple',
    (WidgetTester tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(
            focusNode: node,
            selectionControls: materialTextSelectionControls,
            child: ListView.builder(
              itemCount: 100,
              itemBuilder: (BuildContext context, int index) {
                return Text('Item $index');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      node.requestFocus();
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.keyA, meta: true));
      await tester.pump();

      for (var i = 0; i < 13; i += 1) {
        final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: find.text('Item $i'), matching: find.byType(RichText)),
        );
        expect(
          paragraph.selections[0],
          TextSelection(baseOffset: 0, extentOffset: 'Item $i'.length),
        );
      }
      expect(find.text('Item 13'), findsNothing);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    }),
  );

  testWidgets('select to scroll by dragging selection handles forward', (
    WidgetTester tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            controller: controller,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Long press to bring up the selection handles.
    final RenderParagraph paragraph0 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph0, 2));
    addTearDown(gesture.removePointer);
    await tester.pump(kLongPressTimeout);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(paragraph0.selections[0], const TextSelection(baseOffset: 0, extentOffset: 4));

    final List<TextBox> boxes = paragraph0.getBoxesForSelection(paragraph0.selections[0]);
    expect(boxes.length, 1);
    // Find end handle.
    final Offset handlePos = globalize(boxes[0].toRect().bottomRight, paragraph0);
    await gesture.down(handlePos);

    expect(controller.offset, 0.0);
    double previousOffset = controller.offset;
    // Scrollable only auto scroll if the drag passes the boundary
    await gesture.moveTo(tester.getBottomRight(find.byType(ListView)) + const Offset(0, 40));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);
    previousOffset = controller.offset;

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);

    // Scroll to the end.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(controller.offset, 4200.0);
    final RenderParagraph paragraph99 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 99'), matching: find.byType(RichText)),
    );
    final RenderParagraph paragraph98 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 98'), matching: find.byType(RichText)),
    );
    final RenderParagraph paragraph97 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 97'), matching: find.byType(RichText)),
    );
    final RenderParagraph paragraph96 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 96'), matching: find.byType(RichText)),
    );
    expect(paragraph99.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));
    expect(paragraph98.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));
    expect(paragraph97.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));
    expect(paragraph96.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));
    await gesture.up();
  });

  testWidgets('select to scroll by dragging start selection handle stops scroll when released', (
    WidgetTester tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            controller: controller,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Long press to bring up the selection handles.
    final RenderParagraph paragraph0 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph0, 2));
    addTearDown(gesture.removePointer);
    await tester.pump(kLongPressTimeout);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(paragraph0.selections[0], const TextSelection(baseOffset: 0, extentOffset: 4));

    final List<TextBox> boxes = paragraph0.getBoxesForSelection(paragraph0.selections[0]);
    expect(boxes.length, 1);
    // Find start handle.
    final Offset handlePos = globalize(boxes[0].toRect().bottomLeft, paragraph0);
    await gesture.down(handlePos);

    expect(controller.offset, 0.0);
    double previousOffset = controller.offset;
    // Scrollable only auto scroll if the drag passes the boundary.
    await gesture.moveTo(tester.getBottomRight(find.byType(ListView)) + const Offset(0, 40));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);
    previousOffset = controller.offset;

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);
    previousOffset = controller.offset;

    // Release handle should stop scrolling.
    await gesture.up();
    // Last scheduled scroll.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    previousOffset = controller.offset;
    await tester.pumpAndSettle();
    expect(controller.offset, previousOffset);
  });

  testWidgets('select to scroll by dragging end selection handle stops scroll when released', (
    WidgetTester tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            controller: controller,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Long press to bring up the selection handles.
    final RenderParagraph paragraph0 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph0, 2));
    addTearDown(gesture.removePointer);
    await tester.pump(kLongPressTimeout);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(paragraph0.selections[0], const TextSelection(baseOffset: 0, extentOffset: 4));

    final List<TextBox> boxes = paragraph0.getBoxesForSelection(paragraph0.selections[0]);
    expect(boxes.length, 1);
    final Offset handlePos = globalize(boxes[0].toRect().bottomRight, paragraph0);
    await gesture.down(handlePos);

    expect(controller.offset, 0.0);
    double previousOffset = controller.offset;
    // Scrollable only auto scroll if the drag passes the boundary
    await gesture.moveTo(tester.getBottomRight(find.byType(ListView)) + const Offset(0, 40));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);
    previousOffset = controller.offset;

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);
    previousOffset = controller.offset;

    // Release handle should stop scrolling.
    await gesture.up();
    // Last scheduled scroll.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    previousOffset = controller.offset;
    await tester.pumpAndSettle();
    expect(controller.offset, previousOffset);
  });

  testWidgets('keyboard selection should auto scroll - vertical', (WidgetTester tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          focusNode: node,
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            controller: controller,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final RenderParagraph paragraph9 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 9'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph9, 2),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await gesture.moveTo(textOffsetToPosition(paragraph9, 4) + const Offset(0, 5));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pump();
    expect(paragraph9.selections.length, 1);
    expect(paragraph9.selections[0].start, 2);
    expect(paragraph9.selections[0].end, 4);
    expect(controller.offset, 0.0);

    await sendKeyCombination(
      tester,
      const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true),
    );
    await tester.pump();
    final RenderParagraph paragraph10 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 10'), matching: find.byType(RichText)),
    );
    expect(paragraph10.selections.length, 1);
    expect(paragraph10.selections[0].start, 0);
    expect(paragraph10.selections[0].end, 4);
    expect(controller.offset, 0.0);

    await sendKeyCombination(
      tester,
      const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true),
    );
    await tester.pump();
    final RenderParagraph paragraph11 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 11'), matching: find.byType(RichText)),
    );
    expect(paragraph11.selections.length, 1);
    expect(paragraph11.selections[0].start, 0);
    expect(paragraph11.selections[0].end, 4);
    expect(controller.offset, 0.0);

    // Should start scrolling.
    await sendKeyCombination(
      tester,
      const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true),
    );
    await tester.pump();
    final RenderParagraph paragraph12 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 12'), matching: find.byType(RichText)),
    );
    expect(paragraph12.selections.length, 1);
    expect(paragraph12.selections[0].start, 0);
    expect(paragraph12.selections[0].end, 4);
    expect(controller.offset, 24.0);

    await sendKeyCombination(
      tester,
      const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true),
    );
    await tester.pump();
    final RenderParagraph paragraph13 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 13'), matching: find.byType(RichText)),
    );
    expect(paragraph13.selections.length, 1);
    expect(paragraph13.selections[0].start, 0);
    expect(paragraph13.selections[0].end, 4);
    expect(controller.offset, 72.0);
  }, variant: TargetPlatformVariant.all());

  testWidgets('keyboard selection should auto scroll - vertical reversed', (
    WidgetTester tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          focusNode: node,
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            controller: controller,
            reverse: true,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final RenderParagraph paragraph9 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 9'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph9, 2),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await gesture.moveTo(textOffsetToPosition(paragraph9, 4) + const Offset(0, 5));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pump();
    expect(paragraph9.selections.length, 1);
    expect(paragraph9.selections[0].start, 2);
    expect(paragraph9.selections[0].end, 4);
    expect(controller.offset, 0.0);

    await sendKeyCombination(
      tester,
      const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true),
    );
    await tester.pump();
    final RenderParagraph paragraph10 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 10'), matching: find.byType(RichText)),
    );
    expect(paragraph10.selections.length, 1);
    expect(paragraph10.selections[0].start, 2);
    expect(paragraph10.selections[0].end, 7);
    expect(controller.offset, 0.0);

    await sendKeyCombination(
      tester,
      const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true),
    );
    await tester.pump();
    final RenderParagraph paragraph11 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 11'), matching: find.byType(RichText)),
    );
    expect(paragraph11.selections.length, 1);
    expect(paragraph11.selections[0].start, 2);
    expect(paragraph11.selections[0].end, 7);
    expect(controller.offset, 0.0);

    // Should start scrolling.
    await sendKeyCombination(
      tester,
      const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true),
    );
    await tester.pump();
    final RenderParagraph paragraph12 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 12'), matching: find.byType(RichText)),
    );
    expect(paragraph12.selections.length, 1);
    expect(paragraph12.selections[0].start, 2);
    expect(paragraph12.selections[0].end, 7);
    expect(controller.offset, 24.0);

    await sendKeyCombination(
      tester,
      const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true),
    );
    await tester.pump();
    final RenderParagraph paragraph13 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 13'), matching: find.byType(RichText)),
    );
    expect(paragraph13.selections.length, 1);
    expect(paragraph13.selections[0].start, 2);
    expect(paragraph13.selections[0].end, 7);
    expect(controller.offset, 72.0);
  }, variant: TargetPlatformVariant.all());

  testWidgets('keyboard selection should auto scroll - horizontal', (WidgetTester tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          focusNode: node,
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            controller: controller,
            scrollDirection: Axis.horizontal,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 2'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph2, 0),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await gesture.moveTo(textOffsetToPosition(paragraph2, 1) + const Offset(0, 5));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pump();
    expect(paragraph2.selections.length, 1);
    expect(paragraph2.selections[0].start, 0);
    expect(paragraph2.selections[0].end, 1);
    expect(controller.offset, 0.0);

    await sendKeyCombination(
      tester,
      const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true),
    );
    await tester.pump();
    expect(paragraph2.selections.length, 1);
    expect(paragraph2.selections[0].start, 0);
    expect(paragraph2.selections[0].end, 6);
    expect(controller.offset, 64.0);

    await sendKeyCombination(
      tester,
      const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true),
    );
    await tester.pump();
    final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 3'), matching: find.byType(RichText)),
    );
    expect(paragraph3.selections.length, 1);
    expect(paragraph3.selections[0].start, 0);
    expect(paragraph3.selections[0].end, 6);
    expect(controller.offset, 352.0);
  }, variant: TargetPlatformVariant.all());

  testWidgets('keyboard selection should auto scroll - horizontal reversed', (
    WidgetTester tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          focusNode: node,
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            controller: controller,
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph1, 5) + const Offset(0, 5),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await gesture.moveTo(textOffsetToPosition(paragraph1, 4) + const Offset(0, 5));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(paragraph1.selections.length, 1);
    expect(paragraph1.selections[0].start, 4);
    expect(paragraph1.selections[0].end, 5);
    expect(controller.offset, 0.0);

    await sendKeyCombination(
      tester,
      const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true),
    );
    await tester.pump();
    expect(paragraph1.selections.length, 1);
    expect(paragraph1.selections[0].start, 0);
    expect(paragraph1.selections[0].end, 5);
    expect(controller.offset, 0.0);

    await sendKeyCombination(
      tester,
      const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true),
    );
    await tester.pump();
    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 2'), matching: find.byType(RichText)),
    );
    expect(paragraph2.selections.length, 1);
    expect(paragraph2.selections[0].start, 0);
    expect(paragraph2.selections[0].end, 6);
    expect(controller.offset, 64.0);

    await sendKeyCombination(
      tester,
      const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true),
    );
    await tester.pump();
    final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 3'), matching: find.byType(RichText)),
    );
    expect(paragraph3.selections.length, 1);
    expect(paragraph3.selections[0].start, 0);
    expect(paragraph3.selections[0].end, 6);
    expect(controller.offset, 352.0);
  }, variant: TargetPlatformVariant.all());

  testWidgets('Starting selection in empty padding of scrollable should not crash', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/115787
    const text = 'Some selectable text children';

    await tester.pumpWidget(
      TestWidgetsApp(
        home: SelectableRegion(
          selectionControls: emptyTextSelectionControls,
          child: const SingleChildScrollView(padding: EdgeInsets.all(50.0), child: Text(text)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Offset paddingOffset =
        tester.getTopLeft(find.byType(SingleChildScrollView)) + const Offset(20.0, 20.0);
    final Offset textCenter = tester.getCenter(find.text(text));

    final TestGesture gesture = await tester.startGesture(paddingOffset);
    addTearDown(gesture.removePointer);

    // Simulate long press.
    await tester.pump(kLongPressTimeout);

    // Drag into the text content.
    await gesture.moveTo(textCenter);
    await tester.pump();

    await gesture.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Fast drag starting in padding correctly triggers auto-scroll', (
    WidgetTester tester,
  ) async {
    final String text =
        'Some selectable text children that is long enough to make it scrollable \n' * 20;

    await tester.pumpWidget(
      TestWidgetsApp(
        home: SelectableRegion(
          selectionControls: emptyTextSelectionControls,
          child: SizedBox(
            height: 200.0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 50.0),
              child: Text(text),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    expect(position.pixels, 0.0);

    // Get a point inside the padding (which is inside the scrollable).
    final Offset scrollableTopLeft = tester.getTopLeft(find.byType(SingleChildScrollView));
    final Offset paddingStartOffset =
        scrollableTopLeft + const Offset(50.0, 20.0); // Inside padding.

    // Get a point outside the bottom of the scrollable to trigger downward auto-scrolling.
    final Offset dragEndOffset =
        tester.getBottomLeft(find.byType(SingleChildScrollView)) + const Offset(50.0, 100.0);

    // Start gesture perfectly on padding.
    final TestGesture gesture = await tester.startGesture(paddingStartOffset);
    addTearDown(gesture.removePointer);

    // Simulate long press.
    await tester.pump(kLongPressTimeout);

    // First drag update is far ALREADY OUTSIDE the scrollable.
    // Emulates a very fast drag movement (so the first EdgeUpdate frame is processed outside).
    await gesture.moveTo(dragEndOffset);
    await tester.pump();

    // Let auto-scroller run for a few frames.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // If _selectionStartsInScrollable was correctly preserved as TRUE,
    // the scrollable will have started auto-scrolling downwards.
    expect(position.pixels, greaterThan(0.0));
    await gesture.up();
  });

  testWidgets('automatic edge scrolling respects NeverScrollableScrollPhysics', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/140654.
    // When a scrollable view with non-scrollable physics (e.g.,
    // NeverScrollableScrollPhysics) is wrapped in a SelectableRegion, dragging
    // a selection past the viewport boundary must not advance the scroll offset
    // or throw exceptions.
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      TestWidgetsApp(
        home: SelectableRegion(
          selectionControls: testTextSelectionHandleControls,
          child: ListView.builder(
            controller: controller,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('Item 0')),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    expect(controller.offset, 0.0);

    // Drag past the bottom of the scrollable; this would normally trigger
    // edge auto-scroll.
    await gesture.moveTo(tester.getBottomRight(find.byType(ListView)) + const Offset(0.0, 40.0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // The scroll position must not have advanced, and no exception must have
    // been thrown.
    expect(controller.offset, 0.0);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset, 0.0);
    expect(tester.takeException(), isNull);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.offset, 0.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'paged scrollable does not flip pages during selection, but text still gets selected',
    (WidgetTester tester) async {
      final controller = PageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        TestWidgetsApp(
          home: SelectableRegion(
            selectionControls: testTextSelectionHandleControls,
            child: PageView.builder(
              controller: controller,
              itemCount: 5,
              itemBuilder: (BuildContext context, int index) {
                return Center(child: Text('Page $index'));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.page, 0.0);

      final RenderParagraph page0 = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('Page 0'), matching: find.byType(RichText)),
      );
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('Page 0')),
        kind: ui.PointerDeviceKind.mouse,
      );
      addTearDown(gesture.removePointer);
      await tester.pump();
      expect(controller.page, 0.0);

      // Hold the drag past the right edge; without the fix this keeps flipping
      // pages toward page 1.
      await gesture.moveTo(tester.getBottomRight(find.byType(PageView)) + const Offset(40.0, 0.0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // The page did not flip, but the page's text was still selected.
      expect(controller.page, 0.0);
      expect(page0.selections, isNotEmpty);
      expect(tester.takeException(), isNull);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.page, 0.0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mouse selection drag still edge auto-scrolls a non page-snapping scrollable', (
    WidgetTester tester,
  ) async {
    // Counterpart to the PageView test above: only paged scrollables are
    // affected. A plain ListView still edge scrolls while drag-selecting.
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      TestWidgetsApp(
        home: SelectableRegion(
          selectionControls: testTextSelectionHandleControls,
          child: ListView.builder(
            controller: controller,
            scrollDirection: Axis.horizontal,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Center(child: Text('Item $index'));
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.offset, 0.0);

    final RenderParagraph paragraph0 = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph0, 2),
      kind: ui.PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    expect(controller.offset, 0.0);

    // Drag past the right edge to kick off auto-scroll.
    await gesture.moveTo(tester.getBottomRight(find.byType(ListView)) + const Offset(40.0, 0.0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset, greaterThan(0.0));
    expect(tester.takeException(), isNull);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('vertical ListView inside a PageView still edge scrolls during selection', (
    WidgetTester tester,
  ) async {
    await selectPastNestedListEdge(tester, Axis.vertical);
  });

  testWidgets('horizontal ListView inside a PageView still edge scrolls during selection', (
    WidgetTester tester,
  ) async {
    await selectPastNestedListEdge(tester, Axis.horizontal);
  });

  group('Complex cases', () {
    testWidgets('selection starts outside of the scrollable', (WidgetTester tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(
            selectionControls: materialTextSelectionControls,
            child: Column(
              children: <Widget>[
                const Text('Item 0'),
                SizedBox(
                  height: 400,
                  child: ListView.builder(
                    controller: controller,
                    itemCount: 100,
                    itemBuilder: (BuildContext context, int index) {
                      return Text('Inner item $index');
                    },
                  ),
                ),
                const Text('Item 1'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.jumpTo(1000);
      await tester.pumpAndSettle();
      final RenderParagraph paragraph0 = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
      );
      final TestGesture gesture = await tester.startGesture(
        textOffsetToPosition(paragraph0, 2),
        kind: ui.PointerDeviceKind.mouse,
      );
      addTearDown(gesture.removePointer);
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)),
      );
      await gesture.moveTo(textOffsetToPosition(paragraph1, 2) + const Offset(0, 5));
      await tester.pumpAndSettle();
      await gesture.up();

      // The entire scrollable should be selected.
      expect(paragraph0.selections[0], const TextSelection(baseOffset: 2, extentOffset: 6));
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 2));
      final RenderParagraph innerParagraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('Inner item 20'), matching: find.byType(RichText)),
      );
      expect(innerParagraph.selections[0], const TextSelection(baseOffset: 0, extentOffset: 13));
      // Should not scroll the inner scrollable.
      expect(controller.offset, 1000.0);
    });

    testWidgets('nested scrollables keep selection alive', (WidgetTester tester) async {
      final outerController = ScrollController();
      addTearDown(outerController.dispose);
      final innerController = ScrollController();
      addTearDown(innerController.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(
            selectionControls: materialTextSelectionControls,
            child: ListView.builder(
              controller: outerController,
              itemCount: 100,
              itemBuilder: (BuildContext context, int index) {
                if (index == 2) {
                  return SizedBox(
                    height: 700,
                    child: ListView.builder(
                      controller: innerController,
                      itemCount: 100,
                      itemBuilder: (BuildContext context, int index) {
                        return Text('Iteminner $index');
                      },
                    ),
                  );
                }
                return Text('Item $index');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      innerController.jumpTo(1000);
      await tester.pumpAndSettle();
      RenderParagraph innerParagraph23 = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('Iteminner 23'), matching: find.byType(RichText)),
      );
      final TestGesture gesture = await tester.startGesture(
        textOffsetToPosition(innerParagraph23, 2) + const Offset(0, 5),
        kind: ui.PointerDeviceKind.mouse,
      );
      addTearDown(gesture.removePointer);
      RenderParagraph innerParagraph24 = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('Iteminner 24'), matching: find.byType(RichText)),
      );
      await gesture.moveTo(textOffsetToPosition(innerParagraph24, 2) + const Offset(0, 5));
      await tester.pumpAndSettle();
      await gesture.up();
      expect(innerParagraph23.selections[0], const TextSelection(baseOffset: 2, extentOffset: 12));
      expect(innerParagraph24.selections[0], const TextSelection(baseOffset: 0, extentOffset: 2));

      innerController.jumpTo(2000);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.text('Iteminner 23'), matching: find.byType(RichText)),
        findsNothing,
      );

      outerController.jumpTo(2000);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.text('Iteminner 23'), matching: find.byType(RichText)),
        findsNothing,
      );

      // Selected item is still kept alive.
      expect(
        find.descendant(
          of: find.text('Iteminner 23'),
          matching: find.byType(RichText),
          skipOffstage: false,
        ),
        findsNothing,
      );

      // Selection stays the same after scrolling back.
      outerController.jumpTo(0);
      await tester.pumpAndSettle();
      expect(innerController.offset, 2000.0);
      innerController.jumpTo(1000);
      await tester.pumpAndSettle();
      innerParagraph23 = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('Iteminner 23'), matching: find.byType(RichText)),
      );
      innerParagraph24 = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('Iteminner 24'), matching: find.byType(RichText)),
      );
      expect(innerParagraph23.selections[0], const TextSelection(baseOffset: 2, extentOffset: 12));
      expect(innerParagraph24.selections[0], const TextSelection(baseOffset: 0, extentOffset: 2));
    });

    testWidgets(
      'can copy off screen selection - Apple',
      (WidgetTester tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: SelectionArea(
              focusNode: focusNode,
              selectionControls: materialTextSelectionControls,
              child: ListView.builder(
                controller: controller,
                itemCount: 100,
                itemBuilder: (BuildContext context, int index) {
                  return Text('Item $index');
                },
              ),
            ),
          ),
        );
        focusNode.requestFocus();
        await tester.pumpAndSettle();
        final RenderParagraph paragraph0 = tester.renderObject<RenderParagraph>(
          find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
        );
        final TestGesture gesture = await tester.startGesture(
          textOffsetToPosition(paragraph0, 2) + const Offset(0, 5),
          kind: ui.PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
          find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)),
        );
        await gesture.moveTo(textOffsetToPosition(paragraph1, 2) + const Offset(0, 5));
        await tester.pumpAndSettle();
        await gesture.up();
        expect(paragraph0.selections[0], const TextSelection(baseOffset: 2, extentOffset: 6));
        expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 2));

        // Scroll the selected text out off the screen.
        controller.jumpTo(1000);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
          findsNothing,
        );
        expect(
          find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)),
          findsNothing,
        );

        // Start copying.
        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.keyC, meta: true),
        );

        final clipboardData = mockClipboard.clipboardData as Map<String, dynamic>;
        expect(clipboardData['text'], 'em 0It');
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }),
    );

    testWidgets(
      'can copy off screen selection - non-Apple',
      (WidgetTester tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: SelectionArea(
              focusNode: focusNode,
              selectionControls: materialTextSelectionControls,
              child: ListView.builder(
                controller: controller,
                itemCount: 100,
                itemBuilder: (BuildContext context, int index) {
                  return Text('Item $index');
                },
              ),
            ),
          ),
        );
        focusNode.requestFocus();
        await tester.pumpAndSettle();
        final RenderParagraph paragraph0 = tester.renderObject<RenderParagraph>(
          find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
        );
        final TestGesture gesture = await tester.startGesture(
          textOffsetToPosition(paragraph0, 2) + const Offset(0, 5),
          kind: ui.PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
          find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)),
        );
        await gesture.moveTo(textOffsetToPosition(paragraph1, 2) + const Offset(0, 5));
        await tester.pumpAndSettle();
        await gesture.up();
        expect(paragraph0.selections[0], const TextSelection(baseOffset: 2, extentOffset: 6));
        expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 2));

        // Scroll the selected text out off the screen.
        controller.jumpTo(1000);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)),
          findsNothing,
        );
        expect(
          find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)),
          findsNothing,
        );

        // Start copying.
        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.keyC, control: true),
        );

        final clipboardData = mockClipboard.clipboardData as Map<String, dynamic>;
        expect(clipboardData['text'], 'em 0It');
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.android,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      }),
    );

    // Regression test for https://github.com/flutter/flutter/issues/181169.
    // A scrollable only auto scrolls a selection that started inside it, so
    // neither axis of a two-dimensional scrollable may scroll a selection that
    // started above it.
    testWidgets(
      'selection dragged across a nested two-dimensional scrollable selects its built cells without scrolling it (issue 181169)',
      (WidgetTester tester) async {
        final outerController = ScrollController();
        addTearDown(outerController.dispose);
        final verticalController = ScrollController();
        addTearDown(verticalController.dispose);
        final horizontalController = ScrollController();
        addTearDown(horizontalController.dispose);
        await _pumpNestedScrollableFixture(
          tester,
          outerController: outerController,
          nested: _nestedTableView(
            verticalController: verticalController,
            horizontalController: horizontalController,
          ),
        );

        await _dragAcrossNestedScrollableAndExpectItSelected(tester);
        expect(outerController.offset, 0.0);
        expect(verticalController.offset, 0.0);
        expect(horizontalController.offset, 0.0);
        expect(tester.takeException(), isNull);
      },
    );

    // Regression test for https://github.com/flutter/flutter/issues/181169.
    // A scrollable only auto scrolls a selection that started inside it, so a
    // horizontal list at the start of a vertical list may not scroll a
    // selection that started above both.
    testWidgets(
      'selection dragged across a vertical list whose first child is a horizontal list selects their built items without scrolling them (issue 181169)',
      (WidgetTester tester) async {
        final outerController = ScrollController();
        addTearDown(outerController.dispose);
        final verticalController = ScrollController();
        addTearDown(verticalController.dispose);
        final horizontalController = ScrollController();
        addTearDown(horizontalController.dispose);
        await _pumpNestedScrollableFixture(
          tester,
          outerController: outerController,
          nested: _nestedListViews(
            verticalController: verticalController,
            horizontalController: horizontalController,
          ),
        );

        await _dragAcrossNestedScrollableAndExpectItSelected(tester);
        expect(outerController.offset, 0.0);
        expect(verticalController.offset, 0.0);
        expect(horizontalController.offset, 0.0);
        expect(tester.takeException(), isNull);
      },
    );

    // Regression test for https://github.com/flutter/flutter/issues/181169.
    // A scrollable only auto scrolls a selection that started inside it: when
    // a selection that started above a nested two-dimensional scrollable is
    // held past the bottom of the outer scrollable, only the outer one scrolls.
    testWidgets(
      'selection started above a nested two-dimensional scrollable auto scrolls only the outer scrollable (issue 181169)',
      (WidgetTester tester) async {
        final outerController = ScrollController();
        addTearDown(outerController.dispose);
        final verticalController = ScrollController();
        addTearDown(verticalController.dispose);
        final horizontalController = ScrollController();
        addTearDown(horizontalController.dispose);
        await _pumpNestedScrollableFixture(
          tester,
          outerController: outerController,
          nested: _nestedTableView(
            verticalController: verticalController,
            horizontalController: horizontalController,
          ),
        );

        final TestGesture gesture = await tester.startGesture(
          _insideText(tester, 'Above 8'),
          kind: ui.PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await tester.pump();
        // Over the table horizontally, 50 pixels past the bottom of the outer
        // scrollable.
        await gesture.moveTo(const Offset(300, 650));
        final List<_ScrollOffsets> samples = await _pumpUntilScrollingStops(
          tester,
          () => (
            outer: outerController.offset,
            vertical: verticalController.offset,
            horizontal: horizontalController.offset,
          ),
        );
        await gesture.up();
        await tester.pump();

        // The outer scrollable reached the content after the table.
        expect(outerController.offset, outerController.position.maxScrollExtent);
        expect(_paragraphOf(tester, 'Below 14').selections, <TextSelection>[
          const TextSelection(baseOffset: 0, extentOffset: 8),
        ]);
        // The table never scrolled.
        expect(samples.map((_ScrollOffsets s) => s.vertical), everyElement(0.0));
        expect(samples.map((_ScrollOffsets s) => s.horizontal), everyElement(0.0));
        expect(tester.takeException(), isNull);
      },
    );

    // Regression test for https://github.com/flutter/flutter/issues/181169.
    // A scrollable only auto scrolls a selection that started inside it, so a
    // horizontal list at the start of a vertical list may not scroll sideways
    // when a selection that started above both is held beside it. Unlike the
    // tests above this one never reaches the assertion in
    // EdgeDraggingAutoScroller: the wrong auto scroll is the only symptom, in
    // release builds too.
    testWidgets(
      'selection started above a vertical list does not auto scroll the horizontal list at its start (issue 181169)',
      (WidgetTester tester) async {
        final outerController = ScrollController();
        addTearDown(outerController.dispose);
        final verticalController = ScrollController();
        addTearDown(verticalController.dispose);
        final horizontalController = ScrollController();
        addTearDown(horizontalController.dispose);
        await _pumpNestedScrollableFixture(
          tester,
          outerController: outerController,
          nested: _nestedListViews(
            verticalController: verticalController,
            horizontalController: horizontalController,
            horizontalWidth: 400,
          ),
        );

        final TestGesture gesture = await tester.startGesture(
          _insideText(tester, 'Above 8'),
          kind: ui.PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await tester.pump();
        // Inside the vertical list, in the empty space to the right of the
        // horizontal list (which spans x 0..400, y 200..300).
        await gesture.moveTo(const Offset(600, 250));
        _ScrollOffsets read() => (
          outer: outerController.offset,
          vertical: verticalController.offset,
          horizontal: horizontalController.offset,
        );
        final List<_ScrollOffsets> samples = await _pumpUntilScrollingStops(tester, read);
        await gesture.up();
        samples.addAll(await _pumpUntilScrollingStops(tester, read));

        expect(samples.map((_ScrollOffsets s) => s.horizontal), everyElement(0.0));
        expect(outerController.offset, 0.0);
        expect(verticalController.offset, 0.0);
        expect(_paragraphOf(tester, 'Above 8').selections, <TextSelection>[
          const TextSelection(baseOffset: 2, extentOffset: 7),
        ]);
        expect(_paragraphOf(tester, 'Above 9').selections, <TextSelection>[
          const TextSelection(baseOffset: 0, extentOffset: 7),
        ]);
        _expectAllBuiltTextSelected(
          tester,
          find.byWidgetPredicate(
            (Widget widget) => widget is Scrollable && widget.axisDirection == AxisDirection.right,
          ),
        );
        expect(_paragraphOf(tester, 'V 0').selections, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    // Control: a selection that started inside a nested list still auto scrolls
    // that list to its end before the outer scrollable takes over.
    testWidgets(
      'selection started inside a nested vertical list auto scrolls it to its end before the outer scrollable',
      (WidgetTester tester) async {
        final outerController = ScrollController();
        addTearDown(outerController.dispose);
        final verticalController = ScrollController();
        addTearDown(verticalController.dispose);
        final horizontalController = ScrollController();
        addTearDown(horizontalController.dispose);
        await _pumpNestedScrollableFixture(
          tester,
          outerController: outerController,
          nested: _nestedListViews(
            verticalController: verticalController,
            horizontalController: horizontalController,
          ),
        );

        final TestGesture gesture = await tester.startGesture(
          _insideText(tester, 'V 3'),
          kind: ui.PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await tester.pump();
        // Past the bottom of both the nested list (y 500) and the outer
        // scrollable (y 600).
        await gesture.moveTo(const Offset(300, 650));
        // The horizontal list scrolls out of the nested list and is disposed,
        // so its offset is not tracked.
        final List<_ScrollOffsets> samples = await _pumpUntilScrollingStops(
          tester,
          () => (
            outer: outerController.offset,
            vertical: verticalController.offset,
            horizontal: null,
          ),
        );
        await gesture.up();
        await tester.pump();

        final double verticalEnd = verticalController.position.maxScrollExtent;
        expect(verticalController.offset, verticalEnd);
        expect(outerController.offset, outerController.position.maxScrollExtent);
        // The outer scrollable only moved once the nested list reached its end.
        expect(
          samples.where((_ScrollOffsets s) => s.outer > 0.0).map((_ScrollOffsets s) => s.vertical),
          everyElement(verticalEnd),
        );
        expect(tester.takeException(), isNull);
      },
    );

    // Control: a selection that started inside a nested two-dimensional
    // scrollable still auto scrolls it to its vertical end before the outer
    // scrollable takes over.
    testWidgets(
      'selection started inside a nested two-dimensional scrollable auto scrolls it to its end before the outer scrollable',
      (WidgetTester tester) async {
        final outerController = ScrollController();
        addTearDown(outerController.dispose);
        final verticalController = ScrollController();
        addTearDown(verticalController.dispose);
        final horizontalController = ScrollController();
        addTearDown(horizontalController.dispose);
        await _pumpNestedScrollableFixture(
          tester,
          outerController: outerController,
          nested: _nestedTableView(
            verticalController: verticalController,
            horizontalController: horizontalController,
            maxYIndex: 3,
          ),
        );

        final TestGesture gesture = await tester.startGesture(
          _insideText(tester, 'Cell r0 c1'),
          kind: ui.PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await tester.pump();
        // Over the table horizontally, past the bottom of both the table
        // (y 500) and the outer scrollable (y 600).
        await gesture.moveTo(const Offset(300, 650));
        final List<_ScrollOffsets> samples = await _pumpUntilScrollingStops(
          tester,
          () => (
            outer: outerController.offset,
            vertical: verticalController.offset,
            horizontal: horizontalController.offset,
          ),
        );
        await gesture.up();
        await tester.pump();

        final double verticalEnd = verticalController.position.maxScrollExtent;
        expect(verticalController.offset, verticalEnd);
        expect(outerController.offset, outerController.position.maxScrollExtent);
        // The outer scrollable only moved once the table reached its end.
        expect(
          samples.where((_ScrollOffsets s) => s.outer > 0.0).map((_ScrollOffsets s) => s.vertical),
          everyElement(verticalEnd),
        );
        expect(samples.map((_ScrollOffsets s) => s.horizontal), everyElement(0.0));

        // Clear the selection by clicking on empty space to the right of the
        // last 'Below' row. This works around RenderTwoDimensionalViewport.detach
        // asserting '_owner != null' on teardown when a kept-alive selected cell
        // has been scrolled away (see TODO: link issue).
        await tester.tapAt(const Offset(790, 590), kind: ui.PointerDeviceKind.mouse);
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
