// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

void main() {
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
                    return Container(
                      height: 100,
                      child: Text('item ${items[index]}'),
                    );
                  },
                ),
              ],
            );
          }
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
                    return Container(
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
          }
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
    await pressDragRelease(tester.getCenter(find.text('item 0')), const Offset(0, 151));
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
    await pressDragRelease(tester.getCenter(find.text('item 1')), const Offset(0, 251));
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
}

class TestList extends StatefulWidget {
  const TestList({
    Key? key,
    this.textColor,
    this.iconColor,
    this.proxyDecorator,
    required this.items,
  }) : super(key: key);

  final List<int> items;
  final Color? textColor;
  final Color? iconColor;
  final ReorderItemProxyDecorator? proxyDecorator;

  @override
  _TestListState createState() => _TestListState();
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
                    slivers: <Widget>[
                      SliverReorderableList(
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                            key: ValueKey<int>(items[index]),
                            height: 100,
                            color: items[index].isOdd ? Colors.red : Colors.green,
                            child: ReorderableDragStartListener(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text('item ${items[index]}'),
                                  const Icon(Icons.drag_handle),
                                ],
                              ),
                              index: index,
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
                }
            ),
          ),
        ),
      ),
    );
  }
}
