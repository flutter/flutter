// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

Future<void> test(WidgetTester tester, double offset, { double anchor = 0.0 }) {
  return tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Viewport(
        anchor: anchor / 600.0,
        offset: ViewportOffset.fixed(offset),
        slivers: const <Widget>[
          SliverToBoxAdapter(child: SizedBox(height: 400.0)),
          SliverToBoxAdapter(child: SizedBox(height: 400.0)),
          SliverToBoxAdapter(child: SizedBox(height: 400.0)),
          SliverToBoxAdapter(child: SizedBox(height: 400.0)),
          SliverToBoxAdapter(child: SizedBox(height: 400.0)),
        ],
      ),
    ),
  );
}

Future<void> testSliverFixedExtentList(WidgetTester tester, List<String> items) {
  return tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverFixedExtentList(
            itemExtent: 900,
            delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                return Center(
                  key: ValueKey<String>(items[index]),
                  child: KeepAlive(
                    items[index],
                  )
                );
              },
              childCount : items.length,
              findChildIndexCallback: (Key key) {
                final ValueKey<String> valueKey = key;
                final String data = valueKey.value;
                return items.indexOf(data);
              }
            ),
          ),
        ],
      ),
    ),
  );
}

void verify(WidgetTester tester, List<Offset> idealPositions, List<bool> idealVisibles) {
  final List<Offset> actualPositions = tester.renderObjectList<RenderBox>(find.byType(SizedBox, skipOffstage: false)).map<Offset>(
    (RenderBox target) => target.localToGlobal(const Offset(0.0, 0.0))
  ).toList();
  final List<bool> actualVisibles = tester.renderObjectList<RenderSliverToBoxAdapter>(find.byType(SliverToBoxAdapter, skipOffstage: false)).map<bool>(
    (RenderSliverToBoxAdapter target) => target.geometry.visible
  ).toList();
  expect(actualPositions, equals(idealPositions));
  expect(actualVisibles, equals(idealVisibles));
}

void main() {
  testWidgets('Viewport basic test', (WidgetTester tester) async {
    await test(tester, 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(0.0, 0.0),
      const Offset(0.0, 400.0),
      const Offset(0.0, 800.0),
      const Offset(0.0, 1200.0),
      const Offset(0.0, 1600.0),
    ], <bool>[true, true, false, false, false]);

    await test(tester, 200.0);
    verify(tester, <Offset>[
      const Offset(0.0, -200.0),
      const Offset(0.0, 200.0),
      const Offset(0.0, 600.0),
      const Offset(0.0, 1000.0),
      const Offset(0.0, 1400.0),
    ], <bool>[true, true, false, false, false]);

    await test(tester, 600.0);
    verify(tester, <Offset>[
      const Offset(0.0, -600.0),
      const Offset(0.0, -200.0),
      const Offset(0.0, 200.0),
      const Offset(0.0, 600.0),
      const Offset(0.0, 1000.0),
    ], <bool>[false, true, true, false, false]);

    await test(tester, 900.0);
    verify(tester, <Offset>[
      const Offset(0.0, -900.0),
      const Offset(0.0, -500.0),
      const Offset(0.0, -100.0),
      const Offset(0.0, 300.0),
      const Offset(0.0, 700.0),
    ], <bool>[false, false, true, true, false]);
  });

  testWidgets('Viewport anchor test', (WidgetTester tester) async {
    await test(tester, 0.0, anchor: 100.0);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(0.0, 100.0),
      const Offset(0.0, 500.0),
      const Offset(0.0, 900.0),
      const Offset(0.0, 1300.0),
      const Offset(0.0, 1700.0),
    ], <bool>[true, true, false, false, false]);

    await test(tester, 200.0, anchor: 100.0);
    verify(tester, <Offset>[
      const Offset(0.0, -100.0),
      const Offset(0.0, 300.0),
      const Offset(0.0, 700.0),
      const Offset(0.0, 1100.0),
      const Offset(0.0, 1500.0),
    ], <bool>[true, true, false, false, false]);

    await test(tester, 600.0, anchor: 100.0);
    verify(tester, <Offset>[
      const Offset(0.0, -500.0),
      const Offset(0.0, -100.0),
      const Offset(0.0, 300.0),
      const Offset(0.0, 700.0),
      const Offset(0.0, 1100.0),
    ], <bool>[false, true, true, false, false]);

    await test(tester, 900.0, anchor: 100.0);
    verify(tester, <Offset>[
      const Offset(0.0, -800.0),
      const Offset(0.0, -400.0),
      const Offset(0.0, 0.0),
      const Offset(0.0, 400.0),
      const Offset(0.0, 800.0),
    ], <bool>[false, false, true, true, false]);
  });

  testWidgets('Multiple grids and lists', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: SizedBox(
          width: 44.4,
          height: 60.0,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildListDelegate(
                    <Widget>[
                      Container(height: 22.2, child: const Text('TOP')),
                      Container(height: 22.2),
                      Container(height: 22.2),
                    ],
                  ),
                ),
                SliverFixedExtentList(
                  itemExtent: 22.2,
                  delegate: SliverChildListDelegate(
                    <Widget>[
                      Container(),
                      Container(child: const Text('A')),
                      Container(),
                    ],
                  ),
                ),
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  delegate: SliverChildListDelegate(
                    <Widget>[
                      Container(),
                      Container(child: const Text('B')),
                      Container(),
                    ],
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    <Widget>[
                      Container(height: 22.2),
                      Container(height: 22.2),
                      Container(height: 22.2, child: const Text('BOTTOM')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final TestGesture gesture = await tester.startGesture(const Offset(400.0, 300.0));
    expect(find.text('TOP'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);
    expect(find.text('BOTTOM'), findsNothing);
    await gesture.moveBy(const Offset(0.0, -70.0));
    await tester.pump();
    expect(find.text('TOP'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('BOTTOM'), findsNothing);
    await gesture.moveBy(const Offset(0.0, -70.0));
    await tester.pump();
    expect(find.text('TOP'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('BOTTOM'), findsNothing);
    await gesture.moveBy(const Offset(0.0, -70.0));
    await tester.pump();
    expect(find.text('TOP'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);
    expect(find.text('BOTTOM'), findsOneWidget);
  });

  testWidgets('SliverFixedExtentList correctly clears garbage', (WidgetTester tester) async {
    final List<String> items = <String>['1', '2', '3', '4', '5', '6'];
    await testSliverFixedExtentList(tester, items);
    // Keep alive widgets require 1 frame to notify their parents. Pumps in between
    // drags to ensure widgets are kept alive.
    await tester.drag(find.byType(CustomScrollView),const Offset(0.0, -1200.0));
    await tester.pump();
    await tester.drag(find.byType(CustomScrollView),const Offset(0.0, -1200.0));
    await tester.pump();
    await tester.drag(find.byType(CustomScrollView),const Offset(0.0, -800.0));
    await tester.pump();
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    // Indexes [0, 1, 2] are kept alive and [3, 4] are in viewport, thus the sliver
    // will need to keep updating the elements at these indexes whenever a rebuild is
    // triggered. The current child list in RenderSliverFixedExtentList is
    // '4' -> '5' -> null.
    //
    // With the insertion below, all items will get shifted back 1 position. The sliver
    // will have to update indexes [0, 1, 2, 3, 4, 5]. Since this is the first time
    // item '0' gets initialized, mounting the element will cause it to attach to
    // child list in RenderSliverFixedExtentList. This will create a gap.
    // '0' -> '4' -> '5' -> null.
    items.insert(0, '0');
    await testSliverFixedExtentList(tester, items);
    // Sliver should collect leading and trailing garbage correctly.
    //
    // The child list update should occur in following order.
    // '0' -> '4' -> '5' -> null Started with Original list.
    // '4' -> null               Removed 1 leading garbage and 1 trailing garbage.
    // '3' -> '4' -> null        Prepended '3' because viewport is still at [3, 4].
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('SliverGrid Correctly layout children after rearranging', (WidgetTester tester) async {
      await tester.pumpWidget(const TestSliverGrid(
        <Widget>[
          Text('item0', key: Key('0')),
          Text('item1', key: Key('1')),
        ]
      ));
      await tester.pumpWidget(const TestSliverGrid(
        <Widget>[
          Text('item0', key: Key('0')),
          Text('item3', key: Key('3')),
          Text('item4', key: Key('4')),
          Text('item1', key: Key('1')),
        ]
      ));
      expect(find.text('item0'), findsOneWidget);
      expect(find.text('item3'), findsOneWidget);
      expect(find.text('item4'), findsOneWidget);
      expect(find.text('item1'), findsOneWidget);

      final Offset item0Location = tester.getCenter(find.text('item0'));
      final Offset item3Location = tester.getCenter(find.text('item3'));
      final Offset item4Location = tester.getCenter(find.text('item4'));
      final Offset item1Location = tester.getCenter(find.text('item1'));

      expect(isRight(item0Location, item3Location) && sameHorizontal(item0Location, item3Location), true);
      expect(isBelow(item0Location, item4Location) && sameVertical(item0Location, item4Location), true);
      expect(isBelow(item0Location, item1Location) && isRight(item0Location, item1Location), true);
    },
  );

  testWidgets('SliverFixedExtentList Correctly layout children after rearranging', (WidgetTester tester) async {
      await tester.pumpWidget(const TestSliverFixedExtentList(
          <Widget>[
            Text('item0', key: Key('0')),
            Text('item2', key: Key('2')),
            Text('item1', key: Key('1')),
          ]
      ));
      await tester.pumpWidget(const TestSliverFixedExtentList(
          <Widget>[
            Text('item0', key: Key('0')),
            Text('item3', key: Key('3')),
            Text('item1', key: Key('1')),
            Text('item4', key: Key('4')),
            Text('item2', key: Key('2')),
          ]
      ));
      expect(find.text('item0'), findsOneWidget);
      expect(find.text('item3'), findsOneWidget);
      expect(find.text('item1'), findsOneWidget);
      expect(find.text('item4'), findsOneWidget);
      expect(find.text('item2'), findsOneWidget);

      final Offset item0Location = tester.getCenter(find.text('item0'));
      final Offset item3Location = tester.getCenter(find.text('item3'));
      final Offset item1Location = tester.getCenter(find.text('item1'));
      final Offset item4Location = tester.getCenter(find.text('item4'));
      final Offset item2Location = tester.getCenter(find.text('item2'));

      expect(isBelow(item0Location, item3Location) && sameVertical(item0Location, item3Location), true);
      expect(isBelow(item3Location, item1Location) && sameVertical(item3Location, item1Location), true);
      expect(isBelow(item1Location, item4Location) && sameVertical(item1Location, item4Location), true);
      expect(isBelow(item4Location, item2Location) && sameVertical(item4Location, item2Location), true);
    },
  );

  testWidgets('Can override ErrorWidget.build', (WidgetTester tester) async {
    const Text errorText = Text('error');
    final ErrorWidgetBuilder oldBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) => errorText;
    final SliverChildBuilderDelegate builderThrowsDelegate = SliverChildBuilderDelegate(
      (_, __) => throw 'builder',
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      addSemanticIndexes: false,
    );
    final KeyedSubtree wrapped = builderThrowsDelegate.build(null, 0);
    expect(wrapped.child, errorText);
    expect(tester.takeException(), 'builder');
    ErrorWidget.builder = oldBuilder;
  });

  testWidgets('SliverFixedExtentList with SliverChildBuilderDelegate auto-correct scroll offset - super fast', (WidgetTester tester) async {
    final ScrollController controller = ScrollController(initialScrollOffset: 600);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          controller: controller,
          cacheExtent: 0,
          slivers: <Widget>[
            SliverFixedExtentList(
              itemExtent: 200,
              delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                  if (index <= 6) {
                    return Center(child: Text('Page $index'));
                  }
                  return null;
                },
              ),
            )
          ],
        ),
      )
    );
    await tester.drag(find.text('Page 5'), const Offset(0, -1000));
    // Controller will be temporarily over-scrolled.
    expect(controller.offset, 1600.0);
    await tester.pumpAndSettle();
    // It will be corrected after a auto scroll animation.
    expect(controller.offset, 800.0);
  });

  testWidgets('SliverFixedExtentList with SliverChildBuilderDelegate auto-correct scroll offset - reasonable', (WidgetTester tester) async {
    final ScrollController controller = ScrollController(initialScrollOffset: 600);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          controller: controller,
          cacheExtent: 0,
          slivers: <Widget>[
            SliverFixedExtentList(
              itemExtent: 200,
              delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                  if (index <= 6) {
                    return Center(child: Text('Page $index'));
                  }
                  return null;
                },
              ),
            )
          ],
        ),
      )
    );
    await tester.drag(find.text('Page 5'), const Offset(0, -210));
    // Controller will be temporarily over-scrolled.
    expect(controller.offset, 810.0);
    await tester.pumpAndSettle();
    // It will be corrected after a auto scroll animation.
    expect(controller.offset, 800.0);
  });
}

bool isRight(Offset a, Offset b) => b.dx > a.dx;
bool isBelow(Offset a, Offset b) => b.dy > a.dy;
bool sameHorizontal(Offset a, Offset b) => b.dy == a.dy;
bool sameVertical(Offset a, Offset b) => b.dx == a.dx;

class TestSliverGrid extends StatelessWidget {
  const TestSliverGrid(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: CustomScrollView(
        slivers: <Widget> [
          SliverGrid(
            delegate: SliverChildListDelegate(
              children,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
          ),
        ],
      )
    );
  }
}

class TestSliverFixedExtentList extends StatelessWidget {
  const TestSliverFixedExtentList(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget> [
            SliverFixedExtentList(
              itemExtent: 10.0,
              delegate: SliverChildListDelegate(
                children,
              ),
            ),
          ],
        )
    );
  }
}

class KeepAlive extends StatefulWidget {
  const KeepAlive(this.data);

  final String data;

  @override
  KeepAliveState createState() => KeepAliveState();
}

class KeepAliveState extends State<KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Text(widget.data);
  }
}
