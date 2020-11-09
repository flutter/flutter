// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('$ReorderableListView', () {
    const double itemHeight = 48.0;
    const List<String> originalListItems = <String>['Item 1', 'Item 2', 'Item 3', 'Item 4'];
    List<String> listItems;

    void onReorder(int oldIndex, int newIndex) {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final String element = listItems.removeAt(oldIndex);
      listItems.insert(newIndex, element);
    }

    Widget listItemToWidget(String listItem) {
      return SizedBox(
        key: Key(listItem),
        height: itemHeight,
        width: itemHeight,
        child: Text(listItem),
      );
    }

    Widget build({ Widget header, Axis scrollDirection = Axis.vertical, TextDirection textDirection = TextDirection.ltr }) {
      return MaterialApp(
        home: Directionality(
          textDirection: textDirection,
          child: SizedBox(
            height: itemHeight * 10,
            width: itemHeight * 10,
            child: ReorderableListView(
              header: header,
              children: listItems.map<Widget>(listItemToWidget).toList(),
              scrollDirection: scrollDirection,
              onReorder: onReorder,
            ),
          ),
        ),
      );
    }

    setUp(() {
      // Copy the original list into listItems.
      listItems = originalListItems.toList();
    });

    group('in vertical mode', () {
      testWidgets('reorder is not triggered when children length is less or equals to 1', (WidgetTester tester) async {
        bool onReorderWasCalled = false;
        final List<String> currentListItems = listItems.take(1).toList();
        final ReorderableListView reorderableListView = ReorderableListView(
          header: const Text('Header'),
          children: currentListItems.map<Widget>(listItemToWidget).toList(),
          scrollDirection: Axis.vertical,
          onReorder: (_, __) => onReorderWasCalled = true,
        );
        final List<String> currentOriginalListItems = originalListItems.take(1).toList();
        await tester.pumpWidget(MaterialApp(
          home: SizedBox(
            height: itemHeight * 10,
            child: reorderableListView,
          ),
        ));
        expect(currentListItems, orderedEquals(currentOriginalListItems));
        final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('Item 1')));
        await tester.pump(kLongPressTimeout + kPressTimeout);
        expect(currentListItems, orderedEquals(currentOriginalListItems));
        await drag.moveTo(tester.getBottomLeft(find.text('Item 1')) * 2);
        expect(currentListItems, orderedEquals(currentOriginalListItems));
        await drag.up();
        expect(onReorderWasCalled, false);
        expect(currentListItems, orderedEquals(<String>['Item 1']));
      });

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
        final Widget reorderableListView = ReorderableListView(
          children: const <Widget>[
            SizedBox(
              key: Key('Normal item'),
              height: itemHeight,
              child: Text('Normal item'),
            ),
            SizedBox(
              key: Key('Tall item'),
              height: itemHeight * 2,
              child: Text('Tall item'),
            ),
            SizedBox(
              key: Key('Last item'),
              height: itemHeight,
              child: Text('Last item'),
            ),
          ],
          scrollDirection: Axis.vertical,
          onReorder: (int oldIndex, int newIndex) { },
        );
        await tester.pumpWidget(MaterialApp(
          home: SizedBox(
            height: itemHeight * 10,
            child: reorderableListView,
          ),
        ));

        Element getContentElement() {
          final SingleChildScrollView listScrollView = tester.widget(find.byType(SingleChildScrollView));
          final Widget scrollContents = listScrollView.child;
          final Element contentElement = tester.element(find.byElementPredicate((Element element) => element.widget == scrollContents));
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
          return find.byElementPredicate((Element element) => element.findAncestorWidgetOfExactType<_Stateful>()?.key == key)
              .evaluate()
              .first
              .findAncestorStateOfType<_StatefulState>();
        }
        await tester.pumpWidget(MaterialApp(
          home: ReorderableListView(
            children: <Widget>[
              _Stateful(key: const Key('A')),
              _Stateful(key: const Key('B')),
              _Stateful(key: const Key('C')),
            ],
            onReorder: (int oldIndex, int newIndex) { },
          ),
        ));
        await tester.tap(find.byKey(const Key('A')));
        await tester.pumpAndSettle();
        // Only the 'A' widget should be checked.
        expect(findState(const Key('A')).checked, true);
        expect(findState(const Key('B')).checked, false);
        expect(findState(const Key('C')).checked, false);

        await tester.pumpWidget(MaterialApp(
          home: ReorderableListView(
            children: <Widget>[
              _Stateful(key: const Key('B')),
              _Stateful(key: const Key('C')),
              _Stateful(key: const Key('A')),
            ],
            onReorder: (int oldIndex, int newIndex) { },
          ),
        ));
        // Only the 'A' widget should be checked.
        expect(findState(const Key('B')).checked, false);
        expect(findState(const Key('C')).checked, false);
        expect(findState(const Key('A')).checked, true);
      });

      testWidgets('Preserves children states when rebuilt', (WidgetTester tester) async {
        const Key firstBox = Key('key');
        Widget build() {
          return MaterialApp(
            home: Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox(
                width: 100,
                height: 100,
                child: ReorderableListView(
                  scrollDirection: Axis.vertical,
                  children: const <Widget>[
                    SizedBox(key: firstBox, width: 10, height: 10),
                  ],
                  onReorder: (_, __) {},
                ),
              ),
            ),
          );
        }

        // When the widget is rebuilt, the state of child should be consistent.
        await tester.pumpWidget(build());
        final Element e0 = tester.element(find.byKey(firstBox));
        await tester.pumpWidget(build());
        final Element e1 = tester.element(find.byKey(firstBox));
        expect(e0, equals(e1));
      });

      testWidgets('Uses the PrimaryScrollController when available', (WidgetTester tester) async {
        final ScrollController primary = ScrollController();
        final Widget reorderableList = ReorderableListView(
          children: const <Widget>[
            SizedBox(width: 100.0, height: 100.0, child: Text('C'), key: Key('C')),
            SizedBox(width: 100.0, height: 100.0, child: Text('B'), key: Key('B')),
            SizedBox(width: 100.0, height: 100.0, child: Text('A'), key: Key('A')),
          ],
          onReorder: (int oldIndex, int newIndex) { },
        );

        Widget buildWithScrollController(ScrollController controller) {
          return MaterialApp(
            home: PrimaryScrollController(
              controller: controller,
              child: SizedBox(
                height: 100.0,
                width: 100.0,
                child: reorderableList,
              ),
            ),
          );
        }

        await tester.pumpWidget(buildWithScrollController(primary));
        SingleChildScrollView scrollView = tester.widget(
          find.byType(SingleChildScrollView),
        );
        expect(scrollView.controller, primary);

        // Now try changing the primary scroll controller and checking that the scroll view gets updated.
        final ScrollController primary2 = ScrollController();
        await tester.pumpWidget(buildWithScrollController(primary2));
        scrollView = tester.widget(
          find.byType(SingleChildScrollView),
        );
        expect(scrollView.controller, primary2);
      });

      testWidgets('Test custom ScrollController behavior when set', (WidgetTester tester) async {
        const Key firstBox = Key('C');
        const Key secondBox = Key('B');
        const Key thirdBox = Key('A');
        final ScrollController customController = ScrollController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: ReorderableListView(
                  scrollController: customController,
                  onReorder: (int oldIndex, int newIndex) { },
                  children: const <Widget>[
                    SizedBox(width: 100.0, height: 100.0, child: Text('C'), key: firstBox),
                    SizedBox(width: 100.0, height: 100.0, child: Text('B'), key: secondBox),
                    SizedBox(width: 100.0, height: 100.0, child: Text('A'), key: thirdBox),
                  ],
                ),
              ),
            ),
          ),
        );

        // Check initial scroll offset of first list item relative to
        // the offset of the list view.
        customController.animateTo(
          40.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.linear
        );
        await tester.pumpAndSettle();
        Offset listViewTopLeft = tester.getTopLeft(
          find.byType(ReorderableListView),
        );
        Offset firstBoxTopLeft = tester.getTopLeft(
          find.byKey(firstBox)
        );
        expect(firstBoxTopLeft.dy, listViewTopLeft.dy - 40.0);

        // Drag the UI to see if the scroll controller updates accordingly
        await tester.drag(
          find.text('B'),
          const Offset(0.0, -100.0),
        );
        listViewTopLeft = tester.getTopLeft(
          find.byType(ReorderableListView),
        );
        firstBoxTopLeft = tester.getTopLeft(
          find.byKey(firstBox),
        );
        // Initial scroll controller offset: 40.0
        // Drag UI by 100.0 upwards vertically
        // First 20.0 px always ignored, so scroll offset is only
        // shifted by 80.0.
        // Final offset: 40.0 + 80.0 = 120.0
        expect(customController.offset, 120.0);
      });

      testWidgets('Still builds when no PrimaryScrollController is available', (WidgetTester tester) async {
        final Widget reorderableList = ReorderableListView(
          children: const <Widget>[
            SizedBox(width: 100.0, height: 100.0, child: Text('C'), key: Key('C')),
            SizedBox(width: 100.0, height: 100.0, child: Text('B'), key: Key('B')),
            SizedBox(width: 100.0, height: 100.0, child: Text('A'), key: Key('A')),
          ],
          onReorder: (int oldIndex, int newIndex) { },
        );
        final Widget boilerplate = Localizations(
          locale: const Locale('en'),
          delegates: const <LocalizationsDelegate<dynamic>>[
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          child:SizedBox(
            width: 100.0,
            height: 100.0,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: reorderableList,
            ),
          ),
        );
        try {
          await tester.pumpWidget(boilerplate);
        } catch (e) {
          fail('Expected no error, but got $e');
        }
        // Expect that we have build *a* ScrollController for use in the view.
        final SingleChildScrollView scrollView = tester.widget(
          find.byType(SingleChildScrollView),
        );
        expect(scrollView.controller, isNotNull);
      });

      group('Accessibility (a11y/Semantics)', () {
        Map<CustomSemanticsAction, VoidCallback> getSemanticsActions(int index) {
          final Semantics semantics = find.ancestor(
            of: find.byKey(Key(listItems[index])),
            matching: find.byType(Semantics),
          ).evaluate().first.widget as Semantics;
          return semantics.properties.customSemanticsActions;
        }

        const CustomSemanticsAction moveToStart = CustomSemanticsAction(label: 'Move to the start');
        const CustomSemanticsAction moveToEnd = CustomSemanticsAction(label: 'Move to the end');
        const CustomSemanticsAction moveUp = CustomSemanticsAction(label: 'Move up');
        const CustomSemanticsAction moveDown = CustomSemanticsAction(label: 'Move down');

        testWidgets('Provides the correct accessibility actions in LTR and RTL modes', (WidgetTester tester) async {
          // The a11y actions for a vertical list are the same in LTR and RTL modes.
          final SemanticsHandle handle = tester.ensureSemantics();
          for (final TextDirection direction in TextDirection.values) {
            await tester.pumpWidget(build());

            // The first item can be moved down or to the end.
            final Map<CustomSemanticsAction, VoidCallback> firstSemanticsActions = getSemanticsActions(0);
            expect(firstSemanticsActions.length, 2, reason: 'The first list item should have 2 custom actions with $direction.');
            expect(firstSemanticsActions.containsKey(moveToStart), false, reason: 'The first item cannot `Move to the start` with $direction.');
            expect(firstSemanticsActions.containsKey(moveUp), false, reason: 'The first item cannot `Move up` with $direction.');
            expect(firstSemanticsActions.containsKey(moveDown), true, reason: 'The first item should be able to `Move down` with $direction.');
            expect(firstSemanticsActions.containsKey(moveToEnd), true, reason: 'The first item should be able to `Move to the end` with $direction.');

            // Items in the middle can be moved to the start, end, up or down.
            for (int i = 1; i < listItems.length - 1; i += 1) {
              final Map<CustomSemanticsAction, VoidCallback> ithSemanticsActions = getSemanticsActions(i);
              expect(ithSemanticsActions.length, 4, reason: 'List item $i should have 4 custom actions with $direction.');
              expect(ithSemanticsActions.containsKey(moveToStart), true, reason: 'List item $i should be able to `Move to the start` with $direction.');
              expect(ithSemanticsActions.containsKey(moveUp), true, reason: 'List item $i should be able to `Move up` with $direction.');
              expect(ithSemanticsActions.containsKey(moveDown), true, reason: 'List item $i should be able to `Move down` with $direction.');
              expect(ithSemanticsActions.containsKey(moveToEnd), true, reason: 'List item $i should be able to `Move to the end` with $direction.');
            }

            // The last item can be moved up or to the start.
            final Map<CustomSemanticsAction, VoidCallback> lastSemanticsActions = getSemanticsActions(listItems.length - 1);
            expect(lastSemanticsActions.length, 2, reason: 'The last list item should have 2 custom actions with $direction.');
            expect(lastSemanticsActions.containsKey(moveToStart), true, reason: 'The last item should be able to `Move to the start` with $direction.');
            expect(lastSemanticsActions.containsKey(moveUp), true, reason: 'The last item should be able to `Move up` with $direction.');
            expect(lastSemanticsActions.containsKey(moveDown), false, reason: 'The last item cannot `Move down` with $direction.');
            expect(lastSemanticsActions.containsKey(moveToEnd), false, reason: 'The last item cannot `Move to the end` with $direction.');
          }
          handle.dispose();
        });

        testWidgets('First item accessibility (a11y) actions work', (WidgetTester tester) async {
          final SemanticsHandle handle = tester.ensureSemantics();
          expect(listItems, orderedEquals(originalListItems));

          // Test out move to end: move Item 1 to the end of the list.
          await tester.pumpWidget(build());
          Map<CustomSemanticsAction, VoidCallback> firstSemanticsActions = getSemanticsActions(0);
          firstSemanticsActions[moveToEnd]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 2', 'Item 3', 'Item 4', 'Item 1']));

          // Test out move after: move Item 2 (the current first item) one space down.
          await tester.pumpWidget(build());
          firstSemanticsActions = getSemanticsActions(0);
          firstSemanticsActions[moveDown]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 3', 'Item 2', 'Item 4', 'Item 1']));

          handle.dispose();
        });

        testWidgets('Middle item accessibility (a11y) actions work', (WidgetTester tester) async {
          final SemanticsHandle handle = tester.ensureSemantics();
          expect(listItems, orderedEquals(originalListItems));

          // Test out move to end: move Item 2 to the end of the list.
          await tester.pumpWidget(build());
          Map<CustomSemanticsAction, VoidCallback> middleSemanticsActions = getSemanticsActions(1);
          middleSemanticsActions[moveToEnd]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 1', 'Item 3', 'Item 4', 'Item 2']));

          // Test out move after: move Item 3 (the current second item) one space down.
          await tester.pumpWidget(build());
          middleSemanticsActions = getSemanticsActions(1);
          middleSemanticsActions[moveDown]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 1', 'Item 4', 'Item 3', 'Item 2']));

          // Test out move after: move Item 3 (the current third item) one space up.
          await tester.pumpWidget(build());
          middleSemanticsActions = getSemanticsActions(2);
          middleSemanticsActions[moveUp]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 1', 'Item 3', 'Item 4', 'Item 2']));

          // Test out move to start: move Item 4 (the current third item) to the start of the list.
          await tester.pumpWidget(build());
          middleSemanticsActions = getSemanticsActions(2);
          middleSemanticsActions[moveToStart]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 4', 'Item 1', 'Item 3', 'Item 2']));

          handle.dispose();
        });

        testWidgets('Last item accessibility (a11y) actions work', (WidgetTester tester) async {
          final SemanticsHandle handle = tester.ensureSemantics();
          expect(listItems, orderedEquals(originalListItems));

          // Test out move to start: move Item 4 to the start of the list.
          await tester.pumpWidget(build());
          Map<CustomSemanticsAction, VoidCallback> lastSemanticsActions = getSemanticsActions(listItems.length - 1);
          lastSemanticsActions[moveToStart]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 4', 'Item 1', 'Item 2', 'Item 3']));

          // Test out move up: move Item 3 (the current last item) one space up.
          await tester.pumpWidget(build());
          lastSemanticsActions = getSemanticsActions(listItems.length - 1);
          lastSemanticsActions[moveUp]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 4', 'Item 1', 'Item 3', 'Item 2']));

          handle.dispose();
        });

        testWidgets("Doesn't hide accessibility when a child declares its own semantics", (WidgetTester tester) async {
          final SemanticsHandle handle = tester.ensureSemantics();
          final Widget reorderableListView = ReorderableListView(
            children: <Widget>[
              const SizedBox(
                key: Key('List tile 1'),
                height: itemHeight,
                child: Text('List tile 1'),
              ),
              SizedBox(
                key: const Key('Switch tile'),
                height: itemHeight,
                child: Material(
                  child: SwitchListTile(
                    title: const Text('Switch tile'),
                    value: true,
                    onChanged: (bool newValue) { },
                  ),
                ),
              ),
              const SizedBox(
                key: Key('List tile 2'),
                height: itemHeight,
                child: Text('List tile 2'),
              ),
            ],
            scrollDirection: Axis.vertical,
            onReorder: (int oldIndex, int newIndex) { },
          );
          await tester.pumpWidget(MaterialApp(
            home: SizedBox(
              height: itemHeight * 10,
              child: reorderableListView,
            ),
          ));

          // Get the switch tile's semantics:
          final SemanticsNode semanticsNode = tester.getSemantics(find.byKey(const Key('Switch tile')));

          // Check for properties of both SwitchTile semantics and the ReorderableListView custom semantics actions.
          expect(semanticsNode, matchesSemantics(
            hasToggledState: true,
            isToggled: true,
            isEnabled: true,
            isFocusable: true,
            hasEnabledState: true,
            label: 'Switch tile',
            hasTapAction: true,
            customActions: const <CustomSemanticsAction>[
              CustomSemanticsAction(label: 'Move up'),
              CustomSemanticsAction(label: 'Move down'),
              CustomSemanticsAction(label: 'Move to the end'),
              CustomSemanticsAction(label: 'Move to the start'),
            ],
          ));
          handle.dispose();
        });
      });
    });

    group('in horizontal mode', () {
      testWidgets('reorder is not triggered when children length is less or equals to 1', (WidgetTester tester) async {
        bool onReorderWasCalled = false;
        final List<String> currentListItems = listItems.take(1).toList();
        final ReorderableListView reorderableListView = ReorderableListView(
          header: const Text('Header'),
          children: currentListItems.map<Widget>(listItemToWidget).toList(),
          scrollDirection: Axis.horizontal,
          onReorder: (_, __) => onReorderWasCalled = true,
        );
        final List<String> currentOriginalListItems = originalListItems.take(1).toList();
        await tester.pumpWidget(MaterialApp(
          home: SizedBox(
            height: itemHeight * 10,
            child: reorderableListView,
          ),
        ));
        expect(currentListItems, orderedEquals(currentOriginalListItems));
        final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('Item 1')));
        await tester.pump(kLongPressTimeout + kPressTimeout);
        expect(currentListItems, orderedEquals(currentOriginalListItems));
        await drag.moveTo(tester.getBottomLeft(find.text('Item 1')) * 2);
        expect(currentListItems, orderedEquals(currentOriginalListItems));
        await drag.up();
        expect(onReorderWasCalled, false);
        expect(currentListItems, orderedEquals(<String>['Item 1']));
      });

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
        final Widget reorderableListView = ReorderableListView(
          children: const <Widget>[
            SizedBox(
              key: Key('Normal item'),
              width: itemHeight,
              child: Text('Normal item'),
            ),
            SizedBox(
              key: Key('Tall item'),
              width: itemHeight * 2,
              child: Text('Tall item'),
            ),
            SizedBox(
              key: Key('Last item'),
              width: itemHeight,
              child: Text('Last item'),
            ),
          ],
          scrollDirection: Axis.horizontal,
          onReorder: (int oldIndex, int newIndex) { },
        );
        await tester.pumpWidget(MaterialApp(
          home: SizedBox(
            width: itemHeight * 10,
            child: reorderableListView,
          ),
        ));

        Element getContentElement() {
          final SingleChildScrollView listScrollView = tester.widget(find.byType(SingleChildScrollView));
          final Widget scrollContents = listScrollView.child;
          final Element contentElement = tester.element(find.byElementPredicate((Element element) => element.widget == scrollContents));
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
          return find.byElementPredicate((Element element) => element.findAncestorWidgetOfExactType<_Stateful>()?.key == key)
              .evaluate()
              .first
              .findAncestorStateOfType<_StatefulState>();
        }
        await tester.pumpWidget(MaterialApp(
          home: ReorderableListView(
            children: <Widget>[
              _Stateful(key: const Key('A')),
              _Stateful(key: const Key('B')),
              _Stateful(key: const Key('C')),
            ],
            onReorder: (int oldIndex, int newIndex) { },
            scrollDirection: Axis.horizontal,
          ),
        ));
        await tester.tap(find.byKey(const Key('A')));
        await tester.pumpAndSettle();
        // Only the 'A' widget should be checked.
        expect(findState(const Key('A')).checked, true);
        expect(findState(const Key('B')).checked, false);
        expect(findState(const Key('C')).checked, false);

        await tester.pumpWidget(MaterialApp(
          home: ReorderableListView(
            children: <Widget>[
              _Stateful(key: const Key('B')),
              _Stateful(key: const Key('C')),
              _Stateful(key: const Key('A')),
            ],
            onReorder: (int oldIndex, int newIndex) { },
            scrollDirection: Axis.horizontal,
          ),
        ));
        // Only the 'A' widget should be checked.
        expect(findState(const Key('B')).checked, false);
        expect(findState(const Key('C')).checked, false);
        expect(findState(const Key('A')).checked, true);
      });

      testWidgets('Preserves children states when rebuilt', (WidgetTester tester) async {
        const Key firstBox = Key('key');
        Widget build() {
          return MaterialApp(
            home: Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox(
                width: 100,
                height: 100,
                child: ReorderableListView(
                  scrollDirection: Axis.horizontal,
                  children: const <Widget>[
                    SizedBox(key: firstBox, width: 10, height: 10),
                  ],
                  onReorder: (_, __) {},
                ),
              ),
            ),
          );
        }

        // When the widget is rebuilt, the state of child should be consistent.
        await tester.pumpWidget(build());
        final Element e0 = tester.element(find.byKey(firstBox));
        await tester.pumpWidget(build());
        final Element e1 = tester.element(find.byKey(firstBox));
        expect(e0, equals(e1));
      });

      group('Accessibility (a11y/Semantics)', () {
        Map<CustomSemanticsAction, VoidCallback> getSemanticsActions(int index) {
          final Semantics semantics = find.ancestor(
            of: find.byKey(Key(listItems[index])),
            matching: find.byType(Semantics),
          ).evaluate().first.widget as Semantics;
          return semantics.properties.customSemanticsActions;
        }

        const CustomSemanticsAction moveToStart = CustomSemanticsAction(label: 'Move to the start');
        const CustomSemanticsAction moveToEnd = CustomSemanticsAction(label: 'Move to the end');
        const CustomSemanticsAction moveLeft = CustomSemanticsAction(label: 'Move left');
        const CustomSemanticsAction moveRight = CustomSemanticsAction(label: 'Move right');

        testWidgets('Provides the correct accessibility actions in LTR mode', (WidgetTester tester) async {
          final SemanticsHandle handle = tester.ensureSemantics();

          await tester.pumpWidget(build(scrollDirection: Axis.horizontal));

          // The first item can be moved right or to the end.
          final Map<CustomSemanticsAction, VoidCallback> firstSemanticsActions = getSemanticsActions(0);
          expect(firstSemanticsActions.length, 2, reason: 'The first list item should have 2 custom actions.');
          expect(firstSemanticsActions.containsKey(moveToStart), false, reason: 'The first item cannot `Move to the start`.');
          expect(firstSemanticsActions.containsKey(moveLeft), false, reason: 'The first item cannot `Move left`.');
          expect(firstSemanticsActions.containsKey(moveRight), true, reason: 'The first item should be able to `Move right`.');
          expect(firstSemanticsActions.containsKey(moveToEnd), true, reason: 'The first item should be able to `Move to the end`.');

          // Items in the middle can be moved to the start, end, left or right.
          for (int i = 1; i < listItems.length - 1; i += 1) {
            final Map<CustomSemanticsAction, VoidCallback> ithSemanticsActions = getSemanticsActions(i);
            expect(ithSemanticsActions.length, 4, reason: 'List item $i should have 4 custom actions.');
            expect(ithSemanticsActions.containsKey(moveToStart), true, reason: 'List item $i should be able to `Move to the start`.');
            expect(ithSemanticsActions.containsKey(moveLeft), true, reason: 'List item $i should be able to `Move left`.');
            expect(ithSemanticsActions.containsKey(moveRight), true, reason: 'List item $i should be able to `Move right`.');
            expect(ithSemanticsActions.containsKey(moveToEnd), true, reason: 'List item $i should be able to `Move to the end`.');
          }

          // The last item can be moved left or to the start.
          final Map<CustomSemanticsAction, VoidCallback> lastSemanticsActions = getSemanticsActions(listItems.length - 1);
          expect(lastSemanticsActions.length, 2, reason: 'The last list item should have 2 custom actions.');
          expect(lastSemanticsActions.containsKey(moveToStart), true, reason: 'The last item should be able to `Move to the start`.');
          expect(lastSemanticsActions.containsKey(moveLeft), true, reason: 'The last item should be able to `Move left`.');
          expect(lastSemanticsActions.containsKey(moveRight), false, reason: 'The last item cannot `Move right`.');
          expect(lastSemanticsActions.containsKey(moveToEnd), false, reason: 'The last item cannot `Move to the end`.');
          handle.dispose();
        });

        testWidgets('Provides the correct accessibility actions in Right-To-Left directionality', (WidgetTester tester) async {
          // In RTL mode, the right is the start and the left is the end.
          // The array representation is unchanged (LTR), but the direction of the motion actions is reversed.
          final SemanticsHandle handle = tester.ensureSemantics();

          await tester.pumpWidget(build(scrollDirection: Axis.horizontal, textDirection: TextDirection.rtl));

          // The first item can be moved right or to the end.
          final Map<CustomSemanticsAction, VoidCallback> firstSemanticsActions = getSemanticsActions(0);
          expect(firstSemanticsActions.length, 2, reason: 'The first list item should have 2 custom actions.');
          expect(firstSemanticsActions.containsKey(moveToStart), false, reason: 'The first item cannot `Move to the start`.');
          expect(firstSemanticsActions.containsKey(moveRight), false, reason: 'The first item cannot `Move right`.');
          expect(firstSemanticsActions.containsKey(moveLeft), true, reason: 'The first item should be able to `Move left`.');
          expect(firstSemanticsActions.containsKey(moveToEnd), true, reason: 'The first item should be able to `Move to the end`.');

          // Items in the middle can be moved to the start, end, left or right.
          for (int i = 1; i < listItems.length - 1; i += 1) {
            final Map<CustomSemanticsAction, VoidCallback> ithSemanticsActions = getSemanticsActions(i);
            expect(ithSemanticsActions.length, 4, reason: 'List item $i should have 4 custom actions.');
            expect(ithSemanticsActions.containsKey(moveToStart), true, reason: 'List item $i should be able to `Move to the start`.');
            expect(ithSemanticsActions.containsKey(moveRight), true, reason: 'List item $i should be able to `Move right`.');
            expect(ithSemanticsActions.containsKey(moveLeft), true, reason: 'List item $i should be able to `Move left`.');
            expect(ithSemanticsActions.containsKey(moveToEnd), true, reason: 'List item $i should be able to `Move to the end`.');
          }

          // The last item can be moved left or to the start.
          final Map<CustomSemanticsAction, VoidCallback> lastSemanticsActions = getSemanticsActions(listItems.length - 1);
          expect(lastSemanticsActions.length, 2, reason: 'The last list item should have 2 custom actions.');
          expect(lastSemanticsActions.containsKey(moveToStart), true, reason: 'The last item should be able to `Move to the start`.');
          expect(lastSemanticsActions.containsKey(moveRight), true, reason: 'The last item should be able to `Move right`.');
          expect(lastSemanticsActions.containsKey(moveLeft), false, reason: 'The last item cannot `Move left`.');
          expect(lastSemanticsActions.containsKey(moveToEnd), false, reason: 'The last item cannot `Move to the end`.');
          handle.dispose();
        });

        testWidgets('First item accessibility (a11y) actions work in LTR mode', (WidgetTester tester) async {
          final SemanticsHandle handle = tester.ensureSemantics();
          expect(listItems, orderedEquals(originalListItems));

          // Test out move to end: move Item 1 to the end of the list.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal));
          Map<CustomSemanticsAction, VoidCallback> firstSemanticsActions = getSemanticsActions(0);
          firstSemanticsActions[moveToEnd]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 2', 'Item 3', 'Item 4', 'Item 1']));

          // Test out move after: move Item 2 (the current first item) one space to the right.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal));
          firstSemanticsActions = getSemanticsActions(0);
          firstSemanticsActions[moveRight]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 3', 'Item 2', 'Item 4', 'Item 1']));

          handle.dispose();
        });

        testWidgets('First item accessibility (a11y) actions work in Right-To-Left directionality', (WidgetTester tester) async {
          // In RTL mode, the right is the start and the left is the end.
          // The array representation is unchanged (LTR), but the direction of the motion actions is reversed.
          final SemanticsHandle handle = tester.ensureSemantics();
          expect(listItems, orderedEquals(originalListItems));

          // Test out move to end: move Item 1 to the end of the list.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal, textDirection: TextDirection.rtl));
          Map<CustomSemanticsAction, VoidCallback> firstSemanticsActions = getSemanticsActions(0);
          firstSemanticsActions[moveToEnd]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 2', 'Item 3', 'Item 4', 'Item 1']));

          // Test out move after: move Item 2 (the current first item) one space to the left.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal, textDirection: TextDirection.rtl));
          firstSemanticsActions = getSemanticsActions(0);
          firstSemanticsActions[moveLeft]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 3', 'Item 2', 'Item 4', 'Item 1']));

          handle.dispose();
        });

        testWidgets('Middle item accessibility (a11y) actions work in LTR mode', (WidgetTester tester) async {
          final SemanticsHandle handle = tester.ensureSemantics();
          expect(listItems, orderedEquals(originalListItems));

          // Test out move to end: move Item 2 to the end of the list.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal));
          Map<CustomSemanticsAction, VoidCallback> middleSemanticsActions = getSemanticsActions(1);
          middleSemanticsActions[moveToEnd]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 1', 'Item 3', 'Item 4', 'Item 2']));

          // Test out move after: move Item 3 (the current second item) one space to the right.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal));
          middleSemanticsActions = getSemanticsActions(1);
          middleSemanticsActions[moveRight]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 1', 'Item 4', 'Item 3', 'Item 2']));

          // Test out move after: move Item 3 (the current third item) one space to the left.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal));
          middleSemanticsActions = getSemanticsActions(2);
          middleSemanticsActions[moveLeft]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 1', 'Item 3', 'Item 4', 'Item 2']));

          // Test out move to start: move Item 4 (the current third item) to the start of the list.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal));
          middleSemanticsActions = getSemanticsActions(2);
          middleSemanticsActions[moveToStart]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 4', 'Item 1', 'Item 3', 'Item 2']));

          handle.dispose();
        });

        testWidgets('Middle item accessibility (a11y) actions work in Right-To-Left directionality', (WidgetTester tester) async {
          // In RTL mode, the right is the start and the left is the end.
          // The array representation is unchanged (LTR), but the direction of the motion actions is reversed.
          final SemanticsHandle handle = tester.ensureSemantics();
          expect(listItems, orderedEquals(originalListItems));

          // Test out move to end: move Item 2 to the end of the list.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal, textDirection: TextDirection.rtl));
          Map<CustomSemanticsAction, VoidCallback> middleSemanticsActions = getSemanticsActions(1);
          middleSemanticsActions[moveToEnd]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 1', 'Item 3', 'Item 4', 'Item 2']));

          // Test out move after: move Item 3 (the current second item) one space to the left.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal, textDirection: TextDirection.rtl));
          middleSemanticsActions = getSemanticsActions(1);
          middleSemanticsActions[moveLeft]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 1', 'Item 4', 'Item 3', 'Item 2']));

          // Test out move after: move Item 3 (the current third item) one space to the right.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal, textDirection: TextDirection.rtl));
          middleSemanticsActions = getSemanticsActions(2);
          middleSemanticsActions[moveRight]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 1', 'Item 3', 'Item 4', 'Item 2']));

          // Test out move to start: move Item 4 (the current third item) to the start of the list.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal, textDirection: TextDirection.rtl));
          middleSemanticsActions = getSemanticsActions(2);
          middleSemanticsActions[moveToStart]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 4', 'Item 1', 'Item 3', 'Item 2']));

          handle.dispose();
        });

        testWidgets('Last item accessibility (a11y) actions work in LTR mode', (WidgetTester tester) async {
          final SemanticsHandle handle = tester.ensureSemantics();
          expect(listItems, orderedEquals(originalListItems));

          // Test out move to start: move Item 4 to the start of the list.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal));
          Map<CustomSemanticsAction, VoidCallback> lastSemanticsActions = getSemanticsActions(listItems.length - 1);
          lastSemanticsActions[moveToStart]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 4', 'Item 1', 'Item 2', 'Item 3']));

          // Test out move before: move Item 3 (the current last item) one space to the left.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal));
          lastSemanticsActions = getSemanticsActions(listItems.length - 1);
          lastSemanticsActions[moveLeft]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 4', 'Item 1', 'Item 3', 'Item 2']));

          handle.dispose();
        });

        testWidgets('Last item accessibility (a11y) actions work in Right-To-Left directionality', (WidgetTester tester) async {
          // In RTL mode, the right is the start and the left is the end.
          // The array representation is unchanged (LTR), but the direction of the motion actions is reversed.
          final SemanticsHandle handle = tester.ensureSemantics();
          expect(listItems, orderedEquals(originalListItems));

          // Test out move to start: move Item 4 to the start of the list.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal, textDirection: TextDirection.rtl));
          Map<CustomSemanticsAction, VoidCallback> lastSemanticsActions = getSemanticsActions(listItems.length - 1);
          lastSemanticsActions[moveToStart]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 4', 'Item 1', 'Item 2', 'Item 3']));

          // Test out move before: move Item 3 (the current last item) one space to the right.
          await tester.pumpWidget(build(scrollDirection: Axis.horizontal, textDirection: TextDirection.rtl));
          lastSemanticsActions = getSemanticsActions(listItems.length - 1);
          lastSemanticsActions[moveRight]();
          await tester.pumpAndSettle();
          expect(listItems, orderedEquals(<String>['Item 4', 'Item 1', 'Item 3', 'Item 2']));

          handle.dispose();
        });
      });

    });

    testWidgets('ReorderableListView can be reversed', (WidgetTester tester) async {
      final Widget reorderableListView = ReorderableListView(
        children: const <Widget>[
          SizedBox(
            key: Key('A'),
            child: Text('A'),
          ),
          SizedBox(
            key: Key('B'),
            child: Text('B'),
          ),
          SizedBox(
            key: Key('C'),
            child: Text('C'),
          ),
        ],
        reverse: true,
        onReorder: (int oldIndex, int newIndex) { },
      );
      await tester.pumpWidget(MaterialApp(
        home: reorderableListView,
      ));
      expect(tester.getCenter(find.text('A')).dy, lessThan(tester.getCenter(find.text('B')).dy));
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
  // ignore:prefer_const_constructors_in_immutables
  _Stateful({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _StatefulState();
}

class _StatefulState extends State<_Stateful> {
  bool checked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.0,
      height: 48.0,
      child: Material(
        child: Checkbox(
          value: checked,
          onChanged: (bool newValue) => checked = newValue,
        ),
      ),
    );
  }
}
