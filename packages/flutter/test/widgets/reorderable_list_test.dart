// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression test for https://github.com/flutter/flutter/issues/88191
  testWidgets('Do not crash when dragging with two fingers simultaneously', (WidgetTester tester) async {
    final List<int> items = List<int>.generate(3, (int index) => index);
    void handleReorder(int fromIndex, int toIndex) {
      if (toIndex > fromIndex) {
        toIndex -= 1;
      }
      items.insert(toIndex, items.removeAt(fromIndex));
    }

    await tester.pumpWidget(MaterialApp(
      home: ReorderableList(
        itemBuilder: (BuildContext context, int index) {
          return ReorderableDragStartListener(
            index: index,
            key: ValueKey<int>(items[index]),
            child: SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('item ${items[index]}'),
                ],
              ),
            ),
          );
        },
        itemCount: items.length,
        onReorder: handleReorder,
      ),
    ));

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
    final List<int> items = <int>[1, 2, 3];
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (BuildContext outerContext, StateSetter setState) {
          return CustomScrollView(
            slivers: <Widget>[
              SliverReorderableList(
                itemCount: -1,
                onReorder: (int fromIndex, int toIndex) {
                  setState(() {
                    if (toIndex > fromIndex) {
                      toIndex -= 1;
                    }
                    items.insert(toIndex, items.removeAt(fromIndex));
                  });
                },
                itemBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    height: 100,
                    child: Text('item ${items[index]}'),
                  );
                },
              ),
            ],
          );
        },
      ),
    ));
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('zero itemCount should not build widget', (WidgetTester tester) async {
    final List<int> items = <int>[1, 2, 3];
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (BuildContext outerContext, StateSetter setState) {
          return CustomScrollView(
            slivers: <Widget>[
              SliverFixedExtentList(
                itemExtent: 50.0,
                delegate: SliverChildListDelegate(<Widget>[
                  const Text('before'),
                ]),
              ),
              SliverReorderableList(
                itemCount: 0,
                onReorder: (int fromIndex, int toIndex) {
                  setState(() {
                    if (toIndex > fromIndex) {
                      toIndex -= 1;
                    }
                    items.insert(toIndex, items.removeAt(fromIndex));
                  });
                },
                itemBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    height: 100,
                    child: Text('item ${items[index]}'),
                  );
                },
              ),
              SliverFixedExtentList(
                itemExtent: 50.0,
                delegate: SliverChildListDelegate(<Widget>[
                  const Text('after'),
                ]),
              ),
            ],
          );
        },
      ),
    ));

    expect(find.text('before'), findsOneWidget);
    expect(find.byType(SliverReorderableList), findsNothing);
    expect(find.text('after'), findsOneWidget);
  });

  testWidgets('SliverReorderableList, drag and drop, fixed height items', (WidgetTester tester) async {
    final List<int> items = List<int>.generate(8, (int index) => index);

    Future<void> pressDragRelease(Offset start, Offset delta) async {
      final TestGesture drag = await tester.startGesture(start);
      await tester.pump(kPressTimeout);
      await drag.moveBy(delta);
      await tester.pump(kPressTimeout);
      await drag.up();
      await tester.pumpAndSettle();
    }

    void check({ List<int> visible = const <int>[], List<int> hidden = const <int>[] }) {
      for (final int i in visible) {
        expect(find.text('item $i'), findsOneWidget);
      }
      for (final int i in hidden) {
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

  testWidgets('SliverReorderableList, items inherit DefaultTextStyle, IconTheme', (WidgetTester tester) async {
    const Color textColor = Color(0xffffffff);
    const Color iconColor = Color(0xff0000ff);

    TextStyle getIconStyle() {
      return tester.widget<RichText>(
        find.descendant(
          of: find.byType(Icon),
          matching: find.byType(RichText),
        ),
      ).text.style!;
    }

    TextStyle getTextStyle() {
      return tester.widget<RichText>(
        find.descendant(
          of: find.text('item 0'),
          matching: find.byType(RichText),
        ),
      ).text.style!;
    }

    // This SliverReorderableList has just one item: "item 0".
    await tester.pumpWidget(
      TestList(
        items: List<int>.from(<int>[0]),
        textColor: textColor,
        iconColor: iconColor,
      ),
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
    const ValueKey<String> fadeTransitionKey = ValueKey<String>('reordered-fade');

    await tester.pumpWidget(
      TestList(
        items: List<int>.from(<int>[0, 1, 2, 3]),
        proxyDecorator: (
            Widget child,
            int index,
            Animation<double> animation,
            ) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final Tween<double> fadeValues = Tween<double>(begin: 1.0, end: 0.5);
              final Animation<double> fadeAnimation = animation.drive(fadeValues);
              return FadeTransition(
                key: fadeTransitionKey,
                opacity: fadeAnimation,
                child: child,
              );
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

  testWidgets('ReorderableList supports items with nested list views without throwing layout exception.', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
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
        home: Scaffold(
          appBar: AppBar(title: const Text('Nested Lists')),
          body: ReorderableList(
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
            onReorder: (int oldIndex, int newIndex) {},
          ),
        ),
      ),
    );

    // Start gesture on first item
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey<int>(0))));
    await tester.pump(kPressTimeout);

    // Drag enough for move to start
    await drag.moveBy(const Offset(0, 50));
    await tester.pumpAndSettle();

    // There shouldn't be a layout overflow exception.
    expect(tester.takeException(), isNull);
  });

  testWidgets('ReorderableList supports items with nested list views without throwing layout exception.', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/83224.
    await tester.pumpWidget(
      MaterialApp(
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
        home: Scaffold(
          appBar: AppBar(title: const Text('Nested Lists')),
          body: ReorderableList(
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
            onReorder: (int oldIndex, int newIndex) {},
          ),
        ),
      ),
    );

    // Start gesture on first item.
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey<int>(0))));
    await tester.pump(kPressTimeout);

    // Drag enough for move to start.
    await drag.moveBy(const Offset(0, 50));
    await tester.pumpAndSettle();

    // There shouldn't be a layout overflow exception.
    expect(tester.takeException(), isNull);
  });

  testWidgets('SliverReorderableList - properly animates the drop at starting position in a reversed list', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/84625
    final List<int> items = List<int>.generate(8, (int index) => index);

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
  });

  testWidgets('ReorderableList asserts on both non-null itemExtent and prototypeItem', (WidgetTester tester) async {
    final List<int> numbers = <int>[0,1,2];
    expect(() => ReorderableList(
      itemBuilder: (BuildContext context, int index) {
        return SizedBox(
            key: ValueKey<int>(numbers[index]),
            height: 20 + numbers[index] * 10,
            child: ReorderableDragStartListener(
              index: index,
              child: Text(numbers[index].toString()),
            )
        );
      },
      itemCount: numbers.length,
      itemExtent: 30,
      prototypeItem: const SizedBox(),
      onReorder: (int fromIndex, int toIndex) { },
    ), throwsAssertionError);
  });

  testWidgets('SliverReorderableList asserts on both non-null itemExtent and prototypeItem', (WidgetTester tester) async {
    final List<int> numbers = <int>[0,1,2];
    expect(() => SliverReorderableList(
      itemBuilder: (BuildContext context, int index) {
        return SizedBox(
            key: ValueKey<int>(numbers[index]),
            height: 20 + numbers[index] * 10,
            child: ReorderableDragStartListener(
              index: index,
              child: Text(numbers[index].toString()),
            )
        );
      },
      itemCount: numbers.length,
      itemExtent: 30,
      prototypeItem: const SizedBox(),
      onReorder: (int fromIndex, int toIndex) { },
    ), throwsAssertionError);
  });

  testWidgets('if itemExtent is non-null, children have same extent in the scroll direction', (WidgetTester tester) async {
    final List<int> numbers = <int>[0,1,2];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
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
                    )
                  );
                },
                itemCount: numbers.length,
                itemExtent: 30,
                onReorder: (int fromIndex, int toIndex) {
                  if (fromIndex < toIndex) {
                    toIndex--;
                  }
                  final int value = numbers.removeAt(fromIndex);
                  numbers.insert(toIndex, value);
                },
              );
            },
          ),
        ),
      )
    );

    final double item0Height = tester.getSize(find.text('0').hitTestable()).height;
    final double item1Height = tester.getSize(find.text('1').hitTestable()).height;
    final double item2Height = tester.getSize(find.text('2').hitTestable()).height;

    expect(item0Height, 30.0);
    expect(item1Height, 30.0);
    expect(item2Height, 30.0);
  });

  testWidgets('if prototypeItem is non-null, children have same extent in the scroll direction', (WidgetTester tester) async {
    final List<int> numbers = <int>[0,1,2];

    await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
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
                        )
                    );
                  },
                  itemCount: numbers.length,
                  prototypeItem: const SizedBox(
                    height: 30,
                    child: Text('3'),
                  ),
                  onReorder: (int oldIndex, int newIndex) {  },
                );
              },
            ),
          ),
        )
    );

    final double item0Height = tester.getSize(find.text('0').hitTestable()).height;
    final double item1Height = tester.getSize(find.text('1').hitTestable()).height;
    final double item2Height = tester.getSize(find.text('2').hitTestable()).height;

    expect(item0Height, 30.0);
    expect(item1Height, 30.0);
    expect(item2Height, 30.0);
  });

  group('ReorderableDragStartListener', () {
    testWidgets('It should allow the item to be dragged when enabled is true', (WidgetTester tester) async {
      const int itemCount = 5;
      int onReorderCallCount = 0;
      final List<int> items = List<int>.generate(itemCount, (int index) => index);

      void handleReorder(int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        if (toIndex > fromIndex) {
          toIndex -= 1;
        }
        items.insert(toIndex, items.removeAt(fromIndex));
      }
      // The list has five elements of height 100
      await tester.pumpWidget(
        MaterialApp(
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
            onReorder: handleReorder,
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

    testWidgets('It should not allow the item to be dragged when enabled is false', (WidgetTester tester) async {
      const int itemCount = 5;
      int onReorderCallCount = 0;
      final List<int> items = List<int>.generate(itemCount, (int index) => index);

      void handleReorder(int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        if (toIndex > fromIndex) {
          toIndex -= 1;
        }
        items.insert(toIndex, items.removeAt(fromIndex));
      }
      // The list has five elements of height 100
      await tester.pumpWidget(
        MaterialApp(
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
            onReorder: handleReorder,
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
    testWidgets('It should allow the item to be dragged when enabled is true', (WidgetTester tester) async {
      const int itemCount = 5;
      int onReorderCallCount = 0;
      final List<int> items = List<int>.generate(itemCount, (int index) => index);

      void handleReorder(int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        if (toIndex > fromIndex) {
          toIndex -= 1;
        }
        items.insert(toIndex, items.removeAt(fromIndex));
      }
      // The list has five elements of height 100
      await tester.pumpWidget(
        MaterialApp(
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
            onReorder: handleReorder,
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

    testWidgets('It should not allow the item to be dragged when enabled is false', (WidgetTester tester) async {
      const int itemCount = 5;
      int onReorderCallCount = 0;
      final List<int> items = List<int>.generate(itemCount, (int index) => index);

      void handleReorder(int fromIndex, int toIndex) {
        onReorderCallCount += 1;
        if (toIndex > fromIndex) {
          toIndex -= 1;
        }
        items.insert(toIndex, items.removeAt(fromIndex));
      }
      // The list has five elements of height 100
      await tester.pumpWidget(
        MaterialApp(
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
            onReorder: handleReorder,
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
}

class TestList extends StatefulWidget {
  const TestList({
    Key? key,
    this.textColor,
    this.iconColor,
    this.proxyDecorator,
    required this.items,
    this.reverse = false,
  }) : super(key: key);

  final List<int> items;
  final Color? textColor;
  final Color? iconColor;
  final ReorderItemProxyDecorator? proxyDecorator;
  final bool reverse;

  @override
  State<TestList> createState() => _TestListState();
}

class _TestListState extends State<TestList> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: DefaultTextStyle(
          style: TextStyle(color: widget.textColor),
          child: IconTheme(
            data: IconThemeData(color: widget.iconColor),
            child: StatefulBuilder(
              builder: (BuildContext outerContext, StateSetter setState) {
                final List<int> items = widget.items;
                return CustomScrollView(
                  reverse: widget.reverse,
                  slivers: <Widget>[
                    SliverReorderableList(
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          key: ValueKey<int>(items[index]),
                          height: 100,
                          color: items[index].isOdd ? Colors.red : Colors.green,
                          child: ReorderableDragStartListener(
                            index: index,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('item ${items[index]}'),
                                const Icon(Icons.drag_handle),
                              ],
                            ),
                          ),
                        );
                      },
                      itemCount: items.length,
                      onReorder: (int fromIndex, int toIndex) {
                        setState(() {
                          if (toIndex > fromIndex) {
                            toIndex -= 1;
                          }
                          items.insert(toIndex, items.removeAt(fromIndex));
                        });
                      },
                      proxyDecorator: widget.proxyDecorator,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
