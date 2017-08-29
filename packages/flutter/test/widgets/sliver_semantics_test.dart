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
                      label: 'Semantics Test with Slivers',
                    ),
                    new TestSemantics(
                      id: 3,
                      label: 'Item 0',
                    ),
                    new TestSemantics(
                      id: 4,
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
                id: 6,
                label: 'Semantics Test with Slivers',
                tags: <SemanticsTag>[RenderSemanticsGestureHandler.excludeFromScrolling],
              ),
              new TestSemantics(
                id: 5,
                actions: SemanticsAction.scrollUp.index | SemanticsAction.scrollDown.index,
                children: <TestSemantics>[
                  new TestSemantics(
                    id: 3,
                    label: 'Item 0',
                  ),
                  new TestSemantics(
                    id: 4,
                    label: 'Item 1',
                  ),
                  new TestSemantics(
                    id: 7,
                    label: 'Item 2',
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
                    id: 8,
                    label: 'Semantics Test with Slivers',
                  ),
                  new TestSemantics(
                    id: 3,
                    label: 'Item 0',
                  ),
                  new TestSemantics(
                    id: 4,
                    label: 'Item 1',
                  ),
                  new TestSemantics(
                    id: 7,
                    label: 'Item 2',
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
  });
}
