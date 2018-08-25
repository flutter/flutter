// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Traversal Order of SliverList', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final List<Widget> listChildren = new List<Widget>.generate(30, (int i) {
      return new Container(
        height: 200.0,
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new Semantics(
              container: true,
              child: new Text('Item ${i}a'),
            ),
            new Semantics(
              container: true,
              child: new Text('item ${i}b'),
            ),
          ],
        ),
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
              controller: new ScrollController(initialScrollOffset: 3000.0),
              slivers: <Widget>[
                new SliverList(
                  delegate: new SliverChildListDelegate(listChildren),
                ),
              ],
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
                        label: 'Item 13a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'item 13b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 14a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'item 14b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 15a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'item 15b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 16a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'item 16b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 17a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'item 17b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 18a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'item 18b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 19a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'item 19b',
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
      childOrder: DebugSemanticsDumpOrder.traversalOrder,
      ignoreId: true,
      ignoreTransform: true,
      ignoreRect: true,
    ));

    semantics.dispose();
  });

  testWidgets('Traversal Order of SliverFixedExtentList', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final List<Widget> listChildren = new List<Widget>.generate(30, (int i) {
      return new Container(
        height: 200.0,
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new Semantics(
              container: true,
              child: new Text('Item ${i}a'),
            ),
            new Semantics(
              container: true,
              child: new Text('item ${i}b'),
            ),
          ],
        ),
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
              controller: new ScrollController(initialScrollOffset: 3000.0),
              slivers: <Widget>[
                new SliverFixedExtentList(
                  itemExtent: 200.0,
                  delegate: new SliverChildListDelegate(listChildren),
                ),
              ],
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
                        label: 'Item 13a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'item 13b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 14a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'item 14b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 15a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'item 15b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 16a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'item 16b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 17a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'item 17b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 18a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'item 18b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 19a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'item 19b',
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
      childOrder: DebugSemanticsDumpOrder.traversalOrder,
      ignoreId: true,
      ignoreTransform: true,
      ignoreRect: true,
    ));

    semantics.dispose();
  });

  testWidgets('Traversal Order of SliverGrid', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final List<Widget> listChildren = new List<Widget>.generate(30, (int i) {
      return new Container(
        height: 200.0,
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
              controller: new ScrollController(initialScrollOffset: 1600.0),
              slivers: <Widget>[
                new SliverGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 400.0,
                  children: listChildren,
                ),
              ],
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
                    actions: <SemanticsAction>[SemanticsAction.scrollUp,
                    SemanticsAction.scrollDown],
                    children: <TestSemantics>[
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 12',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 13',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 14',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 15',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 16',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 17',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 18',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 19',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 20',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 21',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 22',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 23',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 24',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 25',
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
      childOrder: DebugSemanticsDumpOrder.traversalOrder,
      ignoreId: true,
      ignoreTransform: true,
      ignoreRect: true,
    ));

    semantics.dispose();
  });

  testWidgets('Traversal Order of List of individual slivers', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final List<Widget> listChildren = new List<Widget>.generate(30, (int i) {
      return new SliverToBoxAdapter(
        child: new Container(
          height: 200.0,
          child: new Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              new Semantics(
                container: true,
                child: new Text('Item ${i}a'),
              ),
              new Semantics(
                container: true,
                child: new Text('item ${i}b'),
              ),
            ],
          ),
        ),
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
              controller: new ScrollController(initialScrollOffset: 3000.0),
              slivers: listChildren,
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
                        label: 'Item 13a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'item 13b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 14a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'item 14b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 15a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'item 15b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 16a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'item 16b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'Item 17a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: 'item 17b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 18a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'item 18b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'Item 19a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: 'item 19b',
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
      childOrder: DebugSemanticsDumpOrder.traversalOrder,
      ignoreId: true,
      ignoreTransform: true,
      ignoreRect: true,
    ));

    semantics.dispose();
  });

  testWidgets('Traversal Order of in a SingleChildScrollView', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final List<Widget> listChildren = new List<Widget>.generate(30, (int i) {
      return new Container(
        height: 200.0,
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new Semantics(
              container: true,
              child: new Text('Item ${i}a'),
            ),
            new Semantics(
              container: true,
              child: new Text('item ${i}b'),
            ),
          ],
        ),
      );
    });
    await tester.pumpWidget(
      new Semantics(
        textDirection: TextDirection.ltr,
        child: new Directionality(
          textDirection: TextDirection.ltr,
          child: new MediaQuery(
            data: const MediaQueryData(),
            child: new SingleChildScrollView(
              controller: new ScrollController(initialScrollOffset: 3000.0),
              child: new Column(
                children: listChildren,
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
                actions: <SemanticsAction>[
                  SemanticsAction.scrollUp,
                  SemanticsAction.scrollDown,
                ],
                children: <TestSemantics>[
                  new TestSemantics(
                    flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                    label: 'Item 13a',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                    label: 'item 13b',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                    label: 'Item 14a',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                    label: 'item 14b',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    label: 'Item 15a',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    label: 'item 15b',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    label: 'Item 16a',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    label: 'item 16b',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    label: 'Item 17a',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    label: 'item 17b',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                    label: 'Item 18a',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                    label: 'item 18b',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                    label: 'Item 19a',
                    textDirection: TextDirection.ltr,
                  ),
                  new TestSemantics(
                    flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                    label: 'item 19b',
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      childOrder: DebugSemanticsDumpOrder.traversalOrder,
      ignoreId: true,
      ignoreTransform: true,
      ignoreRect: true,
    ));

    semantics.dispose();
  });

  testWidgets('Traversal Order with center child', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(new Semantics(
      textDirection: TextDirection.ltr,
      child: new Directionality(
        textDirection: TextDirection.ltr,
        child: new MediaQuery(
          data: const MediaQueryData(),
          child: new Scrollable(
            viewportBuilder: (BuildContext context, ViewportOffset offset) {
              return new Viewport(
                offset: offset,
                center: const ValueKey<int>(0),
                slivers: new List<Widget>.generate(30, (int i) {
                  final int item = i - 15;
                  return new SliverToBoxAdapter(
                    key: new ValueKey<int>(item),
                    child: new Container(
                      height: 200.0,
                      child: new Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          new Semantics(
                            container: true,
                            child: new Text('${item}a'),
                          ),
                          new Semantics(
                            container: true,
                            child: new Text('${item}b'),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
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
                        label: '-2a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: '-2b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: '-1a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: '-1b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: '0a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: '0b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: '1a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: '1b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: '2a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        label: '2b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: '3a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: '3b',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: '4a',
                        textDirection: TextDirection.ltr,
                      ),
                      new TestSemantics(
                        flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                        label: '4b',
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
}
