// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'list_tile_tester.dart';
import 'semantics_tester.dart';

const _kRedColor = Color(0xFFFF0000);
const _kGreenColor = Color(0xFF00FF00);
const _kDragHandleIconData = IconData(0xe25d, fontFamily: 'MaterialIcons');

void main() {
  testWidgets('SliverReorderableList works well when having gestureSettings', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/103404
    const itemCount = 5;
    var onReorderCallCount = 0;
    final items = List<int>.generate(itemCount, (int index) => index);

    void handleReorder(int fromIndex, int toIndex) {
      onReorderCallCount += 1;
      items.insert(toIndex, items.removeAt(fromIndex));
    }

    // The list has five elements of height 100
    await tester.pumpWidget(
      TestWidgetsApp(
        home: MediaQuery(
          data: const MediaQueryData(gestureSettings: DeviceGestureSettings(touchSlop: 8.0)),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverReorderableList(
                itemCount: itemCount,
                itemBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    key: ValueKey<int>(items[index]),
                    height: 100,
                    child: ReorderableDragStartListener(
                      index: index,
                      child: Text('item ${items[index]}'),
                    ),
                  );
                },
                onReorderItem: handleReorder,
              ),
            ],
          ),
        ),
      ),
    );

    // Start gesture on first item
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);

    // Drag a little bit to make `ImmediateMultiDragGestureRecognizer` compete with `VerticalDragGestureRecognizer`
    await drag.moveBy(const Offset(0, 10));
    await tester.pump();
    // Drag enough to move down the first item
    await drag.moveBy(const Offset(0, 40));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();

    expect(onReorderCallCount, 1);
    expect(items, orderedEquals(<int>[1, 0, 2, 3, 4]));
  });

  testWidgets('SliverReorderableList item has correct semantics', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    const itemCount = 5;
    var onReorderCallCount = 0;
    final items = List<int>.generate(itemCount, (int index) => index);

    void handleReorder(int fromIndex, int toIndex) {
      onReorderCallCount += 1;
      items.insert(toIndex, items.removeAt(fromIndex));
    }

    // The list has five elements of height 100
    await tester.pumpWidget(
      TestWidgetsApp(
        home: MediaQuery(
          data: const MediaQueryData(gestureSettings: DeviceGestureSettings(touchSlop: 8.0)),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverReorderableList(
                itemCount: itemCount,
                itemBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    key: ValueKey<int>(items[index]),
                    height: 100,
                    child: ReorderableDragStartListener(
                      index: index,
                      child: Text('item ${items[index]}'),
                    ),
                  );
                },
                onReorderItem: handleReorder,
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      semantics,
      includesNodeWith(label: 'item 0', actions: <SemanticsAction>[SemanticsAction.customAction]),
    );
    final SemanticsNode node = tester.getSemantics(find.text('item 0'));

    // perform custom action 'move down'.
    final int customActionId = CustomSemanticsAction.getIdentifier(
      const CustomSemanticsAction(label: 'Move down'),
    );
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.customAction,
      customActionId,
    );
    await tester.pumpAndSettle();

    expect(onReorderCallCount, 1);
    expect(items, orderedEquals(<int>[1, 0, 2, 3, 4]));

    semantics.dispose();
  });

  testWidgets('SliverReorderableList custom semantics action has correct label', (
    WidgetTester tester,
  ) async {
    const itemCount = 5;
    final items = List<int>.generate(itemCount, (int index) => index);
    // The list has five elements of height 100
    await tester.pumpWidget(
      TestWidgetsApp(
        home: MediaQuery(
          data: const MediaQueryData(gestureSettings: DeviceGestureSettings(touchSlop: 8.0)),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverReorderableList(
                itemCount: itemCount,
                itemBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    key: ValueKey<int>(items[index]),
                    height: 100,
                    child: ReorderableDragStartListener(
                      index: index,
                      child: Text('item ${items[index]}'),
                    ),
                  );
                },
                onReorderItem: (_, _) {},
              ),
            ],
          ),
        ),
      ),
    );
    final SemanticsNode node = tester.getSemantics(find.text('item 0'));
    final SemanticsData data = node.getSemanticsData();
    expect(data.customSemanticsActionIds!.length, 2);
    final CustomSemanticsAction action1 = CustomSemanticsAction.getAction(
      data.customSemanticsActionIds![0],
    )!;
    expect(action1.label, 'Move down');
    final CustomSemanticsAction action2 = CustomSemanticsAction.getAction(
      data.customSemanticsActionIds![1],
    )!;
    expect(action2.label, 'Move to the end');
  });

  // Regression test for https://github.com/flutter/flutter/issues/100451
  testWidgets('SliverReorderableList.builder respects findChildIndexCallback', (
    WidgetTester tester,
  ) async {
    var finderCalled = false;
    var itemCount = 7;
    late StateSetter stateSetter;

    await tester.pumpWidget(
      TestWidgetsApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            stateSetter = setState;
            return CustomScrollView(
              slivers: <Widget>[
                SliverReorderableList(
                  itemCount: itemCount,
                  itemBuilder: (_, int index) => Container(key: Key('$index'), height: 2000.0),
                  findChildIndexCallback: (Key key) {
                    finderCalled = true;
                    return null;
                  },
                  onReorderItem: (_, _) {},
                ),
              ],
            );
          },
        ),
      ),
    );
    expect(finderCalled, false);

    // Trigger update.
    stateSetter(() => itemCount = 77);
    await tester.pump();

    expect(finderCalled, true);
  });

  // Regression test for https://github.com/flutter/flutter/issues/88191
  testWidgets('Do not crash when dragging with two fingers simultaneously', (
    WidgetTester tester,
  ) async {
    final items = List<int>.generate(3, (int index) => index);
    void handleReorder(int fromIndex, int toIndex) {
      items.insert(toIndex, items.removeAt(fromIndex));
    }

    await tester.pumpWidget(
      TestWidgetsApp(
        home: ReorderableList(
          itemBuilder: (BuildContext context, int index) {
            return ReorderableDragStartListener(
              index: index,
              key: ValueKey<int>(items[index]),
              child: SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[Text('item ${items[index]}')],
                ),
              ),
            );
          },
          itemCount: items.length,
          onReorderItem: handleReorder,
        ),
      ),
    );

    final TestGesture drag1 = await tester.startGesture(tester.getCenter(find.text('item 0')));
    final TestGesture drag2 = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kLongPressTimeout);

    await drag1.moveBy(const Offset(0, 100));
    await drag2.moveBy(const Offset(0, 100));
    await tester.pumpAndSettle();

    await drag1.up();
    await drag2.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('negative itemCount should assert', (WidgetTester tester) async {
    final items = <int>[1, 2, 3];
    await tester.pumpWidget(
      TestWidgetsApp(
        home: StatefulBuilder(
          builder: (BuildContext outerContext, StateSetter setState) {
            return CustomScrollView(
              slivers: <Widget>[
                SliverReorderableList(
                  itemCount: -1,
                  onReorderItem: (int fromIndex, int toIndex) {
                    setState(() {
                      items.insert(toIndex, items.removeAt(fromIndex));
                    });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return SizedBox(height: 100, child: Text('item ${items[index]}'));
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('zero itemCount should not build widget', (WidgetTester tester) async {
    final items = <int>[1, 2, 3];
    await tester.pumpWidget(
      TestWidgetsApp(
        home: StatefulBuilder(
          builder: (BuildContext outerContext, StateSetter setState) {
            return CustomScrollView(
              slivers: <Widget>[
                SliverFixedExtentList.list(
                  itemExtent: 50.0,
                  children: const <Widget>[Text('before')],
                ),
                SliverReorderableList(
                  itemCount: 0,
                  onReorderItem: (int fromIndex, int toIndex) {
                    setState(() {
                      items.insert(toIndex, items.removeAt(fromIndex));
                    });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return SizedBox(height: 100, child: Text('item ${items[index]}'));
                  },
                ),
                SliverFixedExtentList.list(
                  itemExtent: 50.0,
                  children: const <Widget>[Text('after')],
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.text('before'), findsOneWidget);
    expect(find.byType(SliverReorderableList), findsNothing);
    expect(find.text('after'), findsOneWidget);
  });

  testWidgets('SliverReorderableList, drag and drop, fixed height items', (
    WidgetTester tester,
  ) async {
    final items = List<int>.generate(8, (int index) => index);

    Future<void> pressDragRelease(Offset start, Offset delta) async {
      final TestGesture drag = await tester.startGesture(start);
      await tester.pump(kPressTimeout);
      await drag.moveBy(delta);
      await tester.pump(kPressTimeout);
      await drag.up();
      await tester.pumpAndSettle();
    }

    void check({List<int> visible = const <int>[], List<int> hidden = const <int>[]}) {
      for (final i in visible) {
        expect(find.text('item $i'), findsOneWidget);
      }
      for (final i in hidden) {
        expect(find.text('item $i'), findsNothing);
      }
    }

    // The SliverReorderableList is 800x600, 8 items, each item is 800x100 with
    // an "item $index" text widget at the item's origin.  Drags are initiated by
    // a simple press on the text widget.
    await tester.pumpWidget(TestList(items: items));
    check(visible: <int>[0, 1, 2, 3, 4, 5], hidden: <int>[6, 7]);

    // Drag item 0 downwards less than halfway and let it snap back. List
    // should remain as it is.
    await pressDragRelease(const Offset(12, 50), const Offset(12, 60));
    check(visible: <int>[0, 1, 2, 3, 4, 5], hidden: <int>[6, 7]);
    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 100));
    expect(items, orderedEquals(<int>[0, 1, 2, 3, 4, 5, 6, 7]));

    // Drag item 0 downwards more than halfway to displace item 1.
    await pressDragRelease(tester.getCenter(find.text('item 0')), const Offset(0, 51));
    check(visible: <int>[0, 1, 2, 3, 4, 5], hidden: <int>[6, 7]);
    expect(tester.getTopLeft(find.text('item 1')), Offset.zero);
    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 100));
    expect(items, orderedEquals(<int>[1, 0, 2, 3, 4, 5, 6, 7]));

    // Drag item 0 back to where it was.
    await pressDragRelease(tester.getCenter(find.text('item 0')), const Offset(0, -51));
    check(visible: <int>[0, 1, 2, 3, 4, 5], hidden: <int>[6, 7]);
    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 100));
    expect(items, orderedEquals(<int>[0, 1, 2, 3, 4, 5, 6, 7]));

    // Drag item 1 to item 3
    await pressDragRelease(tester.getCenter(find.text('item 1')), const Offset(0, 151));
    check(visible: <int>[0, 1, 2, 3, 4, 5], hidden: <int>[6, 7]);
    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 300));
    expect(tester.getTopLeft(find.text('item 3')), const Offset(0, 200));
    expect(items, orderedEquals(<int>[0, 2, 3, 1, 4, 5, 6, 7]));

    // Drag item 1 back to where it was
    await pressDragRelease(tester.getCenter(find.text('item 1')), const Offset(0, -200));
    check(visible: <int>[0, 1, 2, 3, 4, 5], hidden: <int>[6, 7]);
    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 100));
    expect(tester.getTopLeft(find.text('item 3')), const Offset(0, 300));
    expect(items, orderedEquals(<int>[0, 1, 2, 3, 4, 5, 6, 7]));
  });

  testWidgets('SliverReorderableList, items inherit DefaultTextStyle, IconTheme', (
    WidgetTester tester,
  ) async {
    const textColor = Color(0xffffffff);
    const iconColor = Color(0xff0000ff);

    TextStyle getIconStyle() {
      return tester
          .widget<RichText>(find.descendant(of: find.byType(Icon), matching: find.byType(RichText)))
          .text
          .style!;
    }

    TextStyle getTextStyle() {
      return tester
          .widget<RichText>(
            find.descendant(of: find.text('item 0'), matching: find.byType(RichText)),
          )
          .text
          .style!;
    }

    // This SliverReorderableList has just one item: "item 0".
    await tester.pumpWidget(
      TestList(items: List<int>.of(<int>[0]), textColor: textColor, iconColor: iconColor),
    );
    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(getIconStyle().color, iconColor);
    expect(getTextStyle().color, textColor);

    // Dragging item 0 causes it to be reparented in the overlay. The item
    // should still inherit the IconTheme and DefaultTextStyle because they are
    // InheritedThemes.
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);
    await drag.moveBy(const Offset(0, 50));
    await tester.pump(kPressTimeout);
    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 50));
    expect(getIconStyle().color, iconColor);
    expect(getTextStyle().color, textColor);

    // Drag is complete, item 0 returns to where it was.
    await drag.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(getIconStyle().color, iconColor);
    expect(getTextStyle().color, textColor);
  });

  testWidgets('SliverReorderableList - custom proxyDecorator', (WidgetTester tester) async {
    const fadeTransitionKey = ValueKey<String>('reordered-fade');

    await tester.pumpWidget(
      TestList(
        items: List<int>.of(<int>[0, 1, 2, 3]),
        proxyDecorator: (Widget child, int index, Animation<double> animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final fadeValues = Tween<double>(begin: 1.0, end: 0.5);
              final Animation<double> fadeAnimation = animation.drive(fadeValues);
              return FadeTransition(key: fadeTransitionKey, opacity: fadeAnimation, child: child);
            },
            child: child,
          );
        },
      ),
    );

    Finder getItemFadeTransition() => find.byKey(fadeTransitionKey);

    expect(getItemFadeTransition(), findsNothing);

    // Start gesture on first item
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);

    // Drag enough for transition animation defined in proxyDecorator to start.
    await drag.moveBy(const Offset(0, 50));
    await tester.pump();

    // At the start, opacity should be at 1.0.
    expect(getItemFadeTransition(), findsOneWidget);
    FadeTransition fadeTransition = tester.widget(getItemFadeTransition());
    expect(fadeTransition.opacity.value, 1.0);

    // Let animation run halfway.
    await tester.pump(const Duration(milliseconds: 125));
    fadeTransition = tester.widget(getItemFadeTransition());
    expect(fadeTransition.opacity.value, greaterThan(0.5));
    expect(fadeTransition.opacity.value, lessThan(1.0));

    // Allow animation to run to the end.
    await tester.pumpAndSettle();
    expect(find.byKey(fadeTransitionKey), findsOneWidget);
    fadeTransition = tester.widget(getItemFadeTransition());
    expect(fadeTransition.opacity.value, 0.5);

    // Finish reordering.
    await drag.up();
    await tester.pumpAndSettle();
    expect(getItemFadeTransition(), findsNothing);
  });

  testWidgets(
    'ReorderableList supports items with nested list views without throwing layout exception.',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWidgetsApp(
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              // Ensure there is always a top padding to simulate a phone with
              // safe area at the top. If the nested list doesn't have the
              // padding removed before it is put into the overlay it will
              // overflow the layout by the top padding.
              data: MediaQuery.of(context).copyWith(padding: const EdgeInsets.only(top: 50)),
              child: child!,
            );
          },
          home: ReorderableList(
            itemCount: 10,
            itemBuilder: (BuildContext context, int index) {
              return ReorderableDragStartListener(
                index: index,
                key: ValueKey<int>(index),
                child: Column(
                  children: <Widget>[
                    ListView(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      children: const <Widget>[
                        Text('Other data'),
                        Text('Other data'),
                        Text('Other data'),
                      ],
                    ),
                  ],
                ),
              );
            },
            onReorderItem: (_, _) {},
          ),
        ),
      );

      // Start gesture on first item
      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(0))),
      );
      await tester.pump(kPressTimeout);

      // Drag enough for move to start
      await drag.moveBy(const Offset(0, 50));
      await tester.pumpAndSettle();

      // There shouldn't be a layout overflow exception.
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ReorderableList supports items with nested list views without throwing layout exception.',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/83224.
      await tester.pumpWidget(
        TestWidgetsApp(
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              // Ensure there is always a top padding to simulate a phone with
              // safe area at the top. If the nested list doesn't have the
              // padding removed before it is put into the overlay it will
              // overflow the layout by the top padding.
              data: MediaQuery.of(context).copyWith(padding: const EdgeInsets.only(top: 50)),
              child: child!,
            );
          },
          home: ReorderableList(
            itemCount: 10,
            itemBuilder: (BuildContext context, int index) {
              return ReorderableDragStartListener(
                index: index,
                key: ValueKey<int>(index),
                child: Column(
                  children: <Widget>[
                    ListView(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      children: const <Widget>[
                        Text('Other data'),
                        Text('Other data'),
                        Text('Other data'),
                      ],
                    ),
                  ],
                ),
              );
            },
            onReorderItem: (_, _) {},
          ),
        ),
      );

      // Start gesture on first item.
      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(0))),
      );
      await tester.pump(kPressTimeout);

      // Drag enough for move to start.
      await drag.moveBy(const Offset(0, 50));
      await tester.pumpAndSettle();

      // There shouldn't be a layout overflow exception.
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('SliverReorderableList - properly animates the drop in a reversed list', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/110949
    final items = List<int>.generate(8, (int index) => index);

    Future<void> pressDragRelease(Offset start, Offset delta) async {
      final TestGesture drag = await tester.startGesture(start);
      await tester.pump(kPressTimeout);
      await drag.moveBy(delta);
      await tester.pumpAndSettle();
      await drag.up();
      await tester.pump();
    }

    // The TestList is 800x600 SliverReorderableList with 8 items 800x100 each.
    // Each item has a text widget with 'item $index' that can be moved by a
    // press and drag gesture. For this test we are reversing the order so
    // the first item is at the bottom.
    await tester.pumpWidget(TestList(items: items, reverse: true));

    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 500));
    expect(tester.getTopLeft(find.text('item 2')), const Offset(0, 300));

    // Drag item 0 up and insert it between item 1 and item 2. It should
    // smoothly animate.
    await pressDragRelease(tester.getCenter(find.text('item 0')), const Offset(0, -50));
    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 450));
    expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 500));
    expect(tester.getTopLeft(find.text('item 2')), const Offset(0, 300));

    // After the first several frames we should be moving closer to the final position,
    // not further away as was the case with the original bug.
    await tester.pump(const Duration(milliseconds: 10));
    expect(tester.getTopLeft(find.text('item 0')).dy, lessThan(450));
    expect(tester.getTopLeft(find.text('item 0')).dy, greaterThan(400));

    // Sample the middle (don't use exact values as it depends on the internal
    // curve being used).
    await tester.pump(const Duration(milliseconds: 125));
    expect(tester.getTopLeft(find.text('item 0')).dy, lessThan(450));
    expect(tester.getTopLeft(find.text('item 0')).dy, greaterThan(400));

    // Sample the end of the animation.
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(find.text('item 0')).dy, lessThan(450));
    expect(tester.getTopLeft(find.text('item 0')).dy, greaterThan(400));

    // Wait for it to finish, it should be back to the original position
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 400));
  });

  testWidgets(
    'SliverReorderableList - properly animates the drop at starting position in a reversed list',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/84625
      final items = List<int>.generate(8, (int index) => index);

      Future<void> pressDragRelease(Offset start, Offset delta) async {
        final TestGesture drag = await tester.startGesture(start);
        await tester.pump(kPressTimeout);
        await drag.moveBy(delta);
        await tester.pumpAndSettle();
        await drag.up();
        await tester.pump();
      }

      // The TestList is 800x600 SliverReorderableList with 8 items 800x100 each.
      // Each item has a text widget with 'item $index' that can be moved by a
      // press and drag gesture. For this test we are reversing the order so
      // the first item is at the bottom.
      await tester.pumpWidget(TestList(items: items, reverse: true));

      expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 500));
      expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 400));

      // Drag item 0 downwards off the edge and let it snap back. It should
      // smoothly animate back up.
      await pressDragRelease(tester.getCenter(find.text('item 0')), const Offset(0, 50));
      expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 550));
      expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 400));

      // After the first several frames we should be moving closer to the final position,
      // not further away as was the case with the original bug.
      await tester.pump(const Duration(milliseconds: 10));
      expect(tester.getTopLeft(find.text('item 0')).dy, lessThan(550));

      // Sample the middle (don't use exact values as it depends on the internal
      // curve being used).
      await tester.pump(const Duration(milliseconds: 125));
      expect(tester.getTopLeft(find.text('item 0')).dy, lessThan(550));

      // Wait for it to finish, it should be back to the original position
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 500));
    },
  );

  testWidgets('SliverReorderableList - properly animates the drop at starting position', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/150843
    // This tests the overshoot case where an item is dragged back 110% of the way
    final items = List<int>.generate(3, (int index) => index);

    // The TestList is 300x100 SliverReorderableList with 3 items 100x100 each.
    // Each item has a text widget with 'item $index' that can be moved by a
    // press and drag gesture. For this test the first item is at the top
    await tester.pumpWidget(TestList(items: items));

    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 100));

    // Drag item 0 downwards and then upwards.
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);
    await drag.moveBy(const Offset(0, 100));
    await tester.pumpAndSettle();
    await drag.moveBy(const Offset(0, -110));
    await tester.pump();
    expect(tester.getTopLeft(find.text('item 0')), const Offset(0, -10));
    expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 100));

    // Now leave the drag, it should go to index 0.
    await drag.up();
    await tester.pump();

    // It should not go to index 1 and come back
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getTopLeft(find.text('item 0')).dy, lessThan(50));
  });

  testWidgets(
    'SliverReorderableList - properly animates the drop at starting position with reverse:true',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/150843
      // This tests the overshoot case where an item is dragged back 110% of the way in a reverse list
      final items = List<int>.generate(3, (int index) => index);

      // The TestList is 300x100 SliverReorderableList with 3 items 100x100 each.
      // Each item has a text widget with 'item $index' that can be moved by a
      // press and drag gesture. For this test the first item is at the top
      await tester.pumpWidget(TestList(items: items, reverse: true));

      expect(tester.getTopLeft(find.text('item 2')), const Offset(0, 300.0));
      expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 400.0));

      // Drag item 2 downwards and then upwards.
      final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 2')));
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 100));
      await tester.pumpAndSettle();
      await drag.moveBy(const Offset(0, -110));
      await tester.pump();
      expect(tester.getTopLeft(find.text('item 2')), const Offset(0, 290));
      expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 300));

      // Now leave the drag, it should go to index 1.
      await drag.up();
      await tester.pump();

      // It should not go to index 0 and come back
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getTopLeft(find.text('item 2')).dy, greaterThan(350));
    },
  );

  testWidgets(
    'SliverReorderableList - properly animates the drop at starting position (undershoot)',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/88331
      // This tests the edge case where an item is dragged back only 90% of the way
      final items = List<int>.generate(3, (int index) => index);

      // The TestList is 300x100 SliverReorderableList with 3 items 100x100 each.
      // Each item has a text widget with 'item $index' that can be moved by a
      // press and drag gesture. For this test the first item is at the top
      await tester.pumpWidget(TestList(items: items));

      expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
      expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 100));

      // Drag item 0 downwards and then upwards (but not all the way back).
      final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 100));
      await tester.pumpAndSettle();
      await drag.moveBy(const Offset(0, -90));
      await tester.pump();
      expect(tester.getTopLeft(find.text('item 0')), const Offset(0, 10));
      expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 100));

      // Now leave the drag, it should go to index 0.
      await drag.up();
      await tester.pump();

      // It should animate back to the original position
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getTopLeft(find.text('item 0')).dy, lessThan(10));
    },
  );

  testWidgets(
    'SliverReorderableList - properly animates the drop at starting position with reverse:true (undershoot)',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/88331
      // This tests the edge case where an item is dragged back only 90% of the way in a reverse list
      final items = List<int>.generate(3, (int index) => index);

      // The TestList is 300x100 SliverReorderableList with 3 items 100x100 each.
      // Each item has a text widget with 'item $index' that can be moved by a
      // press and drag gesture. For this test the first item is at the top
      await tester.pumpWidget(TestList(items: items, reverse: true));

      expect(tester.getTopLeft(find.text('item 2')), const Offset(0, 300.0));
      expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 400.0));

      // Drag item 2 downwards and then upwards (but not all the way back).
      final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 2')));
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 100));
      await tester.pumpAndSettle();
      await drag.moveBy(const Offset(0, -90));
      await tester.pump();
      expect(tester.getTopLeft(find.text('item 2')), const Offset(0, 310));
      expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 300));

      // Now leave the drag, it should go to index 1.
      await drag.up();
      await tester.pump();

      // It should animate back to the original position
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getTopLeft(find.text('item 2')).dy, closeTo(300, 10));
    },
  );

  testWidgets('ReorderableList animation jumping on interruption', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/173243
    final items = List<int>.generate(3, (int index) => index);

    await tester.pumpWidget(TestList(items: items));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('item 0')), Offset.zero);
    expect(tester.getTopLeft(find.text('item 1')), const Offset(0, 100));

    final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);

    // Drag item 0 down past the swap threshold at 50px.
    for (var i = 0; i < 6; i++) {
      await drag.moveBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 50));
    }

    final double item1YBeforeInterrupt = tester.getCenter(find.text('item 1')).dy;

    // Drag back to trigger swap reversal.
    await drag.moveBy(const Offset(0, -10));
    await tester.pump(const Duration(milliseconds: 50));

    final double item1YAfterInterrupt = tester.getCenter(find.text('item 1')).dy;

    // Position should not jump when animation is interrupted.
    expect(
      item1YAfterInterrupt,
      closeTo(item1YBeforeInterrupt, 5.0),
      reason:
          'Animation jumping detected! Position changed from '
          '$item1YBeforeInterrupt to $item1YAfterInterrupt',
    );

    for (var i = 0; i < 5; i++) {
      await drag.moveBy(const Offset(0, -10));
      await tester.pump(const Duration(milliseconds: 50));
    }

    await drag.up();
    await tester.pumpAndSettle();
  });

  testWidgets('SliverReorderableList calls onReorderStart and onReorderEnd correctly', (
    WidgetTester tester,
  ) async {
    final items = List<int>.generate(8, (int index) => index);
    int? startIndex, endIndex;
    final Finder item0 = find.textContaining('item 0');

    await tester.pumpWidget(
      TestList(
        items: items,
        onReorderStart: (int index) {
          startIndex = index;
        },
        onReorderEnd: (int index) {
          endIndex = index;
        },
      ),
    );

    TestGesture drag = await tester.startGesture(tester.getCenter(item0));
    await tester.pump(kPressTimeout);
    // Drag enough for move to start.
    await drag.moveBy(const Offset(0, 20));

    expect(startIndex, equals(0));
    expect(endIndex, isNull);

    // Move item0 from index 0 to index 3
    await drag.moveBy(const Offset(0, 300));
    await tester.pumpAndSettle();
    await drag.up();
    await tester.pumpAndSettle();

    expect(endIndex, equals(3));

    startIndex = null;
    endIndex = null;

    drag = await tester.startGesture(tester.getCenter(item0));
    await tester.pump(kPressTimeout);
    // Drag enough for move to start.
    await drag.moveBy(const Offset(0, 20));

    expect(startIndex, equals(2));
    expect(endIndex, isNull);

    // Move item0 from index 2 to index 0
    await drag.moveBy(const Offset(0, -200));
    await tester.pumpAndSettle();
    await drag.up();
    await tester.pumpAndSettle();

    expect(endIndex, equals(0));
  });

  testWidgets('ReorderableList calls onReorderStart and onReorderEnd correctly', (
    WidgetTester tester,
  ) async {
    final items = List<int>.generate(8, (int index) => index);
    int? startIndex, endIndex;
    final Finder item0 = find.textContaining('item 0');

    void handleReorder(int fromIndex, int toIndex) {
      items.insert(toIndex, items.removeAt(fromIndex));
    }

    await tester.pumpWidget(
      TestWidgetsApp(
        home: ReorderableList(
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            return SizedBox(
              key: ValueKey<int>(items[index]),
              height: 100,
              child: ReorderableDelayedDragStartListener(
                index: index,
                child: Text('item ${items[index]}'),
              ),
            );
          },
          onReorderItem: handleReorder,
          onReorderStart: (int index) {
            startIndex = index;
          },
          onReorderEnd: (int index) {
            endIndex = index;
          },
        ),
      ),
    );

    TestGesture drag = await tester.startGesture(tester.getCenter(item0));
    await tester.pump(kLongPressTimeout);
    // Drag enough for move to start.
    await drag.moveBy(const Offset(0, 20));

    expect(startIndex, equals(0));
    expect(endIndex, isNull);

    // Move item0 from index 0 to index 3
    await drag.moveBy(const Offset(0, 300));
    await tester.pumpAndSettle();
    await drag.up();
    await tester.pumpAndSettle();

    expect(endIndex, equals(3));

    startIndex = null;
    endIndex = null;

    drag = await tester.startGesture(tester.getCenter(item0));
    await tester.pump(kLongPressTimeout);
    // Drag enough for move to start.
    await drag.moveBy(const Offset(0, 20));

    expect(startIndex, equals(2));
    expect(endIndex, isNull);

    // Move item0 from index 2 to index 0
    await drag.moveBy(const Offset(0, -200));
    await tester.pumpAndSettle();
    await drag.up();
    await tester.pumpAndSettle();

    expect(endIndex, equals(0));
  });

  testWidgets('SliverReorderableList calls old onReorder callback correctly', (
    WidgetTester tester,
  ) async {
    const itemCount = 5;
    var onReorderCallCount = 0;
    final items = List<int>.generate(itemCount, (int index) => index);

    void handleReorder(int fromIndex, int toIndex) {
      onReorderCallCount += 1;

      if (fromIndex < toIndex) {
        toIndex -= 1;
      }

      items.insert(toIndex, items.removeAt(fromIndex));
    }

    await tester.pumpWidget(
      TestWidgetsApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverReorderableList(
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                return SizedBox(
                  key: ValueKey<int>(items[index]),
                  height: 100,
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Text('item ${items[index]}'),
                  ),
                );
              },
              onReorder: handleReorder,
            ),
          ],
        ),
      ),
    );

    // Start gesture on the first item.
    final TestGesture dragDown = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);

    // Drag enough to move down the first item.
    await dragDown.moveBy(const Offset(0, 50));
    await tester.pump();
    await dragDown.up();
    await tester.pumpAndSettle();

    expect(onReorderCallCount, 1);
    expect(items, orderedEquals(<int>[1, 0, 2, 3, 4]));

    // Now do the reverse.
    final TestGesture dragUp = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);

    // Drag enough to move up the first item.
    await dragUp.moveBy(const Offset(0, -50));
    await tester.pump();
    await dragUp.up();
    await tester.pumpAndSettle();

    expect(onReorderCallCount, 2);
    expect(items, orderedEquals(<int>[0, 1, 2, 3, 4]));
  });

  testWidgets('SliverReorderableList calls onReorderItem callback correctly', (
    WidgetTester tester,
  ) async {
    const itemCount = 5;
    final items = List<int>.generate(itemCount, (int index) => index);

    void handleReorderItem(int fromIndex, int toIndex) {
      items.insert(toIndex, items.removeAt(fromIndex));
    }

    await tester.pumpWidget(
      TestWidgetsApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverReorderableList(
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                return SizedBox(
                  key: ValueKey<int>(items[index]),
                  height: 100,
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Text('item ${items[index]}'),
                  ),
                );
              },
              onReorderItem: handleReorderItem,
            ),
          ],
        ),
      ),
    );

    // Start gesture on the first item.
    final TestGesture dragDown = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);

    // Drag enough to move down the first item.
    await dragDown.moveBy(const Offset(0, 50));
    await tester.pump();
    await dragDown.up();
    await tester.pumpAndSettle();

    expect(items, orderedEquals(<int>[1, 0, 2, 3, 4]));

    // Now do the reverse.
    final TestGesture dragUp = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);

    // Drag enough to move up the first item.
    await dragUp.moveBy(const Offset(0, -50));
    await tester.pump();
    await dragUp.up();
    await tester.pumpAndSettle();

    expect(items, orderedEquals(<int>[0, 1, 2, 3, 4]));
  });

  testWidgets('SliverReorderableList asserts if neither onReorder and onReorderItem are provided', (
    WidgetTester tester,
  ) async {
    expect(
      () => SliverReorderableList(itemBuilder: (_, _) => const SizedBox(), itemCount: 0),
      throwsAssertionError,
    );
  });

  testWidgets('SliverReorderableList asserts if both onReorder and onReorderItem are provided', (
    WidgetTester tester,
  ) async {
    expect(
      () => SliverReorderableList(
        onReorder: (_, _) {},
        onReorderItem: (_, _) {},
        itemBuilder: (_, _) => const SizedBox(),
        itemCount: 0,
      ),
      throwsAssertionError,
    );
  });

  testWidgets('ReorderableList calls old onReorder callback correctly', (
    WidgetTester tester,
  ) async {
    const itemCount = 5;
    var onReorderCallCount = 0;
    final items = List<int>.generate(itemCount, (int index) => index);

    void handleReorder(int fromIndex, int toIndex) {
      onReorderCallCount += 1;

      if (fromIndex < toIndex) {
        toIndex -= 1;
      }

      items.insert(toIndex, items.removeAt(fromIndex));
    }

    await tester.pumpWidget(
      TestWidgetsApp(
        home: ReorderableList(
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            return SizedBox(
              key: ValueKey<int>(items[index]),
              height: 100,
              child: ReorderableDragStartListener(
                index: index,
                child: Text('item ${items[index]}'),
              ),
            );
          },
          onReorder: handleReorder,
        ),
      ),
    );

    // Start gesture on the first item.
    final TestGesture dragDown = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);

    // Drag enough to move down the first item.
    await dragDown.moveBy(const Offset(0, 50));
    await tester.pump();
    await dragDown.up();
    await tester.pumpAndSettle();

    expect(onReorderCallCount, 1);
    expect(items, orderedEquals(<int>[1, 0, 2, 3, 4]));

    // Now do the reverse.
    final TestGesture dragUp = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);

    // Drag enough to move up the first item.
    await dragUp.moveBy(const Offset(0, -50));
    await tester.pump();
    await dragUp.up();
    await tester.pumpAndSettle();

    expect(onReorderCallCount, 2);
    expect(items, orderedEquals(<int>[0, 1, 2, 3, 4]));
  });

  testWidgets('ReorderableList calls onReorderItem callback correctly', (
    WidgetTester tester,
  ) async {
    const itemCount = 5;
    final items = List<int>.generate(itemCount, (int index) => index);

    void handleReorderItem(int fromIndex, int toIndex) {
      items.insert(toIndex, items.removeAt(fromIndex));
    }

    await tester.pumpWidget(
      TestWidgetsApp(
        home: ReorderableList(
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            return SizedBox(
              key: ValueKey<int>(items[index]),
              height: 100,
              child: ReorderableDragStartListener(
                index: index,
                child: Text('item ${items[index]}'),
              ),
            );
          },
          onReorderItem: handleReorderItem,
        ),
      ),
    );

    // Start gesture on the first item.
    final TestGesture dragDown = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);

    // Drag enough to move down the first item.
    await dragDown.moveBy(const Offset(0, 50));
    await tester.pump();
    await dragDown.up();
    await tester.pumpAndSettle();

    expect(items, orderedEquals(<int>[1, 0, 2, 3, 4]));

    // Now do the reverse.
    final TestGesture dragUp = await tester.startGesture(tester.getCenter(find.text('item 0')));
    await tester.pump(kPressTimeout);

    // Drag enough to move up the first item.
    await dragUp.moveBy(const Offset(0, -50));
    await tester.pump();
    await dragUp.up();
    await tester.pumpAndSettle();

    expect(items, orderedEquals(<int>[0, 1, 2, 3, 4]));
  });

  testWidgets('ReorderableList asserts if neither onReorder and onReorderItem are provided', (
    WidgetTester tester,
  ) async {
    expect(
      () => ReorderableList(itemBuilder: (_, _) => const SizedBox(), itemCount: 0),
      throwsAssertionError,
    );
  });

  testWidgets('ReorderableList asserts if both onReorder and onReorderItem are provided', (
    WidgetTester tester,
  ) async {
    expect(
      () => ReorderableList(
        onReorder: (_, _) {},
        onReorderItem: (_, _) {},
        itemBuilder: (_, _) => const SizedBox(),
        itemCount: 0,
      ),
      throwsAssertionError,
    );
  });

  testWidgets('ReorderableList asserts on both non-null itemExtent and prototypeItem', (
    WidgetTester tester,
  ) async {
    final numbers = <int>[0, 1, 2];
    expect(
      () => ReorderableList(
        itemBuilder: (BuildContext context, int index) {
          return SizedBox(
            key: ValueKey<int>(numbers[index]),
            height: 20 + numbers[index] * 10,
            child: ReorderableDragStartListener(
              index: index,
              child: Text(numbers[index].toString()),
            ),
          );
        },
        itemCount: numbers.length,
        itemExtent: 30,
        prototypeItem: const SizedBox(),
        onReorderItem: (_, _) {},
      ),
      throwsAssertionError,
    );
  });

  testWidgets('ReorderableList passes itemExtentBuilder to SliverReorderableList', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/155936
    const itemCount = 5;
    const items = <double>[10.0, 20.0, 30.0, 40.0, 50.0];

    void handleReorder(int fromIndex, int toIndex) {
      items.insert(toIndex, items.removeAt(fromIndex));
    }

    // The list has five elements, that indicate the extent for the item at the given index.
    await tester.pumpWidget(
      TestWidgetsApp(
        home: ReorderableList(
          itemBuilder: (_, int index) {
            return SizedBox(key: ValueKey<double>(items[index]), child: Text('Item $index'));
          },
          itemCount: itemCount,
          onReorderItem: handleReorder,
          itemExtentBuilder: (int index, SliverLayoutDimensions dimensions) {
            return items[index];
          },
        ),
      ),
    );

    const expectedExtents = <int, double>{0: 10.0, 1: 20.0, 2: 30.0, 3: 40.0, 4: 50.0};

    final itemExtents = <int, double>{
      for (int i = 0; i < itemCount; i++) i: tester.getSize(find.text('Item $i')).height,
    };

    expect(const MapEquality<int, double>().equals(itemExtents, expectedExtents), isTrue);
  });

  testWidgets('SliverReorderableList asserts on both non-null itemExtent and prototypeItem', (
    WidgetTester tester,
  ) async {
    final numbers = <int>[0, 1, 2];
    expect(
      () => SliverReorderableList(
        itemBuilder: (BuildContext context, int index) {
          return SizedBox(
            key: ValueKey<int>(numbers[index]),
            height: 20 + numbers[index] * 10,
            child: ReorderableDragStartListener(
              index: index,
              child: Text(numbers[index].toString()),
            ),
          );
        },
        itemCount: numbers.length,
        itemExtent: 30,
        prototypeItem: const SizedBox(),
        onReorderItem: (_, _) {},
      ),
      throwsAssertionError,
    );
  });

  testWidgets('if itemExtent is non-null, children have same extent in the scroll direction', (
    WidgetTester tester,
  ) async {
    final numbers = <int>[0, 1, 2];

    await tester.pumpWidget(
      TestWidgetsApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ReorderableList(
              itemBuilder: (BuildContext context, int index) {
                return SizedBox(
                  key: ValueKey<int>(numbers[index]),
                  // children with different heights
                  height: 20 + numbers[index] * 10,
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Text(numbers[index].toString()),
                  ),
                );
              },
              itemCount: numbers.length,
              itemExtent: 30,
              onReorderItem: (int fromIndex, int toIndex) {
                final int value = numbers.removeAt(fromIndex);
                numbers.insert(toIndex, value);
              },
            );
          },
        ),
      ),
    );

    final double item0Height = tester.getSize(find.text('0').hitTestable()).height;
    final double item1Height = tester.getSize(find.text('1').hitTestable()).height;
    final double item2Height = tester.getSize(find.text('2').hitTestable()).height;

    expect(item0Height, 30.0);
    expect(item1Height, 30.0);
    expect(item2Height, 30.0);
  });

  testWidgets('if prototypeItem is non-null, children have same extent in the scroll direction', (
    WidgetTester tester,
  ) async {
    final numbers = <int>[0, 1, 2];

    await tester.pumpWidget(
      TestWidgetsApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ReorderableList(
              itemBuilder: (BuildContext context, int index) {
                return SizedBox(
                  key: ValueKey<int>(numbers[index]),
                  // children with different heights
                  height: 20 + numbers[index] * 10,
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Text(numbers[index].toString()),
                  ),
                );
              },
              itemCount: numbers.length,
              prototypeItem: const SizedBox(height: 30, child: Text('3')),
              onReorderItem: (_, _) {},
            );
          },
        ),
      ),
    );

    final double item0Height = tester.getSize(find.text('0').hitTestable()).height;
    final double item1Height = tester.getSize(find.text('1').hitTestable()).height;
    final double item2Height = tester.getSize(find.text('2').hitTestable()).height;

    expect(item0Height, 30.0);
    expect(item1Height, 30.0);
    expect(item2Height, 30.0);
  });

  group('ReorderableDragStartListener', () {
    testWidgets('It should allow the item to be dragged when enabled is true', (
      WidgetTester tester,
    ) async {
      const itemCount = 5;
      var onReorderCallCount = 0;
      final items = List<int>.generate(itemCount, (int index) => index);

      void handleReorder(int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        items.insert(toIndex, items.removeAt(fromIndex));
      }

      // The list has five elements of height 100
      await tester.pumpWidget(
        TestWidgetsApp(
          home: ReorderableList(
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                key: ValueKey<int>(items[index]),
                height: 100,
                child: ReorderableDragStartListener(
                  index: index,
                  child: Text('item ${items[index]}'),
                ),
              );
            },
            onReorderItem: handleReorder,
          ),
        ),
      );

      // Start gesture on first item
      final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
      await tester.pump(kPressTimeout);

      // Drag enough to move down the first item
      await drag.moveBy(const Offset(0, 50));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(onReorderCallCount, 1);
      expect(items, orderedEquals(<int>[1, 0, 2, 3, 4]));
    });

    testWidgets('It should not allow the item to be dragged when enabled is false', (
      WidgetTester tester,
    ) async {
      const itemCount = 5;
      var onReorderCallCount = 0;
      final items = List<int>.generate(itemCount, (int index) => index);

      void handleReorder(int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        items.insert(toIndex, items.removeAt(fromIndex));
      }

      // The list has five elements of height 100
      await tester.pumpWidget(
        TestWidgetsApp(
          home: ReorderableList(
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                key: ValueKey<int>(items[index]),
                height: 100,
                child: ReorderableDragStartListener(
                  index: index,
                  enabled: false,
                  child: Text('item ${items[index]}'),
                ),
              );
            },
            onReorderItem: handleReorder,
          ),
        ),
      );

      // Start gesture on first item
      final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
      await tester.pump(kLongPressTimeout);

      // Drag enough to move down the first item
      await drag.moveBy(const Offset(0, 50));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(onReorderCallCount, 0);
      expect(items, orderedEquals(<int>[0, 1, 2, 3, 4]));
    });
  });

  group('ReorderableDelayedDragStartListener', () {
    testWidgets('It should allow the item to be dragged when enabled is true', (
      WidgetTester tester,
    ) async {
      const itemCount = 5;
      var onReorderCallCount = 0;
      final items = List<int>.generate(itemCount, (int index) => index);

      void handleReorder(int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        items.insert(toIndex, items.removeAt(fromIndex));
      }

      // The list has five elements of height 100
      await tester.pumpWidget(
        TestWidgetsApp(
          home: ReorderableList(
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                key: ValueKey<int>(items[index]),
                height: 100,
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  child: Text('item ${items[index]}'),
                ),
              );
            },
            onReorderItem: handleReorder,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start gesture on first item
      final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
      await tester.pump(kLongPressTimeout);

      // Drag enough to move down the first item
      await drag.moveBy(const Offset(0, 50));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(onReorderCallCount, 1);
      expect(items, orderedEquals(<int>[1, 0, 2, 3, 4]));
    });

    testWidgets('It should not allow the item to be dragged when enabled is false', (
      WidgetTester tester,
    ) async {
      const itemCount = 5;
      var onReorderCallCount = 0;
      final items = List<int>.generate(itemCount, (int index) => index);

      void handleReorder(int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        items.insert(toIndex, items.removeAt(fromIndex));
      }

      // The list has five elements of height 100
      await tester.pumpWidget(
        TestWidgetsApp(
          home: ReorderableList(
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                key: ValueKey<int>(items[index]),
                height: 100,
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  enabled: false,
                  child: Text('item ${items[index]}'),
                ),
              );
            },
            onReorderItem: handleReorder,
          ),
        ),
      );

      // Start gesture on first item
      final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('item 0')));
      await tester.pump(kLongPressTimeout);

      // Drag enough to move down the first item
      await drag.moveBy(const Offset(0, 50));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(onReorderCallCount, 0);
      expect(items, orderedEquals(<int>[0, 1, 2, 3, 4]));
    });
  });

  testWidgets('SliverReorderableList properly disposes items', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/105010
    const itemCount = 5;
    final items = List<int>.generate(itemCount, (int index) => index);
    var showList = false;

    await tester.pumpWidget(
      TestWidgetsApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            if (!showList) {
              return GestureDetector(
                onTap: () => setState(() {
                  showList = true;
                }),
                child: const Text('Show list'),
              );
            }
            return Column(
              children: <Widget>[
                Expanded(
                  child: CustomScrollView(
                    slivers: <Widget>[
                      SliverReorderableList(
                        itemCount: itemCount,
                        itemBuilder: (BuildContext context, int index) {
                          return ReorderableDragStartListener(
                            key: ValueKey<String>('item-$index'),
                            index: index,
                            child: TestListTile(title: Text('item ${items[index]}')),
                          );
                        },
                        onReorderItem: (_, _) {},
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    showList = false;
                  }),
                  child: const Text('Close list'),
                ),
              ],
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show list'));
    await tester.pumpAndSettle();

    final Finder item0 = find.text('item 0');
    expect(item0, findsOneWidget);

    // Start gesture on first item without drag up event.
    final TestGesture drag = await tester.startGesture(tester.getCenter(item0));
    await drag.moveBy(const Offset(0, 200));
    await tester.pump();

    await tester.tap(find.text('Close list'));
    await tester.pumpAndSettle();

    expect(item0, findsNothing);
  });

  testWidgets('SliverReorderableList auto scrolls speed is configurable', (
    WidgetTester tester,
  ) async {
    Future<void> pumpFor({
      required Duration duration,
      Duration interval = const Duration(milliseconds: 50),
    }) async {
      await tester.pump();

      int times = (duration.inMilliseconds / interval.inMilliseconds).ceil();
      while (times > 0) {
        await tester.pump(interval + const Duration(milliseconds: 1));
        await tester.idle();
        times--;
      }
    }

    Future<double> pumpListAndDrag({required double autoScrollerVelocityScalar}) async {
      final items = List<int>.generate(10, (int index) => index);
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        TestWidgetsApp(
          home: CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              SliverReorderableList(
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    key: ValueKey<int>(items[index]),
                    height: 100,
                    color: items[index].isOdd ? _kRedColor : _kGreenColor,
                    child: ReorderableDragStartListener(
                      index: index,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('item ${items[index]}'),
                          const Icon(_kDragHandleIconData),
                        ],
                      ),
                    ),
                  );
                },
                itemCount: items.length,
                onReorderItem: (_, _) {},
                autoScrollerVelocityScalar: autoScrollerVelocityScalar,
              ),
            ],
          ),
        ),
      );

      expect(scrollController.offset, 0);

      final Finder item = find.text('item 0');
      final TestGesture drag = await tester.startGesture(tester.getCenter(item));

      // Drag just enough to touch the edge but not surpass it, so the
      // auto scroller is not yet triggered
      await drag.moveBy(const Offset(0, 500));
      await pumpFor(duration: const Duration(milliseconds: 200));

      expect(scrollController.offset, 0);

      // Now drag a little bit more so the auto scroller triggers
      await drag.moveBy(const Offset(0, 50));
      await pumpFor(
        duration: const Duration(milliseconds: 600),
        interval: Duration(milliseconds: (1000 / autoScrollerVelocityScalar).round()),
      );

      return scrollController.offset;
    }

    const double fastVelocityScalar = 20;
    final double offsetForFastScroller = await pumpListAndDrag(
      autoScrollerVelocityScalar: fastVelocityScalar,
    );

    // Reset widget tree
    await tester.pumpWidget(const SizedBox());

    const double slowVelocityScalar = 5;
    final double offsetForSlowScroller = await pumpListAndDrag(
      autoScrollerVelocityScalar: slowVelocityScalar,
    );

    expect(offsetForFastScroller / offsetForSlowScroller, fastVelocityScalar / slowVelocityScalar);
  });

  testWidgets(
    'Null check error when dragging and dropping last element into last index with reverse:true',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/132077
      const itemCount = 5;
      final items = List<String>.generate(itemCount, (int index) => 'Item ${index + 1}');

      await tester.pumpWidget(
        TestWidgetsApp(
          home: ReorderableList(
            onReorderItem: (int oldIndex, int newIndex) {
              final String item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
            },
            itemCount: items.length,
            reverse: true,
            itemBuilder: (BuildContext context, int index) {
              return ReorderableDragStartListener(
                key: Key('$index'),
                index: index,
                child: TestListTile(title: Text(items[index])),
              );
            },
          ),
        ),
      );

      // Start gesture on last item
      final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('Item 5')));
      await tester.pump(kLongPressTimeout);

      // Drag to move up the last item, and drop at the last index
      await drag.moveBy(const Offset(0, -50));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), null);
    },
  );

  testWidgets('When creating a new item, be in the correct position', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestWidgetsApp(
        home: LayoutBuilder(
          builder: (_, BoxConstraints view) {
            // The third one just appears on the screen
            final double itemSize = view.maxWidth / 2 - 20;
            return CustomScrollView(
              scrollDirection: Axis.horizontal,
              cacheExtent: 0, // The fourth one will not be created in the initial state.
              slivers: <Widget>[
                SliverReorderableList(
                  itemBuilder: (BuildContext context, int index) {
                    return ReorderableDragStartListener(
                      key: ValueKey<int>(index),
                      index: index,
                      child: Builder(
                        builder: (BuildContext context) {
                          return SizedBox(width: itemSize, child: Text('$index'));
                        },
                      ),
                    );
                  },
                  itemCount: 4,
                  onReorderItem: (_, _) {},
                ),
              ],
            );
          },
        ),
      ),
    );
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('0')));
    await tester.pump(kLongPressTimeout);
    await drag.moveBy(const Offset(20, 0));
    await tester.pump();
    expect(find.text('3').hitTestable(at: Alignment.topLeft), findsNothing);
    await drag.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Tests the correctness of the drop animation in various scenarios', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/138994
    late Size screenSize;
    final itemSizes = <double>[20, 50, 30, 80, 100, 30];
    Future<void> pumpFor(bool reverse, Axis scrollDirection) async {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Builder(
            builder: (BuildContext context) {
              screenSize = MediaQuery.sizeOf(context);
              return CustomScrollView(
                reverse: reverse,
                scrollDirection: scrollDirection,
                slivers: <Widget>[
                  SliverReorderableList(
                    itemBuilder: (BuildContext context, int index) {
                      return ReorderableDragStartListener(
                        key: ValueKey<int>(index),
                        index: index,
                        child: Builder(
                          builder: (BuildContext context) {
                            return SizedBox(
                              height: scrollDirection == Axis.vertical
                                  ? itemSizes[index]
                                  : double.infinity,
                              width: scrollDirection == Axis.horizontal
                                  ? itemSizes[index]
                                  : double.infinity,
                              child: Text('$index'),
                            );
                          },
                        ),
                      );
                    },
                    itemCount: itemSizes.length,
                    onReorderItem: (_, _) {},
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    Future<void> testMove(
      int from,
      int to, {
      bool reverse = false,
      Axis scrollDirection = Axis.vertical,
    }) async {
      await pumpFor(reverse, scrollDirection);
      final double targetOffset = (List<double>.of(itemSizes)..removeAt(from)).sublist(0, to).sum;
      final targetPosition = reverse
          ? (scrollDirection == Axis.vertical
                ? Offset(0, screenSize.height - targetOffset - itemSizes[from])
                : Offset(screenSize.width - targetOffset - itemSizes[from], 0))
          : (scrollDirection == Axis.vertical ? Offset(0, targetOffset) : Offset(targetOffset, 0));
      final Offset moveOffset = targetPosition - tester.getTopLeft(find.text('$from'));
      await tester.timedDrag(find.text('$from'), moveOffset, const Duration(seconds: 1));
      // Before the drop animation starts
      final Offset animationBeginOffset = tester.getTopLeft(find.text('$from'));
      // Halfway through the animation
      await tester.pump(const Duration(milliseconds: 125));
      expect(
        tester.getTopLeft(find.text('$from')),
        Offset.lerp(animationBeginOffset, targetPosition, 0.5),
      );
      // Animation ends
      await tester.pump(const Duration(milliseconds: 125));
      expect(tester.getTopLeft(find.text('$from')), targetPosition);
      await tester.pumpAndSettle();
    }

    final testCases = <(int, int)>[(3, 1), (3, 3), (3, 5), (0, 5), (5, 0)];
    for (final element in testCases) {
      await testMove(element.$1, element.$2);
      await testMove(element.$1, element.$2, reverse: true);
      await testMove(element.$1, element.$2, scrollDirection: Axis.horizontal);
      await testMove(element.$1, element.$2, reverse: true, scrollDirection: Axis.horizontal);
    }
  });

  testWidgets('Tests that the item position is correct when prototypeItem or itemExtent are set', (
    WidgetTester tester,
  ) async {
    Future<void> pumpFor({Widget? prototypeItem, double? itemExtent}) async {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: CustomScrollView(
            slivers: <Widget>[
              SliverReorderableList(
                itemBuilder: (BuildContext context, int index) {
                  return ReorderableDragStartListener(
                    key: ValueKey<int>(index),
                    index: index,
                    child: SizedBox(height: 100, child: Text('$index')),
                  );
                },
                itemCount: 5,
                itemExtent: itemExtent,
                prototypeItem: prototypeItem,
                onReorderItem: (_, _) {},
              ),
            ],
          ),
        ),
      );
    }

    Future<void> testFor({Widget? prototypeItem, double? itemExtent}) async {
      await pumpFor(prototypeItem: prototypeItem, itemExtent: itemExtent);
      final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('0')));
      await tester.pump(kLongPressTimeout);
      await drag.moveBy(const Offset(0, 20));
      await tester.pump();
      expect(tester.getTopLeft(find.text('1')), const Offset(0, 100));
      await drag.up();
      await tester.pumpAndSettle();
    }

    await testFor();
    await testFor(prototypeItem: const SizedBox(height: 100, width: 100, child: Text('prototype')));
    await testFor(itemExtent: 100);
  });

  testWidgets('The item being dragged will not be affected by layout constraints.', (
    WidgetTester tester,
  ) async {
    final itemLayoutConstraints = <int, BoxConstraints>{};
    await tester.pumpWidget(
      TestWidgetsApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverReorderableList(
              itemBuilder: (BuildContext context, int index) {
                return LayoutBuilder(
                  key: ValueKey<int>(index),
                  builder: (BuildContext context, BoxConstraints constraints) {
                    itemLayoutConstraints[index] = constraints;
                    return SizedBox(
                      height: 100,
                      child: ReorderableDragStartListener(index: index, child: Text('$index')),
                    );
                  },
                );
              },
              itemCount: 5,
              onReorderItem: (_, _) {},
            ),
          ],
        ),
      ),
    );
    final preDragLayoutConstraints = Map<int, BoxConstraints>.of(itemLayoutConstraints);
    itemLayoutConstraints.clear();
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.text('0')));
    await tester.pump(kLongPressTimeout);
    await drag.moveBy(const Offset(0, 20));
    await tester.pump();
    expect(itemLayoutConstraints, preDragLayoutConstraints);
    await drag.up();
    await tester.pumpAndSettle();
  });

  testWidgets('DragBoundary defines the boundary for ReorderableList.', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      TestWidgetsApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.only(top: 100),
            height: 300,
            child: DragBoundary(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverReorderableList(
                    itemBuilder: (BuildContext context, int index) {
                      return ReorderableDragStartListener(
                        key: ValueKey<int>(index),
                        index: index,
                        child: Text('$index'),
                      );
                    },
                    itemCount: 5,
                    onReorderItem: (_, _) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    TestGesture drag = await tester.startGesture(tester.getCenter(find.text('0')));
    await tester.pump(kLongPressTimeout);
    await drag.moveBy(const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('0')), const Offset(0, 100));
    await drag.up();
    await tester.pumpAndSettle();

    drag = await tester.startGesture(tester.getCenter(find.text('0')));
    await tester.pump(kLongPressTimeout);
    await drag.moveBy(const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(find.text('0')), const Offset(0, 400));
    await drag.up();
    await tester.pumpAndSettle();
  });

  testWidgets('ReorderableList does not crash at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestWidgetsApp(
        home: Center(
          child: SizedBox.shrink(
            child: ReorderableList(
              itemBuilder: (_, _) => const Text(key: Key('x'), 'X'),
              itemCount: 3,
              onReorderItem: (_, _) {},
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(ReorderableList)), Size.zero);
  });

  testWidgets('ReorderableDragStartListener does not crash at zero area', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const TestWidgetsApp(
        home: Center(
          child: SizedBox.shrink(child: ReorderableDragStartListener(index: 1, child: Text('X'))),
        ),
      ),
    );
    expect(tester.getSize(find.byType(ReorderableDragStartListener)), Size.zero);
  });

  testWidgets('ReorderableDelayedDragStartListener does not crash at zero area', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const TestWidgetsApp(
        home: Center(
          child: SizedBox.shrink(
            child: ReorderableDelayedDragStartListener(index: 1, child: Text('X')),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(ReorderableDelayedDragStartListener)), Size.zero);
  });

  group('SliverReorderableList.separated', () {
    // Distinct extents that make a wrong constant-vs-cumulative offset
    // assumption visible: items carry their extent by value, separators by
    // boundary index.
    double distinctItemExtent(int value) => 100.0 + value * 10.0;
    double distinctSeparatorExtent(int boundary) => 10.0 + boundary * 10.0;

    double topOf(WidgetTester tester, Finder finder, Axis axis) {
      final Offset topLeft = tester.getTopLeft(finder);
      return axis == Axis.vertical ? topLeft.dy : topLeft.dx;
    }

    double extentOf(WidgetTester tester, Finder finder, Axis axis) {
      final Size size = tester.getSize(finder);
      return axis == Axis.vertical ? size.height : size.width;
    }

    // All separators remain visible for the whole drag: there is no hiding
    // mechanism, so a separator is shown whenever its subtree is mounted.
    void expectSeparatorShown(WidgetTester tester, int boundary) {
      expect(
        find.byKey(ValueKey<String>('sep$boundary')),
        findsOneWidget,
        reason: 'separator $boundary should be shown',
      );
    }

    testWidgets('renders n items and n - 1 separators for itemCount 0, 1, 2, 4', (
      WidgetTester tester,
    ) async {
      for (final count in <int>[0, 1, 2, 4]) {
        final itemIndices = <int>[];
        final separatorIndices = <int>[];
        await tester.pumpWidget(
          TestSeparatedList(
            items: List<int>.generate(count, (int index) => index),
            itemBuilder: (BuildContext context, int index) {
              itemIndices.add(index);
              return _AxisBox(
                key: ValueKey<int>(index),
                axis: Axis.vertical,
                extent: 100,
                child: Text('item $index'),
              );
            },
            separatorBuilder: (BuildContext context, int boundary) {
              separatorIndices.add(boundary);
              return _AxisBox(
                key: ValueKey<String>('sep$boundary'),
                axis: Axis.vertical,
                extent: 20,
                child: Text('sep $boundary'),
              );
            },
          ),
        );

        for (var index = 0; index < count; index += 1) {
          expect(find.text('item $index'), findsOneWidget, reason: 'count $count item $index');
        }
        for (var boundary = 0; boundary < count - 1; boundary += 1) {
          expect(find.text('sep $boundary'), findsOneWidget, reason: 'count $count sep $boundary');
        }
        expect(find.text('item ${count == 0 ? 0 : count}'), findsNothing);
        if (count > 0) {
          expect(find.text('sep ${count - 1}'), findsNothing);
        }
        // itemBuilder index range is 0 .. count - 1; separatorBuilder is
        // 0 .. count - 2.
        expect(itemIndices.every((int index) => index >= 0 && index < count), isTrue);
        expect(
          separatorIndices.every((int boundary) => boundary >= 0 && boundary < count - 1),
          isTrue,
        );
      }
    });

    testWidgets('negative itemCount should assert', (WidgetTester tester) async {
      expect(
        () => SliverReorderableList.separated(
          itemCount: -1,
          itemBuilder: (_, _) => const SizedBox(),
          separatorBuilder: (_, _) => const SizedBox(),
          onReorderItem: (_, _) {},
        ),
        throwsAssertionError,
      );
    });

    testWidgets('only items receive drag listeners; separators cannot start a reorder', (
      WidgetTester tester,
    ) async {
      var reorderCalls = 0;
      await tester.pumpWidget(
        TestSeparatedList(
          items: const <int>[0, 1, 2, 3],
          onReorderItem: (int _, int _) => reorderCalls += 1,
        ),
      );

      // Separators contain no drag listener.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('sep0')),
          matching: find.byType(ReorderableDragStartListener),
        ),
        findsNothing,
      );
      // Items do contain a drag listener.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<int>(0)),
          matching: find.byType(ReorderableDragStartListener),
        ),
        findsOneWidget,
      );

      // A press-drag started on a separator does not reorder anything.
      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<String>('sep0'))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 200));
      await tester.pump(kPressTimeout);
      await drag.up();
      await tester.pumpAndSettle();
      expect(reorderCalls, 0);
    });

    testWidgets('items carry dense reorder semantics while separators carry none', (
      WidgetTester tester,
    ) async {
      final semantics = SemanticsTester(tester);
      await tester.pumpWidget(const TestSeparatedList(items: <int>[0, 1, 2, 3]));

      // Every item exposes the custom reorder semantic action; separators do
      // not (they are position-based and non-interactive).
      for (var index = 0; index < 4; index += 1) {
        expect(
          semantics,
          includesNodeWith(
            label: 'item $index',
            actions: <SemanticsAction>[SemanticsAction.customAction],
          ),
          reason: 'item $index should expose a reorder action',
        );
      }
      for (var boundary = 0; boundary < 3; boundary += 1) {
        final SemanticsNode node = tester.getSemantics(find.text('sep $boundary'));
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.customAction),
          isFalse,
          reason: 'separator $boundary should not expose reorder actions',
        );
      }

      // Items are indexed densely by item index (0..3) via the delegate's
      // semanticIndexCallback; separators contribute no semantic index.
      final List<int> indexedSemantics = tester
          .widgetList<IndexedSemantics>(find.byType(IndexedSemantics))
          .map((IndexedSemantics widget) => widget.index)
          .toList();
      expect(indexedSemantics, containsAll(<int>[0, 1, 2, 3]));
      expect(indexedSemantics.where((int index) => index >= 4), isEmpty);

      semantics.dispose();
    });

    testWidgets('accessibility reorder action reports adjusted item indices', (
      WidgetTester tester,
    ) async {
      final semantics = SemanticsTester(tester);
      final items = <int>[0, 1, 2, 3];
      int? reportedOldIndex;
      int? reportedNewIndex;
      await tester.pumpWidget(
        TestSeparatedList(
          items: items,
          onReorderItem: (int from, int to) {
            reportedOldIndex = from;
            reportedNewIndex = to;
          },
        ),
      );

      // Perform the 'Move down' custom action on item 0. The semantics path
      // routes through the shared index adjustment, so a downward move of one
      // slot must report newIndex 1, not the raw insertion index 2.
      final SemanticsNode node = tester.getSemantics(find.text('item 0'));
      final int customActionId = CustomSemanticsAction.getIdentifier(
        const CustomSemanticsAction(label: 'Move down'),
      );
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.customAction,
        customActionId,
      );
      await tester.pumpAndSettle();

      expect(reportedOldIndex, 0);
      expect(reportedNewIndex, 1);
      expect(items, orderedEquals(<int>[1, 0, 2, 3]));
      for (var boundary = 0; boundary < 3; boundary += 1) {
        expectSeparatorShown(tester, boundary);
      }

      semantics.dispose();
    });

    testWidgets('pointer cancellation during a drag restores all separators', (
      WidgetTester tester,
    ) async {
      final items = <int>[0, 1, 2, 3];
      var reorderCalls = 0;
      await tester.pumpWidget(
        TestSeparatedList(items: items, onReorderItem: (int _, int _) => reorderCalls += 1),
      );

      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(0))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 210));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expectSeparatorShown(tester, 1);

      // The gesture is canceled rather than released: no reorder fires and every
      // separator is restored with a zeroed transform.
      await drag.cancel();
      await tester.pumpAndSettle();
      expect(reorderCalls, 0);
      expect(items, orderedEquals(<int>[0, 1, 2, 3]));
      for (var boundary = 0; boundary < 3; boundary += 1) {
        expectSeparatorShown(tester, boundary);
      }
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep1')), Axis.vertical), 220);
    });

    testWidgets('multi-slot downward drag translates every item and separator', (
      WidgetTester tester,
    ) async {
      final items = <int>[0, 1, 2, 3];
      int? oldIndex;
      int? newIndex;
      await tester.pumpWidget(
        TestSeparatedList(
          items: items,
          itemExtent: distinctItemExtent,
          separatorExtent: distinctSeparatorExtent,
          onReorderItem: (int from, int to) {
            oldIndex = from;
            newIndex = to;
          },
        ),
      );

      // Initial layout (vertical):
      // item0 0..100, sep0 100..110, item1 110..220, sep1 220..240,
      // item2 240..360, sep2 360..390, item3 390..520.
      expect(topOf(tester, find.byKey(const ValueKey<int>(1)), Axis.vertical), 110);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep1')), Axis.vertical), 220);

      // Drag item0 down to final gap g == 2 (insert index 3).
      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(0))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 210));
      await tester.pump();
      // Let the per-child offset animations settle while still holding the drag.
      await tester.pump(const Duration(milliseconds: 300));

      // Expected in-flight geometry: items in (d, g] shift toward the start
      // by the dragged item's extent plus their own leading separator, and
      // separators in [d, g) shift by their following item's extent minus the
      // dragged item's extent:
      // item1 0..110, sep0 110..120, item2 120..240, sep1 240..260,
      // gap 260..360, sep2 360..390, item3 390..520.
      expect(topOf(tester, find.byKey(const ValueKey<int>(1)), Axis.vertical), 0);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep0')), Axis.vertical), 110);
      expect(topOf(tester, find.byKey(const ValueKey<int>(2)), Axis.vertical), 120);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep1')), Axis.vertical), 240);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep2')), Axis.vertical), 360);
      expect(topOf(tester, find.byKey(const ValueKey<int>(3)), Axis.vertical), 390);

      // Every separator stays visible; the gap is flanked by sep1 above and
      // sep2 below, and sep1 keeps its extent.
      for (var boundary = 0; boundary < 3; boundary += 1) {
        expectSeparatorShown(tester, boundary);
      }
      expect(extentOf(tester, find.byKey(const ValueKey<String>('sep1')), Axis.vertical), 20);

      await drag.up();
      await tester.pumpAndSettle();

      // Downward move must not be double-decremented.
      expect(oldIndex, 0);
      expect(newIndex, 2);
      expect(items, orderedEquals(<int>[1, 2, 0, 3]));
      for (var boundary = 0; boundary < 3; boundary += 1) {
        expectSeparatorShown(tester, boundary);
      }
    });

    testWidgets('multi-slot upward drag translates every item and separator', (
      WidgetTester tester,
    ) async {
      final items = <int>[0, 1, 2, 3];
      int? oldIndex;
      int? newIndex;
      await tester.pumpWidget(
        TestSeparatedList(
          items: items,
          itemExtent: distinctItemExtent,
          separatorExtent: distinctSeparatorExtent,
          onReorderItem: (int from, int to) {
            oldIndex = from;
            newIndex = to;
          },
        ),
      );

      // Drag item3 (390..520) up to final gap g == 1.
      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(3))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, -280));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Expected in-flight geometry:
      // item0 0..100, sep0 100..110, gap 110..240, sep1 240..260,
      // item1 260..370, sep2 370..400, item2 400..520.
      expect(topOf(tester, find.byKey(const ValueKey<int>(0)), Axis.vertical), 0);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep0')), Axis.vertical), 100);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep1')), Axis.vertical), 240);
      expect(topOf(tester, find.byKey(const ValueKey<int>(1)), Axis.vertical), 260);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep2')), Axis.vertical), 370);
      expect(topOf(tester, find.byKey(const ValueKey<int>(2)), Axis.vertical), 400);

      for (var boundary = 0; boundary < 3; boundary += 1) {
        expectSeparatorShown(tester, boundary);
      }

      await drag.up();
      await tester.pumpAndSettle();

      expect(oldIndex, 3);
      expect(newIndex, 1);
      expect(items, orderedEquals(<int>[0, 3, 1, 2]));
    });

    testWidgets('interior gap keeps every separator visible and preserves its state', (
      WidgetTester tester,
    ) async {
      final items = <int>[0, 1, 2, 3, 4];
      await tester.pumpWidget(
        TestSeparatedList(
          items: items,
          itemExtent: distinctItemExtent,
          separatorExtent: distinctSeparatorExtent,
        ),
      );

      final Element separator2Before = tester.element(find.byKey(const ValueKey<String>('sep2')));

      // Drag item1 down to gap g == 3. The gap ends up flanked by sep2 on its
      // leading side and sep3 on its trailing side, both visible.
      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(1))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 250));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      for (var boundary = 0; boundary < 4; boundary += 1) {
        expectSeparatorShown(tester, boundary);
      }
      // The gap-leading separator sep2 sits directly above the empty slot,
      // which is exactly the dragged item's extent (110): sep2 380..410,
      // gap 410..520, sep3 520..560.
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep2')), Axis.vertical), 380);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep3')), Axis.vertical), 520);
      // The gap-leading separator keeps its measured extent and its element
      // (and hence its State) identity.
      expect(extentOf(tester, find.byKey(const ValueKey<String>('sep2')), Axis.vertical), 30);
      expect(
        identical(tester.element(find.byKey(const ValueKey<String>('sep2'))), separator2Before),
        isTrue,
      );

      await drag.up();
      await tester.pumpAndSettle();
      expect(items, orderedEquals(<int>[0, 2, 3, 1, 4]));
    });

    testWidgets('first and last gap drags keep every separator visible', (
      WidgetTester tester,
    ) async {
      // At the first gap (g == 0) the gap has only a trailing separator; at the
      // last gap only a leading one. In both cases every separator stays
      // visible and aligned.
      final items = <int>[0, 1, 2, 3];
      await tester.pumpWidget(
        TestSeparatedList(
          items: items,
          itemExtent: distinctItemExtent,
          separatorExtent: distinctSeparatorExtent,
        ),
      );

      // Drag item1 up into the first gap (g == 0).
      TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(1))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, -85));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      for (var boundary = 0; boundary < 3; boundary += 1) {
        expectSeparatorShown(tester, boundary);
      }
      await drag.up();
      await tester.pumpAndSettle();
      expect(items, orderedEquals(<int>[1, 0, 2, 3]));

      // Reset the order for the last-gap case.
      items.setAll(0, <int>[0, 1, 2, 3]);
      await tester.pumpWidget(
        TestSeparatedList(
          items: items,
          itemExtent: distinctItemExtent,
          separatorExtent: distinctSeparatorExtent,
        ),
      );

      // Drag item0 down into the last gap (g == 3): its leading separator sep2
      // stays visible directly above the empty slot at the list end.
      final Element separator2Before = tester.element(find.byKey(const ValueKey<String>('sep2')));
      drag = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey<int>(0))));
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 370));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      for (var boundary = 0; boundary < 3; boundary += 1) {
        expectSeparatorShown(tester, boundary);
      }
      // The gap-leading separator keeps its measured extent and its element
      // (and hence its State) identity.
      expect(extentOf(tester, find.byKey(const ValueKey<String>('sep2')), Axis.vertical), 30);
      expect(
        identical(tester.element(find.byKey(const ValueKey<String>('sep2'))), separator2Before),
        isTrue,
      );
      await drag.up();
      await tester.pumpAndSettle();
      expect(items, orderedEquals(<int>[1, 2, 3, 0]));
    });

    testWidgets('no callback fires when an item is dropped in its original gap', (
      WidgetTester tester,
    ) async {
      final items = <int>[0, 1, 2, 3];
      var reorderCalls = 0;
      await tester.pumpWidget(
        TestSeparatedList(items: items, onReorderItem: (int _, int _) => reorderCalls += 1),
      );

      // Small drag that snaps back to the original position (d == g).
      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(1))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 10));
      await tester.pump(kPressTimeout);
      await drag.up();
      await tester.pumpAndSettle();

      expect(reorderCalls, 0);
      expect(items, orderedEquals(<int>[0, 1, 2, 3]));
    });

    testWidgets('separator styles stay tied to the visual boundary index', (
      WidgetTester tester,
    ) async {
      final items = <int>[0, 1, 2, 3];
      await tester.pumpWidget(
        TestSeparatedList(
          items: items,
          separatorBuilder: (BuildContext context, int boundary) {
            // Position-dependent style: even boundaries are tall, odd short.
            return _AxisBox(
              key: ValueKey<String>('sep$boundary'),
              axis: Axis.vertical,
              extent: boundary.isEven ? 30 : 10,
              child: Text('sep $boundary'),
            );
          },
        ),
      );

      double separatorExtent(int boundary) =>
          extentOf(tester, find.byKey(ValueKey<String>('sep$boundary')), Axis.vertical);
      expect(separatorExtent(0), 30);
      expect(separatorExtent(1), 10);
      expect(separatorExtent(2), 30);

      // Reorder and confirm boundary 0 is still tall, boundary 1 still short:
      // the style follows the boundary, not a data item.
      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(0))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 210));
      await tester.pump(kPressTimeout);
      await drag.up();
      await tester.pumpAndSettle();

      expect(items, orderedEquals(<int>[1, 2, 0, 3]));
      expect(separatorExtent(0), 30);
      expect(separatorExtent(1), 10);
      expect(separatorExtent(2), 30);
    });

    testWidgets('an explicit cancelReorder mid-drag restores all separators and zero transforms', (
      WidgetTester tester,
    ) async {
      final items = <int>[0, 1, 2, 3];
      final listKey = GlobalKey<SliverReorderableListState>();
      await tester.pumpWidget(TestSeparatedList(items: items, listKey: listKey));

      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(0))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 210));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expectSeparatorShown(tester, 1);

      listKey.currentState!.cancelReorder();
      await tester.pumpAndSettle();
      await drag.up();
      await tester.pumpAndSettle();
      for (var boundary = 0; boundary < 3; boundary += 1) {
        expectSeparatorShown(tester, boundary);
      }
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep0')), Axis.vertical), 100);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep1')), Axis.vertical), 220);
      expect(items, orderedEquals(<int>[0, 1, 2, 3]));
    });

    testWidgets('a drop restores all separators and settles all transforms', (
      WidgetTester tester,
    ) async {
      final items = <int>[0, 1, 2, 3];
      await tester.pumpWidget(TestSeparatedList(items: items));

      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(0))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 90));
      await tester.pump(kPressTimeout);
      await drag.up();
      await tester.pumpAndSettle();
      for (var boundary = 0; boundary < 3; boundary += 1) {
        expectSeparatorShown(tester, boundary);
      }
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep0')), Axis.vertical), 100);
      expect(items, orderedEquals(<int>[1, 0, 2, 3]));
    });

    testWidgets('an itemCount change during a drag restores all separators', (
      WidgetTester tester,
    ) async {
      final items = <int>[0, 1, 2, 3, 4];
      await tester.pumpWidget(TestSeparatedList(items: items));

      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(0))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 210));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expectSeparatorShown(tester, 1);

      // Shrinking itemCount mid-drag cancels the reorder and must restore
      // every separator without crashing.
      items.removeLast();
      await tester.pumpWidget(TestSeparatedList(items: items));
      await drag.up();
      await tester.pumpAndSettle();

      expect(items, orderedEquals(<int>[0, 1, 2, 3]));
      for (var boundary = 0; boundary < 3; boundary += 1) {
        expectSeparatorShown(tester, boundary);
      }
    });

    testWidgets('switching to the default constructor mid-drag cancels cleanly', (
      WidgetTester tester,
    ) async {
      final items = <int>[0, 1, 2, 3];
      var reorderCalls = 0;

      Widget buildList({required bool separated}) {
        Widget itemBuilder(BuildContext context, int index) {
          return _AxisBox(
            key: ValueKey<int>(items[index]),
            axis: Axis.vertical,
            extent: 100,
            child: ReorderableDragStartListener(index: index, child: Text('item ${items[index]}')),
          );
        }

        Widget separatorBuilder(BuildContext context, int boundary) {
          return _AxisBox(
            key: ValueKey<String>('sep$boundary'),
            axis: Axis.vertical,
            extent: 20,
            child: Text('sep $boundary'),
          );
        }

        return TestWidgetsApp(
          home: CustomScrollView(
            slivers: <Widget>[
              if (separated)
                SliverReorderableList.separated(
                  itemCount: items.length,
                  itemBuilder: itemBuilder,
                  separatorBuilder: separatorBuilder,
                  onReorderItem: (int _, int _) => reorderCalls += 1,
                )
              else
                SliverReorderableList(
                  itemCount: items.length,
                  itemBuilder: itemBuilder,
                  onReorderItem: (int _, int _) => reorderCalls += 1,
                ),
            ],
          ),
        );
      }

      await tester.pumpWidget(buildList(separated: true));

      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(0))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 210));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Swap in the default constructor while the drag is active: the reorder
      // cancels, the separators unmount, and the drag's separator state must
      // not leak into the non-separated layout.
      await tester.pumpWidget(buildList(separated: false));
      await drag.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(reorderCalls, 0);
      expect(items, orderedEquals(<int>[0, 1, 2, 3]));
      expect(find.text('sep 0'), findsNothing);
      // Every item sits at its natural, untransformed position.
      for (var index = 0; index < items.length; index += 1) {
        expect(topOf(tester, find.byKey(ValueKey<int>(index)), Axis.vertical), index * 100.0);
      }
    });

    testWidgets('findItemIndexCallback receives only original item keys and preserves item state', (
      WidgetTester tester,
    ) async {
      final items = <int>[0, 1, 2, 3];
      final receivedKeys = <Key>[];
      await tester.pumpWidget(
        TestSeparatedList(
          items: items,
          findItemIndexCallback: (Key key) {
            receivedKeys.add(key);
            if (key is ValueKey<int>) {
              final int position = items.indexOf(key.value);
              return position == -1 ? null : position;
            }
            return null;
          },
          itemBuilder: (BuildContext context, int index) {
            final int value = items[index];
            return _AxisBox(
              key: ValueKey<int>(value),
              axis: Axis.vertical,
              extent: 100,
              child: ReorderableDragStartListener(
                index: index,
                child: _StatefulLabel(label: 'item $value'),
              ),
            );
          },
        ),
      );

      // Capture the State of an item that the reorder relocates (item 1 moves
      // from index 1 to index 0) and give it local state that only survives if
      // the State instance itself survives.
      final _StatefulLabelState stateBefore = tester.state<_StatefulLabelState>(
        find.descendant(
          of: find.byKey(const ValueKey<int>(1)),
          matching: find.byType(_StatefulLabel),
        ),
      );
      stateBefore.localState = 42;

      // A non-adjacent reorder forces the delegate to relocate keyed children,
      // which invokes findItemIndexCallback.
      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(0))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, 210));
      await tester.pump(kPressTimeout);
      await drag.up();
      await tester.pumpAndSettle();

      expect(items, orderedEquals(<int>[1, 2, 0, 3]));
      // The callback was invoked, and every forwarded key is an original user
      // item key: exactly ValueKey<int>, never the private item-wrapper key and
      // never a separator key. The runtimeType comparison matters because the
      // private separator key subtypes ValueKey<int>, so an `is` check could
      // not detect a leaked separator key.
      expect(receivedKeys, isNotEmpty);
      expect(
        receivedKeys.every((Key key) => key.runtimeType == ValueKey<int>),
        isTrue,
        reason: 'findItemIndexCallback must only receive original item keys, got $receivedKeys',
      );
      // Relocating the keyed item must preserve its State, not merely rebuild
      // an equivalent widget at the new index.
      final _StatefulLabelState stateAfter = tester.state<_StatefulLabelState>(
        find.descendant(
          of: find.byKey(const ValueKey<int>(1)),
          matching: find.byType(_StatefulLabel),
        ),
      );
      expect(identical(stateAfter, stateBefore), isTrue);
      expect(stateAfter.localState, 42);
    });

    testWidgets('horizontal and reverse lists settle to the reordered order', (
      WidgetTester tester,
    ) async {
      Future<void> runAxis(Axis axis, {required bool reverse}) async {
        final items = <int>[0, 1, 2, 3];
        await tester.pumpWidget(
          TestSeparatedList(items: items, scrollDirection: axis, reverse: reverse),
        );
        await tester.pump();

        // A single-slot move expressed as the vector from item0 to item1. Using
        // real centers makes the delta adapt to the scroll axis and to reversed
        // layouts automatically; the 0.75 factor lands the proxy in item1's
        // second half so it inserts after it.
        final Offset start = tester.getCenter(find.byKey(const ValueKey<int>(0)));
        final Offset delta = (tester.getCenter(find.byKey(const ValueKey<int>(1))) - start) * 0.75;
        final TestGesture drag = await tester.startGesture(start);
        await tester.pump(kPressTimeout);
        await drag.moveBy(delta);
        await tester.pump(kPressTimeout);
        await drag.up();
        await tester.pumpAndSettle();

        expect(items, orderedEquals(<int>[1, 0, 2, 3]), reason: 'axis $axis reverse $reverse');
        for (var boundary = 0; boundary < 3; boundary += 1) {
          expectSeparatorShown(tester, boundary);
        }
      }

      await runAxis(Axis.vertical, reverse: false);
      await runAxis(Axis.vertical, reverse: true);
      await runAxis(Axis.horizontal, reverse: false);
      await runAxis(Axis.horizontal, reverse: true);
    });

    testWidgets('horizontal multi-slot drag translates every item and separator', (
      WidgetTester tester,
    ) async {
      final items = <int>[0, 1, 2, 3];
      await tester.pumpWidget(
        TestSeparatedList(
          items: items,
          scrollDirection: Axis.horizontal,
          itemExtent: distinctItemExtent,
          separatorExtent: distinctSeparatorExtent,
        ),
      );

      // Initial layout (horizontal, left to right):
      // item0 0..100, sep0 100..110, item1 110..220, sep1 220..240,
      // item2 240..360, sep2 360..390, item3 390..520.
      expect(topOf(tester, find.byKey(const ValueKey<int>(1)), Axis.horizontal), 110);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep1')), Axis.horizontal), 220);

      // Drag item0 right to final gap g == 2 (insert index 3), mirroring the
      // vertical multi-slot downward test on the horizontal axis.
      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(0))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(210, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Expected in-flight geometry, identical to the vertical case but along
      // the horizontal axis:
      // item1 0..110, sep0 110..120, item2 120..240, sep1 240..260,
      // gap 260..360, sep2 360..390, item3 390..520.
      expect(topOf(tester, find.byKey(const ValueKey<int>(1)), Axis.horizontal), 0);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep0')), Axis.horizontal), 110);
      expect(topOf(tester, find.byKey(const ValueKey<int>(2)), Axis.horizontal), 120);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep1')), Axis.horizontal), 240);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep2')), Axis.horizontal), 360);
      expect(topOf(tester, find.byKey(const ValueKey<int>(3)), Axis.horizontal), 390);
      for (var boundary = 0; boundary < 3; boundary += 1) {
        expectSeparatorShown(tester, boundary);
      }
      expect(extentOf(tester, find.byKey(const ValueKey<String>('sep1')), Axis.horizontal), 20);

      await drag.up();
      await tester.pumpAndSettle();
      expect(items, orderedEquals(<int>[1, 2, 0, 3]));
    });

    testWidgets('reversed multi-slot drag translates every item and separator', (
      WidgetTester tester,
    ) async {
      final items = <int>[0, 1, 2, 3];
      await tester.pumpWidget(
        TestSeparatedList(
          items: items,
          reverse: true,
          itemExtent: distinctItemExtent,
          separatorExtent: distinctSeparatorExtent,
        ),
      );

      // Initial layout (reverse vertical, anchored to the 600px viewport
      // bottom and growing upward):
      // item0 500..600, sep0 490..500, item1 380..490, sep1 360..380,
      // item2 240..360, sep2 210..240, item3 80..210.
      expect(topOf(tester, find.byKey(const ValueKey<int>(0)), Axis.vertical), 500);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep0')), Axis.vertical), 490);
      expect(topOf(tester, find.byKey(const ValueKey<int>(1)), Axis.vertical), 380);

      // Drag item0 up, toward the end of the reversed list, to final gap
      // g == 2 (insert index 3). A sign error in the reverse-axis conversion
      // would translate children the wrong way mid-drag even if the settled
      // order came out right.
      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(0))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(0, -210));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Expected in-flight geometry, the non-reversed downward case mirrored
      // along the axis:
      // item3 80..210, sep2 210..240, gap 240..340, sep1 340..360,
      // item2 360..480, sep0 480..490, item1 490..600.
      expect(topOf(tester, find.byKey(const ValueKey<int>(1)), Axis.vertical), 490);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep0')), Axis.vertical), 480);
      expect(topOf(tester, find.byKey(const ValueKey<int>(2)), Axis.vertical), 360);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep1')), Axis.vertical), 340);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep2')), Axis.vertical), 210);
      expect(topOf(tester, find.byKey(const ValueKey<int>(3)), Axis.vertical), 80);
      for (var boundary = 0; boundary < 3; boundary += 1) {
        expectSeparatorShown(tester, boundary);
      }
      expect(extentOf(tester, find.byKey(const ValueKey<String>('sep1')), Axis.vertical), 20);

      await drag.up();
      await tester.pumpAndSettle();
      expect(items, orderedEquals(<int>[1, 2, 0, 3]));
    });

    testWidgets('reversed horizontal multi-slot drag translates every item and separator', (
      WidgetTester tester,
    ) async {
      final items = <int>[0, 1, 2, 3];
      await tester.pumpWidget(
        TestSeparatedList(
          items: items,
          scrollDirection: Axis.horizontal,
          reverse: true,
          itemExtent: distinctItemExtent,
          separatorExtent: distinctSeparatorExtent,
        ),
      );

      // Initial layout (reverse horizontal, anchored to the 800px viewport
      // right edge and growing leftward):
      // item0 700..800, sep0 690..700, item1 580..690, sep1 560..580,
      // item2 440..560, sep2 410..440, item3 280..410.
      expect(topOf(tester, find.byKey(const ValueKey<int>(0)), Axis.horizontal), 700);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep0')), Axis.horizontal), 690);
      expect(topOf(tester, find.byKey(const ValueKey<int>(1)), Axis.horizontal), 580);

      // Drag item0 left, toward the end of the reversed list, to final gap
      // g == 2 (insert index 3). A sign error in the reverse-axis conversion
      // could cancel against one in the axis swap and still settle to the
      // right order, so the in-flight rectangles are asserted too.
      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(0))),
      );
      await tester.pump(kPressTimeout);
      await drag.moveBy(const Offset(-210, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Expected in-flight geometry, the non-reversed downward case mirrored
      // along the horizontal axis:
      // item3 280..410, sep2 410..440, gap 440..540, sep1 540..560,
      // item2 560..680, sep0 680..690, item1 690..800.
      expect(topOf(tester, find.byKey(const ValueKey<int>(1)), Axis.horizontal), 690);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep0')), Axis.horizontal), 680);
      expect(topOf(tester, find.byKey(const ValueKey<int>(2)), Axis.horizontal), 560);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep1')), Axis.horizontal), 540);
      expect(topOf(tester, find.byKey(const ValueKey<String>('sep2')), Axis.horizontal), 410);
      expect(topOf(tester, find.byKey(const ValueKey<int>(3)), Axis.horizontal), 280);
      for (var boundary = 0; boundary < items.length - 1; boundary += 1) {
        expectSeparatorShown(tester, boundary);
      }
      expect(extentOf(tester, find.byKey(const ValueKey<String>('sep1')), Axis.horizontal), 20);

      await drag.up();
      await tester.pumpAndSettle();
      expect(items, orderedEquals(<int>[1, 2, 0, 3]));
    });

    testWidgets('direction reversal while offset animations are running settles correctly', (
      WidgetTester tester,
    ) async {
      final items = <int>[0, 1, 2, 3, 4];
      await tester.pumpWidget(
        TestSeparatedList(
          items: items,
          itemExtent: distinctItemExtent,
          separatorExtent: distinctSeparatorExtent,
        ),
      );

      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(0))),
      );
      await tester.pump(kPressTimeout);
      // Move down to open a gap, then reverse before the animation completes.
      await drag.moveBy(const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await drag.moveBy(const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Back at the original gap: all separators shown, transforms zeroed.
      for (var boundary = 0; boundary < 4; boundary += 1) {
        expectSeparatorShown(tester, boundary);
      }
      expect(topOf(tester, find.byKey(const ValueKey<int>(1)), Axis.vertical), 110);

      await drag.up();
      await tester.pumpAndSettle();
      expect(items, orderedEquals(<int>[0, 1, 2, 3, 4]));
    });

    testWidgets('autoscroll builds and disposes children mid-drag and still reorders', (
      WidgetTester tester,
    ) async {
      final items = List<int>.generate(20, (int index) => index);
      int? droppedIndex;
      await tester.pumpWidget(
        TestSeparatedList(
          items: items,
          autoScrollerVelocityScalar: 1000,
          onReorderItem: (int from, int to) => droppedIndex = to,
        ),
      );

      // A later item does not fit in the 600px viewport initially.
      expect(find.byKey(const ValueKey<int>(10)), findsNothing);

      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<int>(0))),
      );
      await tester.pump(kPressTimeout);
      // Hold the drag against the bottom edge to trigger autoscroll, which
      // disposes children at the top and builds new ones at the bottom
      // mid-drag.
      await drag.moveBy(const Offset(0, 560));
      for (var frame = 0; frame < 40; frame += 1) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // A previously-unbuilt item was built while the drag was in progress.
      // (Item 0 stays findable because it is the dragged item rendered in the
      // drag proxy overlay.)
      expect(find.byKey(const ValueKey<int>(10)), findsOneWidget);

      // Leave the autoscroll edge zone and let the scroll and the offset
      // animations settle while still holding the drag, so the in-flight
      // geometry below is stable.
      await drag.moveBy(const Offset(0, -100));
      await tester.pumpAndSettle();

      // Record the lazily built item 10's in-flight position; it is validated
      // below against the drop index the reorder callback reports.
      const slotExtent = 120.0;
      final double pixels = tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
      final double item10Top = topOf(tester, find.byKey(const ValueKey<int>(10)), Axis.vertical);

      await drag.up();
      await tester.pumpAndSettle();

      // Item 0 moved somewhere past item 10 and the list is intact.
      expect(droppedIndex, isNotNull);
      expect(droppedIndex, greaterThanOrEqualTo(10));
      expect(items.first, isNot(0));
      expect(items, hasLength(20));

      // Since the insertion gap g was at or past item 10, the lazily built
      // item 10 must have sat at its transformed in-flight position: items in
      // (d, g] are shifted one slot (slotExtent) toward the start. A child
      // that registered mid-drag but was left at a stale zero transform would
      // have sat one slot lower.
      // (Separator target offsets are exactly zero under uniform extents, so
      // the items are the discriminating children in this test.)
      expect(item10Top, moreOrLessEquals(10 * slotExtent - slotExtent - pixels));

      // Every separator currently in view is restored at its natural boundary
      // with a zeroed transform.
      final double settledPixels = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .pixels;
      var mountedSeparators = 0;
      for (var boundary = 0; boundary < items.length - 1; boundary += 1) {
        final Finder separator = find.byKey(ValueKey<String>('sep$boundary'));
        if (!tester.any(separator)) {
          continue;
        }
        mountedSeparators += 1;
        expect(
          topOf(tester, separator, Axis.vertical),
          moreOrLessEquals((boundary + 1) * 100.0 + boundary * 20.0 - settledPixels),
          reason: 'separator $boundary should be restored after the drag',
        );
      }
      expect(mountedSeparators, greaterThan(0));
    });
  });
}

class TestSeparatedList extends StatelessWidget {
  const TestSeparatedList({
    super.key,
    required this.items,
    this.listKey,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.itemExtent,
    this.separatorExtent,
    this.onReorderItem,
    this.findItemIndexCallback,
    this.autoScrollerVelocityScalar,
    this.itemBuilder,
    this.separatorBuilder,
  });

  static const double _defaultItemExtent = 100.0;
  static const double _defaultSeparatorExtent = 20.0;

  final List<int> items;
  final Key? listKey;
  final Axis scrollDirection;
  final bool reverse;
  final double Function(int value)? itemExtent;
  final double Function(int boundary)? separatorExtent;
  final ReorderCallback? onReorderItem;
  final ChildIndexGetter? findItemIndexCallback;
  final double? autoScrollerVelocityScalar;
  final IndexedWidgetBuilder? itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;

  @override
  Widget build(BuildContext context) {
    return TestWidgetsApp(
      home: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return CustomScrollView(
            scrollDirection: scrollDirection,
            reverse: reverse,
            slivers: <Widget>[
              SliverReorderableList.separated(
                key: listKey,
                itemCount: items.length,
                autoScrollerVelocityScalar: autoScrollerVelocityScalar,
                findItemIndexCallback: findItemIndexCallback,
                itemBuilder:
                    itemBuilder ??
                    (BuildContext context, int index) {
                      final int value = items[index];
                      return _AxisBox(
                        key: ValueKey<int>(value),
                        axis: scrollDirection,
                        extent: itemExtent?.call(value) ?? _defaultItemExtent,
                        child: ReorderableDragStartListener(
                          index: index,
                          child: Text('item $value'),
                        ),
                      );
                    },
                separatorBuilder:
                    separatorBuilder ??
                    (BuildContext context, int boundary) {
                      return _AxisBox(
                        key: ValueKey<String>('sep$boundary'),
                        axis: scrollDirection,
                        extent: separatorExtent?.call(boundary) ?? _defaultSeparatorExtent,
                        child: Text('sep $boundary'),
                      );
                    },
                onReorderItem: (int fromIndex, int toIndex) {
                  onReorderItem?.call(fromIndex, toIndex);
                  setState(() {
                    items.insert(toIndex, items.removeAt(fromIndex));
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// A box whose extent along [axis] is fixed and whose cross-axis extent fills
// the viewport. Used by the separated-list tests so that every item and
// separator has a deterministic, assertable rectangle.
class _AxisBox extends StatelessWidget {
  const _AxisBox({super.key, required this.axis, required this.extent, required this.child});

  final Axis axis;
  final double extent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return axis == Axis.vertical
        ? SizedBox(height: extent, width: double.infinity, child: child)
        : SizedBox(width: extent, height: double.infinity, child: child);
  }
}

// A stateful leaf for the separated-list tests. Its [State] retains
// [localState] only if the framework relocates (rather than recreates) its
// element when a keyed item moves to a new index.
class _StatefulLabel extends StatefulWidget {
  const _StatefulLabel({required this.label});

  final String label;

  @override
  State<_StatefulLabel> createState() => _StatefulLabelState();
}

class _StatefulLabelState extends State<_StatefulLabel> {
  int localState = 0;

  @override
  Widget build(BuildContext context) {
    return Text(widget.label);
  }
}

class TestList extends StatelessWidget {
  const TestList({
    super.key,
    this.textColor,
    this.iconColor,
    this.proxyDecorator,
    required this.items,
    this.reverse = false,
    this.onReorderStart,
    this.onReorderEnd,
    this.autoScrollerVelocityScalar,
  });

  final List<int> items;
  final Color? textColor;
  final Color? iconColor;
  final ReorderItemProxyDecorator? proxyDecorator;
  final bool reverse;
  final void Function(int)? onReorderStart, onReorderEnd;
  final double? autoScrollerVelocityScalar;

  @override
  Widget build(BuildContext context) {
    return TestWidgetsApp(
      home: DefaultTextStyle(
        style: TextStyle(color: textColor),
        child: IconTheme(
          data: IconThemeData(color: iconColor),
          child: StatefulBuilder(
            builder: (BuildContext outerContext, StateSetter setState) {
              final List<int> items = this.items;
              return CustomScrollView(
                reverse: reverse,
                slivers: <Widget>[
                  SliverReorderableList(
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        key: ValueKey<int>(items[index]),
                        height: 100,
                        color: items[index].isOdd ? _kRedColor : _kGreenColor,
                        child: ReorderableDragStartListener(
                          index: index,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('item ${items[index]}'),
                              const Icon(_kDragHandleIconData),
                            ],
                          ),
                        ),
                      );
                    },
                    itemCount: items.length,
                    onReorderItem: (int fromIndex, int toIndex) {
                      setState(() {
                        items.insert(toIndex, items.removeAt(fromIndex));
                      });
                    },
                    proxyDecorator: proxyDecorator,
                    onReorderStart: onReorderStart,
                    onReorderEnd: onReorderEnd,
                    autoScrollerVelocityScalar: autoScrollerVelocityScalar,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
