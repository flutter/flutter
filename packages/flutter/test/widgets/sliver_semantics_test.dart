// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('excludeFromScrollable works correctly', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    const double appBarExpandedHeight = 200.0;

    final ScrollController scrollController = new ScrollController();
    final List<Widget> listChildren = new List<Widget>.generate(30, (int i) {
      return new Container(
        height: appBarExpandedHeight,
        child: new Text('Item $i'),
      );
    });
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new MediaQuery(
          data: const MediaQueryData(),
          child: new CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              const SliverAppBar(
                pinned: true,
                expandedHeight: appBarExpandedHeight,
                title: const Text('Semantics Test with Slivers'),
              ),
              new SliverList(
                delegate: new SliverChildListDelegate(listChildren),
              ),
            ],
          ),
        ),
      ),
    );

    // AppBar is child of node with semantic scroll actions.
    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            tags: <SemanticsTag>[RenderViewport.useTwoPaneSemantics],
            children: <TestSemantics>[
              new TestSemantics(
                id: 5,
                actions: SemanticsAction.scrollUp.index,
                children: <TestSemantics>[
                  new TestSemantics(
                    id: 2,
                    label: 'Item 0',
                  ),
                  new TestSemantics(
                    id: 3,
                    label: 'Item 1',
                  ),
                  new TestSemantics(
                    id: 4,
                    label: 'Semantics Test with Slivers',
                  ),
                ],
              ),
            ],
          )
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
    ));

    // Scroll down far enough to reach the pinned state of the app bar.
    scrollController.jumpTo(appBarExpandedHeight);
    await tester.pump();

    // App bar is NOT a child of node with semantic scroll actions.
    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            tags: <SemanticsTag>[RenderViewport.useTwoPaneSemantics],
            children: <TestSemantics>[
              new TestSemantics(
                id: 5,
                actions: SemanticsAction.scrollUp.index | SemanticsAction.scrollDown.index,
                children: <TestSemantics>[
                  new TestSemantics(
                    id: 2,
                    label: 'Item 0',
                  ),
                  new TestSemantics(
                    id: 3,
                    label: 'Item 1',
                  ),
                  new TestSemantics(
                    id: 6,
                    label: 'Item 2',
                  ),
                ],
              ),
              new TestSemantics(
                id: 4,
                label: 'Semantics Test with Slivers',
                tags: <SemanticsTag>[RenderViewport.excludeFromScrolling],
              ),
            ],
          )
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
    ));

    // Scroll halfway back to the top, app bar is no longer in pinned state.
    scrollController.jumpTo(appBarExpandedHeight / 2);
    await tester.pump();

    // AppBar is child of node with semantic scroll actions.
    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            tags: <SemanticsTag>[RenderViewport.useTwoPaneSemantics],
            children: <TestSemantics>[
              new TestSemantics(
                id: 5,
                actions: SemanticsAction.scrollUp.index | SemanticsAction.scrollDown.index,
                children: <TestSemantics>[
                  new TestSemantics(
                    id: 2,
                    label: 'Item 0',
                  ),
                  new TestSemantics(
                    id: 3,
                    label: 'Item 1',
                  ),
                  new TestSemantics(
                    id: 6,
                    label: 'Item 2',
                  ),
                  new TestSemantics(
                    id: 4,
                    label: 'Semantics Test with Slivers',
                  ),
                ],
              ),
            ],
          )
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
    ));

    semantics.dispose();
  });

  testWidgets('Offscreen sliver are not included in semantics tree', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    const double containerHeight = 200.0;

    final ScrollController scrollController = new ScrollController(
      initialScrollOffset: containerHeight * 1.5,
    );
    final List<Widget> slivers = new List<Widget>.generate(30, (int i) {
      return new SliverToBoxAdapter(
        child: new Container(
          height: containerHeight,
          child: new Text('Item $i', textDirection: TextDirection.ltr),
        ),
      );
    });
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new SizedBox(
            height: containerHeight,
            child: new CustomScrollView(
              controller: scrollController,
              slivers: slivers,
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 7,
            tags: <SemanticsTag>[RenderViewport.useTwoPaneSemantics],
            children: <TestSemantics>[
              new TestSemantics(
                id: 10,
                actions: SemanticsAction.scrollUp.index | SemanticsAction.scrollDown.index,
                children: <TestSemantics>[
                  new TestSemantics(
                    id: 8,
                    label: 'Item 2',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    id: 9,
                    label: 'Item 1',
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ],
          )
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
    ));

    semantics.dispose();
  });

  testWidgets('SemanticsNodes of Slivers are in paint order', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final List<Widget> slivers = new List<Widget>.generate(5, (int i) {
      return new SliverToBoxAdapter(
        child: new Container(
          height: 20.0,
          child: new Text('Item $i'),
        ),
      );
    });
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new CustomScrollView(
          slivers: slivers,
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 11,
            tags: <SemanticsTag>[RenderViewport.useTwoPaneSemantics],
            children: <TestSemantics>[
              new TestSemantics(
                id: 17,
                children: <TestSemantics>[
                  new TestSemantics(
                    id: 12,
                    label: 'Item 4',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    id: 13,
                    label: 'Item 3',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    id: 14,
                    label: 'Item 2',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    id: 15,
                    label: 'Item 1',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    id: 16,
                    label: 'Item 0',
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ],
          )
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
    ));

    semantics.dispose();
  });

  testWidgets('SemanticsNodes of a sliver fully covered by another overlapping sliver are excluded', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final List<Widget> listChildren = new List<Widget>.generate(10, (int i) {
      return new Container(
        height: 200.0,
        child: new Text('Item $i', textDirection: TextDirection.ltr),
      );
    });
    final ScrollController controller = new ScrollController(initialScrollOffset: 280.0);
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: const MediaQueryData(),
        child: new CustomScrollView(
          slivers: <Widget>[
            const SliverAppBar(
              pinned: true,
              expandedHeight: 100.0,
              title: const Text('AppBar'),
            ),
            new SliverList(
              delegate: new SliverChildListDelegate(listChildren),
            ),
          ],
          controller: controller,
        ),
      ),
    ));

    // 'Item 0' is covered by app bar.
    expect(semantics, isNot(includesNodeWith(label: 'Item 0')));

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 18,
            rect: TestSemantics.fullScreen,
            tags: <SemanticsTag>[RenderViewport.useTwoPaneSemantics],
            children: <TestSemantics>[
              new TestSemantics(
                id: 23,
                actions: SemanticsAction.scrollUp.index | SemanticsAction.scrollDown.index,
                rect: TestSemantics.fullScreen,
                children: <TestSemantics>[
                  // Item 0 is missing because its covered by the app bar.
                  new TestSemantics(
                    id: 19,
                    rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                    // Item 1 starts 20.0dp below edge, so there would be room for Item 0.
                    transform: new Matrix4.translation(new Vector3(0.0, 20.0, 0.0)),
                    label: 'Item 1',
                  ),
                  new TestSemantics(
                    id: 20,
                    rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                    transform: new Matrix4.translation(new Vector3(0.0, 220.0, 0.0)),
                    label: 'Item 2',
                  ),
                  new TestSemantics(
                    id: 21,
                    rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                    transform: new Matrix4.translation(new Vector3(0.0, 420.0, 0.0)),
                    label: 'Item 3',
                  ),
                ],
              ),
              new TestSemantics(
                id: 22,
                rect: new Rect.fromLTRB(0.0, 0.0, 120.0, 20.0),
                tags: <SemanticsTag>[RenderViewport.excludeFromScrolling],
                label: 'AppBar',
              ),
            ],
          )
        ],
      ),
      ignoreTransform: true,
    ));

    semantics.dispose();
  });

  testWidgets('Slivers fully covered by another overlapping sliver are excluded', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final ScrollController controller = new ScrollController(initialScrollOffset: 280.0);
    final List<Widget> slivers = new List<Widget>.generate(10, (int i) {
      return new SliverToBoxAdapter(
        child: new Container(
          height: 200.0,
          child: new Text('Item $i', textDirection: TextDirection.ltr),
        ),
      );
    });
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: const MediaQueryData(),
        child: new CustomScrollView(
          controller: controller,
          slivers: <Widget>[
            const SliverAppBar(
              pinned: true,
              expandedHeight: 100.0,
              title: const Text('AppBar'),
            ),
          ]..addAll(slivers),
        ),
      ),
    ));

    // 'Item 0' is covered by app bar.
    expect(semantics, isNot(includesNodeWith(label: 'Item 0')));

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 24,
            rect: TestSemantics.fullScreen,
            tags: <SemanticsTag>[RenderViewport.useTwoPaneSemantics],
            children: <TestSemantics>[
              new TestSemantics(
                id: 29,
                actions: SemanticsAction.scrollUp.index | SemanticsAction.scrollDown.index,
                rect: TestSemantics.fullScreen,
                children: <TestSemantics>[
                  new TestSemantics(
                    id: 25,
                    rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                    transform: new Matrix4.translation(new Vector3(0.0, 420.0, 0.0)),
                    label: 'Item 3',
                  ),
                  new TestSemantics(
                    id: 26,
                    rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                    transform: new Matrix4.translation(new Vector3(0.0, 220.0, 0.0)),
                    label: 'Item 2',
                  ),
                  new TestSemantics(
                    id: 27,
                    rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                    // Item 1 starts 20.0dp below edge, so there would be room for Item 0.
                    transform: new Matrix4.translation(new Vector3(0.0, 20.0, 0.0)),
                    label: 'Item 1',
                  ),
                  // Item 0 is missing because its covered by the app bar.
                ],
              ),
              new TestSemantics(
                id: 28,
                rect: new Rect.fromLTRB(0.0, 0.0, 120.0, 20.0),
                tags: <SemanticsTag>[RenderViewport.excludeFromScrolling],
                label: 'AppBar'
              ),
            ],
          )
        ],
      ),
      ignoreTransform: true,
    ));

    semantics.dispose();
  });

  testWidgets('SemanticsNodes of a sliver fully covered by another overlapping sliver are excluded (reverse)', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final List<Widget> listChildren = new List<Widget>.generate(10, (int i) {
      return new Container(
        height: 200.0,
        child: new Text('Item $i', textDirection: TextDirection.ltr),
      );
    });
    final ScrollController controller = new ScrollController(initialScrollOffset: 280.0);
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: const MediaQueryData(),
        child: new CustomScrollView(
          reverse: true, // This is the important setting for this test.
          slivers: <Widget>[
            const SliverAppBar(
              pinned: true,
              expandedHeight: 100.0,
              title: const Text('AppBar'),
            ),
            new SliverList(
              delegate: new SliverChildListDelegate(listChildren),
            ),
          ],
          controller: controller,
        ),
      ),
    ));

    // 'Item 0' is covered by app bar.
    expect(semantics, isNot(includesNodeWith(label: 'Item 0')));

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 30,
            rect: TestSemantics.fullScreen,
            tags: <SemanticsTag>[RenderViewport.useTwoPaneSemantics],
            children: <TestSemantics>[
              new TestSemantics(
                id: 35,
                actions: SemanticsAction.scrollUp.index | SemanticsAction.scrollDown.index,
                rect: TestSemantics.fullScreen,
                children: <TestSemantics>[
                  // Item 0 is missing because its covered by the app bar.
                  new TestSemantics(
                    id: 31,
                    // Item 1 ends at 580dp, so there would be 20dp space for Item 0.
                    rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                    transform: new Matrix4.translation(new Vector3(0.0, 380.0, 0.0)),
                    label: 'Item 1',
                  ),
                  new TestSemantics(
                    id: 32,
                    rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                    transform: new Matrix4.translation(new Vector3(0.0, 180.0, 0.0)),
                    label: 'Item 2',
                  ),
                  new TestSemantics(
                    id: 33,
                    rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                    transform: new Matrix4.translation(new Vector3(0.0, -20.0, 0.0)),
                    label: 'Item 3',
                  ),
                ],
              ),
              new TestSemantics(
                id: 34,
                rect: new Rect.fromLTRB(0.0, 0.0, 120.0, 20.0),
                transform: new Matrix4.translation(new Vector3(0.0, 544.0, 0.0)),
                tags: <SemanticsTag>[RenderViewport.excludeFromScrolling],
                label: 'AppBar'
              ),
            ],
          )
        ],
      ),
      ignoreTransform: true,
    ));

    semantics.dispose();
  });

  testWidgets('Slivers fully covered by another overlapping sliver are excluded (reverse)', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final ScrollController controller = new ScrollController(initialScrollOffset: 280.0);
    final List<Widget> slivers = new List<Widget>.generate(10, (int i) {
      return new SliverToBoxAdapter(
        child: new Container(
          height: 200.0,
          child: new Text('Item $i', textDirection: TextDirection.ltr),
        ),
      );
    });
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: const MediaQueryData(),
        child: new CustomScrollView(
          reverse: true, // This is the important setting for this test.
          controller: controller,
          slivers: <Widget>[
            const SliverAppBar(
              pinned: true,
              expandedHeight: 100.0,
              title: const Text('AppBar'),
            ),
          ]..addAll(slivers),
        ),
      ),
    ));

    // 'Item 0' is covered by app bar.
    expect(semantics, isNot(includesNodeWith(label: 'Item 0')));

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 36,
            rect: TestSemantics.fullScreen,
            tags: <SemanticsTag>[RenderViewport.useTwoPaneSemantics],
            children: <TestSemantics>[
              new TestSemantics(
                id: 41,
                actions: SemanticsAction.scrollUp.index | SemanticsAction.scrollDown.index,
                rect: TestSemantics.fullScreen,
                children: <TestSemantics>[
                  new TestSemantics(
                    id: 37,
                    rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                    transform: new Matrix4.translation(new Vector3(0.0, -20.0, 0.0)),
                    label: 'Item 3',
                  ),
                  new TestSemantics(
                    id: 38,
                    rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                    transform: new Matrix4.translation(new Vector3(0.0, 180.0, 0.0)),
                    label: 'Item 2',
                  ),
                  new TestSemantics(
                    id: 39,
                    rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                    // Item 1 ends at 580dp, so there would be 20dp space for Item 0.
                    transform: new Matrix4.translation(new Vector3(0.0, 380.0, 0.0)),
                    label: 'Item 1',
                  ),
                  // Item 0 is missing because its covered by the app bar.
                ],
              ),
              new TestSemantics(
                id: 40,
                rect: new Rect.fromLTRB(0.0, 0.0, 120.0, 20.0),
                transform: new Matrix4.translation(new Vector3(0.0, 544.0, 0.0)),
                tags: <SemanticsTag>[RenderViewport.excludeFromScrolling],
                label: 'AppBar'
              ),
            ],
          )
        ],
      ),
      ignoreTransform: true,
    ));

    semantics.dispose();
  });

  testWidgets('Slivers fully covered by another overlapping sliver are excluded (with center sliver)', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final ScrollController controller = new ScrollController(initialScrollOffset: 280.0);
    final GlobalKey forwardAppBarKey = new GlobalKey(debugLabel: 'forward app bar');
    final List<Widget> forwardChildren = new List<Widget>.generate(10, (int i) {
      return new Container(
        height: 200.0,
        child: new Text('Forward Item $i', textDirection: TextDirection.ltr),
      );
    });
    final List<Widget> backwardChildren = new List<Widget>.generate(10, (int i) {
      return new Container(
        height: 200.0,
        child: new Text('Backward Item $i', textDirection: TextDirection.ltr),
      );
    });
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: const MediaQueryData(),
        child: new Scrollable(
          controller: controller,
          viewportBuilder: (BuildContext context, ViewportOffset offset) {
            return new Viewport(
              offset: offset,
              center: forwardAppBarKey,
              slivers: <Widget>[
                new SliverList(
                  delegate: new SliverChildListDelegate(backwardChildren),
                ),
                const SliverAppBar(
                  pinned: true,
                  expandedHeight: 100.0,
                  flexibleSpace: const FlexibleSpaceBar(
                    title: const Text('Backward app bar', textDirection: TextDirection.ltr),
                  ),
                ),
                new SliverAppBar(
                  pinned: true,
                  key: forwardAppBarKey,
                  expandedHeight: 100.0,
                  flexibleSpace: const FlexibleSpaceBar(
                    title: const Text('Forward app bar', textDirection: TextDirection.ltr),
                  ),
                ),
                new SliverList(
                  delegate: new SliverChildListDelegate(forwardChildren),
                ),
              ],
            );
          },
        ),
      ),
    ));

    // 'Forward Item 0' is covered by app bar.
    expect(semantics, isNot(includesNodeWith(label: 'Forward Item 0')));
    expect(semantics, includesNodeWith(label: 'Forward Item 1'));

    controller.jumpTo(-880.0);
    await tester.pumpAndSettle();
    expect(semantics, isNot(includesNodeWith(label: 'Backward Item 0')));
    expect(semantics, includesNodeWith(label: 'Backward Item 1'));

    semantics.dispose();
  });

}
