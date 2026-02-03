// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sliver_test_utils.dart';
import 'widgets_app_tester.dart';

void main() {
  void verifyPaintPosition(GlobalKey key, Offset ideal, [bool? visible]) {
    final target = key.currentContext!.findRenderObject()! as RenderSliver;
    expect(target.parent, isA<RenderViewport>());
    final parentData = target.parentData! as SliverPhysicalParentData;
    final Offset actual = parentData.paintOffset;
    expect(actual, ideal);

    if (visible != null) {
      final SliverGeometry geometry = target.geometry!;
      expect(geometry.visible, visible);
    }
  }

  void verifyActualBoxPosition(WidgetTester tester, Finder finder, int index, Rect ideal) {
    final RenderBox box = tester.renderObjectList<RenderBox>(finder).elementAt(index);
    final rect = Rect.fromPoints(
      box.localToGlobal(Offset.zero),
      box.localToGlobal(box.size.bottomRight(Offset.zero)),
    );
    expect(rect, equals(ideal));
  }

  testWidgets('_SliverScrollingPersistentHeader should update stretchConfiguration', (
    WidgetTester tester,
  ) async {
    for (final stretchTriggerOffset in <double>[10.0, 20.0]) {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: CustomScrollView(
            slivers: <Widget>[
              SliverPersistentHeader(
                delegate: TestDelegate(
                  stretchConfiguration: OverScrollHeaderStretchConfiguration(
                    stretchTriggerOffset: stretchTriggerOffset,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    expect(
      tester.allWidgets.where(
        (Widget w) => w.runtimeType.toString() == '_SliverScrollingPersistentHeader',
      ),
      isNotEmpty,
    );

    final RenderSliverScrollingPersistentHeader render = tester.allRenderObjects
        .whereType<RenderSliverScrollingPersistentHeader>()
        .first;
    expect(render.stretchConfiguration?.stretchTriggerOffset, 20);
  });

  testWidgets('_SliverPinnedPersistentHeader should update stretchConfiguration', (
    WidgetTester tester,
  ) async {
    for (final stretchTriggerOffset in <double>[10.0, 20.0]) {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: CustomScrollView(
            slivers: <Widget>[
              SliverPersistentHeader(
                pinned: true,
                delegate: TestDelegate(
                  stretchConfiguration: OverScrollHeaderStretchConfiguration(
                    stretchTriggerOffset: stretchTriggerOffset,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    expect(
      tester.allWidgets.where(
        (Widget w) => w.runtimeType.toString() == '_SliverPinnedPersistentHeader',
      ),
      isNotEmpty,
    );

    final RenderSliverPinnedPersistentHeader render = tester.allRenderObjects
        .whereType<RenderSliverPinnedPersistentHeader>()
        .first;
    expect(render.stretchConfiguration?.stretchTriggerOffset, 20);
  });

  testWidgets('_SliverPinnedPersistentHeader should update showOnScreenConfiguration', (
    WidgetTester tester,
  ) async {
    for (final maxShowOnScreenExtent in <double>[1000, 2000]) {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: CustomScrollView(
            slivers: <Widget>[
              SliverPersistentHeader(
                pinned: true,
                delegate: TestDelegate(
                  showOnScreenConfiguration: PersistentHeaderShowOnScreenConfiguration(
                    maxShowOnScreenExtent: maxShowOnScreenExtent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    expect(
      tester.allWidgets.where(
        (Widget w) => w.runtimeType.toString() == '_SliverPinnedPersistentHeader',
      ),
      isNotEmpty,
    );

    final RenderSliverPinnedPersistentHeader render = tester.allRenderObjects
        .whereType<RenderSliverPinnedPersistentHeader>()
        .first;
    expect(render.showOnScreenConfiguration?.maxShowOnScreenExtent, 2000);
  });

  testWidgets("SliverPersistentHeader - floating - scroll offset doesn't change", (
    WidgetTester tester,
  ) async {
    const bigHeight = 1000.0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            const BigSliver(height: bigHeight),
            SliverPersistentHeader(delegate: TestDelegate(), floating: true),
            const BigSliver(height: bigHeight),
          ],
        ),
      ),
    );
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    final double max =
        bigHeight * 2.0 +
        TestDelegate().maxExtent -
        600.0; // 600 is the height of the test viewport
    assert(max < 10000.0);
    expect(max, 1600.0);
    expect(position.pixels, 0.0);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    position.animateTo(10000.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(position.pixels, max);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
  });

  testWidgets('SliverPersistentHeader - floating - normal behavior works', (
    WidgetTester tester,
  ) async {
    final delegate = TestDelegate2();
    const bigHeight = 1000.0;
    GlobalKey key1, key2, key3;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            BigSliver(key: key1 = GlobalKey(), height: bigHeight),
            SliverPersistentHeader(key: key2 = GlobalKey(), delegate: delegate, floating: true),
            BigSliver(key: key3 = GlobalKey(), height: bigHeight),
          ],
        ),
      ),
    );
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    verifyPaintPosition(key1, Offset.zero, true);
    verifyPaintPosition(key2, const Offset(0.0, 1000.0), false);
    verifyPaintPosition(key3, const Offset(0.0, 1200.0), false);

    position.animateTo(
      bigHeight - 600.0 + delegate.maxExtent,
      curve: Curves.linear,
      duration: const Duration(minutes: 1),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, Offset.zero, true);
    verifyPaintPosition(key2, Offset(0.0, 600.0 - delegate.maxExtent), true);
    verifyActualBoxPosition(
      tester,
      find.byType(Container),
      0,
      Rect.fromLTWH(0.0, 600.0 - delegate.maxExtent, 800.0, delegate.maxExtent),
    );
    verifyPaintPosition(key3, const Offset(0.0, 600.0), false);

    assert(delegate.maxExtent * 2.0 < 600.0); // make sure this fits on the test screen...
    position.animateTo(
      bigHeight - 600.0 + delegate.maxExtent * 2.0,
      curve: Curves.linear,
      duration: const Duration(minutes: 1),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, Offset.zero, true);
    verifyPaintPosition(key2, Offset(0.0, 600.0 - delegate.maxExtent * 2.0), true);
    verifyActualBoxPosition(
      tester,
      find.byType(Container),
      0,
      Rect.fromLTWH(0.0, 600.0 - delegate.maxExtent * 2.0, 800.0, delegate.maxExtent),
    );
    verifyPaintPosition(key3, Offset(0.0, 600.0 - delegate.maxExtent), true);

    position.animateTo(bigHeight, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyActualBoxPosition(
      tester,
      find.byType(Container),
      0,
      Rect.fromLTWH(0.0, 0.0, 800.0, delegate.maxExtent),
    );
    verifyPaintPosition(key3, Offset(0.0, delegate.maxExtent), true);

    position.animateTo(
      bigHeight + delegate.maxExtent * 0.1,
      curve: Curves.linear,
      duration: const Duration(minutes: 1),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyActualBoxPosition(
      tester,
      find.byType(Container),
      0,
      Rect.fromLTWH(0.0, 0.0, 800.0, delegate.maxExtent * 0.9),
    );
    verifyPaintPosition(key3, Offset(0.0, delegate.maxExtent * 0.9), true);

    position.animateTo(
      bigHeight + delegate.maxExtent * 0.5,
      curve: Curves.linear,
      duration: const Duration(minutes: 1),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyActualBoxPosition(
      tester,
      find.byType(Container),
      0,
      Rect.fromLTWH(0.0, 0.0, 800.0, delegate.maxExtent * 0.5),
    );
    verifyPaintPosition(key3, Offset(0.0, delegate.maxExtent * 0.5), true);

    position.animateTo(
      bigHeight + delegate.maxExtent * 0.9,
      curve: Curves.linear,
      duration: const Duration(minutes: 1),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyActualBoxPosition(
      tester,
      find.byType(Container),
      0,
      Rect.fromLTWH(0.0, -delegate.maxExtent * 0.4, 800.0, delegate.maxExtent * 0.5),
    );
    verifyPaintPosition(key3, Offset(0.0, delegate.maxExtent * 0.1), true);

    position.animateTo(
      bigHeight + delegate.maxExtent * 2.0,
      curve: Curves.linear,
      duration: const Duration(minutes: 1),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, false);
    verifyPaintPosition(key3, Offset.zero, true);
  });

  testWidgets('SliverPersistentHeader - floating - no floating behavior when animating', (
    WidgetTester tester,
  ) async {
    final delegate = TestDelegate();
    const bigHeight = 1000.0;
    GlobalKey key1, key2, key3;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            BigSliver(key: key1 = GlobalKey(), height: bigHeight),
            SliverPersistentHeader(key: key2 = GlobalKey(), delegate: delegate, floating: true),
            BigSliver(key: key3 = GlobalKey(), height: bigHeight),
          ],
        ),
      ),
    );
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    verifyPaintPosition(key1, Offset.zero, true);
    verifyPaintPosition(key2, const Offset(0.0, 1000.0), false);
    verifyPaintPosition(key3, const Offset(0.0, 1200.0), false);

    position.animateTo(
      bigHeight + delegate.maxExtent * 2.0,
      curve: Curves.linear,
      duration: const Duration(minutes: 1),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, false);
    verifyPaintPosition(key3, Offset.zero, true);

    position.animateTo(
      bigHeight + delegate.maxExtent * 1.9,
      curve: Curves.linear,
      duration: const Duration(minutes: 1),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, false);
    verifyPaintPosition(key3, Offset.zero, true);
  });

  testWidgets('SliverPersistentHeader - floating - floating behavior when dragging down', (
    WidgetTester tester,
  ) async {
    final delegate = TestDelegate2();
    const bigHeight = 1000.0;
    GlobalKey key1, key2, key3;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            BigSliver(key: key1 = GlobalKey(), height: bigHeight),
            SliverPersistentHeader(key: key2 = GlobalKey(), delegate: delegate, floating: true),
            BigSliver(key: key3 = GlobalKey(), height: bigHeight),
          ],
        ),
      ),
    );
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable)).position
            as ScrollPositionWithSingleContext;

    verifyPaintPosition(key1, Offset.zero, true);
    verifyPaintPosition(key2, const Offset(0.0, 1000.0), false);
    verifyPaintPosition(key3, const Offset(0.0, 1200.0), false);

    position.animateTo(
      bigHeight + delegate.maxExtent * 2.0,
      curve: Curves.linear,
      duration: const Duration(minutes: 1),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, false);
    verifyPaintPosition(key3, Offset.zero, true);

    position.animateTo(
      bigHeight + delegate.maxExtent * 1.9,
      curve: Curves.linear,
      duration: const Duration(minutes: 1),
    );
    position.updateUserScrollDirection(ScrollDirection.forward);
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyActualBoxPosition(
      tester,
      find.byType(Container),
      0,
      Rect.fromLTWH(0.0, -delegate.maxExtent * 0.4, 800.0, delegate.maxExtent * 0.5),
    );
    verifyPaintPosition(key3, Offset.zero, true);
  });

  testWidgets('SliverPersistentHeader - floating - overscroll gap is below header', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverPersistentHeader(delegate: TestDelegate(), floating: true),
            SliverList.list(children: const <Widget>[SizedBox(height: 300.0, child: Text('X'))]),
          ],
        ),
      ),
    );

    expect(
      tester.getTopLeft(
        find.ancestor(of: find.text('Sliver Persistent Header'), matching: find.byType(SizedBox)),
      ),
      Offset.zero,
    );
    expect(tester.getTopLeft(find.text('X')), const Offset(0.0, 200.0));

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    position.jumpTo(-50.0);
    await tester.pump();

    expect(
      tester.getTopLeft(
        find.ancestor(of: find.text('Sliver Persistent Header'), matching: find.byType(SizedBox)),
      ),
      Offset.zero,
    );
    expect(tester.getTopLeft(find.text('X')), const Offset(0.0, 250.0));
  });

  testWidgets('SliverPersistentHeader - pinned', (WidgetTester tester) async {
    const bigHeight = 550.0;
    GlobalKey key1, key2, key3, key4, key5;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            BigSliver(key: key1 = GlobalKey(), height: bigHeight),
            SliverPersistentHeader(
              key: key2 = GlobalKey(),
              delegate: TestDelegate2(),
              pinned: true,
            ),
            SliverPersistentHeader(
              key: key3 = GlobalKey(),
              delegate: TestDelegate2(),
              pinned: true,
            ),
            BigSliver(key: key4 = GlobalKey(), height: bigHeight),
            BigSliver(key: key5 = GlobalKey(), height: bigHeight),
          ],
        ),
      ),
    );
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    final double max =
        bigHeight * 3.0 +
        TestDelegate().maxExtent * 2.0 -
        600.0; // 600 is the height of the test viewport
    assert(max < 10000.0);
    expect(max, 1450.0);
    expect(position.pixels, 0.0);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    position.animateTo(10000.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 10));
    expect(position.pixels, max);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyPaintPosition(key4, Offset.zero, true);
    verifyPaintPosition(key5, const Offset(0.0, 50.0), true);
  });

  testWidgets('SliverPersistentHeader - toStringDeep of maxExtent that throws', (
    WidgetTester tester,
  ) async {
    final delegateThatCanThrow = TestDelegateThatCanThrow();
    GlobalKey key;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverPersistentHeader(
              key: key = GlobalKey(),
              delegate: delegateThatCanThrow,
              pinned: true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 10));

    final RenderObject renderObject = key.currentContext!.findRenderObject()!;
    // The delegate must only start throwing immediately before calling
    // toStringDeep to avoid triggering spurious exceptions.
    // If the _RenderSliverPinnedPersistentHeaderForWidgets class was not
    // private it would make more sense to create an instance of it directly.
    delegateThatCanThrow.shouldThrow = true;
    expect(renderObject, hasAGoodToStringDeep);
    expect(
      renderObject.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        '_RenderSliverPinnedPersistentHeaderForWidgets#00000 relayoutBoundary=up1\n'
        ' │ parentData: paintOffset=Offset(0.0, 0.0) (can use size)\n'
        ' │ constraints: SliverConstraints(AxisDirection.down,\n'
        ' │   GrowthDirection.forward, ScrollDirection.idle, scrollOffset:\n'
        ' │   0.0, precedingScrollExtent: 0.0, remainingPaintExtent: 600.0,\n'
        ' │   crossAxisExtent: 800.0, crossAxisDirection:\n'
        ' │   AxisDirection.right, viewportMainAxisExtent: 600.0,\n'
        ' │   remainingCacheExtent: 850.0, cacheOrigin: 0.0)\n'
        ' │ geometry: SliverGeometry(scrollExtent: 200.0, paintExtent: 200.0,\n'
        ' │   maxPaintExtent: 200.0, hasVisualOverflow: true, cacheExtent:\n'
        ' │   200.0)\n'
        ' │ maxExtent: EXCEPTION (FlutterError)\n'
        ' │ child position: 0.0\n'
        ' │\n'
        ' └─child: RenderConstrainedBox#00000 relayoutBoundary=up2\n'
        '   │ parentData: <none> (can use size)\n'
        '   │ constraints: BoxConstraints(w=800.0, 0.0<=h<=200.0)\n'
        '   │ size: Size(800.0, 200.0)\n'
        '   │ additionalConstraints: BoxConstraints(0.0<=w<=Infinity,\n'
        '   │   100.0<=h<=200.0)\n'
        '   │\n'
        '   └─child: RenderLimitedBox#00000 relayoutBoundary=up3\n'
        '     │ parentData: <none> (can use size)\n'
        '     │ constraints: BoxConstraints(w=800.0, 100.0<=h<=200.0)\n'
        '     │ size: Size(800.0, 200.0)\n'
        '     │ maxWidth: 0.0\n'
        '     │ maxHeight: 0.0\n'
        '     │\n'
        '     └─child: RenderConstrainedBox#00000 relayoutBoundary=up4\n'
        '         parentData: <none> (can use size)\n'
        '         constraints: BoxConstraints(w=800.0, 100.0<=h<=200.0)\n'
        '         size: Size(800.0, 200.0)\n'
        '         additionalConstraints: BoxConstraints(biggest)\n',
      ),
    );
  });

  testWidgets('SliverPersistentHeader - pinned with slow scroll', (WidgetTester tester) async {
    const bigHeight = 550.0;
    GlobalKey key1, key2, key3, key4, key5;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            BigSliver(key: key1 = GlobalKey(), height: bigHeight),
            SliverPersistentHeader(
              key: key2 = GlobalKey(),
              delegate: TestDelegate2(),
              pinned: true,
            ),
            SliverPersistentHeader(
              key: key3 = GlobalKey(),
              delegate: TestDelegate2(),
              pinned: true,
            ),
            BigSliver(key: key4 = GlobalKey(), height: bigHeight),
            BigSliver(key: key5 = GlobalKey(), height: bigHeight),
          ],
        ),
      ),
    );

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    verifyPaintPosition(key1, Offset.zero, true);
    verifyPaintPosition(key2, const Offset(0.0, 550.0), true);
    verifyPaintPosition(key3, const Offset(0.0, 750.0), false);
    verifyPaintPosition(key4, const Offset(0.0, 950.0), false);
    verifyPaintPosition(key5, const Offset(0.0, 1500.0), false);
    position.animateTo(550.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle();
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyPaintPosition(key3, const Offset(0.0, 200.0), true);
    verifyPaintPosition(key4, const Offset(0.0, 400.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 950.0), false);
    position.animateTo(600.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyPaintPosition(key3, const Offset(0.0, 150.0), true);
    verifyPaintPosition(key4, const Offset(0.0, 350.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 900.0), false);
    position.animateTo(650.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyActualBoxPosition(
      tester,
      find.byType(Container),
      1,
      const Rect.fromLTWH(0.0, 100.0, 800.0, 200.0),
    );
    verifyPaintPosition(key4, const Offset(0.0, 300.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 850.0), false);
    position.animateTo(700.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyActualBoxPosition(
      tester,
      find.byType(Container),
      1,
      const Rect.fromLTWH(0.0, 100.0, 800.0, 200.0),
    );
    verifyPaintPosition(key4, const Offset(0.0, 250.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 800.0), false);
    position.animateTo(750.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyActualBoxPosition(
      tester,
      find.byType(Container),
      1,
      const Rect.fromLTWH(0.0, 100.0, 800.0, 200.0),
    );
    verifyPaintPosition(key4, const Offset(0.0, 200.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 750.0), false);
    position.animateTo(800.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 60));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyPaintPosition(key4, const Offset(0.0, 150.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 700.0), false);
    position.animateTo(850.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 70));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyPaintPosition(key4, const Offset(0.0, 100.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 650.0), false);
    position.animateTo(900.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 80));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyPaintPosition(key4, const Offset(0.0, 50.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 600.0), false);
    position.animateTo(950.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 90));
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyActualBoxPosition(
      tester,
      find.byType(Container),
      1,
      const Rect.fromLTWH(0.0, 100.0, 800.0, 100.0),
    );
    verifyPaintPosition(key4, Offset.zero, true);
    verifyPaintPosition(key5, const Offset(0.0, 550.0), true);
  });

  testWidgets('SliverPersistentHeader - pinned with less overlap', (WidgetTester tester) async {
    const bigHeight = 650.0;
    GlobalKey key1, key2, key3, key4, key5;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            BigSliver(key: key1 = GlobalKey(), height: bigHeight),
            SliverPersistentHeader(
              key: key2 = GlobalKey(),
              delegate: TestDelegate2(),
              pinned: true,
            ),
            SliverPersistentHeader(
              key: key3 = GlobalKey(),
              delegate: TestDelegate2(),
              pinned: true,
            ),
            BigSliver(key: key4 = GlobalKey(), height: bigHeight),
            BigSliver(key: key5 = GlobalKey(), height: bigHeight),
          ],
        ),
      ),
    );
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    final double max =
        bigHeight * 3.0 +
        TestDelegate2().maxExtent * 2.0 -
        600.0; // 600 is the height of the test viewport
    assert(max < 10000.0);
    expect(max, 1750.0);
    expect(position.pixels, 0.0);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    position.animateTo(10000.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 10));
    expect(position.pixels, max);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    verifyPaintPosition(key1, Offset.zero, false);
    verifyPaintPosition(key2, Offset.zero, true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyPaintPosition(key4, Offset.zero, false);
    verifyPaintPosition(key5, Offset.zero, true);
  });

  testWidgets('SliverPersistentHeader - overscroll gap is below header', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverPersistentHeader(delegate: TestDelegate2(), pinned: true),
            SliverList.list(children: const <Widget>[SizedBox(height: 300.0, child: Text('X'))]),
          ],
        ),
      ),
    );

    expect(tester.getTopLeft(find.byType(Container)), Offset.zero);
    expect(tester.getTopLeft(find.text('X')), const Offset(0.0, 200.0));

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    position.jumpTo(-50.0);
    await tester.pump();

    expect(tester.getTopLeft(find.byType(Container)), Offset.zero);
    expect(tester.getTopLeft(find.text('X')), const Offset(0.0, 250.0));

    position.jumpTo(50.0);
    await tester.pump();

    expect(tester.getTopLeft(find.byType(Container)), Offset.zero);
    expect(tester.getTopLeft(find.text('X')), const Offset(0.0, 150.0));

    position.jumpTo(150.0);
    await tester.pump();

    expect(tester.getTopLeft(find.byType(Container)), Offset.zero);
    expect(tester.getTopLeft(find.text('X')), const Offset(0.0, 50.0));
  });

  testWidgets('SliverPersistentHeader pointer scrolled floating', (WidgetTester tester) async {
    final GlobalKey headerKey = GlobalKey();
    await tester.pumpWidget(
      TestWidgetsApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverPersistentHeader(key: headerKey, floating: true, delegate: TestDelegate3()),
            SliverFixedExtentList(
              itemExtent: 50.0,
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => Text('Item $index'),
                childCount: 30,
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 5'), findsOneWidget);
    verifySliverGeometry(key: headerKey, visible: true, paintExtent: 56.0);

    // Pointer scroll the app bar away, we will scroll back less to validate the
    // app bar floats back in.
    final Offset point1 = tester.getCenter(find.text('Item 5'));
    final testPointer = TestPointer(1, ui.PointerDeviceKind.mouse);
    testPointer.hover(point1);
    await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, 300.0)));
    await tester.pump();
    expect(find.text('Test Title'), findsNothing);
    expect(find.text('Item 1'), findsNothing);
    expect(find.text('Item 5'), findsOneWidget);
    verifySliverGeometry(key: headerKey, paintExtent: 0.0, visible: false);

    // Scroll back to float in appbar
    await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, -50.0)));
    await tester.pump();
    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Item 1'), findsNothing);
    expect(find.text('Item 5'), findsOneWidget);
    verifySliverGeometry(key: headerKey, paintExtent: 50.0, visible: true);

    // Float the rest of the way in.
    await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, -250.0)));
    await tester.pump();
    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 5'), findsOneWidget);
    verifySliverGeometry(key: headerKey, paintExtent: 56.0, visible: true);
  });

  testWidgets('SliverPersistentHeader - scrolling', (WidgetTester tester) async {
    const bigHeight = 550.0;
    GlobalKey key1, key2, key3, key4, key5;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            BigSliver(key: key1 = GlobalKey(), height: bigHeight),
            SliverPersistentHeader(key: key2 = GlobalKey(), delegate: TestDelegate()),
            SliverPersistentHeader(key: key3 = GlobalKey(), delegate: TestDelegate()),
            BigSliver(key: key4 = GlobalKey(), height: bigHeight),
            BigSliver(key: key5 = GlobalKey(), height: bigHeight),
          ],
        ),
      ),
    );
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    final double max =
        bigHeight * 3.0 +
        TestDelegate().maxExtent * 2.0 -
        600.0; // 600 is the height of the test viewport
    assert(max < 10000.0);
    expect(max, 1450.0);
    expect(position.pixels, 0.0);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    position.animateTo(10000.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 10));
    expect(position.pixels, max);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    verifyPaintPosition(key1, Offset.zero);
    verifyPaintPosition(key2, Offset.zero);
    verifyPaintPosition(key3, Offset.zero);
    verifyPaintPosition(key4, Offset.zero);
    verifyPaintPosition(key5, const Offset(0.0, 50.0));
  });

  testWidgets('SliverPersistentHeader - scrolling off screen', (WidgetTester tester) async {
    const bigHeight = 550.0;
    final GlobalKey key = GlobalKey();
    final delegate = TestDelegate();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            const BigSliver(height: bigHeight),
            SliverPersistentHeader(key: key, delegate: delegate),
            const BigSliver(height: bigHeight),
            const BigSliver(height: bigHeight),
          ],
        ),
      ),
    );
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    position.animateTo(
      bigHeight + delegate.maxExtent - 5.0,
      curve: Curves.linear,
      duration: const Duration(minutes: 1),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    final RenderBox box = tester.renderObject<RenderBox>(find.text('Sliver Persistent Header'));
    final rect = Rect.fromPoints(
      box.localToGlobal(Offset.zero),
      box.localToGlobal(box.size.bottomRight(Offset.zero)),
    );
    expect(rect, equals(const Rect.fromLTWH(0.0, -195.0, 800.0, 200.0)));
  });

  testWidgets('SliverPersistentHeader - scrolling - overscroll gap is below header', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverPersistentHeader(delegate: TestDelegate()),
            SliverList.list(children: const <Widget>[SizedBox(height: 300.0, child: Text('X'))]),
          ],
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('Sliver Persistent Header')), Offset.zero);
    expect(tester.getTopLeft(find.text('X')), const Offset(0.0, 200.0));

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    position.jumpTo(-50.0);
    await tester.pump();

    expect(tester.getTopLeft(find.text('Sliver Persistent Header')), Offset.zero);
    expect(tester.getTopLeft(find.text('X')), const Offset(0.0, 250.0));
  });

  testWidgets(
    'Sliver SliverPersistentHeader const child delegate - scrolling - overscroll gap is below header',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverPersistentHeader(delegate: TestDelegate()),
              const SliverList(
                delegate: SliverChildListDelegate.fixed(<Widget>[
                  SizedBox(height: 300.0, child: Text('X')),
                ]),
              ),
            ],
          ),
        ),
      );

      expect(tester.getTopLeft(find.text('Sliver Persistent Header')), Offset.zero);
      expect(tester.getTopLeft(find.text('X')), const Offset(0.0, 200.0));

      final ScrollPosition position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      position.jumpTo(-50.0);
      await tester.pump();

      expect(tester.getTopLeft(find.text('Sliver Persistent Header')), Offset.zero);
      expect(tester.getTopLeft(find.text('X')), const Offset(0.0, 250.0));
    },
  );

  group('has correct semantics when', () {
    testWidgets('within viewport', (WidgetTester tester) async {
      const double cacheExtent = 250;
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            cacheExtent: cacheExtent,
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverPersistentHeader(delegate: TestDelegate()),
              const SliverList(
                delegate: SliverChildListDelegate.fixed(<Widget>[
                  SizedBox(height: 300.0, child: Text('X')),
                ]),
              ),
            ],
          ),
        ),
      );

      final SemanticsFinder sliver = find.semantics.byLabel('Sliver Persistent Header');

      expect(sliver, findsOne);
      expect(sliver, isSemantics(isHidden: false));
      handle.dispose();
    });

    testWidgets('partially scrolling off screen', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final delegate = TestDelegate();
      final SemanticsHandle handle = tester.ensureSemantics();
      const double cacheExtent = 250;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            cacheExtent: cacheExtent,
            slivers: <Widget>[
              SliverPersistentHeader(key: key, delegate: delegate),
              const BigSliver(height: 550.0),
              const BigSliver(height: 550.0),
            ],
          ),
        ),
      );
      final ScrollPosition position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      position.animateTo(
        delegate.maxExtent - 20.0,
        curve: Curves.linear,
        duration: const Duration(minutes: 1),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      final RenderBox box = tester.renderObject<RenderBox>(find.text('Sliver Persistent Header'));
      final rect = Rect.fromPoints(
        box.localToGlobal(Offset.zero),
        box.localToGlobal(box.size.bottomRight(Offset.zero)),
      );
      expect(rect, equals(const Rect.fromLTWH(0.0, -180.0, 800.0, 200.0)));

      final SemanticsFinder sliver = find.semantics.byLabel('Sliver Persistent Header');

      expect(sliver, findsOne);
      expect(sliver, isSemantics(isHidden: false));
      handle.dispose();
    });

    testWidgets('completely scrolling off screen but within cache extent', (
      WidgetTester tester,
    ) async {
      final GlobalKey key = GlobalKey();
      final delegate = TestDelegate();
      final SemanticsHandle handle = tester.ensureSemantics();
      const double cacheExtent = 250;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            cacheExtent: cacheExtent,
            slivers: <Widget>[
              SliverPersistentHeader(key: key, delegate: delegate),
              const BigSliver(height: 550.0),
              const BigSliver(height: 550.0),
            ],
          ),
        ),
      );
      final ScrollPosition position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      position.animateTo(
        delegate.maxExtent + 20.0,
        curve: Curves.linear,
        duration: const Duration(minutes: 1),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      final SemanticsFinder sliver = find.semantics.byLabel('Sliver Persistent Header');

      expect(sliver, findsOne);
      expect(sliver, isSemantics(isHidden: true));
      handle.dispose();
    });

    testWidgets('completely scrolling off screen and not within cache extent', (
      WidgetTester tester,
    ) async {
      final GlobalKey key = GlobalKey();
      final delegate = TestDelegate();
      final SemanticsHandle handle = tester.ensureSemantics();
      const double cacheExtent = 250;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            cacheExtent: cacheExtent,
            slivers: <Widget>[
              SliverPersistentHeader(key: key, delegate: delegate),
              const BigSliver(height: 550.0),
              const BigSliver(height: 550.0),
            ],
          ),
        ),
      );
      final ScrollPosition position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      position.animateTo(
        delegate.maxExtent + 300.0,
        curve: Curves.linear,
        duration: const Duration(minutes: 1),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      expect(find.semantics.byLabel('Sliver Persistent Header'), findsNothing);
      handle.dispose();
    });
  });
}

class TestDelegate extends SliverPersistentHeaderDelegate {
  TestDelegate({this.stretchConfiguration, this.showOnScreenConfiguration});

  @override
  double get maxExtent => 200.0;

  @override
  double get minExtent => 200.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(height: maxExtent, child: const Text('Sliver Persistent Header'));
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;

  @override
  final OverScrollHeaderStretchConfiguration? stretchConfiguration;
  @override
  final PersistentHeaderShowOnScreenConfiguration? showOnScreenConfiguration;
}

class TestDelegate2 extends SliverPersistentHeaderDelegate {
  @override
  double get maxExtent => 200.0;

  @override
  double get minExtent => 100.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      constraints: BoxConstraints(minHeight: minExtent, maxHeight: maxExtent),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class TestDelegate3 extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(height: 56, color: const Color(0xFFFF0000), child: const Text('Test Title'));
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class TestDelegateThatCanThrow extends SliverPersistentHeaderDelegate {
  bool shouldThrow = false;

  @override
  double get maxExtent {
    return shouldThrow ? throw FlutterError('Unavailable maxExtent') : 200.0;
  }

  @override
  double get minExtent {
    return shouldThrow ? throw FlutterError('Unavailable minExtent') : 100.0;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      constraints: BoxConstraints(minHeight: minExtent, maxHeight: maxExtent),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class RenderBigSliver extends RenderSliver {
  RenderBigSliver(double height) : _height = height;

  double get height => _height;
  double _height;
  set height(double value) {
    if (value == _height) {
      return;
    }
    _height = value;
    markNeedsLayout();
  }

  double get paintExtent =>
      (height - constraints.scrollOffset).clamp(0.0, constraints.remainingPaintExtent);

  @override
  void performLayout() {
    geometry = SliverGeometry(
      scrollExtent: height,
      paintExtent: paintExtent,
      maxPaintExtent: height,
    );
  }
}

class BigSliver extends LeafRenderObjectWidget {
  const BigSliver({super.key, required this.height});

  final double height;

  @override
  RenderBigSliver createRenderObject(BuildContext context) {
    return RenderBigSliver(height);
  }

  @override
  void updateRenderObject(BuildContext context, RenderBigSliver renderObject) {
    renderObject.height = height;
  }
}
