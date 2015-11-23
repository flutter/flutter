// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

const double itemExtent = 100.0;
ScrollDirection scrollDirection = ScrollDirection.vertical;
DismissDirection dismissDirection = DismissDirection.horizontal;
List<int> dismissedItems = <int>[];

void handleOnResized(item) {
  expect(dismissedItems.contains(item), isFalse);
}

void handleOnDismissed(item) {
  expect(dismissedItems.contains(item), isFalse);
  dismissedItems.add(item);
}

Widget buildDismissableItem(BuildContext context, int item, int index) {
  return new Dismissable(
    key: new ValueKey<int>(item),
    direction: dismissDirection,
    onDismissed: () { handleOnDismissed(item); },
    onResized: () { handleOnResized(item); },
    child: new Container(
      width: itemExtent,
      height: itemExtent,
      child: new Text(item.toString())
    )
  );
}

Widget widgetBuilder() {
  return new Container(
    padding: const EdgeDims.all(10.0),
    child: new ScrollableList<int>(
      items: [0, 1, 2, 3, 4].where((int i) => !dismissedItems.contains(i)).toList(),
      itemBuilder: buildDismissableItem,
      scrollDirection: scrollDirection,
      itemExtent: itemExtent
    )
  );
}

void dismissElement(WidgetTester tester, Element itemElement, { DismissDirection gestureDirection }) {
  assert(itemElement != null);
  assert(gestureDirection != DismissDirection.horizontal);
  assert(gestureDirection != DismissDirection.vertical);

  Point downLocation;
  Point upLocation;
  switch(gestureDirection) {
    case DismissDirection.left:
      // Note: getTopRight() returns a point that's just beyond
      // itemWidget's right edge and outside the Dismissable event
      // listener's bounds.
      downLocation = tester.getTopRight(itemElement) + const Offset(-0.1, 0.0);
      upLocation = tester.getTopLeft(itemElement);
      break;
    case DismissDirection.right:
      downLocation = tester.getTopLeft(itemElement);
      upLocation = tester.getTopRight(itemElement);
      break;
    case DismissDirection.up:
      // Note: getBottomLeft() returns a point that's just below
      // itemWidget's bottom edge and outside the Dismissable event
      // listener's bounds.
      downLocation = tester.getBottomLeft(itemElement) + const Offset(0.0, -0.1);
      upLocation = tester.getTopLeft(itemElement);
      break;
    case DismissDirection.down:
      downLocation = tester.getTopLeft(itemElement);
      upLocation = tester.getBottomLeft(itemElement);
      break;
    default:
      fail("unsupported gestureDirection");
  }

  TestPointer pointer = new TestPointer(5);
  tester.dispatchEvent(pointer.down(downLocation), downLocation);
  tester.dispatchEvent(pointer.move(upLocation), downLocation);
  tester.dispatchEvent(pointer.up(), downLocation);
}

void dismissItem(WidgetTester tester, int item, { DismissDirection gestureDirection }) {
  assert(gestureDirection != DismissDirection.horizontal);
  assert(gestureDirection != DismissDirection.vertical);

  Element itemElement = tester.findText(item.toString());
  expect(itemElement, isNotNull);

  dismissElement(tester, itemElement, gestureDirection: gestureDirection);

  tester.pumpWidget(widgetBuilder()); // start the resize animation
  tester.pumpWidget(widgetBuilder(), const Duration(seconds: 1)); // finish the resize animation
  tester.pumpWidget(widgetBuilder(), const Duration(seconds: 1)); // dismiss
}

class Test1215DismissableComponent extends StatelessComponent {
  Test1215DismissableComponent(this.text);
  final String text;
  Widget build(BuildContext context) {
    return new Dismissable(
      child: new AspectRatio(
        aspectRatio: 1.0,
        child: new Text(this.text)
      )
    );
  }
}

void main() {
  test('Horizontal drag triggers dismiss scrollDirection=vertical', () {
    testWidgets((WidgetTester tester) {
      scrollDirection = ScrollDirection.vertical;
      dismissDirection = DismissDirection.horizontal;
      dismissedItems = <int>[];

      tester.pumpWidget(widgetBuilder());
      expect(dismissedItems, isEmpty);

      dismissItem(tester, 0, gestureDirection: DismissDirection.right);
      expect(tester.findText('0'), isNull);
      expect(dismissedItems, equals([0]));

      dismissItem(tester, 1, gestureDirection: DismissDirection.left);
      expect(tester.findText('1'), isNull);
      expect(dismissedItems, equals([0, 1]));
    });
  });

  test('Vertical drag triggers dismiss scrollDirection=horizontal', () {
    testWidgets((WidgetTester tester) {
      scrollDirection = ScrollDirection.horizontal;
      dismissDirection = DismissDirection.vertical;
      dismissedItems = <int>[];

      tester.pumpWidget(widgetBuilder());
      expect(dismissedItems, isEmpty);

      dismissItem(tester, 0, gestureDirection: DismissDirection.up);
      expect(tester.findText('0'), isNull);
      expect(dismissedItems, equals([0]));

      dismissItem(tester, 1, gestureDirection: DismissDirection.down);
      expect(tester.findText('1'), isNull);
      expect(dismissedItems, equals([0, 1]));
    });
  });

  test('drag-left with DismissDirection.left triggers dismiss', () {
    testWidgets((WidgetTester tester) {
      scrollDirection = ScrollDirection.vertical;
      dismissDirection = DismissDirection.left;
      dismissedItems = <int>[];

      tester.pumpWidget(widgetBuilder());
      expect(dismissedItems, isEmpty);

      dismissItem(tester, 0, gestureDirection: DismissDirection.right);
      expect(tester.findText('0'), isNotNull);
      expect(dismissedItems, isEmpty);

      dismissItem(tester, 0, gestureDirection: DismissDirection.left);
      expect(tester.findText('0'), isNull);
      expect(dismissedItems, equals([0]));
    });
  });

  test('drag-right with DismissDirection.right triggers dismiss', () {
    testWidgets((WidgetTester tester) {
      scrollDirection = ScrollDirection.vertical;
      dismissDirection = DismissDirection.right;
      dismissedItems = <int>[];

      tester.pumpWidget(widgetBuilder());
      expect(dismissedItems, isEmpty);

      dismissItem(tester, 0, gestureDirection: DismissDirection.left);
      expect(tester.findText('0'), isNotNull);
      expect(dismissedItems, isEmpty);

      dismissItem(tester, 0, gestureDirection: DismissDirection.right);
      expect(tester.findText('0'), isNull);
      expect(dismissedItems, equals([0]));
    });
  });

  test('drag-up with DismissDirection.up triggers dismiss', () {
    testWidgets((WidgetTester tester) {
      scrollDirection = ScrollDirection.horizontal;
      dismissDirection = DismissDirection.up;
      dismissedItems = <int>[];

      tester.pumpWidget(widgetBuilder());
      expect(dismissedItems, isEmpty);

      dismissItem(tester, 0, gestureDirection: DismissDirection.down);
      expect(tester.findText('0'), isNotNull);
      expect(dismissedItems, isEmpty);

      dismissItem(tester, 0, gestureDirection: DismissDirection.up);
      expect(tester.findText('0'), isNull);
      expect(dismissedItems, equals([0]));
    });
  });

  test('drag-down with DismissDirection.down triggers dismiss', () {
    testWidgets((WidgetTester tester) {
      scrollDirection = ScrollDirection.horizontal;
      dismissDirection = DismissDirection.down;
      dismissedItems = <int>[];

      tester.pumpWidget(widgetBuilder());
      expect(dismissedItems, isEmpty);

      dismissItem(tester, 0, gestureDirection: DismissDirection.up);
      expect(tester.findText('0'), isNotNull);
      expect(dismissedItems, isEmpty);

      dismissItem(tester, 0, gestureDirection: DismissDirection.down);
      expect(tester.findText('0'), isNull);
      expect(dismissedItems, equals([0]));
    });
  });

  // This is a regression test for
  // https://github.com/domokit/sky_engine/issues/1068
  test('Verify that drag-move events do not assert', () {
    testWidgets((WidgetTester tester) {
      scrollDirection = ScrollDirection.horizontal;
      dismissDirection = DismissDirection.down;
      dismissedItems = <int>[];

      tester.pumpWidget(widgetBuilder());
      Element itemElement = tester.findText('0');

      TestPointer pointer = new TestPointer(5);
      Point location = tester.getTopLeft(itemElement);
      Offset offset = new Offset(0.0, 5.0);
      tester.dispatchEvent(pointer.down(location), location);
      tester.dispatchEvent(pointer.move(location + offset), location);
      tester.pumpWidget(widgetBuilder());
      tester.dispatchEvent(pointer.move(location + (offset * 2.0)), location);
      tester.pumpWidget(widgetBuilder());
      tester.dispatchEvent(pointer.move(location + (offset * 3.0)), location);
      tester.pumpWidget(widgetBuilder());
      tester.dispatchEvent(pointer.move(location + (offset * 4.0)), location);
      tester.pumpWidget(widgetBuilder());
    });
  });

  // This one is for
  // https://github.com/flutter/engine/issues/1215
  test('dismissing bottom then top (smoketest)', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Center(
        child: new Container(
          width: 100.0,
          height: 1000.0,
          child: new Column(<Widget>[
            new Test1215DismissableComponent('1'),
            new Test1215DismissableComponent('2')
          ])
        )
      ));
      expect(tester.findText('1'), isNotNull);
      expect(tester.findText('2'), isNotNull);
      dismissElement(tester, tester.findText('2'), gestureDirection: DismissDirection.right);
      tester.pump(new Duration(seconds: 1));
      expect(tester.findText('1'), isNotNull);
      expect(tester.findText('2'), isNull);
      dismissElement(tester, tester.findText('1'), gestureDirection: DismissDirection.right);
      tester.pump(new Duration(seconds: 1));
      expect(tester.findText('1'), isNull);
      expect(tester.findText('2'), isNull);
    });
  });
}
