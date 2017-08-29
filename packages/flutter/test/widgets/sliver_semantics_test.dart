// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

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
      new MediaQuery(
        data: const MediaQueryData(),
        child: new CustomScrollView(
          controller: scrollController,
          slivers: <Widget>[
            new SliverAppBar(
              pinned: true,
              expandedHeight: appBarExpandedHeight,
              title: const Text('Semantics Test with Slivers'),
            ),
            new SliverList(
              delegate: new SliverChildListDelegate(listChildren),
            ),
          ],
        ),
    ));

    // AppBar is child of node with semantic scroll actions.
    expect(semantics, hasSemantics(
        new TestSemantics.root(
          children: <TestSemantics>[
            new TestSemantics.rootChild(
              id: 1,
              tags: <SemanticsTag>[RenderSemanticsGestureHandler.useTwoPaneSemantics],
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
            tags: <SemanticsTag>[RenderSemanticsGestureHandler.useTwoPaneSemantics],
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
                id: 7,
                label: 'Semantics Test with Slivers',
                tags: <SemanticsTag>[RenderSemanticsGestureHandler.excludeFromScrolling],
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
            tags: <SemanticsTag>[RenderSemanticsGestureHandler.useTwoPaneSemantics],
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
                    id: 8,
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
          child: new Text('Item $i'),
        ),
      );
    });
    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          height: containerHeight,
          child: new CustomScrollView(
            controller: scrollController,
            slivers: slivers,
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 9,
            tags: <SemanticsTag>[RenderSemanticsGestureHandler.useTwoPaneSemantics],
            children: <TestSemantics>[
              new TestSemantics(
                id: 12,
                actions: SemanticsAction.scrollUp.index | SemanticsAction.scrollDown.index,
                children: <TestSemantics>[
                  new TestSemantics(
                    id: 10,
                    label: 'Item 2',
                  ),
                  new TestSemantics(
                    id: 11,
                    label: 'Item 1',
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
      new CustomScrollView(
        slivers: slivers,
      ),
    );
    
    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 13,
            tags: <SemanticsTag>[RenderSemanticsGestureHandler.useTwoPaneSemantics],
            children: <TestSemantics>[
              new TestSemantics(
                id: 19,
                children: <TestSemantics>[
                  new TestSemantics(
                    id: 14,
                    label: 'Item 4',
                  ),
                  new TestSemantics(
                    id: 15,
                    label: 'Item 3',
                  ),
                  new TestSemantics(
                    id: 16,
                    label: 'Item 2',
                  ),
                  new TestSemantics(
                    id: 17,
                    label: 'Item 1',
                  ),
                  new TestSemantics(
                    id: 18,
                    label: 'Item 0',
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
}
