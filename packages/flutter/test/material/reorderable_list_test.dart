import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('$ReorderableListView', () {
    const double itemHeight = 48.0;
    const List<String> originalListItems = const <String>['Item 1', 'Item 2', 'Item 3', 'Item 4'];
    List<String> listItems;

    void onSwap(int oldIndex, int newIndex) {
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

    Widget build({Axis scrollDirection = Axis.vertical}) {
      return new MaterialApp(
        home: new SizedBox(
          height: itemHeight * 10, 
          child: new ReorderableListView(
            children: listItems.map(listItemToWidget).toList(),
            scrollDirection: scrollDirection,
            onSwap: onSwap,
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
    });

    // TODO(djshuckerow): figure out how to write a test for scrolling the list.
  });
}

Future<void> longPressDrag(WidgetTester tester, Offset start, Offset end) async {
  final TestGesture drag = await tester.startGesture(start);
  await tester.pump(kLongPressTimeout + kPressTimeout);
  await drag.moveTo(end);
  await drag.up();
}