// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import 'semantics_tester.dart';

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
                  ),
                );
              },
              childCount : items.length,
              findChildIndexCallback: (Key key) {
                final ValueKey<String> valueKey = key as ValueKey<String>;
                return items.indexOf(valueKey.value);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

void verify(WidgetTester tester, List<Offset> idealPositions, List<bool> idealVisibles) {
  final List<Offset> actualPositions = tester.renderObjectList<RenderBox>(find.byType(SizedBox, skipOffstage: false)).map<Offset>(
    (RenderBox target) => target.localToGlobal(Offset.zero),
  ).toList();
  final List<bool> actualVisibles = tester.renderObjectList<RenderSliverToBoxAdapter>(find.byType(SliverToBoxAdapter, skipOffstage: false)).map<bool>(
    (RenderSliverToBoxAdapter target) => target.geometry!.visible,
  ).toList();
  expect(actualPositions, equals(idealPositions));
  expect(actualVisibles, equals(idealVisibles));
}

void main() {
  testWidgets('Viewport basic test', (WidgetTester tester) async {
    await test(tester, 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      Offset.zero,
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
      Offset.zero,
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
                    const <Widget>[
                      SizedBox(height: 22.2, child: Text('TOP')),
                      SizedBox(height: 22.2),
                      SizedBox(height: 22.2),
                    ],
                  ),
                ),
                SliverFixedExtentList(
                  itemExtent: 22.2,
                  delegate: SliverChildListDelegate(
                    const <Widget>[
                      SizedBox(),
                      Text('A'),
                      SizedBox(),
                    ],
                  ),
                ),
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  delegate: SliverChildListDelegate(
                    const <Widget>[
                      SizedBox(),
                      Text('B'),
                      SizedBox(),
                    ],
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    const <Widget>[
                      SizedBox(height: 22.2),
                      SizedBox(height: 22.2),
                      SizedBox(height: 22.2, child: Text('BOTTOM')),
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

  testWidgets('SliverFixedExtentList handles underflow when its children changes', (WidgetTester tester) async {
    final List<String> items = <String>['1', '2', '3', '4', '5', '6'];
    final List<String> initializedChild = <String>[];
    List<Widget> children = <Widget>[];
    for (final String item in items) {
      children.add(
          StateInitSpy(
            item, () => initializedChild.add(item), key: ValueKey<String>(item),
          ),
      );
    }
    final ScrollController controller = ScrollController(initialScrollOffset: 5400);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          controller: controller,
          slivers: <Widget>[
            SliverFixedExtentList(
              itemExtent: 900,
              delegate: SliverChildListDelegate(children),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);
    expect(find.text('6'), findsOneWidget);
    expect(listEquals<String>(initializedChild, <String>['6']), isTrue);

    // move to item 1 and swap the children at the same time
    controller.jumpTo(0);
    final Widget temp = children[5];
    children[5] = children[0];
    children[0] = temp;
    children = List<Widget>.from(children);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          controller: controller,
          slivers: <Widget>[
            SliverFixedExtentList(
              itemExtent: 900,
              delegate: SliverChildListDelegate(children),
            ),
          ],
        ),
      ),
    );
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);
    expect(find.text('6'), findsOneWidget);
    // None of the children should be built.
    expect(listEquals<String>(initializedChild, <String>['6']), isTrue);
  });

  testWidgets(
    'SliverGrid Correctly layout children after rearranging',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TestSliverGrid(
        <Widget>[
          Text('item0', key: Key('0')),
          Text('item1', key: Key('1')),
        ],
      ));
      await tester.pumpWidget(const TestSliverGrid(
        <Widget>[
          Text('item0', key: Key('0')),
          Text('item3', key: Key('3')),
          Text('item4', key: Key('4')),
          Text('item1', key: Key('1')),
        ],
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

  testWidgets(
    'SliverGrid negative usableCrossAxisExtent',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 4,
              height: 4,
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    delegate: SliverChildListDelegate(
                      <Widget>[
                        const Center(child: Text('A')),
                        const Center(child: Text('B')),
                        const Center(child: Text('C')),
                        const Center(child: Text('D')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SliverList can handle inaccurate scroll offset due to changes in children list',
      (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/pull/59888.
      bool skip = true;
      Widget buildItem(BuildContext context, int index) {
        return !skip || index.isEven
          ? Card(
          child: ListTile(
            title: Text(
              'item$index',
              style: const TextStyle(fontSize: 80),
            ),
          ),
        )
          : Container();
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: <Widget> [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    buildItem,
                    childCount: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      // Only even items 0~12 are on the screen.
      expect(find.text('item0'), findsOneWidget);
      expect(find.text('item12'), findsOneWidget);
      expect(find.text('item14'), findsNothing);

      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, -750.0));
      await tester.pump();
      // Only even items 16~28 are on the screen.
      expect(find.text('item15'), findsNothing);
      expect(find.text('item16'), findsOneWidget);
      expect(find.text('item28'), findsOneWidget);

      skip = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: <Widget> [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    buildItem,
                    childCount: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Only items 12~19 are on the screen.
      expect(find.text('item11'), findsNothing);
      expect(find.text('item12'), findsOneWidget);
      expect(find.text('item19'), findsOneWidget);
      expect(find.text('item20'), findsNothing);

      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, 250.0));
      await tester.pump();

      // Only items 10~16 are on the screen.
      expect(find.text('item9'), findsNothing);
      expect(find.text('item10'), findsOneWidget);
      expect(find.text('item16'), findsOneWidget);
      expect(find.text('item17'), findsNothing);

      // The inaccurate scroll offset should reach zero at this point
      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, 250.0));
      await tester.pump();

      // Only items 7~13 are on the screen.
      expect(find.text('item6'), findsNothing);
      expect(find.text('item7'), findsOneWidget);
      expect(find.text('item13'), findsOneWidget);
      expect(find.text('item14'), findsNothing);

      // It will be corrected as we scroll, so we have to drag multiple times.
      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, 250.0));
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, 250.0));
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, 250.0));
      await tester.pump();

      // Only items 0~6 are on the screen.
      expect(find.text('item0'), findsOneWidget);
      expect(find.text('item6'), findsOneWidget);
      expect(find.text('item7'), findsNothing);
    },
  );

  testWidgets(
    'SliverFixedExtentList Correctly layout children after rearranging',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TestSliverFixedExtentList(
          <Widget>[
            Text('item0', key: Key('0')),
            Text('item2', key: Key('2')),
            Text('item1', key: Key('1')),
          ],
      ));
      await tester.pumpWidget(const TestSliverFixedExtentList(
          <Widget>[
            Text('item0', key: Key('0')),
            Text('item3', key: Key('3')),
            Text('item1', key: Key('1')),
            Text('item4', key: Key('4')),
            Text('item2', key: Key('2')),
          ],
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
    final KeyedSubtree wrapped = builderThrowsDelegate.build(_NullBuildContext(), 0)! as KeyedSubtree;
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
            ),
          ],
        ),
      ),
    );
    expect(find.text('Page 0'), findsNothing);
    expect(find.text('Page 6'), findsNothing);

    await tester.drag(find.text('Page 5'), const Offset(0, -1000));
    // Controller will be temporarily over-scrolled (before the frame triggered by the drag) because
    // SliverFixedExtentList doesn't report its size until it has built its last child, so the
    // maxScrollExtent is infinite, so when we move by 1000 pixels in one go, we go all the way.
    //
    // This never actually gets rendered, it's just the controller state before we lay out.
    expect(controller.offset, 1600.0);

    // However, once we pump, the scroll offset gets clamped to the newly discovered maximum, which
    // is the itemExtent (200) times the number of items (7) minus the height of the viewport (600).
    // This adds up to 800.0.
    await tester.pump();
    expect(find.text('Page 0'), findsNothing);
    expect(find.text('Page 6'), findsOneWidget);
    expect(controller.offset, 800.0);

    expect(await tester.pumpAndSettle(), 1); // there should be no animation here
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
            ),
          ],
        ),
      ),
    );
    await tester.drag(find.text('Page 5'), const Offset(0, -210));
    // Controller will be temporarily over-scrolled.
    expect(controller.offset, 810.0);
    await tester.pumpAndSettle();
    // It will be corrected after a auto scroll animation.
    expect(controller.offset, 800.0);
  });

  Widget boilerPlate(Widget sliver) {
    return Localizations(
      locale: const Locale('en', 'us'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: CustomScrollView(slivers: <Widget>[sliver]),
        ),
      ),
    );
  }

  group('SliverOffstage - ', () {
    testWidgets('offstage true', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      await tester.pumpWidget(boilerPlate(
        const SliverOffstage(
          sliver: SliverToBoxAdapter(
            child: Text('a'),
          ),
        ),
      ));

      expect(semantics.nodesWith(label: 'a'), hasLength(0));
      expect(find.byType(Text), findsNothing);
      final RenderViewport renderViewport = tester.renderObject(find.byType(Viewport));
      final RenderSliver renderSliver = renderViewport.lastChild!;
      expect(renderSliver.geometry!.scrollExtent, 0.0);
      expect(find.byType(SliverOffstage), findsNothing);
    });

    testWidgets('offstage false', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      await tester.pumpWidget(boilerPlate(
        const SliverOffstage(
          offstage: false,
          sliver: SliverToBoxAdapter(
            child: Text('a'),
          ),
        ),
      ));

      expect(semantics.nodesWith(label: 'a'), hasLength(1));
      expect(find.byType(Text), findsOneWidget);
      final RenderViewport renderViewport = tester.renderObject(find.byType(Viewport));
      final RenderSliver renderSliver = renderViewport.lastChild!;
      expect(renderSliver.geometry!.scrollExtent, 14.0);
      expect(find.byType(SliverOffstage), paints..paragraph());
    });
  });

  group('SliverOpacity - ', () {
    testWidgets('painting & semantics', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);

      // Opacity 1.0: Semantics and painting
      await tester.pumpWidget(boilerPlate(
        const SliverOpacity(
          sliver: SliverToBoxAdapter(
            child: Text(
              'a',
              textDirection: TextDirection.rtl,
            ),
          ),
          opacity: 1.0,
        ),
      ));

      expect(semantics.nodesWith(label: 'a'), hasLength(1));
      expect(find.byType(SliverOpacity), paints..paragraph());

      // Opacity 0.0: Nothing
      await tester.pumpWidget(boilerPlate(
        const SliverOpacity(
          sliver: SliverToBoxAdapter(
            child: Text(
              'a',
              textDirection: TextDirection.rtl,
            ),
          ),
          opacity: 0.0,
        ),
      ));

      expect(semantics.nodesWith(label: 'a'), hasLength(0));
      expect(find.byType(SliverOpacity), paintsNothing);

      // Opacity 0.0 with semantics: Just semantics
      await tester.pumpWidget(boilerPlate(
        const SliverOpacity(
          sliver: SliverToBoxAdapter(
            child: Text(
              'a',
              textDirection: TextDirection.rtl,
            ),
          ),
          opacity: 0.0,
          alwaysIncludeSemantics: true,
        ),
      ));

      expect(semantics.nodesWith(label: 'a'), hasLength(1));
      expect(find.byType(SliverOpacity), paintsNothing);

      // Opacity 0.0 without semantics: Nothing
      await tester.pumpWidget(boilerPlate(
        const SliverOpacity(
          sliver: SliverToBoxAdapter(
            child: Text(
              'a',
              textDirection: TextDirection.rtl,
            ),
          ),
          opacity: 0.0,
        ),
      ));

      expect(semantics.nodesWith(label: 'a'), hasLength(0));
      expect(find.byType(SliverOpacity), paintsNothing);

      // Opacity 0.1: Semantics and painting
      await tester.pumpWidget(boilerPlate(
        const SliverOpacity(
          sliver: SliverToBoxAdapter(
            child: Text(
              'a',
              textDirection: TextDirection.rtl,
            ),
          ),
          opacity: 0.1,
        ),
      ));

      expect(semantics.nodesWith(label: 'a'), hasLength(1));
      expect(find.byType(SliverOpacity), paints..paragraph());

      // Opacity 0.1 without semantics: Still has semantics and painting
      await tester.pumpWidget(boilerPlate(
        const SliverOpacity(
          sliver: SliverToBoxAdapter(
            child: Text(
              'a',
              textDirection: TextDirection.rtl,
            ),
          ),
          opacity: 0.1,
        ),
      ));

      expect(semantics.nodesWith(label: 'a'), hasLength(1));
      expect(find.byType(SliverOpacity), paints..paragraph());

      // Opacity 0.1 with semantics: Semantics and painting
      await tester.pumpWidget(boilerPlate(
        const SliverOpacity(
          sliver: SliverToBoxAdapter(
            child: Text(
              'a',
              textDirection: TextDirection.rtl,
            ),
          ),
          opacity: 0.1,
          alwaysIncludeSemantics: true,
        ),
      ));

      expect(semantics.nodesWith(label: 'a'), hasLength(1));
      expect(find.byType(SliverOpacity), paints..paragraph());

      semantics.dispose();
    });
  });

  group('SliverIgnorePointer - ', () {
    testWidgets('ignores pointer events', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      final List<String> events = <String>[];
      await tester.pumpWidget(boilerPlate(
        SliverIgnorePointer(
          ignoringSemantics: false,
          sliver: SliverToBoxAdapter(
            child: GestureDetector(
              child: const Text('a'),
              onTap: () {
                events.add('tap');
              },
            ),
          ),
        ),
      ));
      expect(semantics.nodesWith(label: 'a'), hasLength(1));
      await tester.tap(find.byType(GestureDetector), warnIfMissed: false);
      expect(events, equals(<String>[]));
    });

    testWidgets('ignores semantics', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      final List<String> events = <String>[];
      await tester.pumpWidget(boilerPlate(
        SliverIgnorePointer(
          ignoring: false,
          ignoringSemantics: true,
          sliver: SliverToBoxAdapter(
            child: GestureDetector(
              child: const Text('a'),
              onTap: () {
                events.add('tap');
              },
            ),
          ),
        ),
      ));
      expect(semantics.nodesWith(label: 'a'), hasLength(0));
      await tester.tap(find.byType(GestureDetector));
      expect(events, equals(<String>['tap']));
    });

    testWidgets('ignores pointer events & semantics', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      final List<String> events = <String>[];
      await tester.pumpWidget(boilerPlate(
        SliverIgnorePointer(
          ignoringSemantics: true,
          sliver: SliverToBoxAdapter(
            child: GestureDetector(
              child: const Text('a'),
              onTap: () {
                events.add('tap');
              },
            ),
          ),
        ),
      ));
      expect(semantics.nodesWith(label: 'a'), hasLength(0));
      await tester.tap(find.byType(GestureDetector), warnIfMissed: false);
      expect(events, equals(<String>[]));
    });

    testWidgets('ignores nothing', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      final List<String> events = <String>[];
      await tester.pumpWidget(boilerPlate(
        SliverIgnorePointer(
          ignoring: false,
          ignoringSemantics: false,
          sliver: SliverToBoxAdapter(
            child: GestureDetector(
              child: const Text('a'),
              onTap: () {
                events.add('tap');
              },
            ),
          ),
        ),
      ));
      expect(semantics.nodesWith(label: 'a'), hasLength(1));
      await tester.tap(find.byType(GestureDetector));
      expect(events, equals(<String>['tap']));
    });
  });

  testWidgets('SliverList handles 0 scrollOffsetCorrection', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/62198
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: <Widget>[
            SliverList(
              delegate: SliverChildListDelegate(
                const <Widget>[
                  SizedBox.shrink(),
                  Text('index 1'),
                  Text('index 2'),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
    await tester.fling(find.byType(Scrollable), const Offset(0.0, -500.0), 10000.0);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('SliverGrid children can be arbitrarily placed', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/64006
    int firstTapped = 0;
    int secondTapped = 0;
    final Key key = UniqueKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: key,
        body: CustomScrollView(
          slivers: <Widget>[
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Material(
                    color: index.isEven ? Colors.yellow : Colors.red,
                    child: InkWell(
                      onTap: () {
                        index.isEven ? firstTapped++ : secondTapped++;
                      },
                      child: Text('Index $index'),
                    ),
                  );
                },
                childCount: 2,
              ),
              gridDelegate: _TestArbitrarySliverGridDelegate(),
            ),
          ],
        ),
      ),
    ));
    // Assertion not triggered by arbitrary placement
    expect(tester.takeException(), isNull);

    // Verify correct hit testing
    await tester.tap(find.text('Index 0'));
    expect(firstTapped, 1);
    expect(secondTapped, 0);
    await tester.tap(find.text('Index 1'));
    expect(firstTapped, 1);
    expect(secondTapped, 1);
    // Check other places too
    final Offset bottomLeft = tester.getBottomLeft(find.byKey(key));
    await tester.tapAt(bottomLeft);
    expect(firstTapped, 1);
    expect(secondTapped, 1);
    final Offset topRight = tester.getTopRight(find.byKey(key));
    await tester.tapAt(topRight);
    expect(firstTapped, 1);
    expect(secondTapped, 1);
    await tester.tapAt(const Offset(100.0, 100.0));
    expect(firstTapped, 1);
    expect(secondTapped, 1);
    await tester.tapAt(const Offset(700.0, 500.0));
    expect(firstTapped, 1);
    expect(secondTapped, 1);
  });
}

bool isRight(Offset a, Offset b) => b.dx > a.dx;
bool isBelow(Offset a, Offset b) => b.dy > a.dy;
bool sameHorizontal(Offset a, Offset b) => b.dy == a.dy;
bool sameVertical(Offset a, Offset b) => b.dx == a.dx;

class TestSliverGrid extends StatelessWidget {
  const TestSliverGrid(this.children, { super.key });

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
      ),
    );
  }
}

class _TestArbitrarySliverGridDelegate implements SliverGridDelegate {
  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    return _TestArbitrarySliverGridLayout();
  }

  @override
  bool shouldRelayout(SliverGridDelegate oldDelegate) {
    return false;
  }
}

class _TestArbitrarySliverGridLayout implements SliverGridLayout {
  @override
  double computeMaxScrollOffset(int childCount) => 1000;

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) => 0;

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) => 2;

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    return SliverGridGeometry(
      scrollOffset: index * 100.0 + 300.0,
      crossAxisOffset: 200.0,
      mainAxisExtent: 100.0,
      crossAxisExtent: 100.0,
    );
  }
}

class TestSliverFixedExtentList extends StatelessWidget {
  const TestSliverFixedExtentList(this.children, { super.key });

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
        ),
    );
  }
}

class StateInitSpy extends StatefulWidget {
  const StateInitSpy(this.data, this.onStateInit, { super.key });

  final String data;
  final VoidCallback onStateInit;

  @override
  StateInitSpyState createState() => StateInitSpyState();
}

class StateInitSpyState extends State<StateInitSpy> {
  @override
  void initState() {
    super.initState();
    widget.onStateInit();
  }

  @override
  Widget build(BuildContext context) {
    return Text(widget.data);
  }
}

class KeepAlive extends StatefulWidget {
  const KeepAlive(this.data, { super.key });

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

class _NullBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
