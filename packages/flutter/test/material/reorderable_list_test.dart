// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('$ReorderableListView', () {
    const double itemHeight = 48.0;
    const List<String> originalListItems = const <String>['Item 1', 'Item 2', 'Item 3', 'Item 4'];
    List<String> listItems;

    void onReorder(int oldIndex, int newIndex) {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final String element = listItems.removeAt(oldIndex);
      listItems.insert(newIndex, element);
    }

    Widget listItemToWidget(String listItem) {
      return new SizedBox(
        key: new Key(listItem),
        height: itemHeight,
        width: itemHeight,
        child: new Text(listItem),
      );
    }

    Widget build({Widget header, Axis scrollDirection = Axis.vertical}) {
      return new MaterialApp(
        home: new SizedBox(
          height: itemHeight * 10,
          width: itemHeight * 10,
          child: new ReorderableListView(
            header: header,
            children: listItems.map(listItemToWidget).toList(),
            scrollDirection: scrollDirection,
            onReorder: onReorder,
          ),
        ),
      );
    }

    setUp(() {
      // Copy the original list into listItems.
      listItems = originalListItems.toList();
    });

    group('in vertical mode', () {
      testWidgets('reorders its contents only when a drag finishes', (WidgetTester tester) async {
        await tester.pumpWidget(build());
        expect(listItems, orderedEquals(originalListItems));
        final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('Item 1')));
        await tester.pump(kLongPressTimeout + kPressTimeout);
        expect(listItems, orderedEquals(originalListItems));
        await drag.moveTo(tester.getCenter(find.text('Item 4')));
        expect(listItems, orderedEquals(originalListItems));
        await drag.up();
        expect(listItems, orderedEquals(<String>['Item 2', 'Item 3', 'Item 1', 'Item 4']));
      });

      testWidgets('allows reordering from the very top to the very bottom', (WidgetTester tester) async {
        await tester.pumpWidget(build());
        expect(listItems, orderedEquals(originalListItems));
        await longPressDrag(
          tester,
          tester.getCenter(find.text('Item 1')),
          tester.getCenter(find.text('Item 4')) + const Offset(0.0, itemHeight * 2),
        );
        expect(listItems, orderedEquals(<String>['Item 2', 'Item 3', 'Item 4', 'Item 1']));
      });

      testWidgets('allows reordering from the very bottom to the very top', (WidgetTester tester) async {
        await tester.pumpWidget(build());
        expect(listItems, orderedEquals(originalListItems));
        await longPressDrag(
          tester,
          tester.getCenter(find.text('Item 4')),
          tester.getCenter(find.text('Item 1')),
        );
        expect(listItems, orderedEquals(<String>['Item 4', 'Item 1', 'Item 2', 'Item 3']));
      });

      testWidgets('allows reordering inside the middle of the widget', (WidgetTester tester) async {
        await tester.pumpWidget(build());
        expect(listItems, orderedEquals(originalListItems));
        await longPressDrag(
          tester,
          tester.getCenter(find.text('Item 3')),
          tester.getCenter(find.text('Item 2')),
        );
        expect(listItems, orderedEquals(<String>['Item 1', 'Item 3', 'Item 2', 'Item 4']));
      });

      testWidgets('properly reorders with a header', (WidgetTester tester) async {
        await tester.pumpWidget(build(header: const Text('Header Text')));
        expect(find.text('Header Text'), findsOneWidget);
        expect(listItems, orderedEquals(originalListItems));
        await longPressDrag(
          tester,
          tester.getCenter(find.text('Item 1')),
          tester.getCenter(find.text('Item 4')) + const Offset(0.0, itemHeight * 2),
        );
        expect(find.text('Header Text'), findsOneWidget);
        expect(listItems, orderedEquals(<String>['Item 2', 'Item 3', 'Item 4', 'Item 1']));
      });

      testWidgets('properly determines the vertical drop area extents', (WidgetTester tester) async {
        final Widget reorderableListView = new ReorderableListView(
          children: const <Widget>[
            const SizedBox(
              key: const Key('Normal item'),
              height: itemHeight,
              child: const Text('Normal item'),
            ),
            const SizedBox(
              key: const Key('Tall item'),
              height: itemHeight * 2,
              child: const Text('Tall item'),
            ),
            const SizedBox(
              key: const Key('Last item'),
              height: itemHeight,
              child: const Text('Last item'),
            )
          ],
          scrollDirection: Axis.vertical,
          onReorder: (int oldIndex, int newIndex) {},
        );
        await tester.pumpWidget(new MaterialApp(
          home: new SizedBox(
            height: itemHeight * 10,
            child: reorderableListView,
          ),
        ));

        Element getContentElement() {
          final SingleChildScrollView listScrollView = find.byType(SingleChildScrollView).evaluate().first.widget;
          final Widget scrollContents = listScrollView.child;
          final Element contentElement = find.byElementPredicate((Element element) => element.widget == scrollContents).evaluate().first;
          return contentElement;
        }

        const double kNonDraggingListHeight = 292.0;
        // The list view pads the drop area by 8dp.
        const double kDraggingListHeight = 300.0;
        // Drag a normal text item
        expect(getContentElement().size.height, kNonDraggingListHeight);
        TestGesture drag = await tester.startGesture(tester.getCenter(find.text('Normal item')));
        await tester.pump(kLongPressTimeout + kPressTimeout);
        await tester.pumpAndSettle();
        expect(getContentElement().size.height, kDraggingListHeight);

        // Move it
        await drag.moveTo(tester.getCenter(find.text('Last item')));
        await tester.pumpAndSettle();
        expect(getContentElement().size.height, kDraggingListHeight);

        // Drop it
        await drag.up();
        await tester.pumpAndSettle();
        expect(getContentElement().size.height, kNonDraggingListHeight);

        // Drag a tall item
        drag = await tester.startGesture(tester.getCenter(find.text('Tall item')));
        await tester.pump(kLongPressTimeout + kPressTimeout);
        await tester.pumpAndSettle();
        expect(getContentElement().size.height, kDraggingListHeight);

        // Move it
        await drag.moveTo(tester.getCenter(find.text('Last item')));
        await tester.pumpAndSettle();
        expect(getContentElement().size.height, kDraggingListHeight);

        // Drop it
        await drag.up();
        await tester.pumpAndSettle();
        expect(getContentElement().size.height, kNonDraggingListHeight);
      });

      testWidgets('Preserves children states when the list parent changes the order', (WidgetTester tester) async {
        _StatefulState findState(Key key) {
          return find.byElementPredicate((Element element) => element.ancestorWidgetOfExactType(_Stateful)?.key == key)
              .evaluate()
              .first
              .ancestorStateOfType(const TypeMatcher<_StatefulState>());
        }
        await tester.pumpWidget(new MaterialApp(
          home: new ReorderableListView(
            children: <Widget>[
              new _Stateful(key: const Key('A')),
              new _Stateful(key: const Key('B')),
              new _Stateful(key: const Key('C')),
            ],
            onReorder: (int oldIndex, int newIndex) {},
          ),
        ));
        await tester.tap(find.byKey(const Key('A')));
        await tester.pumpAndSettle();
        // Only the 'A' widget should be checked.
        expect(findState(const Key('A')).checked, true);
        expect(findState(const Key('B')).checked, false);
        expect(findState(const Key('C')).checked, false);

        await tester.pumpWidget(new MaterialApp(
          home: new ReorderableListView(
            children: <Widget>[
              new _Stateful(key: const Key('B')),
              new _Stateful(key: const Key('C')),
              new _Stateful(key: const Key('A')),
            ],
            onReorder: (int oldIndex, int newIndex) {},
          ),
        ));
        // Only the 'A' widget should be checked.
        expect(findState(const Key('B')).checked, false);
        expect(findState(const Key('C')).checked, false);
        expect(findState(const Key('A')).checked, true);
      });
    });

    group('in horizontal mode', () {
      testWidgets('allows reordering from the very top to the very bottom', (WidgetTester tester) async {
        await tester.pumpWidget(build(scrollDirection: Axis.horizontal));
        expect(listItems, orderedEquals(originalListItems));
        await longPressDrag(
          tester,
          tester.getCenter(find.text('Item 1')),
          tester.getCenter(find.text('Item 4')) + const Offset(itemHeight * 2, 0.0),
        );
        expect(listItems, orderedEquals(<String>['Item 2', 'Item 3', 'Item 4', 'Item 1']));
      });

      testWidgets('allows reordering from the very bottom to the very top', (WidgetTester tester) async {
        await tester.pumpWidget(build(scrollDirection: Axis.horizontal));
        expect(listItems, orderedEquals(originalListItems));
        await longPressDrag(
          tester,
          tester.getCenter(find.text('Item 4')),
          tester.getCenter(find.text('Item 1')),
        );
        expect(listItems, orderedEquals(<String>['Item 4', 'Item 1', 'Item 2', 'Item 3']));
      });

      testWidgets('allows reordering inside the middle of the widget', (WidgetTester tester) async {
        await tester.pumpWidget(build(scrollDirection: Axis.horizontal));
        expect(listItems, orderedEquals(originalListItems));
        await longPressDrag(
          tester,
          tester.getCenter(find.text('Item 3')),
          tester.getCenter(find.text('Item 2')),
        );
        expect(listItems, orderedEquals(<String>['Item 1', 'Item 3', 'Item 2', 'Item 4']));
      });

      testWidgets('properly reorders with a header', (WidgetTester tester) async {
        await tester.pumpWidget(build(header: const Text('Header Text'), scrollDirection: Axis.horizontal));
        expect(find.text('Header Text'), findsOneWidget);
        expect(listItems, orderedEquals(originalListItems));
        await longPressDrag(
          tester,
          tester.getCenter(find.text('Item 1')),
          tester.getCenter(find.text('Item 4')) + const Offset(itemHeight * 2, 0.0),
        );
        await tester.pumpAndSettle();
        expect(find.text('Header Text'), findsOneWidget);
        expect(listItems, orderedEquals(<String>['Item 2', 'Item 3', 'Item 4', 'Item 1']));

        await tester.pumpWidget(build(header: const Text('Header Text'), scrollDirection: Axis.horizontal));
        await longPressDrag(
          tester,
          tester.getCenter(find.text('Item 4')),
          tester.getCenter(find.text('Item 3')),
        );
        expect(find.text('Header Text'), findsOneWidget);
        expect(listItems, orderedEquals(<String>['Item 2', 'Item 4', 'Item 3', 'Item 1']));
      });

      testWidgets('properly determines the horizontal drop area extents', (WidgetTester tester) async {
        final Widget reorderableListView = new ReorderableListView(
          children: const <Widget>[
            const SizedBox(
              key: const Key('Normal item'),
              width: itemHeight,
              child: const Text('Normal item'),
            ),
            const SizedBox(
              key: const Key('Tall item'),
              width: itemHeight * 2,
              child: const Text('Tall item'),
            ),
            const SizedBox(
              key: const Key('Last item'),
              width: itemHeight,
              child: const Text('Last item'),
            )
          ],
          scrollDirection: Axis.horizontal,
          onReorder: (int oldIndex, int newIndex) {},
        );
        await tester.pumpWidget(new MaterialApp(
          home: new SizedBox(
            width: itemHeight * 10,
            child: reorderableListView,
          ),
        ));

        Element getContentElement() {
          final SingleChildScrollView listScrollView = find.byType(SingleChildScrollView).evaluate().first.widget;
          final Widget scrollContents = listScrollView.child;
          final Element contentElement = find.byElementPredicate((Element element) => element.widget == scrollContents).evaluate().first;
          return contentElement;
        }

        const double kNonDraggingListWidth = 292.0;
        // The list view pads the drop area by 8dp.
        const double kDraggingListWidth = 300.0;
        // Drag a normal text item
        expect(getContentElement().size.width, kNonDraggingListWidth);
        TestGesture drag = await tester.startGesture(tester.getCenter(find.text('Normal item')));
        await tester.pump(kLongPressTimeout + kPressTimeout);
        await tester.pumpAndSettle();
        expect(getContentElement().size.width, kDraggingListWidth);

        // Move it
        await drag.moveTo(tester.getCenter(find.text('Last item')));
        await tester.pumpAndSettle();
        expect(getContentElement().size.width, kDraggingListWidth);

        // Drop it
        await drag.up();
        await tester.pumpAndSettle();
        expect(getContentElement().size.width, kNonDraggingListWidth);

        // Drag a tall item
        drag = await tester.startGesture(tester.getCenter(find.text('Tall item')));
        await tester.pump(kLongPressTimeout + kPressTimeout);
        await tester.pumpAndSettle();
        expect(getContentElement().size.width, kDraggingListWidth);

        // Move it
        await drag.moveTo(tester.getCenter(find.text('Last item')));
        await tester.pumpAndSettle();
        expect(getContentElement().size.width, kDraggingListWidth);

        // Drop it
        await drag.up();
        await tester.pumpAndSettle();
        expect(getContentElement().size.width, kNonDraggingListWidth);
      });


      testWidgets('Preserves children states when the list parent changes the order', (WidgetTester tester) async {
        _StatefulState findState(Key key) {
          return find.byElementPredicate((Element element) => element.ancestorWidgetOfExactType(_Stateful)?.key == key)
              .evaluate()
              .first
              .ancestorStateOfType(const TypeMatcher<_StatefulState>());
        }
        await tester.pumpWidget(new MaterialApp(
          home: new ReorderableListView(
            children: <Widget>[
              new _Stateful(key: const Key('A')),
              new _Stateful(key: const Key('B')),
              new _Stateful(key: const Key('C')),
            ],
            onReorder: (int oldIndex, int newIndex) {},
            scrollDirection: Axis.horizontal,
          ),
        ));
        await tester.tap(find.byKey(const Key('A')));
        await tester.pumpAndSettle();
        // Only the 'A' widget should be checked.
        expect(findState(const Key('A')).checked, true);
        expect(findState(const Key('B')).checked, false);
        expect(findState(const Key('C')).checked, false);

        await tester.pumpWidget(new MaterialApp(
          home: new ReorderableListView(
            children: <Widget>[
              new _Stateful(key: const Key('B')),
              new _Stateful(key: const Key('C')),
              new _Stateful(key: const Key('A')),
            ],
            onReorder: (int oldIndex, int newIndex) {},
            scrollDirection: Axis.horizontal,
          ),
        ));
        // Only the 'A' widget should be checked.
        expect(findState(const Key('B')).checked, false);
        expect(findState(const Key('C')).checked, false);
        expect(findState(const Key('A')).checked, true);
      });
    });

    // TODO(djshuckerow): figure out how to write a test for scrolling the list.
  });
}

Future<void> longPressDrag(WidgetTester tester, Offset start, Offset end) async {
  final TestGesture drag = await tester.startGesture(start);
  await tester.pump(kLongPressTimeout + kPressTimeout);
  await drag.moveTo(end);
  await tester.pump(kPressTimeout);
  await drag.up();
}

class _Stateful extends StatefulWidget {
  // Ignoring the preference for const constructors because we want to test with regular non-const instances.
  // ignore:prefer_const_constructors
  // ignore:prefer_const_constructors_in_immutables
  _Stateful({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new _StatefulState();
}

class _StatefulState extends State<_Stateful> {
  bool checked = false;

  @override
  Widget build(BuildContext context) {
    return new Container(
      width: 48.0,
      height: 48.0,
      child: new Material(
        child: new Checkbox(
          value: checked,
          onChanged: (bool newValue) => checked = newValue,
        ),
      ),
    );
  }
}