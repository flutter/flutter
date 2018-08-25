// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Viewport getOffsetToReveal - down', (WidgetTester tester) async {
    List<Widget> children;
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: Container(
            height: 200.0,
            width: 300.0,
            child: new ListView(
              controller: new ScrollController(initialScrollOffset: 300.0),
              children: children = new List<Widget>.generate(20, (int i) {
                return new Container(
                  height: 100.0,
                  width: 300.0,
                  child: new Text('Tile $i'),
                );
              }),
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport = tester.allRenderObjects.firstWhere((RenderObject r) => r is RenderAbstractViewport);

    final RenderObject target = tester.renderObject(find.byWidget(children[5], skipOffstage: false));
    RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
    expect(revealed.offset, 500.0);
    expect(revealed.rect, new Rect.fromLTWH(0.0, 0.0, 300.0, 100.0));

    revealed = viewport.getOffsetToReveal(target, 1.0);
    expect(revealed.offset, 400.0);
    expect(revealed.rect, new Rect.fromLTWH(0.0, 100.0, 300.0, 100.0));

    revealed = viewport.getOffsetToReveal(target, 0.0, rect: new Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 540.0);
    expect(revealed.rect, new Rect.fromLTWH(40.0, 0.0, 10.0, 10.0));

    revealed = viewport.getOffsetToReveal(target, 1.0, rect: new Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 350.0);
    expect(revealed.rect, new Rect.fromLTWH(40.0, 190.0, 10.0, 10.0));
  });

  testWidgets('Viewport getOffsetToReveal - right', (WidgetTester tester) async {
    List<Widget> children;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: Container(
            height: 300.0,
            width: 200.0,
            child: new ListView(
              scrollDirection: Axis.horizontal,
              controller: new ScrollController(initialScrollOffset: 300.0),
              children: children = new List<Widget>.generate(20, (int i) {
                return new Container(
                  height: 300.0,
                  width: 100.0,
                  child: new Text('Tile $i'),
                );
              }),
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport = tester.allRenderObjects.firstWhere((RenderObject r) => r is RenderAbstractViewport);

    final RenderObject target = tester.renderObject(find.byWidget(children[5], skipOffstage: false));
    RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
    expect(revealed.offset, 500.0);
    expect(revealed.rect, new Rect.fromLTWH(0.0, 0.0, 100.0, 300.0));

    revealed = viewport.getOffsetToReveal(target, 1.0);
    expect(revealed.offset, 400.0);
    expect(revealed.rect, new Rect.fromLTWH(100.0, 0.0, 100.0, 300.0));

    revealed = viewport.getOffsetToReveal(target, 0.0, rect: new Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 540.0);
    expect(revealed.rect, new Rect.fromLTWH(0.0, 40.0, 10.0, 10.0));

    revealed = viewport.getOffsetToReveal(target, 1.0, rect: new Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 350.0);
    expect(revealed.rect, new Rect.fromLTWH(190.0, 40.0, 10.0, 10.0));
  });

  testWidgets('Viewport getOffsetToReveal - up', (WidgetTester tester) async {
    List<Widget> children;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: Container(
            height: 200.0,
            width: 300.0,
            child: new ListView(
              controller: new ScrollController(initialScrollOffset: 300.0),
              reverse: true,
              children: children = new List<Widget>.generate(20, (int i) {
                return new Container(
                  height: 100.0,
                  width: 300.0,
                  child: new Text('Tile $i'),
                );
              }),
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport = tester.allRenderObjects.firstWhere((RenderObject r) => r is RenderAbstractViewport);

    final RenderObject target = tester.renderObject(find.byWidget(children[5], skipOffstage: false));
    RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
    expect(revealed.offset, 500.0);
    expect(revealed.rect, new Rect.fromLTWH(0.0, 100.0, 300.0, 100.0));

    revealed = viewport.getOffsetToReveal(target, 1.0);
    expect(revealed.offset, 400.0);
    expect(revealed.rect, new Rect.fromLTWH(0.0, 0.0, 300.0, 100.0));

    revealed = viewport.getOffsetToReveal(target, 0.0, rect: new Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 550.0);
    expect(revealed.rect, new Rect.fromLTWH(40.0, 190.0, 10.0, 10.0));

    revealed = viewport.getOffsetToReveal(target, 1.0, rect: new Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 360.0);
    expect(revealed.rect, new Rect.fromLTWH(40.0, 0.0, 10.0, 10.0));
  });

  testWidgets('Viewport getOffsetToReveal - left', (WidgetTester tester) async {
    List<Widget> children;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: Container(
            height: 300.0,
            width: 200.0,
            child: new ListView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              controller: new ScrollController(initialScrollOffset: 300.0),
              children: children = new List<Widget>.generate(20, (int i) {
                return new Container(
                  height: 300.0,
                  width: 100.0,
                  child: new Text('Tile $i'),
                );
              }),
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport = tester.allRenderObjects.firstWhere((RenderObject r) => r is RenderAbstractViewport);

    final RenderObject target = tester.renderObject(find.byWidget(children[5], skipOffstage: false));
    RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
    expect(revealed.offset, 500.0);
    expect(revealed.rect, new Rect.fromLTWH(100.0, 0.0, 100.0, 300.0));

    revealed = viewport.getOffsetToReveal(target, 1.0);
    expect(revealed.offset, 400.0);
    expect(revealed.rect, new Rect.fromLTWH(0.0, 0.0, 100.0, 300.0));

    revealed = viewport.getOffsetToReveal(target, 0.0, rect: new Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 550.0);
    expect(revealed.rect, new Rect.fromLTWH(190.0, 40.0, 10.0, 10.0));

    revealed = viewport.getOffsetToReveal(target, 1.0, rect: new Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 360.0);
    expect(revealed.rect, new Rect.fromLTWH(0.0, 40.0, 10.0, 10.0));
  });

  testWidgets('Nested Viewports showOnScreen', (WidgetTester tester) async {
    final List<List<Widget>> children = new List<List<Widget>>(10);
    final List<ScrollController> controllersX = new List<ScrollController>.generate(10, (int i) => new ScrollController(initialScrollOffset: 400.0));
    final ScrollController controllerY  = new ScrollController(initialScrollOffset: 400.0);

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
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: Container(
            height: 200.0,
            width: 200.0,
            child: new ListView(
              controller: controllerY,
              children: new List<Widget>.generate(10, (int y) {
                return Container(
                  height: 100.0,
                  child: new ListView(
                    scrollDirection: Axis.horizontal,
                    controller: controllersX[y],
                    children: children[y] = new List<Widget>.generate(10, (int x) {
                      return new Container(
                        height: 100.0,
                        width: 100.0,
                        child: new Text('$x,$y'),
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

    Future<Null> buildNestedScroller({WidgetTester tester, ScrollController inner, ScrollController outer}) {
      return tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Center(
            child: Container(
              height: 200.0,
              width: 300.0,
              child: new ListView(
                controller: outer,
                children: <Widget>[
                  new Container(
                    height: 200.0,
                  ),
                  new Container(
                    height: 200.0,
                    width: 300.0,
                    child: new ListView(
                      controller: inner,
                      children: children = new List<Widget>.generate(10, (int i) {
                        return new Container(
                          height: 100.0,
                          width: 300.0,
                          child: new Text('$i'),
                        );
                      }),
                    ),
                  ),
                  new Container(
                    height: 200.0,
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('in view in inner, but not in outer', (WidgetTester tester) async {
      final ScrollController inner = new ScrollController();
      final ScrollController outer = new ScrollController();
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
      final ScrollController inner = new ScrollController();
      final ScrollController outer = new ScrollController();
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
      final ScrollController inner = new ScrollController(initialScrollOffset: 200.0);
      final ScrollController outer = new ScrollController(initialScrollOffset: 200.0);
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
      final ScrollController inner = new ScrollController(initialScrollOffset: 200.0);
      final ScrollController outer = new ScrollController(initialScrollOffset: 200.0);
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
      final ScrollController inner = new ScrollController();
      final ScrollController outer = new ScrollController(initialScrollOffset: 100.0);
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

  testWidgets('Viewport showOnScreen with objects larger than viewport', (WidgetTester tester) async {
    List<Widget> children;
    ScrollController controller;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: Container(
            height: 200.0,
            child: new ListView(
              controller: controller = new ScrollController(initialScrollOffset: 300.0),
              children: children = new List<Widget>.generate(20, (int i) {
                return new Container(
                  height: 300.0,
                  child: new Text('Tile $i'),
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
}
