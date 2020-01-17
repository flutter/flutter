// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is separate from viewport_caching_test.dart because we can't use
// both testWidgets and rendering_tester in the same file - testWidgets will
// initialize a binding, which rendering_tester will attempt to re-initialize
// (or vice versa).

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Viewport getOffsetToReveal - down', (WidgetTester tester) async {
    List<Widget> children;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 200.0,
            width: 300.0,
            child: ListView(
              controller: ScrollController(initialScrollOffset: 300.0),
              children: children = List<Widget>.generate(20, (int i) {
                return Container(
                  height: 100.0,
                  width: 300.0,
                  child: Text('Tile $i'),
                );
              }),
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport = tester.allRenderObjects.whereType<RenderAbstractViewport>().first;

    final RenderObject target = tester.renderObject(find.byWidget(children[5], skipOffstage: false));
    RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
    expect(revealed.offset, 500.0);
    expect(revealed.rect, const Rect.fromLTWH(0.0, 0.0, 300.0, 100.0));

    revealed = viewport.getOffsetToReveal(target, 1.0);
    expect(revealed.offset, 400.0);
    expect(revealed.rect, const Rect.fromLTWH(0.0, 100.0, 300.0, 100.0));

    revealed = viewport.getOffsetToReveal(target, 0.0, rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 540.0);
    expect(revealed.rect, const Rect.fromLTWH(40.0, 0.0, 10.0, 10.0));

    revealed = viewport.getOffsetToReveal(target, 1.0, rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 350.0);
    expect(revealed.rect, const Rect.fromLTWH(40.0, 190.0, 10.0, 10.0));
  });

  testWidgets('Viewport getOffsetToReveal - right', (WidgetTester tester) async {
    List<Widget> children;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 300.0,
            width: 200.0,
            child: ListView(
              scrollDirection: Axis.horizontal,
              controller: ScrollController(initialScrollOffset: 300.0),
              children: children = List<Widget>.generate(20, (int i) {
                return Container(
                  height: 300.0,
                  width: 100.0,
                  child: Text('Tile $i'),
                );
              }),
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport = tester.allRenderObjects.whereType<RenderAbstractViewport>().first;

    final RenderObject target = tester.renderObject(find.byWidget(children[5], skipOffstage: false));
    RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
    expect(revealed.offset, 500.0);
    expect(revealed.rect, const Rect.fromLTWH(0.0, 0.0, 100.0, 300.0));

    revealed = viewport.getOffsetToReveal(target, 1.0);
    expect(revealed.offset, 400.0);
    expect(revealed.rect, const Rect.fromLTWH(100.0, 0.0, 100.0, 300.0));

    revealed = viewport.getOffsetToReveal(target, 0.0, rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 540.0);
    expect(revealed.rect, const Rect.fromLTWH(0.0, 40.0, 10.0, 10.0));

    revealed = viewport.getOffsetToReveal(target, 1.0, rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 350.0);
    expect(revealed.rect, const Rect.fromLTWH(190.0, 40.0, 10.0, 10.0));
  });

  testWidgets('Viewport getOffsetToReveal - up', (WidgetTester tester) async {
    List<Widget> children;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 200.0,
            width: 300.0,
            child: ListView(
              controller: ScrollController(initialScrollOffset: 300.0),
              reverse: true,
              children: children = List<Widget>.generate(20, (int i) {
                return Container(
                  height: 100.0,
                  width: 300.0,
                  child: Text('Tile $i'),
                );
              }),
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport = tester.allRenderObjects.whereType<RenderAbstractViewport>().first;

    final RenderObject target = tester.renderObject(find.byWidget(children[5], skipOffstage: false));
    RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
    expect(revealed.offset, 500.0);
    expect(revealed.rect, const Rect.fromLTWH(0.0, 100.0, 300.0, 100.0));

    revealed = viewport.getOffsetToReveal(target, 1.0);
    expect(revealed.offset, 400.0);
    expect(revealed.rect, const Rect.fromLTWH(0.0, 0.0, 300.0, 100.0));

    revealed = viewport.getOffsetToReveal(target, 0.0, rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 550.0);
    expect(revealed.rect, const Rect.fromLTWH(40.0, 190.0, 10.0, 10.0));

    revealed = viewport.getOffsetToReveal(target, 1.0, rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 360.0);
    expect(revealed.rect, const Rect.fromLTWH(40.0, 0.0, 10.0, 10.0));
  });

  testWidgets('Viewport getOffsetToReveal - left', (WidgetTester tester) async {
    List<Widget> children;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 300.0,
            width: 200.0,
            child: ListView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              controller: ScrollController(initialScrollOffset: 300.0),
              children: children = List<Widget>.generate(20, (int i) {
                return Container(
                  height: 300.0,
                  width: 100.0,
                  child: Text('Tile $i'),
                );
              }),
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport = tester.allRenderObjects.whereType<RenderAbstractViewport>().first;

    final RenderObject target = tester.renderObject(find.byWidget(children[5], skipOffstage: false));
    RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
    expect(revealed.offset, 500.0);
    expect(revealed.rect, const Rect.fromLTWH(100.0, 0.0, 100.0, 300.0));

    revealed = viewport.getOffsetToReveal(target, 1.0);
    expect(revealed.offset, 400.0);
    expect(revealed.rect, const Rect.fromLTWH(0.0, 0.0, 100.0, 300.0));

    revealed = viewport.getOffsetToReveal(target, 0.0, rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 550.0);
    expect(revealed.rect, const Rect.fromLTWH(190.0, 40.0, 10.0, 10.0));

    revealed = viewport.getOffsetToReveal(target, 1.0, rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 360.0);
    expect(revealed.rect, const Rect.fromLTWH(0.0, 40.0, 10.0, 10.0));
  }, skip: isBrowser);

  testWidgets('Viewport getOffsetToReveal Sliver - down', (WidgetTester tester) async {
    final List<Widget> children = <Widget>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 200.0,
            width: 300.0,
            child: CustomScrollView(
              controller: ScrollController(initialScrollOffset: 300.0),
              slivers: List<Widget>.generate(20, (int i) {
                final Widget sliver = SliverToBoxAdapter(
                  child: Container(
                    height: 100.0,
                    child: Text('Tile $i'),
                  ),
                );
                children.add(sliver);
                return SliverPadding(
                  padding: const EdgeInsets.all(22.0),
                  sliver: sliver,
                );
              }),
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport = tester.allRenderObjects.whereType<RenderAbstractViewport>().first;

    final RenderObject target = tester.renderObject(find.byWidget(children[5], skipOffstage: false));
    RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
    expect(revealed.offset, 5 * (100 + 22 + 22) + 22);

    revealed = viewport.getOffsetToReveal(target, 1.0);
    expect(revealed.offset, 5 * (100 + 22 + 22) + 22 - 100);
  });

  testWidgets('Viewport getOffsetToReveal Sliver - right', (WidgetTester tester) async {
    final List<Widget> children = <Widget>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 300.0,
            width: 200.0,
            child: CustomScrollView(
              scrollDirection: Axis.horizontal,
              controller: ScrollController(initialScrollOffset: 300.0),
              slivers: List<Widget>.generate(20, (int i) {
                final Widget sliver = SliverToBoxAdapter(
                    child: Container(
                      width: 100.0,
                      child: Text('Tile $i'),
                    ),
                );
                children.add(sliver);
                return SliverPadding(
                  padding: const EdgeInsets.all(22.0),
                  sliver: sliver,
                );
              }),
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport = tester.allRenderObjects.whereType<RenderAbstractViewport>().first;

    final RenderObject target = tester.renderObject(find.byWidget(children[5], skipOffstage: false));
    RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
    expect(revealed.offset, 5 * (100 + 22 + 22) + 22);

    revealed = viewport.getOffsetToReveal(target, 1.0);
    expect(revealed.offset, 5 * (100 + 22 + 22) + 22 - 100);
  });

  testWidgets('Viewport getOffsetToReveal Sliver - up', (WidgetTester tester) async {
    final List<Widget> children = <Widget>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 200.0,
            width: 300.0,
            child: CustomScrollView(
              controller: ScrollController(initialScrollOffset: 300.0),
              reverse: true,
              slivers: List<Widget>.generate(20, (int i) {
                final Widget sliver = SliverToBoxAdapter(
                    child: Container(
                      height: 100.0,
                      child: Text('Tile $i'),
                    ),
                );
                children.add(sliver);
                return SliverPadding(
                  padding: const EdgeInsets.all(22.0),
                  sliver: sliver,
                );
              }),
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport = tester.allRenderObjects.whereType<RenderAbstractViewport>().first;

    final RenderObject target = tester.renderObject(find.byWidget(children[5], skipOffstage: false));
    RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
    expect(revealed.offset, 5 * (100 + 22 + 22) + 22);

    revealed = viewport.getOffsetToReveal(target, 1.0);
    expect(revealed.offset, 5 * (100 + 22 + 22) + 22 - 100);
  });

  testWidgets('Viewport getOffsetToReveal Sliver - up - reverse growth', (WidgetTester tester) async {
    const Key centerKey = ValueKey<String>('center');
    final Widget centerSliver = SliverPadding(
      key: centerKey,
      padding: const EdgeInsets.all(22.0),
      sliver: SliverToBoxAdapter(
        child: Container(
          height: 100.0,
          child: const Text('Tile center'),
        ),
      ),
    );
    final Widget lowerItem = Container(
      height: 100.0,
      child: const Text('Tile lower'),
    );
    final Widget lowerSliver = SliverPadding(
      padding: const EdgeInsets.all(22.0),
      sliver: SliverToBoxAdapter(
        child: lowerItem,
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 200.0,
            width: 300.0,
            child: CustomScrollView(
              center: centerKey,
              reverse: true,
              slivers: <Widget>[lowerSliver, centerSliver],
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport = tester.allRenderObjects.whereType<RenderAbstractViewport>().first;

    final RenderObject target = tester.renderObject(find.byWidget(lowerItem, skipOffstage: false));
    RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
    expect(revealed.offset, - 100 - 22);

    revealed = viewport.getOffsetToReveal(target, 1.0);
    expect(revealed.offset, - 100 - 22 - 100);
  });

  testWidgets('Viewport getOffsetToReveal Sliver - left - reverse growth', (WidgetTester tester) async {
    const Key centerKey = ValueKey<String>('center');
    final Widget centerSliver = SliverPadding(
      key: centerKey,
      padding: const EdgeInsets.all(22.0),
      sliver: SliverToBoxAdapter(
        child: Container(
          width: 100.0,
          child: const Text('Tile center'),
        ),
      ),
    );
    final Widget lowerItem = Container(
      width: 100.0,
      child: const Text('Tile lower'),
    );
    final Widget lowerSliver = SliverPadding(
      padding: const EdgeInsets.all(22.0),
      sliver: SliverToBoxAdapter(
        child: lowerItem,
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 200.0,
            width: 300.0,
            child: CustomScrollView(
              scrollDirection: Axis.horizontal,
              center: centerKey,
              reverse: true,
              slivers: <Widget>[lowerSliver, centerSliver],
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport = tester.allRenderObjects.whereType<RenderAbstractViewport>().first;

    final RenderObject target = tester.renderObject(find.byWidget(lowerItem, skipOffstage: false));
    RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
    expect(revealed.offset, -100 - 22);

    revealed = viewport.getOffsetToReveal(target, 1.0);
    expect(revealed.offset, - 100 - 22 - 200);
  });

  testWidgets('Viewport getOffsetToReveal Sliver - left', (WidgetTester tester) async {
    final List<Widget> children = <Widget>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 300.0,
            width: 200.0,
            child: CustomScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              controller: ScrollController(initialScrollOffset: 300.0),
              slivers: List<Widget>.generate(20, (int i) {
                final Widget sliver = SliverToBoxAdapter(
                    child: Container(
                      width: 100.0,
                      child: Text('Tile $i'),
                    ),
                );
                children.add(sliver);
                return SliverPadding(
                  padding: const EdgeInsets.all(22.0),
                  sliver: sliver,
                );
              }),
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport = tester.allRenderObjects.whereType<RenderAbstractViewport>().first;

    final RenderObject target = tester.renderObject(find.byWidget(children[5], skipOffstage: false));
    RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
    expect(revealed.offset, 5 * (100 + 22 + 22) + 22);

    revealed = viewport.getOffsetToReveal(target, 1.0);
    expect(revealed.offset, 5 * (100 + 22 + 22) + 22 - 100);
  });

  testWidgets('Nested Viewports showOnScreen', (WidgetTester tester) async {
    final List<List<Widget>> children = List<List<Widget>>(10);
    final List<ScrollController> controllersX = List<ScrollController>.generate(10, (int i) => ScrollController(initialScrollOffset: 400.0));
    final ScrollController controllerY  = ScrollController(initialScrollOffset: 400.0);

    /// Builds a gird:
    ///
    ///       <- x ->
    ///   0 1 2 3 4 5 6 7 8 9
    /// 0 c c c c c c c c c c
    /// 1 c c c c c c c c c c
    /// 2 c c c c c c c c c c
    /// 3 c c c c c c c c c c  y
    /// 4 c c c c v v c c c c
    /// 5 c c c c v v c c c c
    /// 6 c c c c c c c c c c
    /// 7 c c c c c c c c c c
    /// 8 c c c c c c c c c c
    /// 9 c c c c c c c c c c
    ///
    /// Each c is a 100x100 container, v are containers visible in initial
    /// viewport.

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 200.0,
            width: 200.0,
            child: ListView(
              controller: controllerY,
              children: List<Widget>.generate(10, (int y) {
                return Container(
                  height: 100.0,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    controller: controllersX[y],
                    children: children[y] = List<Widget>.generate(10, (int x) {
                      return Container(
                        height: 100.0,
                        width: 100.0,
                        child: Text('$x,$y'),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );

    // Already in viewport
    tester.renderObject(find.byWidget(children[4][4], skipOffstage: false)).showOnScreen();
    await tester.pumpAndSettle();
    expect(controllersX[4].offset, 400.0);
    expect(controllerY.offset, 400.0);

    controllersX[4].jumpTo(400.0);
    controllerY.jumpTo(400.0);
    await tester.pumpAndSettle();

    // Above viewport
    tester.renderObject(find.byWidget(children[3][4], skipOffstage: false)).showOnScreen();
    await tester.pumpAndSettle();
    expect(controllersX[3].offset, 400.0);
    expect(controllerY.offset, 300.0);

    controllersX[3].jumpTo(400.0);
    controllerY.jumpTo(400.0);
    await tester.pumpAndSettle();

    // Below viewport
    tester.renderObject(find.byWidget(children[6][4], skipOffstage: false)).showOnScreen();
    await tester.pumpAndSettle();
    expect(controllersX[6].offset, 400.0);
    expect(controllerY.offset, 500.0);

    controllersX[6].jumpTo(400.0);
    controllerY.jumpTo(400.0);
    await tester.pumpAndSettle();

    // Left of viewport
    tester.renderObject(find.byWidget(children[4][3], skipOffstage: false)).showOnScreen();
    await tester.pumpAndSettle();
    expect(controllersX[4].offset, 300.0);
    expect(controllerY.offset, 400.0);

    controllersX[4].jumpTo(400.0);
    controllerY.jumpTo(400.0);
    await tester.pumpAndSettle();

    // Right of viewport
    tester.renderObject(find.byWidget(children[4][6], skipOffstage: false)).showOnScreen();
    await tester.pumpAndSettle();
    expect(controllersX[4].offset, 500.0);
    expect(controllerY.offset, 400.0);

    controllersX[4].jumpTo(400.0);
    controllerY.jumpTo(400.0);
    await tester.pumpAndSettle();

    // Above and left of viewport
    tester.renderObject(find.byWidget(children[3][3], skipOffstage: false)).showOnScreen();
    await tester.pumpAndSettle();
    expect(controllersX[3].offset, 300.0);
    expect(controllerY.offset, 300.0);

    controllersX[3].jumpTo(400.0);
    controllerY.jumpTo(400.0);
    await tester.pumpAndSettle();

    // Below and left of viewport
    tester.renderObject(find.byWidget(children[6][3], skipOffstage: false)).showOnScreen();
    await tester.pumpAndSettle();
    expect(controllersX[6].offset, 300.0);
    expect(controllerY.offset, 500.0);

    controllersX[6].jumpTo(400.0);
    controllerY.jumpTo(400.0);
    await tester.pumpAndSettle();

    // Above and right of viewport
    tester.renderObject(find.byWidget(children[3][6], skipOffstage: false)).showOnScreen();
    await tester.pumpAndSettle();
    expect(controllersX[3].offset, 500.0);
    expect(controllerY.offset, 300.0);

    controllersX[3].jumpTo(400.0);
    controllerY.jumpTo(400.0);
    await tester.pumpAndSettle();

    // Below and right of viewport
    tester.renderObject(find.byWidget(children[6][6], skipOffstage: false)).showOnScreen();
    await tester.pumpAndSettle();
    expect(controllersX[6].offset, 500.0);
    expect(controllerY.offset, 500.0);

    controllersX[6].jumpTo(400.0);
    controllerY.jumpTo(400.0);
    await tester.pumpAndSettle();

    // Below and right of viewport with animations
    tester.renderObject(find.byWidget(children[6][6], skipOffstage: false)).showOnScreen(duration: const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isTrue);
    expect(controllersX[6].offset, greaterThan(400.0));
    expect(controllersX[6].offset, lessThan(500.0));
    expect(controllerY.offset, greaterThan(400.0));
    expect(controllerY.offset, lessThan(500.0));
    await tester.pumpAndSettle();
    expect(controllersX[6].offset, 500.0);
    expect(controllerY.offset, 500.0);
  });

  group('Nested viewports (same orientation) showOnScreen', () {
    List<Widget> children;

    Future<void> buildNestedScroller({ WidgetTester tester, ScrollController inner, ScrollController outer }) {
      return tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Container(
              height: 200.0,
              width: 300.0,
              child: ListView(
                controller: outer,
                children: <Widget>[
                  Container(
                    height: 200.0,
                  ),
                  Container(
                    height: 200.0,
                    width: 300.0,
                    child: ListView(
                      controller: inner,
                      children: children = List<Widget>.generate(10, (int i) {
                        return Container(
                          height: 100.0,
                          width: 300.0,
                          child: Text('$i'),
                        );
                      }),
                    ),
                  ),
                  Container(
                    height: 200.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Reverse List showOnScreen', (WidgetTester tester) async {
      const double screenHeight = 400.0;
      const double screenWidth = 400.0;
      const double itemHeight = screenHeight / 10.0;
      const ValueKey<String> centerKey = ValueKey<String>('center');

      tester.binding.window.devicePixelRatioTestValue = 1.0;
      tester.binding.window.physicalSizeTestValue = const Size(screenWidth, screenHeight);

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
            center: centerKey,
            reverse: true,
            slivers: <Widget>[
              SliverList(
                delegate: SliverChildListDelegate(
                  List<Widget>.generate(
                    10,
                        (int index) => SizedBox(
                      height: itemHeight,
                      child: Text('Item ${-index - 1}'),
                    ),
                  ),
                ),
              ),
              SliverList(
                key: centerKey,
                delegate: SliverChildListDelegate(
                  List<Widget>.generate(
                    1,
                        (int index) => const SizedBox(
                      height: itemHeight,
                      child: Text('Item 0'),
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  List<Widget>.generate(
                    10,
                    (int index) => SizedBox(
                      height: itemHeight,
                      child: Text('Item ${index + 1}'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Item -1'), findsNothing);

      final RenderBox itemNeg1 =
        tester.renderObject(find.text('Item -1', skipOffstage: false));

      itemNeg1.showOnScreen(duration: const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Item -1'), findsOneWidget);
    });

    testWidgets('in view in inner, but not in outer', (WidgetTester tester) async {
      final ScrollController inner = ScrollController();
      final ScrollController outer = ScrollController();
      await buildNestedScroller(
        tester: tester,
        inner: inner,
        outer: outer,
      );
      expect(outer.offset, 0.0);
      expect(inner.offset, 0.0);

      tester.renderObject(find.byWidget(children[0], skipOffstage: false)).showOnScreen();
      await tester.pumpAndSettle();
      expect(inner.offset, 0.0);
      expect(outer.offset, 100.0);
    });

    testWidgets('not in view of neither inner nor outer', (WidgetTester tester) async {
      final ScrollController inner = ScrollController();
      final ScrollController outer = ScrollController();
      await buildNestedScroller(
        tester: tester,
        inner: inner,
        outer: outer,
      );
      expect(outer.offset, 0.0);
      expect(inner.offset, 0.0);

      tester.renderObject(find.byWidget(children[4], skipOffstage: false)).showOnScreen();
      await tester.pumpAndSettle();
      expect(inner.offset, 300.0);
      expect(outer.offset, 200.0);
    });

    testWidgets('in view in inner and outer', (WidgetTester tester) async {
      final ScrollController inner = ScrollController(initialScrollOffset: 200.0);
      final ScrollController outer = ScrollController(initialScrollOffset: 200.0);
      await buildNestedScroller(
        tester: tester,
        inner: inner,
        outer: outer,
      );
      expect(outer.offset, 200.0);
      expect(inner.offset, 200.0);

      tester.renderObject(find.byWidget(children[2])).showOnScreen();
      await tester.pumpAndSettle();
      expect(outer.offset, 200.0);
      expect(inner.offset, 200.0);
    });

    testWidgets('inner shown in outer, but item not visible', (WidgetTester tester) async {
      final ScrollController inner = ScrollController(initialScrollOffset: 200.0);
      final ScrollController outer = ScrollController(initialScrollOffset: 200.0);
      await buildNestedScroller(
        tester: tester,
        inner: inner,
        outer: outer,
      );
      expect(outer.offset, 200.0);
      expect(inner.offset, 200.0);

      tester.renderObject(find.byWidget(children[5], skipOffstage: false)).showOnScreen();
      await tester.pumpAndSettle();
      expect(outer.offset, 200.0);
      expect(inner.offset, 400.0);
    });

    testWidgets('inner half shown in outer, item only visible in inner', (WidgetTester tester) async {
      final ScrollController inner = ScrollController();
      final ScrollController outer = ScrollController(initialScrollOffset: 100.0);
      await buildNestedScroller(
        tester: tester,
        inner: inner,
        outer: outer,
      );
      expect(outer.offset, 100.0);
      expect(inner.offset, 0.0);

      tester.renderObject(find.byWidget(children[1])).showOnScreen();
      await tester.pumpAndSettle();
      expect(outer.offset, 200.0);
      expect(inner.offset, 0.0);
    });
  });

  testWidgets('Nested Viewports showOnScreen with allowImplicitScrolling=false for inner viewport', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/20893.

    List<Widget> slivers;
    final ScrollController controllerX =  ScrollController(initialScrollOffset: 0.0);
    final ScrollController controllerY  = ScrollController(initialScrollOffset: 0.0);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 200.0,
            width: 200.0,
            child: ListView(
              controller: controllerY,
              children: <Widget>[
                Container(
                  height: 150.0,
                ),
                Container(
                  height: 100.0,
                  child: ListView(
                    physics: const PageScrollPhysics(), // Turns off `allowImplicitScrolling`
                    scrollDirection: Axis.horizontal,
                    controller: controllerX,
                    children: slivers = <Widget>[
                      Container(
                        width: 150.0,
                      ),
                      Container(
                        width: 150.0,
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 150.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    tester.renderObject(find.byWidget(slivers[1])).showOnScreen();
    await tester.pumpAndSettle();
    expect(controllerX.offset, 0.0);
    expect(controllerY.offset, 50.0);
  });

  testWidgets('Nested Viewports showOnScreen on Sliver with allowImplicitScrolling=false for inner viewport', (WidgetTester tester) async {
    Widget sliver;
    final ScrollController controllerX =  ScrollController(initialScrollOffset: 0.0);
    final ScrollController controllerY  = ScrollController(initialScrollOffset: 0.0);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 200.0,
            width: 200.0,
            child: ListView(
              controller: controllerY,
              children: <Widget>[
                Container(
                  height: 150.0,
                ),
                Container(
                  height: 100.0,
                  child: CustomScrollView(
                    physics: const PageScrollPhysics(), // Turns off `allowImplicitScrolling`
                    scrollDirection: Axis.horizontal,
                    controller: controllerX,
                    slivers: <Widget>[
                      SliverPadding(
                        padding: const EdgeInsets.all(25.0),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            width: 100.0,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(25.0),
                        sliver: sliver = SliverToBoxAdapter(
                          child: Container(
                            width: 100.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 150.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    tester.renderObject(find.byWidget(sliver)).showOnScreen();
    await tester.pumpAndSettle();
    expect(controllerX.offset, 0.0);
    expect(controllerY.offset, 25.0);
  });

  testWidgets('Viewport showOnScreen with objects larger than viewport', (WidgetTester tester) async {
    List<Widget> children;
    ScrollController controller;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 200.0,
            child: ListView(
              controller: controller = ScrollController(initialScrollOffset: 300.0),
              children: children = List<Widget>.generate(20, (int i) {
                return Container(
                  height: 300.0,
                  child: Text('Tile $i'),
                );
              }),
            ),
          ),
        ),
      ),
    );

    expect(controller.offset, 300.0);

    // Already aligned with leading edge, nothing happens.
    tester.renderObject(find.byWidget(children[1], skipOffstage: false)).showOnScreen();
    await tester.pumpAndSettle();
    expect(controller.offset, 300.0);

    // Above leading edge aligns trailing edges
    tester.renderObject(find.byWidget(children[0], skipOffstage: false)).showOnScreen();
    await tester.pumpAndSettle();
    expect(controller.offset, 100.0);

    // Below trailing edge aligns leading edges
    tester.renderObject(find.byWidget(children[1], skipOffstage: false)).showOnScreen();
    await tester.pumpAndSettle();
    expect(controller.offset, 300.0);

    controller.jumpTo(250.0);
    await tester.pumpAndSettle();
    expect(controller.offset, 250.0);

    // Partly visible across leading edge aligns trailing edges
    tester.renderObject(find.byWidget(children[0], skipOffstage: false)).showOnScreen();
    await tester.pumpAndSettle();
    expect(controller.offset, 100.0);

    controller.jumpTo(150.0);
    await tester.pumpAndSettle();
    expect(controller.offset, 150.0);

    // Partly visible across trailing edge aligns leading edges
    tester.renderObject(find.byWidget(children[1], skipOffstage: false)).showOnScreen();
    await tester.pumpAndSettle();
    expect(controller.offset, 300.0);
  });

  group('unbounded constraints control test', () {
    Widget buildNestedWidget([Axis a1 = Axis.vertical, Axis a2 = Axis.horizontal]) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            child: ListView(
              scrollDirection: a1,
              children: List<Widget>.generate(10, (int y) {
                return Container(
                  child: ListView(
                    scrollDirection: a2,
                  ),
                );
              }),
            ),
          ),
        ),
      );
    }

    Future<void> expectFlutterError({
      Widget widget,
      WidgetTester tester,
      String message,
    }) async {
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails error) => errors.add(error);
      try {
        await tester.pumpWidget(widget);
      } finally {
        FlutterError.onError = oldHandler;
      }
      expect(errors, isNotEmpty);
      expect(errors.first.exception, isFlutterError);
      expect(errors.first.exception.toStringDeep(), message);
    }

    testWidgets('Horizontal viewport was given unbounded height', (WidgetTester tester) async {
      await expectFlutterError(
        widget: buildNestedWidget(),
        tester: tester,
        message:
          'FlutterError\n'
          '   Horizontal viewport was given unbounded height.\n'
          '   Viewports expand in the cross axis to fill their container and\n'
          '   constrain their children to match their extent in the cross axis.\n'
          '   In this case, a horizontal viewport was given an unlimited amount\n'
          '   of vertical space in which to expand.\n',
      );
    });

    testWidgets('Horizontal viewport was given unbounded width', (WidgetTester tester) async {
      await expectFlutterError(
        widget: buildNestedWidget(Axis.horizontal, Axis.horizontal),
        tester: tester,
        message:
          'FlutterError\n'
          '   Horizontal viewport was given unbounded width.\n'
          '   Viewports expand in the scrolling direction to fill their\n'
          '   container.In this case, a horizontal viewport was given an\n'
          '   unlimited amount of horizontal space in which to expand. This\n'
          '   situation typically happens when a scrollable widget is nested\n'
          '   inside another scrollable widget.\n'
          '   If this widget is always nested in a scrollable widget there is\n'
          '   no need to use a viewport because there will always be enough\n'
          '   horizontal space for the children. In this case, consider using a\n'
          '   Row instead. Otherwise, consider using the "shrinkWrap" property\n'
          '   (or a ShrinkWrappingViewport) to size the width of the viewport\n'
          '   to the sum of the widths of its children.\n'
      );
    });

    testWidgets('Vertical viewport was given unbounded width', (WidgetTester tester) async {
      await expectFlutterError(
        widget: buildNestedWidget(Axis.horizontal, Axis.vertical),
        tester: tester,
        message:
          'FlutterError\n'
          '   Vertical viewport was given unbounded width.\n'
          '   Viewports expand in the cross axis to fill their container and\n'
          '   constrain their children to match their extent in the cross axis.\n'
          '   In this case, a vertical viewport was given an unlimited amount\n'
          '   of horizontal space in which to expand.\n'
      );
    });

    testWidgets('Vertical viewport was given unbounded height', (WidgetTester tester) async {
      await expectFlutterError(
        widget: buildNestedWidget(Axis.vertical, Axis.vertical),
        tester: tester,
        message:
          'FlutterError\n'
          '   Vertical viewport was given unbounded height.\n'
          '   Viewports expand in the scrolling direction to fill their\n'
          '   container. In this case, a vertical viewport was given an\n'
          '   unlimited amount of vertical space in which to expand. This\n'
          '   situation typically happens when a scrollable widget is nested\n'
          '   inside another scrollable widget.\n'
          '   If this widget is always nested in a scrollable widget there is\n'
          '   no need to use a viewport because there will always be enough\n'
          '   vertical space for the children. In this case, consider using a\n'
          '   Column instead. Otherwise, consider using the "shrinkWrap"\n'
          '   property (or a ShrinkWrappingViewport) to size the height of the\n'
          '   viewport to the sum of the heights of its children.\n'
      );
    });
  });

  test('Viewport debugThrowIfNotCheckingIntrinsics() control test', () {
    final RenderViewport renderViewport = RenderViewport(
      crossAxisDirection: AxisDirection.right, offset: ViewportOffset.zero()
    );
    FlutterError error;
    try {
      renderViewport.computeMinIntrinsicHeight(0);
    } on FlutterError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(
      error.toStringDeep(),
      'FlutterError\n'
      '   RenderViewport does not support returning intrinsic dimensions.\n'
      '   Calculating the intrinsic dimensions would require instantiating\n'
      '   every child of the viewport, which defeats the point of viewports\n'
      '   being lazy.\n'
      '   If you are merely trying to shrink-wrap the viewport in the main\n'
      '   axis direction, consider a RenderShrinkWrappingViewport render\n'
      '   object (ShrinkWrappingViewport widget), which achieves that\n'
      '   effect without implementing the intrinsic dimension API.\n',
    );

    final RenderShrinkWrappingViewport renderShrinkWrappingViewport = RenderShrinkWrappingViewport(
      crossAxisDirection: AxisDirection.right, offset: ViewportOffset.zero()
    );
    error = null;
    try {
      renderShrinkWrappingViewport.computeMinIntrinsicHeight(0);
    } on FlutterError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(
      error.toStringDeep(),
      'FlutterError\n'
      '   RenderShrinkWrappingViewport does not support returning intrinsic\n'
      '   dimensions.\n'
      '   Calculating the intrinsic dimensions would require instantiating\n'
      '   every child of the viewport, which defeats the point of viewports\n'
      '   being lazy.\n'
      '   If you are merely trying to shrink-wrap the viewport in the main\n'
      '   axis direction, you should be able to achieve that effect by just\n'
      '   giving the viewport loose constraints, without needing to measure\n'
      '   its intrinsic dimensions.\n',
    );
  });

  testWidgets('Handles infinite constraints when TargetPlatform is iOS or macOS', (WidgetTester tester) async {
    // regression test for https://github.com/flutter/flutter/issues/45866
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GridView(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 3,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3),
              children: const <Widget>[
                Text('a'),
                Text('b'),
                Text('c'),
              ],
            ),
          ],
        ),
      ),
    );

    expect(find.text('b'), findsOneWidget);
    await tester.drag(find.text('b'), const Offset(0, 200));
    await tester.pumpAndSettle();
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS, TargetPlatform.macOS }));
}
