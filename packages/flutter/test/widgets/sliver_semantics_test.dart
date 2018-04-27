// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

import 'semantics_tester.dart';

void main() {
  group('Sliver Semantics', () {
    setUp(() {
      debugResetSemanticsIdCounter();
    });

    _tests();
  });
}

void _tests() {
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
      new Semantics(
        textDirection: TextDirection.ltr,
        child: new Directionality(
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
      ),
    );

    // AppBar is child of node with semantic scroll actions.
    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics(
            id: 1,
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              new TestSemantics(
                id: 2,
                children: <TestSemantics>[
                  new TestSemantics(
                    id: 9,
                    actions: <SemanticsAction>[SemanticsAction.scrollUp],
                    children: <TestSemantics>[
                      new TestSemantics(
                        id: 7,
                        children: <TestSemantics>[
                          new TestSemantics(
                            id: 8,
                            flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
                            label: 'Semantics Test with Slivers',
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                      new TestSemantics(
                        id: 3,
                        label: 'Item 0',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        id: 4,
                        label: 'Item 1',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        id: 5,
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 2',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        id: 6,
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 3',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
          new TestSemantics(
            id: 1,
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              new TestSemantics(
                id: 2,
                children: <TestSemantics>[
                  new TestSemantics(
                    id: 7,
                    tags: <SemanticsTag>[RenderViewport.excludeFromScrolling],
                    children: <TestSemantics>[
                      new TestSemantics(
                        id: 8,
                        flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
                        label: 'Semantics Test with Slivers',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                  new TestSemantics(
                    id: 9,
                    actions: <SemanticsAction>[
                      SemanticsAction.scrollUp,
                      SemanticsAction.scrollDown,
                    ],
                    children: <TestSemantics>[
                      new TestSemantics(
                        id: 3,
                        label: 'Item 0',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        id: 4,
                        label: 'Item 1',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        id: 5,
                        label: 'Item 2',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        id: 6,
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 3',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        id: 10,
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 4',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
          new TestSemantics(
            id: 1,
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              new TestSemantics(
                id: 2,
                children: <TestSemantics>[
                  new TestSemantics(
                    id: 9,
                    actions: <SemanticsAction>[
                      SemanticsAction.scrollUp,
                      SemanticsAction.scrollDown,
                    ],
                    children: <TestSemantics>[
                      new TestSemantics(
                        id: 7,
                        children: <TestSemantics>[
                          new TestSemantics(
                            id: 8,
                            flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
                            label: 'Semantics Test with Slivers',
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                      new TestSemantics(
                        id: 3,
                        label: 'Item 0',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        id: 4,
                        label: 'Item 1',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        id: 5,
                        label: 'Item 2',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        id: 6,
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 3',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
    ));

    semantics.dispose();
  });

  testWidgets('Offscreen sliver are hidden in semantics tree', (WidgetTester tester) async {
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
      new Semantics(
        textDirection: TextDirection.ltr,
        child: new Directionality(
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
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics(
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              new TestSemantics(
                children: <TestSemantics>[
                  new TestSemantics(
                    actions: <SemanticsAction>[
                      SemanticsAction.scrollUp,
                      SemanticsAction.scrollDown,
                    ],
                    children: <TestSemantics>[
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 0',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 1',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 2',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 3',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
      ignoreId: true,
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
      new Semantics(
        textDirection: TextDirection.ltr,
        child: new Directionality(
          textDirection: TextDirection.ltr,
          child: new CustomScrollView(
            slivers: slivers,
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics(
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              new TestSemantics(
                children: <TestSemantics>[
                  new TestSemantics(
                    children: <TestSemantics>[
                      new TestSemantics(
                        label: 'Item 4',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 3',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 2',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 1',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 0',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
      ignoreId: true,
      childOrder: DebugSemanticsDumpOrder.inverseHitTest,
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
    await tester.pumpWidget(new Semantics(
      textDirection: TextDirection.ltr,
      child: new Directionality(
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
      ),
    ));

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics(
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              new TestSemantics(
                children: <TestSemantics>[
                  new TestSemantics(
                    tags: <SemanticsTag>[RenderViewport.excludeFromScrolling],
                    children: <TestSemantics>[
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
                        label: 'AppBar',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                  new TestSemantics(
                    actions: <SemanticsAction>[
                      SemanticsAction.scrollUp,
                      SemanticsAction.scrollDown,
                    ],
                    children: <TestSemantics>[
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 0',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 1',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 2',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 3',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 4',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 5',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ignoreTransform: true,
      ignoreId: true,
      ignoreRect: true,
    ));

    semantics.dispose();
  });

  testWidgets('Slivers fully covered by another overlapping sliver are hidden', (WidgetTester tester) async {
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
    await tester.pumpWidget(new Semantics(
      textDirection: TextDirection.ltr,
      child: new Directionality(
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
      ),
    ));

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics(
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              new TestSemantics(
                children: <TestSemantics>[
                  new TestSemantics(
                    tags: <SemanticsTag>[RenderViewport.excludeFromScrolling],
                    children: <TestSemantics>[
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
                        label: 'AppBar',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                  new TestSemantics(
                    actions: <SemanticsAction>[
                      SemanticsAction.scrollUp,
                      SemanticsAction.scrollDown,
                    ],
                    children: <TestSemantics>[
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 0',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 1',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 2',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 3',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 4',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 5',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ignoreTransform: true,
      ignoreRect: true,
      ignoreId: true,
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
    await tester.pumpWidget(new Semantics(
      textDirection: TextDirection.ltr,
      child: new Directionality(
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
      ),
    ));

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics(
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              new TestSemantics(
                children: <TestSemantics>[
                  new TestSemantics(
                    actions: <SemanticsAction>[
                      SemanticsAction.scrollUp,
                      SemanticsAction.scrollDown,
                    ],
                    children: <TestSemantics>[
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 5',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 4',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 3',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 2',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 1',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 0',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                  new TestSemantics(
                    tags: <SemanticsTag>[RenderViewport.excludeFromScrolling],
                    children: <TestSemantics>[
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
                        label: 'AppBar',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ignoreTransform: true,
      ignoreId: true,
      ignoreRect: true,
    ));

    semantics.dispose();
  });

  testWidgets('Slivers fully covered by another overlapping sliver are hidden (reverse)', (WidgetTester tester) async {
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
    await tester.pumpWidget(new Semantics(
      textDirection: TextDirection.ltr,
      child: new Directionality(
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
      ),
    ));

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics(
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              new TestSemantics(
                children: <TestSemantics>[
                  new TestSemantics(
                    actions: <SemanticsAction>[SemanticsAction.scrollUp,
                    SemanticsAction.scrollDown],
                    children: <TestSemantics>[
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 5',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 4',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 3',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 2',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 1',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 0',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                  new TestSemantics(
                    tags: <SemanticsTag>[RenderViewport.excludeFromScrolling],
                    children: <TestSemantics>[
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
                        label: 'AppBar',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ignoreTransform: true,
      ignoreId: true,
      ignoreRect: true,
    ));

    semantics.dispose();
  });

  testWidgets('Slivers fully covered by another overlapping sliver are hidden (with center sliver)', (WidgetTester tester) async {
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
    await tester.pumpWidget(new Semantics(
      textDirection: TextDirection.ltr,
      child: new Directionality(
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
      ),
    ));

    // 'Forward Item 0' is covered by app bar.
    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics(
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              new TestSemantics(
                children: <TestSemantics>[
                  new TestSemantics(
                    tags: <SemanticsTag>[RenderViewport.excludeFromScrolling],
                    children: <TestSemantics>[
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
                        label: 'Forward app bar',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                  new TestSemantics(
                    actions: <SemanticsAction>[
                      SemanticsAction.scrollUp,
                      SemanticsAction.scrollDown,
                    ],
                    children: <TestSemantics>[
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Forward Item 0',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Forward Item 1',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Forward Item 2',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Forward Item 3',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Forward Item 4',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Forward Item 5',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ignoreTransform: true,
      ignoreRect: true,
      ignoreId: true,
    ));

    controller.jumpTo(-880.0);
    await tester.pumpAndSettle();

    // 'Backward Item 0' is covered by app bar.
    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics(
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              new TestSemantics(
                children: <TestSemantics>[
                  new TestSemantics(
                    actions: <SemanticsAction>[
                      SemanticsAction.scrollUp,
                      SemanticsAction.scrollDown,
                    ],
                    children: <TestSemantics>[
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Backward Item 5',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Backward Item 4',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Backward Item 3',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Backward Item 2',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Backward Item 1',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Backward Item 0',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                  new TestSemantics(
                    tags: <SemanticsTag>[RenderViewport.excludeFromScrolling],
                    children: <TestSemantics>[
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
                        label: 'Backward app bar',
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ), ignoreTransform: true, ignoreRect: true, ignoreId: true,
    ));

    semantics.dispose();
  });

}
