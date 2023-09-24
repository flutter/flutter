// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import '../rendering/rendering_tester.dart' show TestClipPaintingContext;

class TestSliverChildListDelegate extends SliverChildListDelegate {
  TestSliverChildListDelegate(super.children);

  final List<String> log = <String>[];

  @override
  void didFinishLayout(int firstIndex, int lastIndex) {
    log.add('didFinishLayout firstIndex=$firstIndex lastIndex=$lastIndex');
  }
}

class Alive extends StatefulWidget {
  const Alive(this.alive, this.index, { super.key });
  final bool alive;
  final int index;

  @override
  AliveState createState() => AliveState();

  @override
  String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) => '$index $alive';
}

class AliveState extends State<Alive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.alive;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Text('${widget.index}:$wantKeepAlive');
  }
}

typedef WhetherToKeepAlive = bool Function(int);
class _StatefulListView extends StatefulWidget {
  const _StatefulListView(this.aliveCallback);

  final WhetherToKeepAlive aliveCallback;
  @override
  _StatefulListViewState createState() => _StatefulListViewState();
}

class _StatefulListViewState extends State<_StatefulListView> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // force a rebuild - the test(s) using this are verifying that the list is
      // still correct after rebuild
      onTap: () => setState,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          children: List<Widget>.generate(200, (int i) {
            return Builder(
              builder: (BuildContext context) {
                return Alive(widget.aliveCallback(i), i);
              },
            );
          }),
        ),
      ),
    );
  }
}

void main() {
  // Regression test for https://github.com/flutter/flutter/issues/100451
  testWidgetsWithLeakTracking('ListView.builder respects findChildIndexCallback', (WidgetTester tester) async {
    bool finderCalled = false;
    int itemCount = 7;
    late StateSetter stateSetter;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            stateSetter = setState;
            return ListView.builder(
              itemCount: itemCount,
              itemBuilder: (BuildContext _, int index) => Container(
                key: Key('$index'),
                height: 2000.0,
              ),
              findChildIndexCallback: (Key key) {
                finderCalled = true;
                return null;
              },
            );
          },
        ),
      )
    );
    expect(finderCalled, false);

    // Trigger update.
    stateSetter(() => itemCount = 77);
    await tester.pump();

    expect(finderCalled, true);
  });

  // Regression test for https://github.com/flutter/flutter/issues/100451
  testWidgetsWithLeakTracking('ListView.separator respects findChildIndexCallback', (WidgetTester tester) async {
    bool finderCalled = false;
    int itemCount = 7;
    late StateSetter stateSetter;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            stateSetter = setState;
            return ListView.separated(
              itemCount: itemCount,
              itemBuilder: (BuildContext _, int index) => Container(
                key: Key('$index'),
                height: 2000.0,
              ),
              findChildIndexCallback: (Key key) {
                finderCalled = true;
                return null;
              },
              separatorBuilder: (BuildContext _, int __) => const Divider(),
            );
          },
        ),
      )
    );
    expect(finderCalled, false);

    // Trigger update.
    stateSetter(() => itemCount = 77);
    await tester.pump();

    expect(finderCalled, true);
  });

  testWidgetsWithLeakTracking('ListView default control', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: ListView(itemExtent: 100.0),
        ),
      ),
    );
  });

  testWidgetsWithLeakTracking('ListView itemExtent control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          itemExtent: 200.0,
          children: List<Widget>.generate(20, (int i) {
            return ColoredBox(
              color: Colors.green,
              child: Text('$i'),
            );
          }),
        ),
      ),
    );

    final RenderBox box = tester.renderObject<RenderBox>(find.byType(ColoredBox).first);
    expect(box.size.height, equals(200.0));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0.0, -250.0));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsNothing);
    expect(find.text('6'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0.0, 200.0));
    await tester.pump();

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);
  });

  testWidgetsWithLeakTracking('ListView large scroll jump', (WidgetTester tester) async {
    final List<int> log = <int>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          itemExtent: 200.0,
          children: List<Widget>.generate(20, (int i) {
            return Builder(
              builder: (BuildContext context) {
                log.add(i);
                return Text('$i');
              },
            );
          }),
        ),
      ),
    );

    expect(log, equals(<int>[0, 1, 2, 3, 4]));
    log.clear();

    final ScrollableState state = tester.state(find.byType(Scrollable));
    final ScrollPosition position = state.position;
    position.jumpTo(2025.0);

    expect(log, isEmpty);
    await tester.pump();

    expect(log, equals(<int>[8, 9, 10, 11, 12, 13, 14]));
    log.clear();

    position.jumpTo(975.0);

    expect(log, isEmpty);
    await tester.pump();

    expect(log, equals(<int>[7, 6, 5, 4, 3]));
    log.clear();
  });

  testWidgetsWithLeakTracking('ListView large scroll jump and keepAlive first child not keepAlive', (WidgetTester tester) async {
    Future<void> checkAndScroll([ String zero = '0:false' ]) async {
      expect(find.text(zero), findsOneWidget);
      expect(find.text('1:false'), findsOneWidget);
      expect(find.text('2:false'), findsOneWidget);
      expect(find.text('3:true'), findsOneWidget);
      expect(find.text('116:false'), findsNothing);
      final ScrollableState state = tester.state(find.byType(Scrollable));
      final ScrollPosition position = state.position;
      position.jumpTo(1025.0);

      await tester.pump();

      expect(find.text(zero), findsNothing);
      expect(find.text('1:false'), findsNothing);
      expect(find.text('2:false'), findsNothing);
      expect(find.text('3:true', skipOffstage: false), findsOneWidget);
      expect(find.text('116:false'), findsOneWidget);

      await tester.tapAt(const Offset(100.0, 100.0));
      position.jumpTo(0.0);
      await tester.pump();
      await tester.pump();

      expect(find.text(zero), findsOneWidget);
      expect(find.text('1:false'), findsOneWidget);
      expect(find.text('2:false'), findsOneWidget);
      expect(find.text('3:true'), findsOneWidget);
    }

    await tester.pumpWidget(_StatefulListView((int i) => i > 2 && i % 3 == 0));
    await checkAndScroll();

    await tester.pumpWidget(_StatefulListView((int i) => i % 3 == 0));
    await checkAndScroll('0:true');
  });

  testWidgetsWithLeakTracking('ListView can build out of underflow', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          itemExtent: 100.0,
        ),
      ),
    );

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          itemExtent: 100.0,
          children: List<Widget>.generate(2, (int i) {
            return Text('$i');
          }),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          itemExtent: 100.0,
          children: List<Widget>.generate(5, (int i) {
            return Text('$i');
          }),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsNothing);
  });

  testWidgetsWithLeakTracking('ListView can build out of overflow padding', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.shrink(
            child: ListView(
              padding: const EdgeInsets.all(8.0),
              children: const <Widget>[
                Text('padded', textDirection: TextDirection.ltr),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('padded', skipOffstage: false), findsOneWidget);
  });

  testWidgetsWithLeakTracking('ListView with itemExtent in unbounded context', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          child: ListView(
            itemExtent: 100.0,
            shrinkWrap: true,
            children: List<Widget>.generate(20, (int i) {
              return Text('$i');
            }),
          ),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    expect(find.text('19'), findsOneWidget);
  });

  testWidgetsWithLeakTracking('ListView with shrink wrap in bounded context correctly uses cache extent', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: 400,
          child: ListView(
            itemExtent: 100.0,
            shrinkWrap: true,
            children: List<Widget>.generate(20, (int i) {
              return Text('Text $i');
            }),
          ),
        ),
      ),
    );
    expect(tester.getSemantics(find.text('Text 5')), matchesSemantics());
    expect(tester.getSemantics(find.text('Text 6', skipOffstage: false)), matchesSemantics(isHidden: true));
    expect(tester.getSemantics(find.text('Text 7', skipOffstage: false)), matchesSemantics(isHidden: true));
    expect(tester.getSemantics(find.text('Text 8', skipOffstage: false)), matchesSemantics(isHidden: true));
    handle.dispose();
  });

  testWidgetsWithLeakTracking('ListView hidden items should stay hidden if their semantics are updated', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: 400,
          child: ListView(
            itemExtent: 100.0,
            shrinkWrap: true,
            children: List<Widget>.generate(20, (int i) {
              return Text('Text $i');
            }),
          ),
        ),
      ),
    );
    // Scrollable maybe be marked dirty after layout.
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.text('Text 5')), matchesSemantics());
    expect(tester.getSemantics(find.text('Text 6', skipOffstage: false)), matchesSemantics(isHidden: true));
    expect(tester.getSemantics(find.text('Text 7', skipOffstage: false)), matchesSemantics(isHidden: true));
    expect(tester.getSemantics(find.text('Text 8', skipOffstage: false)), matchesSemantics(isHidden: true));

    // Marks Text 6 semantics as dirty.
    final RenderObject text6 = tester.renderObject(find.text('Text 6', skipOffstage: false));
    text6.markNeedsSemanticsUpdate();

    // Verify the semantics is still hidden.
    await tester.pump();
    expect(tester.getSemantics(find.text('Text 6', skipOffstage: false)), matchesSemantics(isHidden: true));

    handle.dispose();
  });

  testWidgetsWithLeakTracking('didFinishLayout has correct indices', (WidgetTester tester) async {
    final TestSliverChildListDelegate delegate = TestSliverChildListDelegate(
      List<Widget>.generate(
        20,
        (int i) {
          return Text('$i', textDirection: TextDirection.ltr);
        },
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.custom(
          itemExtent: 110.0,
          childrenDelegate: delegate,
        ),
      ),
    );

    expect(delegate.log, equals(<String>['didFinishLayout firstIndex=0 lastIndex=7']));
    delegate.log.clear();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.custom(
          itemExtent: 210.0,
          childrenDelegate: delegate,
        ),
      ),
    );

    expect(delegate.log, equals(<String>['didFinishLayout firstIndex=0 lastIndex=4']));
    delegate.log.clear();

    await tester.drag(find.byType(ListView), const Offset(0.0, -600.0));

    expect(delegate.log, isEmpty);

    await tester.pump();

    expect(delegate.log, equals(<String>['didFinishLayout firstIndex=1 lastIndex=6']));
    delegate.log.clear();
  });

  testWidgetsWithLeakTracking('ListView automatically pad MediaQuery on axis', (WidgetTester tester) async {
    EdgeInsets? innerMediaQueryPadding;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.all(30.0),
          ),
          child: ListView(
            children: <Widget>[
              const Text('top', textDirection: TextDirection.ltr),
              Builder(builder: (BuildContext context) {
                innerMediaQueryPadding = MediaQuery.paddingOf(context);
                return Container();
              }),
            ],
          ),
        ),
      ),
    );
    // Automatically apply the top/bottom padding into sliver.
    expect(tester.getTopLeft(find.text('top')).dy, 30.0);
    // Leave left/right padding as is for children.
    expect(innerMediaQueryPadding, const EdgeInsets.symmetric(horizontal: 30.0));
  });

  testWidgetsWithLeakTracking('ListView clips if overflow is smaller than cacheExtent', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/17426.

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            height: 200.0,
            child: ListView(
              cacheExtent: 500.0,
              children: <Widget>[
                Container(
                  height: 90.0,
                ),
                Container(
                  height: 110.0,
                ),
                Container(
                  height: 80.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Viewport), paints..clipRect());
  });

  testWidgetsWithLeakTracking('ListView does not clips if no overflow', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            height: 200.0,
            child: ListView(
              cacheExtent: 500.0,
              children: const <Widget>[
                SizedBox(
                  height: 100.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Viewport), isNot(paints..clipRect()));
  });

  testWidgetsWithLeakTracking('ListView (fixed extent) clips if overflow is smaller than cacheExtent', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/17426.

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            height: 200.0,
            child: ListView(
              itemExtent: 100.0,
              cacheExtent: 500.0,
              children: const <Widget>[
                SizedBox(
                  height: 100.0,
                ),
                SizedBox(
                  height: 100.0,
                ),
                SizedBox(
                  height: 100.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Viewport), paints..clipRect());
  });

  testWidgetsWithLeakTracking('ListView (fixed extent) does not clips if no overflow', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            height: 200.0,
            child: ListView(
              itemExtent: 100.0,
              cacheExtent: 500.0,
              children: const <Widget>[
                SizedBox(
                  height: 100.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Viewport), isNot(paints..clipRect()));
  });

  testWidgetsWithLeakTracking('ListView.horizontal has implicit scrolling by default', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            height: 200.0,
            child: ListView(
              scrollDirection: Axis.horizontal,
              itemExtent: 100.0,
              children: const <Widget>[
                SizedBox(
                  height: 100.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.getSemantics(find.byType(Scrollable)), matchesSemantics(
      children: <Matcher>[
        matchesSemantics(
          children: <Matcher>[
            matchesSemantics(hasImplicitScrolling: true),
          ],
        ),
      ],
    ));
    handle.dispose();
  });

  testWidgetsWithLeakTracking('Updates viewport dimensions when scroll direction changes', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/43380.
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);

    Widget buildListView({ required Axis scrollDirection }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            height: 200.0,
            width: 100.0,
            child: ListView(
              controller: controller,
              scrollDirection: scrollDirection,
              itemExtent: 50.0,
              children: const <Widget>[
                SizedBox(
                  height: 50.0,
                  width: 50.0,
                ),
              ],
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildListView(scrollDirection: Axis.horizontal));
    expect(controller.position.viewportDimension, 100.0);

    await tester.pumpWidget(buildListView(scrollDirection: Axis.vertical));
    expect(controller.position.viewportDimension, 200.0);

    await tester.pumpWidget(buildListView(scrollDirection: Axis.horizontal));
    expect(controller.position.viewportDimension, 100.0);
  });

  testWidgetsWithLeakTracking('ListView respects clipBehavior', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          children: <Widget>[Container(height: 2000.0)],
        ),
      ),
    );

    // 1st, check that the render object has received the default clip behavior.
    final RenderViewport renderObject = tester.allRenderObjects.whereType<RenderViewport>().first;
    expect(renderObject.clipBehavior, equals(Clip.hardEdge));

    // 2nd, check that the painting context has received the default clip behavior.
    final TestClipPaintingContext context = TestClipPaintingContext();
    renderObject.paint(context, Offset.zero);
    expect(context.clipBehavior, equals(Clip.hardEdge));

    // 3rd, pump a new widget to check that the render object can update its clip behavior.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          clipBehavior: Clip.antiAlias,
          children: <Widget>[Container(height: 2000.0)],
        ),
      ),
    );
    expect(renderObject.clipBehavior, equals(Clip.antiAlias));

    // 4th, check that a non-default clip behavior can be sent to the painting context.
    renderObject.paint(context, Offset.zero);
    expect(context.clipBehavior, equals(Clip.antiAlias));
  },
  leakTrackingTestConfig: const LeakTrackingTestConfig(
    // TODO(ksokolovskyi): remove after fixing
    // https://github.com/flutter/flutter/issues/134572
    notDisposedAllowList: <String, int?> {'ContainerLayer': 1},
  ));

  testWidgetsWithLeakTracking('ListView.builder respects clipBehavior', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.builder(
          itemCount: 10,
          itemBuilder: (BuildContext _, int __) => Container(height: 2000.0),
          clipBehavior: Clip.antiAlias,
        ),
      ),
    );
    final RenderViewport renderObject = tester.allRenderObjects.whereType<RenderViewport>().first;
    expect(renderObject.clipBehavior, equals(Clip.antiAlias));
  });

  testWidgetsWithLeakTracking('ListView.custom respects clipBehavior', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.custom(
          childrenDelegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => Container(height: 2000.0),
            childCount: 1,
          ),
          clipBehavior: Clip.antiAlias,
        ),
      ),
    );
    final RenderViewport renderObject = tester.allRenderObjects.whereType<RenderViewport>().first;
    expect(renderObject.clipBehavior, equals(Clip.antiAlias));
  });

  testWidgetsWithLeakTracking('ListView.separated respects clipBehavior', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.separated(
          itemCount: 10,
          itemBuilder: (BuildContext _, int __) => Container(height: 2000.0),
          separatorBuilder: (BuildContext _, int __) => const Divider(),
          clipBehavior: Clip.antiAlias,
        ),
      ),
    );
    final RenderViewport renderObject = tester.allRenderObjects.whereType<RenderViewport>().first;
    expect(renderObject.clipBehavior, equals(Clip.antiAlias));
  });

  // Regression test for https://github.com/flutter/flutter/pull/131393
  testWidgetsWithLeakTracking('itemExtentBuilder test', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    final List<int> buildLog = <int>[];
    late SliverLayoutDimensions sliverLayoutDimensions;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.builder(
          controller: controller,
          itemExtentBuilder: (int index, SliverLayoutDimensions dimensions) {
            sliverLayoutDimensions = dimensions;
            return 100.0;
          },
          itemBuilder: (BuildContext context, int index) {
            buildLog.insert(0, index);
            return Text('Item $index');
          },
        ),
      ),
    );

    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 5'), findsOneWidget);
    expect(find.text('Item 6'), findsNothing);
    expect(
      sliverLayoutDimensions,
      const SliverLayoutDimensions(
        scrollOffset: 0.0,
        precedingScrollExtent: 0.0,
        viewportMainAxisExtent: 600.0,
        crossAxisExtent: 800.0,
      )
    );
    // viewport(600.0) + cache extent after(250.0)
    expect(buildLog.length, 9);
    expect(buildLog.min, 0);
    expect(buildLog.max, 8);

    buildLog.clear();

    // Scrolling drastically.
    controller.jumpTo(10000.0);
    await tester.pump();

    expect(find.text('Item 99'), findsNothing);
    expect(find.text('Item 100'), findsOneWidget);
    expect(find.text('Item 105'), findsOneWidget);
    expect(find.text('Item 106'), findsNothing);
    expect(
        sliverLayoutDimensions,
        const SliverLayoutDimensions(
          scrollOffset: 10000.0,
          precedingScrollExtent: 0.0,
          viewportMainAxisExtent: 600.0,
          crossAxisExtent: 800.0,
        )
    );
    // Scrolling drastically only loading the visible and cached area items.
    // cache extent before(250.0) + viewport(600.0) + cache extent after(250.0)
    expect(buildLog.length, 12);
    expect(buildLog.min, 97);
    expect(buildLog.max, 108);

    buildLog.clear();
    controller.jumpTo(5000.0);
    await tester.pump();

    expect(find.text('Item 49'), findsNothing);
    expect(find.text('Item 50'), findsOneWidget);
    expect(find.text('Item 55'), findsOneWidget);
    expect(find.text('Item 56'), findsNothing);
    expect(
        sliverLayoutDimensions,
        const SliverLayoutDimensions(
          scrollOffset: 5000.0,
          precedingScrollExtent: 0.0,
          viewportMainAxisExtent: 600.0,
          crossAxisExtent: 800.0,
        )
    );
    // cache extent before(250.0) + viewport(600.0) + cache extent after(250.0)
    expect(buildLog.length, 12);
    expect(buildLog.min, 47);
    expect(buildLog.max, 58);

    buildLog.clear();
    controller.jumpTo(4700.0);
    await tester.pump();

    expect(find.text('Item 46'), findsNothing);
    expect(find.text('Item 47'), findsOneWidget);
    expect(find.text('Item 52'), findsOneWidget);
    expect(find.text('Item 53'), findsNothing);
    expect(
        sliverLayoutDimensions,
        const SliverLayoutDimensions(
          scrollOffset: 4700.0,
          precedingScrollExtent: 0.0,
          viewportMainAxisExtent: 600.0,
          crossAxisExtent: 800.0,
        )
    );
    // Only newly entered cached area items need to be loaded.
    expect(buildLog.length, 3);
    expect(buildLog.min, 44);
    expect(buildLog.max, 46);

    buildLog.clear();
    controller.jumpTo(5300.0);
    await tester.pump();

    expect(find.text('Item 52'), findsNothing);
    expect(find.text('Item 53'), findsOneWidget);
    expect(find.text('Item 58'), findsOneWidget);
    expect(find.text('Item 59'), findsNothing);
    expect(
        sliverLayoutDimensions,
        const SliverLayoutDimensions(
          scrollOffset: 5300.0,
          precedingScrollExtent: 0.0,
          viewportMainAxisExtent: 600.0,
          crossAxisExtent: 800.0,
        )
    );
    // Only newly entered cached area items need to be loaded.
    expect(buildLog.length, 6);
    expect(buildLog.min, 56);
    expect(buildLog.max, 61);
  });

  testWidgetsWithLeakTracking('itemExtent, prototypeItem and itemExtentBuilder conflicts test', (WidgetTester tester) async {
    Object? error;
    try {
      await tester.pumpWidget(
        ListView.builder(
          itemExtentBuilder: (int index, SliverLayoutDimensions dimensions) {
            return 100.0;
          },
          itemExtent: 100.0,
          itemBuilder: (BuildContext context, int index) {
            return Text('Item $index');
          },
        ),
      );
    } catch (e) {
      error = e;
    }
    expect(error, isNotNull);

    error = null;
    try {
      await tester.pumpWidget(
        ListView.builder(
          itemExtentBuilder: (int index, SliverLayoutDimensions dimensions) {
            return 100.0;
          },
          prototypeItem: Container(),
          itemBuilder: (BuildContext context, int index) {
            return Text('Item $index');
          },
        ),
      );
    } catch (e) {
      error = e;
    }
    expect(error, isNotNull);

    error = null;
    try {
      await tester.pumpWidget(
        ListView.builder(
          itemExtent: 100.0,
          prototypeItem: Container(),
          itemBuilder: (BuildContext context, int index) {
            return Text('Item $index');
          },
        ),
      );
    } catch (e) {
      error = e;
    }
    expect(error, isNotNull);
  });
}
