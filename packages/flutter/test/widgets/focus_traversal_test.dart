// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

/// Used to test removal of nodes while sorting.
class SkipAllButFirstAndLastPolicy extends FocusTraversalPolicy with DirectionalFocusTraversalPolicyMixin {
  @override
  Iterable<FocusNode> sortDescendants(Iterable<FocusNode> descendants, FocusNode currentNode) {
    return <FocusNode>[
      descendants.first,
      if (currentNode != descendants.first && currentNode != descendants.last) currentNode,
      descendants.last,
    ];
  }
}

void main() {
  group(WidgetOrderTraversalPolicy, () {
    testWidgets('Find the initial focus if there is none yet.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final GlobalKey key3 = GlobalKey(debugLabel: '3');
      final GlobalKey key4 = GlobalKey(debugLabel: '4');
      final GlobalKey key5 = GlobalKey(debugLabel: '5');
      await tester.pumpWidget(FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: FocusScope(
          key: key1,
          child: Column(
            children: <Widget>[
              Focus(
                key: key2,
                child: SizedBox(key: key3, width: 100, height: 100),
              ),
              Focus(
                key: key4,
                child: SizedBox(key: key5, width: 100, height: 100),
              ),
            ],
          ),
        ),
      ));

      final Element firstChild = tester.element(find.byKey(key3));
      final Element secondChild = tester.element(find.byKey(key5));
      final FocusNode firstFocusNode = Focus.of(firstChild);
      final FocusNode secondFocusNode = Focus.of(secondChild);
      final FocusNode scope = Focus.of(firstChild).enclosingScope!;
      secondFocusNode.nextFocus();

      await tester.pump();

      expect(firstFocusNode.hasFocus, isTrue);
      expect(secondFocusNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
    });

    testWidgets('Find the initial focus if there is none yet and traversing backwards.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final GlobalKey key3 = GlobalKey(debugLabel: '3');
      final GlobalKey key4 = GlobalKey(debugLabel: '4');
      final GlobalKey key5 = GlobalKey(debugLabel: '5');
      await tester.pumpWidget(FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: FocusScope(
          key: key1,
          child: Column(
            children: <Widget>[
              Focus(
                key: key2,
                child: SizedBox(key: key3, width: 100, height: 100),
              ),
              Focus(
                key: key4,
                child: SizedBox(key: key5, width: 100, height: 100),
              ),
            ],
          ),
        ),
      ));

      final Element firstChild = tester.element(find.byKey(key3));
      final Element secondChild = tester.element(find.byKey(key5));
      final FocusNode firstFocusNode = Focus.of(firstChild);
      final FocusNode secondFocusNode = Focus.of(secondChild);
      final FocusNode scope = Focus.of(firstChild).enclosingScope!;

      expect(firstFocusNode.hasFocus, isFalse);
      expect(secondFocusNode.hasFocus, isFalse);

      secondFocusNode.previousFocus();

      await tester.pump();

      expect(firstFocusNode.hasFocus, isFalse);
      expect(secondFocusNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);
    });

    testWidgets('Move focus to next node.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final GlobalKey key3 = GlobalKey(debugLabel: '3');
      final GlobalKey key4 = GlobalKey(debugLabel: '4');
      final GlobalKey key5 = GlobalKey(debugLabel: '5');
      final GlobalKey key6 = GlobalKey(debugLabel: '6');
      bool? focus1;
      bool? focus2;
      bool? focus3;
      bool? focus5;
      await tester.pumpWidget(
        FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: FocusScope(
            debugLabel: 'key1',
            key: key1,
            onFocusChange: (bool focus) => focus1 = focus,
            child: Column(
              children: <Widget>[
                FocusScope(
                  debugLabel: 'key2',
                  key: key2,
                  onFocusChange: (bool focus) => focus2 = focus,
                  child: Column(
                    children: <Widget>[
                      Focus(
                        debugLabel: 'key3',
                        key: key3,
                        onFocusChange: (bool focus) => focus3 = focus,
                        child: Container(key: key4),
                      ),
                      Focus(
                        debugLabel: 'key5',
                        key: key5,
                        onFocusChange: (bool focus) => focus5 = focus,
                        child: Container(key: key6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final Element firstChild = tester.element(find.byKey(key4));
      final Element secondChild = tester.element(find.byKey(key6));
      final FocusNode firstFocusNode = Focus.of(firstChild);
      final FocusNode secondFocusNode = Focus.of(secondChild);
      final FocusNode scope = Focus.of(firstChild).enclosingScope!;
      firstFocusNode.requestFocus();

      await tester.pump();

      expect(focus1, isTrue);
      expect(focus2, isTrue);
      expect(focus3, isTrue);
      expect(focus5, isNull);
      expect(firstFocusNode.hasFocus, isTrue);
      expect(secondFocusNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);

      focus1 = null;
      focus2 = null;
      focus3 = null;
      focus5 = null;

      Focus.of(firstChild).nextFocus();

      await tester.pump();

      expect(focus1, isNull);
      expect(focus2, isNull);
      expect(focus3, isFalse);
      expect(focus5, isTrue);
      expect(firstFocusNode.hasFocus, isFalse);
      expect(secondFocusNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);

      focus1 = null;
      focus2 = null;
      focus3 = null;
      focus5 = null;

      Focus.of(firstChild).nextFocus();

      await tester.pump();

      expect(focus1, isNull);
      expect(focus2, isNull);
      expect(focus3, isTrue);
      expect(focus5, isFalse);
      expect(firstFocusNode.hasFocus, isTrue);
      expect(secondFocusNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);

      focus1 = null;
      focus2 = null;
      focus3 = null;
      focus5 = null;

      // Tests that can still move back to original node.
      Focus.of(firstChild).previousFocus();

      await tester.pump();

      expect(focus1, isNull);
      expect(focus2, isNull);
      expect(focus3, isFalse);
      expect(focus5, isTrue);
      expect(firstFocusNode.hasFocus, isFalse);
      expect(secondFocusNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);
    });

    testWidgets('Move focus to previous node.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final GlobalKey key3 = GlobalKey(debugLabel: '3');
      final GlobalKey key4 = GlobalKey(debugLabel: '4');
      final GlobalKey key5 = GlobalKey(debugLabel: '5');
      final GlobalKey key6 = GlobalKey(debugLabel: '6');
      await tester.pumpWidget(
        FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: FocusScope(
            key: key1,
            child: Column(
              children: <Widget>[
                FocusScope(
                  key: key2,
                  child: Column(
                    children: <Widget>[
                      Focus(
                        key: key3,
                        child: Container(key: key4),
                      ),
                      Focus(
                        key: key5,
                        child: Container(key: key6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final Element firstChild = tester.element(find.byKey(key4));
      final Element secondChild = tester.element(find.byKey(key6));
      final FocusNode firstFocusNode = Focus.of(firstChild);
      final FocusNode secondFocusNode = Focus.of(secondChild);
      final FocusNode scope = Focus.of(firstChild).enclosingScope!;
      secondFocusNode.requestFocus();

      await tester.pump();

      expect(firstFocusNode.hasFocus, isFalse);
      expect(secondFocusNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);

      Focus.of(firstChild).previousFocus();

      await tester.pump();

      expect(firstFocusNode.hasFocus, isTrue);
      expect(secondFocusNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);

      Focus.of(firstChild).previousFocus();

      await tester.pump();

      expect(firstFocusNode.hasFocus, isFalse);
      expect(secondFocusNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);

      // Tests that can still move back to original node.
      Focus.of(firstChild).nextFocus();

      await tester.pump();

      expect(firstFocusNode.hasFocus, isTrue);
      expect(secondFocusNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
    });

    testWidgets('Move focus to next/previous node while skipping nodes in policy', (WidgetTester tester) async {
      final List<FocusNode> nodes =
      List<FocusNode>.generate(7, (int index) => FocusNode(debugLabel: 'Node $index'));
      await tester.pumpWidget(
        FocusTraversalGroup(
          policy: SkipAllButFirstAndLastPolicy(),
          child: Column(
            children: List<Widget>.generate(
              nodes.length,
              (int index) => Focus(
                focusNode: nodes[index],
                child: const SizedBox(),
              ),
            ),
          ),
        ),
      );

      nodes[2].requestFocus();
      await tester.pump();

      expect(nodes[2].hasPrimaryFocus, isTrue);

      primaryFocus!.nextFocus();
      await tester.pump();

      expect(nodes[6].hasPrimaryFocus, isTrue);

      primaryFocus!.previousFocus();
      await tester.pump();

      expect(nodes[0].hasPrimaryFocus, isTrue);
    });

    testWidgets('Find the initial focus when a route is pushed or popped.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final FocusNode testNode1 = FocusNode(debugLabel: 'First Focus Node');
      final FocusNode testNode2 = FocusNode(debugLabel: 'Second Focus Node');
      await tester.pumpWidget(
        MaterialApp(
          home: FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: Center(
              child: Builder(builder: (BuildContext context) {
                return MaterialButton(
                  key: key1,
                  focusNode: testNode1,
                  autofocus: true,
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                          return Center(
                            child: MaterialButton(
                              key: key2,
                              focusNode: testNode2,
                              autofocus: true,
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Go Back'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: const Text('Go Forward'),
                );
              }),
            ),
          ),
        ),
      );

      final Element firstChild = tester.element(find.text('Go Forward'));
      final FocusNode firstFocusNode = Focus.of(firstChild);
      final FocusNode scope = Focus.of(firstChild).enclosingScope!;
      await tester.pump();

      expect(firstFocusNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);

      await tester.tap(find.text('Go Forward'));
      await tester.pumpAndSettle();

      final Element secondChild = tester.element(find.text('Go Back'));
      final FocusNode secondFocusNode = Focus.of(secondChild);

      expect(firstFocusNode.hasFocus, isFalse);
      expect(secondFocusNode.hasFocus, isTrue);

      await tester.tap(find.text('Go Back'));
      await tester.pumpAndSettle();

      expect(firstFocusNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);
    });
  });

  group(ReadingOrderTraversalPolicy, () {
    testWidgets('Find the initial focus if there is none yet.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final GlobalKey key3 = GlobalKey(debugLabel: '3');
      final GlobalKey key4 = GlobalKey(debugLabel: '4');
      final GlobalKey key5 = GlobalKey(debugLabel: '5');
      await tester.pumpWidget(FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: FocusScope(
          key: key1,
          child: Column(
            children: <Widget>[
              Focus(
                key: key2,
                child: SizedBox(key: key3, width: 100, height: 100),
              ),
              Focus(
                key: key4,
                child: SizedBox(key: key5, width: 100, height: 100),
              ),
            ],
          ),
        ),
      ));

      final Element firstChild = tester.element(find.byKey(key3));
      final Element secondChild = tester.element(find.byKey(key5));
      final FocusNode firstFocusNode = Focus.of(firstChild);
      final FocusNode secondFocusNode = Focus.of(secondChild);
      final FocusNode scope = Focus.of(firstChild).enclosingScope!;
      secondFocusNode.nextFocus();

      await tester.pump();

      expect(firstFocusNode.hasFocus, isTrue);
      expect(secondFocusNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
    });

    testWidgets('Move reading focus to next node.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final GlobalKey key3 = GlobalKey(debugLabel: '3');
      final GlobalKey key4 = GlobalKey(debugLabel: '4');
      final GlobalKey key5 = GlobalKey(debugLabel: '5');
      final GlobalKey key6 = GlobalKey(debugLabel: '6');
      bool? focus1;
      bool? focus2;
      bool? focus3;
      bool? focus5;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: FocusScope(
              debugLabel: 'key1',
              key: key1,
              onFocusChange: (bool focus) => focus1 = focus,
              child: Column(
                children: <Widget>[
                  FocusScope(
                    debugLabel: 'key2',
                    key: key2,
                    onFocusChange: (bool focus) => focus2 = focus,
                    child: Row(
                      children: <Widget>[
                        Focus(
                          debugLabel: 'key3',
                          key: key3,
                          onFocusChange: (bool focus) => focus3 = focus,
                          child: Container(key: key4),
                        ),
                        Focus(
                          debugLabel: 'key5',
                          key: key5,
                          onFocusChange: (bool focus) => focus5 = focus,
                          child: Container(key: key6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      void clear() {
        focus1 = null;
        focus2 = null;
        focus3 = null;
        focus5 = null;
      }

      final Element firstChild = tester.element(find.byKey(key4));
      final Element secondChild = tester.element(find.byKey(key6));
      final FocusNode firstFocusNode = Focus.of(firstChild);
      final FocusNode secondFocusNode = Focus.of(secondChild);
      final FocusNode scope = Focus.of(firstChild).enclosingScope!;
      firstFocusNode.requestFocus();

      await tester.pump();

      expect(focus1, isTrue);
      expect(focus2, isTrue);
      expect(focus3, isTrue);
      expect(focus5, isNull);
      expect(firstFocusNode.hasFocus, isTrue);
      expect(secondFocusNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
      clear();

      Focus.of(firstChild).nextFocus();

      await tester.pump();

      expect(focus1, isNull);
      expect(focus2, isNull);
      expect(focus3, isFalse);
      expect(focus5, isTrue);
      expect(firstFocusNode.hasFocus, isFalse);
      expect(secondFocusNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);
      clear();

      Focus.of(firstChild).nextFocus();

      await tester.pump();

      expect(focus1, isNull);
      expect(focus2, isNull);
      expect(focus3, isTrue);
      expect(focus5, isFalse);
      expect(firstFocusNode.hasFocus, isTrue);
      expect(secondFocusNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
      clear();

      // Tests that can still move back to original node.
      Focus.of(firstChild).previousFocus();

      await tester.pump();

      expect(focus1, isNull);
      expect(focus2, isNull);
      expect(focus3, isFalse);
      expect(focus5, isTrue);
      expect(firstFocusNode.hasFocus, isFalse);
      expect(secondFocusNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);
    });

    testWidgets('Move reading focus to previous node.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final GlobalKey key3 = GlobalKey(debugLabel: '3');
      final GlobalKey key4 = GlobalKey(debugLabel: '4');
      final GlobalKey key5 = GlobalKey(debugLabel: '5');
      final GlobalKey key6 = GlobalKey(debugLabel: '6');
      await tester.pumpWidget(
        FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: FocusScope(
            key: key1,
            child: Column(
              children: <Widget>[
                FocusScope(
                  key: key2,
                  child: Column(
                    children: <Widget>[
                      Focus(
                        key: key3,
                        child: Container(key: key4),
                      ),
                      Focus(
                        key: key5,
                        child: Container(key: key6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final Element firstChild = tester.element(find.byKey(key4));
      final Element secondChild = tester.element(find.byKey(key6));
      final FocusNode firstFocusNode = Focus.of(firstChild);
      final FocusNode secondFocusNode = Focus.of(secondChild);
      final FocusNode scope = Focus.of(firstChild).enclosingScope!;
      secondFocusNode.requestFocus();

      await tester.pump();

      expect(firstFocusNode.hasFocus, isFalse);
      expect(secondFocusNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);

      Focus.of(firstChild).previousFocus();

      await tester.pump();

      expect(firstFocusNode.hasFocus, isTrue);
      expect(secondFocusNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);

      Focus.of(firstChild).previousFocus();

      await tester.pump();

      expect(firstFocusNode.hasFocus, isFalse);
      expect(secondFocusNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);

      // Tests that can still move back to original node.
      Focus.of(firstChild).nextFocus();

      await tester.pump();

      expect(firstFocusNode.hasFocus, isTrue);
      expect(secondFocusNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
    });

    testWidgets('Focus order is correct in the presence of different directionalities.', (WidgetTester tester) async {
      const int nodeCount = 10;
      final FocusScopeNode scopeNode = FocusScopeNode();
      final List<FocusNode> nodes = List<FocusNode>.generate(nodeCount, (int index) => FocusNode(debugLabel: 'Node $index'));
      Widget buildTest(TextDirection topDirection) {
        return Directionality(
          textDirection: topDirection,
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: FocusScope(
              node: scopeNode,
              child: Column(
                children: <Widget>[
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(children: <Widget>[
                      Focus(
                        focusNode: nodes[0],
                        child: const SizedBox(width: 10, height: 10),
                      ),
                      Focus(
                        focusNode: nodes[1],
                        child: const SizedBox(width: 10, height: 10),
                      ),
                      Focus(
                        focusNode: nodes[2],
                        child: const SizedBox(width: 10, height: 10),
                      ),
                    ]),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(children: <Widget>[
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Focus(
                          focusNode: nodes[3],
                          child: const SizedBox(width: 10, height: 10),
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Focus(
                          focusNode: nodes[4],
                          child: const SizedBox(width: 10, height: 10),
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Focus(
                          focusNode: nodes[5],
                          child: const SizedBox(width: 10, height: 10),
                        ),
                      ),
                    ]),
                  ),
                  Row(children: <Widget>[
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Focus(
                        focusNode: nodes[6],
                        child: const SizedBox(width: 10, height: 10),
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Focus(
                        focusNode: nodes[7],
                        child: const SizedBox(width: 10, height: 10),
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Focus(
                        focusNode: nodes[8],
                        child: const SizedBox(width: 10, height: 10),
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Focus(
                        focusNode: nodes[9],
                        child: const SizedBox(width: 10, height: 10),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      }
      await tester.pumpWidget(buildTest(TextDirection.rtl));

      // The last four *are* correct: the Row is sensitive to the directionality
      // too, so it swaps the positions of 7 and 8.
      final List<int> order = <int>[];
      for (int i = 0; i < nodeCount; ++i) {
        nodes.first.nextFocus();
        await tester.pump();
        order.add(nodes.indexOf(primaryFocus!));
      }
      expect(order, orderedEquals(<int>[0, 1, 2, 4, 3, 5, 6, 7, 8, 9]));

      await tester.pumpWidget(buildTest(TextDirection.ltr));

      order.clear();
      for (int i = 0; i < nodeCount; ++i) {
        nodes.first.nextFocus();
        await tester.pump();
        order.add(nodes.indexOf(primaryFocus!));
      }
      expect(order, orderedEquals(<int>[0, 1, 2, 4, 3, 5, 6, 8, 7, 9]));
    });

    testWidgets('Focus order is reading order regardless of widget order, even when overlapping.', (WidgetTester tester) async {
      const int nodeCount = 10;
      final List<FocusNode> nodes = List<FocusNode>.generate(nodeCount, (int index) => FocusNode(debugLabel: 'Node $index'));
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Stack(
              alignment: Alignment.topLeft,
              children: List<Widget>.generate(nodeCount, (int index) {
                // Boxes that all have the same upper left origin corner.
                return Focus(
                  focusNode: nodes[index],
                  child: SizedBox(width: 10.0 * (index + 1), height: 10.0 * (index + 1)),
                );
              }),
            ),
          ),
        ),
      );

      final List<int> order = <int>[];
      for (int i = 0; i < nodeCount; ++i) {
        nodes.first.nextFocus();
        await tester.pump();
        order.add(nodes.indexOf(primaryFocus!));
      }
      expect(order, orderedEquals(<int>[9, 8, 7, 6, 5, 4, 3, 2, 1, 0]));

      // Concentric boxes.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Stack(
              alignment: Alignment.center,
              children: List<Widget>.generate(nodeCount, (int index) {
                return Focus(
                  focusNode: nodes[index],
                  child: SizedBox(width: 10.0 * (index + 1), height: 10.0 * (index + 1)),
                );
              }),
            ),
          ),
        ),
      );

      order.clear();
      for (int i = 0; i < nodeCount; ++i) {
        nodes.first.nextFocus();
        await tester.pump();
        order.add(nodes.indexOf(primaryFocus!));
      }
      expect(order, orderedEquals(<int>[9, 8, 7, 6, 5, 4, 3, 2, 1, 0]));

      // Stacked (vertically) and centered (horizontally, on each other)
      // widgets, not overlapping.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Stack(
              alignment: Alignment.center,
              children: List<Widget>.generate(nodeCount, (int index) {
                return Positioned(
                  top: 5.0 * index * (index + 1),
                  left: 5.0 * (9 - index),
                  child: Focus(
                    focusNode: nodes[index],
                    child: Container(
                      decoration: BoxDecoration(border: Border.all()),
                      width: 10.0 * (index + 1),
                      height: 10.0 * (index + 1),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      );

      order.clear();
      for (int i = 0; i < nodeCount; ++i) {
        nodes.first.nextFocus();
        await tester.pump();
        order.add(nodes.indexOf(primaryFocus!));
      }
      expect(order, orderedEquals(<int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 0]));
    });
  });

  group(OrderedTraversalPolicy, () {
    testWidgets('Find the initial focus if there is none yet.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      await tester.pumpWidget(FocusTraversalGroup(
        policy: OrderedTraversalPolicy(secondary: ReadingOrderTraversalPolicy()),
        child: FocusScope(
          child: Column(
            children: <Widget>[
              FocusTraversalOrder(
                order: const NumericFocusOrder(2),
                child: Focus(
                  child: SizedBox(key: key1, width: 100, height: 100),
                ),
              ),
              FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: Focus(
                  child: SizedBox(key: key2, width: 100, height: 100),
                ),
              ),
            ],
          ),
        ),
      ));

      final Element firstChild = tester.element(find.byKey(key1));
      final Element secondChild = tester.element(find.byKey(key2));
      final FocusNode firstFocusNode = Focus.of(firstChild);
      final FocusNode secondFocusNode = Focus.of(secondChild);
      final FocusNode scope = Focus.of(firstChild).enclosingScope!;
      secondFocusNode.nextFocus();

      await tester.pump();

      expect(firstFocusNode.hasFocus, isFalse);
      expect(secondFocusNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);
    });

    testWidgets('Fall back to the secondary sort if no FocusTraversalOrder exists.', (WidgetTester tester) async {
      const int nodeCount = 10;
      final List<FocusNode> nodes = List<FocusNode>.generate(nodeCount, (int index) => FocusNode(debugLabel: 'Node $index'));
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(secondary: WidgetOrderTraversalPolicy()),
            child: FocusScope(
              child: Row(
                children: List<Widget>.generate(
                  nodeCount,
                  (int index) => Focus(
                    focusNode: nodes[index],
                    child: const SizedBox(width: 10, height: 10),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Because it should be using widget order, this shouldn't be affected by
      // the directionality.
      for (int i = 0; i < nodeCount; ++i) {
        nodes.first.nextFocus();
        await tester.pump();
        expect(nodes[i].hasPrimaryFocus, isTrue, reason: "node $i doesn't have focus, but should");
      }

      // Now check backwards.
      for (int i = nodeCount - 1; i > 0; --i) {
        nodes.first.previousFocus();
        await tester.pump();
        expect(nodes[i - 1].hasPrimaryFocus, isTrue, reason: "node ${i - 1} doesn't have focus, but should");
      }
    });

    testWidgets('Move focus to next/previous node using numerical order.', (WidgetTester tester) async {
      const int nodeCount = 10;
      final List<FocusNode> nodes = List<FocusNode>.generate(nodeCount, (int index) => FocusNode(debugLabel: 'Node $index'));
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(secondary: WidgetOrderTraversalPolicy()),
            child: FocusScope(
              child: Row(
                children: List<Widget>.generate(
                  nodeCount,
                  (int index) => FocusTraversalOrder(
                    order: NumericFocusOrder(nodeCount - index.toDouble()),
                    child: Focus(
                      focusNode: nodes[index],
                      child: const SizedBox(width: 10, height: 10),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // The orders are assigned to be backwards from normal, so should go backwards.
      for (int i = nodeCount - 1; i >= 0; --i) {
        nodes.first.nextFocus();
        await tester.pump();
        expect(nodes[i].hasPrimaryFocus, isTrue, reason: "node $i doesn't have focus, but should");
      }

      // Now check backwards.
      for (int i = 1; i < nodeCount; ++i) {
        nodes.first.previousFocus();
        await tester.pump();
        expect(nodes[i].hasPrimaryFocus, isTrue, reason: "node $i doesn't have focus, but should");
      }
    });

    testWidgets('Move focus to next/previous node using lexical order.', (WidgetTester tester) async {
      const int nodeCount = 10;

      /// Generate ['J' ... 'A'];
      final List<String> keys = List<String>.generate(nodeCount, (int index) => String.fromCharCode('A'.codeUnits[0] + nodeCount - index - 1));
      final List<FocusNode> nodes = List<FocusNode>.generate(nodeCount, (int index) => FocusNode(debugLabel: 'Node ${keys[index]}'));
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(secondary: WidgetOrderTraversalPolicy()),
            child: FocusScope(
              child: Row(
                children: List<Widget>.generate(
                  nodeCount,
                  (int index) => FocusTraversalOrder(
                    order: LexicalFocusOrder(keys[index]),
                    child: Focus(
                      focusNode: nodes[index],
                      child: const SizedBox(width: 10, height: 10),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // The orders are assigned to be backwards from normal, so should go backwards.
      for (int i = nodeCount - 1; i >= 0; --i) {
        nodes.first.nextFocus();
        await tester.pump();
        expect(nodes[i].hasPrimaryFocus, isTrue, reason: "node $i doesn't have focus, but should");
      }

      // Now check backwards.
      for (int i = 1; i < nodeCount; ++i) {
        nodes.first.previousFocus();
        await tester.pump();
        expect(nodes[i].hasPrimaryFocus, isTrue, reason: "node $i doesn't have focus, but should");
      }
    });

    testWidgets('Focus order is correct in the presence of FocusTraversalPolicyGroups.', (WidgetTester tester) async {
      const int nodeCount = 10;
      final FocusScopeNode scopeNode = FocusScopeNode();
      final List<FocusNode> nodes = List<FocusNode>.generate(nodeCount, (int index) => FocusNode(debugLabel: 'Node $index'));
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: FocusScope(
              node: scopeNode,
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(secondary: WidgetOrderTraversalPolicy()),
                child: Row(
                  children: <Widget>[
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(0),
                      child: FocusTraversalGroup(
                        policy: WidgetOrderTraversalPolicy(),
                        child: Row(children: <Widget>[
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(9),
                            child: Focus(
                              focusNode: nodes[9],
                              child: const SizedBox(width: 10, height: 10),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(8),
                            child: Focus(
                              focusNode: nodes[8],
                              child: const SizedBox(width: 10, height: 10),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(7),
                            child: Focus(
                              focusNode: nodes[7],
                              child: const SizedBox(width: 10, height: 10),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(1),
                      child: FocusTraversalGroup(
                        policy: OrderedTraversalPolicy(secondary: WidgetOrderTraversalPolicy()),
                        child: Row(children: <Widget>[
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(4),
                            child: Focus(
                              focusNode: nodes[4],
                              child: const SizedBox(width: 10, height: 10),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(5),
                            child: Focus(
                              focusNode: nodes[5],
                              child: const SizedBox(width: 10, height: 10),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(6),
                            child: Focus(
                              focusNode: nodes[6],
                              child: const SizedBox(width: 10, height: 10),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(2),
                      child: FocusTraversalGroup(
                        policy: OrderedTraversalPolicy(secondary: WidgetOrderTraversalPolicy()),
                        child: Row(children: <Widget>[
                          FocusTraversalOrder(
                            order: const LexicalFocusOrder('D'),
                            child: Focus(
                              focusNode: nodes[3],
                              child: const SizedBox(width: 10, height: 10),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const LexicalFocusOrder('C'),
                            child: Focus(
                              focusNode: nodes[2],
                              child: const SizedBox(width: 10, height: 10),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const LexicalFocusOrder('B'),
                            child: Focus(
                              focusNode: nodes[1],
                              child: const SizedBox(width: 10, height: 10),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const LexicalFocusOrder('A'),
                            child: Focus(
                              focusNode: nodes[0],
                              child: const SizedBox(width: 10, height: 10),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final List<int> expectedOrder = <int>[9, 8, 7, 4, 5, 6, 0, 1, 2, 3];
      final List<int> order = <int>[];
      for (int i = 0; i < nodeCount; ++i) {
        nodes.first.nextFocus();
        await tester.pump();
        order.add(nodes.indexOf(primaryFocus!));
      }
      expect(order, orderedEquals(expectedOrder));
    });

    testWidgets('Find the initial focus when a route is pushed or popped.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final FocusNode testNode1 = FocusNode(debugLabel: 'First Focus Node');
      final FocusNode testNode2 = FocusNode(debugLabel: 'Second Focus Node');
      await tester.pumpWidget(
        MaterialApp(
          home: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(secondary: WidgetOrderTraversalPolicy()),
            child: Center(
              child: Builder(builder: (BuildContext context) {
                return FocusTraversalOrder(
                  order: const NumericFocusOrder(0),
                  child: MaterialButton(
                    key: key1,
                    focusNode: testNode1,
                    autofocus: true,
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) {
                            return Center(
                              child: FocusTraversalOrder(
                                order: const NumericFocusOrder(0),
                                child: MaterialButton(
                                  key: key2,
                                  focusNode: testNode2,
                                  autofocus: true,
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Go Back'),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    child: const Text('Go Forward'),
                  ),
                );
              }),
            ),
          ),
        ),
      );

      final Element firstChild = tester.element(find.text('Go Forward'));
      final FocusNode firstFocusNode = Focus.of(firstChild);
      final FocusNode scope = Focus.of(firstChild).enclosingScope!;
      await tester.pump();

      expect(firstFocusNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);

      await tester.tap(find.text('Go Forward'));
      await tester.pumpAndSettle();

      final Element secondChild = tester.element(find.text('Go Back'));
      final FocusNode secondFocusNode = Focus.of(secondChild);

      expect(firstFocusNode.hasFocus, isFalse);
      expect(secondFocusNode.hasFocus, isTrue);

      await tester.tap(find.text('Go Back'));
      await tester.pumpAndSettle();

      expect(firstFocusNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);
    });
  });

  group(DirectionalFocusTraversalPolicyMixin, () {
    testWidgets('Move focus in all directions.', (WidgetTester tester) async {
      final GlobalKey upperLeftKey = GlobalKey(debugLabel: 'upperLeftKey');
      final GlobalKey upperRightKey = GlobalKey(debugLabel: 'upperRightKey');
      final GlobalKey lowerLeftKey = GlobalKey(debugLabel: 'lowerLeftKey');
      final GlobalKey lowerRightKey = GlobalKey(debugLabel: 'lowerRightKey');
      bool? focusUpperLeft;
      bool? focusUpperRight;
      bool? focusLowerLeft;
      bool? focusLowerRight;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: FocusScope(
              debugLabel: 'Scope',
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Focus(
                        debugLabel: 'upperLeft',
                        onFocusChange: (bool focus) => focusUpperLeft = focus,
                        child: SizedBox(width: 100, height: 100, key: upperLeftKey),
                      ),
                      Focus(
                        debugLabel: 'upperRight',
                        onFocusChange: (bool focus) => focusUpperRight = focus,
                        child: SizedBox(width: 100, height: 100, key: upperRightKey),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Focus(
                        debugLabel: 'lowerLeft',
                        onFocusChange: (bool focus) => focusLowerLeft = focus,
                        child: SizedBox(width: 100, height: 100, key: lowerLeftKey),
                      ),
                      Focus(
                        debugLabel: 'lowerRight',
                        onFocusChange: (bool focus) => focusLowerRight = focus,
                        child: SizedBox(width: 100, height: 100, key: lowerRightKey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      void clear() {
        focusUpperLeft = null;
        focusUpperRight = null;
        focusLowerLeft = null;
        focusLowerRight = null;
      }

      final FocusNode upperLeftNode = Focus.of(tester.element(find.byKey(upperLeftKey)));
      final FocusNode upperRightNode = Focus.of(tester.element(find.byKey(upperRightKey)));
      final FocusNode lowerLeftNode = Focus.of(tester.element(find.byKey(lowerLeftKey)));
      final FocusNode lowerRightNode = Focus.of(tester.element(find.byKey(lowerRightKey)));
      final FocusNode scope = upperLeftNode.enclosingScope!;
      upperLeftNode.requestFocus();

      await tester.pump();

      expect(focusUpperLeft, isTrue);
      expect(focusUpperRight, isNull);
      expect(focusLowerLeft, isNull);
      expect(focusLowerRight, isNull);
      expect(upperLeftNode.hasFocus, isTrue);
      expect(upperRightNode.hasFocus, isFalse);
      expect(lowerLeftNode.hasFocus, isFalse);
      expect(lowerRightNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
      clear();

      expect(scope.focusInDirection(TraversalDirection.right), isTrue);

      await tester.pump();

      expect(focusUpperLeft, isFalse);
      expect(focusUpperRight, isTrue);
      expect(focusLowerLeft, isNull);
      expect(focusLowerRight, isNull);
      expect(upperLeftNode.hasFocus, isFalse);
      expect(upperRightNode.hasFocus, isTrue);
      expect(lowerLeftNode.hasFocus, isFalse);
      expect(lowerRightNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
      clear();

      expect(scope.focusInDirection(TraversalDirection.down), isTrue);

      await tester.pump();

      expect(focusUpperLeft, isNull);
      expect(focusUpperRight, isFalse);
      expect(focusLowerLeft, isNull);
      expect(focusLowerRight, isTrue);
      expect(upperLeftNode.hasFocus, isFalse);
      expect(upperRightNode.hasFocus, isFalse);
      expect(lowerLeftNode.hasFocus, isFalse);
      expect(lowerRightNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);
      clear();

      expect(scope.focusInDirection(TraversalDirection.left), isTrue);

      await tester.pump();

      expect(focusUpperLeft, isNull);
      expect(focusUpperRight, isNull);
      expect(focusLowerLeft, isTrue);
      expect(focusLowerRight, isFalse);
      expect(upperLeftNode.hasFocus, isFalse);
      expect(upperRightNode.hasFocus, isFalse);
      expect(lowerLeftNode.hasFocus, isTrue);
      expect(lowerRightNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
      clear();

      expect(scope.focusInDirection(TraversalDirection.up), isTrue);

      await tester.pump();

      expect(focusUpperLeft, isTrue);
      expect(focusUpperRight, isNull);
      expect(focusLowerLeft, isFalse);
      expect(focusLowerRight, isNull);
      expect(upperLeftNode.hasFocus, isTrue);
      expect(upperRightNode.hasFocus, isFalse);
      expect(lowerLeftNode.hasFocus, isFalse);
      expect(lowerRightNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
    });

    testWidgets('Directional focus avoids hysteresis.', (WidgetTester tester) async {
      final List<GlobalKey> keys = <GlobalKey>[
        GlobalKey(debugLabel: 'row 1:1'),
        GlobalKey(debugLabel: 'row 2:1'),
        GlobalKey(debugLabel: 'row 2:2'),
        GlobalKey(debugLabel: 'row 3:1'),
        GlobalKey(debugLabel: 'row 3:2'),
        GlobalKey(debugLabel: 'row 3:3'),
      ];
      List<bool?> focus = List<bool?>.generate(keys.length, (int _) => null);
      Focus makeFocus(int index) {
        return Focus(
          debugLabel: keys[index].toString(),
          onFocusChange: (bool isFocused) => focus[index] = isFocused,
          child: SizedBox(width: 100, height: 100, key: keys[index]),
        );
      }

      /// Layout is:
      ///           keys[0]
      ///       keys[1] keys[2]
      ///    keys[3] keys[4] keys[5]
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: FocusScope(
              debugLabel: 'Scope',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      makeFocus(0),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      makeFocus(1),
                      makeFocus(2),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      makeFocus(3),
                      makeFocus(4),
                      makeFocus(5),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      void clear() {
        focus = List<bool?>.generate(keys.length, (int _) => null);
      }

      final List<FocusNode> nodes = keys.map<FocusNode>((GlobalKey key) => Focus.of(tester.element(find.byKey(key)))).toList();
      final FocusNode scope = nodes[0].enclosingScope!;
      nodes[4].requestFocus();

      void expectState(List<bool?> states) {
        for (int index = 0; index < states.length; ++index) {
          expect(focus[index], states[index] == null ? isNull : (states[index]! ? isTrue : isFalse));
          if (states[index] == null) {
            expect(nodes[index].hasFocus, isFalse);
          } else {
            expect(nodes[index].hasFocus, states[index]);
          }
          expect(scope.hasFocus, isTrue);
        }
      }

      // Test to make sure that the same path is followed backwards and forwards.
      await tester.pump();
      expectState(<bool?>[null, null, null, null, true, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.up), isTrue);
      await tester.pump();

      expectState(<bool?>[null, null, true, null, false, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.up), isTrue);
      await tester.pump();

      expectState(<bool?>[true, null, false, null, null, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.down), isTrue);
      await tester.pump();

      expectState(<bool?>[false, null, true, null, null, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.down), isTrue);
      await tester.pump();
      expectState(<bool?>[null, null, false, null, true, null]);
      clear();

      // Make sure that moving in a different axis clears the history.
      expect(scope.focusInDirection(TraversalDirection.left), isTrue);
      await tester.pump();
      expectState(<bool?>[null, null, null, true, false, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.up), isTrue);
      await tester.pump();

      expectState(<bool?>[null, true, null, false, null, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.up), isTrue);
      await tester.pump();

      expectState(<bool?>[true, false, null, null, null, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.down), isTrue);
      await tester.pump();

      expectState(<bool?>[false, true, null, null, null, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.down), isTrue);
      await tester.pump();
      expectState(<bool?>[null, false, null, true, null, null]);
      clear();
    });

    testWidgets('Can find first focus in all directions.', (WidgetTester tester) async {
      final GlobalKey upperLeftKey = GlobalKey(debugLabel: 'upperLeftKey');
      final GlobalKey upperRightKey = GlobalKey(debugLabel: 'upperRightKey');
      final GlobalKey lowerLeftKey = GlobalKey(debugLabel: 'lowerLeftKey');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: FocusScope(
              debugLabel: 'scope',
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Focus(
                        debugLabel: 'upperLeft',
                        child: SizedBox(width: 100, height: 100, key: upperLeftKey),
                      ),
                      Focus(
                        debugLabel: 'upperRight',
                        child: SizedBox(width: 100, height: 100, key: upperRightKey),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Focus(
                        debugLabel: 'lowerLeft',
                        child: SizedBox(width: 100, height: 100, key: lowerLeftKey),
                      ),
                      const Focus(
                        debugLabel: 'lowerRight',
                        child: SizedBox(width: 100, height: 100),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final FocusNode upperLeftNode = Focus.of(tester.element(find.byKey(upperLeftKey)));
      final FocusNode upperRightNode = Focus.of(tester.element(find.byKey(upperRightKey)));
      final FocusNode lowerLeftNode = Focus.of(tester.element(find.byKey(lowerLeftKey)));
      final FocusNode scope = upperLeftNode.enclosingScope!;

      await tester.pump();

      final FocusTraversalPolicy policy = FocusTraversalGroup.of(upperLeftKey.currentContext!);

      expect(policy.findFirstFocusInDirection(scope, TraversalDirection.up), equals(lowerLeftNode));
      expect(policy.findFirstFocusInDirection(scope, TraversalDirection.down), equals(upperLeftNode));
      expect(policy.findFirstFocusInDirection(scope, TraversalDirection.left), equals(upperRightNode));
      expect(policy.findFirstFocusInDirection(scope, TraversalDirection.right), equals(upperLeftNode));
    });

    testWidgets('Can find focus when policy data dirty', (WidgetTester tester) async {
      final FocusNode focusTop = FocusNode(debugLabel: 'top');
      final FocusNode focusCenter = FocusNode(debugLabel: 'center');
      final FocusNode focusBottom = FocusNode(debugLabel: 'bottom');

      final FocusTraversalPolicy policy = ReadingOrderTraversalPolicy();
      await tester.pumpWidget(FocusTraversalGroup(
        policy: policy,
        child: FocusScope(
          debugLabel: 'Scope',
          child: Column(
            children: <Widget>[
              Focus(focusNode: focusTop, child: const SizedBox(width: 100, height: 100)),
              Focus(focusNode: focusCenter, child: const SizedBox(width: 100, height: 100)),
              Focus(focusNode: focusBottom, child: const SizedBox(width: 100, height: 100)),
            ],
          ),
        ),
      ));

      focusTop.requestFocus();
      final FocusNode scope = focusTop.enclosingScope!;

      scope.focusInDirection(TraversalDirection.down);
      scope.focusInDirection(TraversalDirection.down);

      await tester.pump();
      expect(focusBottom.hasFocus, isTrue);

      // Remove center focus node.
      await tester.pumpWidget(FocusTraversalGroup(
        policy: policy,
        child: FocusScope(
          debugLabel: 'Scope',
          child: Column(
            children: <Widget>[
              Focus(focusNode: focusTop, child: const SizedBox(width: 100, height: 100)),
              Focus(focusNode: focusBottom, child: const SizedBox(width: 100, height: 100)),
            ],
          ),
        ),
      ));

      expect(focusBottom.hasFocus, isTrue);
      scope.focusInDirection(TraversalDirection.up);
      await tester.pump();

      expect(focusCenter.hasFocus, isFalse);
      expect(focusTop.hasFocus, isTrue);
    });

    testWidgets('Focus traversal actions are invoked when shortcuts are used.', (WidgetTester tester) async {
      final GlobalKey upperLeftKey = GlobalKey(debugLabel: 'upperLeftKey');
      final GlobalKey upperRightKey = GlobalKey(debugLabel: 'upperRightKey');
      final GlobalKey lowerLeftKey = GlobalKey(debugLabel: 'lowerLeftKey');
      final GlobalKey lowerRightKey = GlobalKey(debugLabel: 'lowerRightKey');

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFFFFFFFF),
          onGenerateRoute: (RouteSettings settings) {
            return TestRoute(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: FocusScope(
                  debugLabel: 'scope',
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Focus(
                            autofocus: true,
                            debugLabel: 'upperLeft',
                            child: SizedBox(width: 100, height: 100, key: upperLeftKey),
                          ),
                          Focus(
                            debugLabel: 'upperRight',
                            child: SizedBox(width: 100, height: 100, key: upperRightKey),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Focus(
                            debugLabel: 'lowerLeft',
                            child: SizedBox(width: 100, height: 100, key: lowerLeftKey),
                          ),
                          Focus(
                            debugLabel: 'lowerRight',
                            child: SizedBox(width: 100, height: 100, key: lowerRightKey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(Focus.of(upperLeftKey.currentContext!).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(Focus.of(upperRightKey.currentContext!).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(Focus.of(lowerLeftKey.currentContext!).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(Focus.of(lowerRightKey.currentContext!).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(Focus.of(upperLeftKey.currentContext!).hasPrimaryFocus, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      expect(Focus.of(lowerRightKey.currentContext!).hasPrimaryFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      expect(Focus.of(lowerLeftKey.currentContext!).hasPrimaryFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      expect(Focus.of(upperRightKey.currentContext!).hasPrimaryFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      expect(Focus.of(upperLeftKey.currentContext!).hasPrimaryFocus, isTrue);

      // Traverse in a direction
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(Focus.of(upperRightKey.currentContext!).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(Focus.of(lowerRightKey.currentContext!).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(Focus.of(lowerLeftKey.currentContext!).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(Focus.of(upperLeftKey.currentContext!).hasPrimaryFocus, isTrue);
    }, skip: isBrowser, variant: KeySimulatorTransitModeVariant.all()); // https://github.com/flutter/flutter/issues/35347

    testWidgets('Focus traversal inside a vertical scrollable scrolls to stay visible.', (WidgetTester tester) async {
      final List<int> items = List<int>.generate(11, (int index) => index).toList();
      final List<FocusNode> nodes = List<FocusNode>.generate(11, (int index) => FocusNode(debugLabel: 'Item ${index + 1}')).toList();
      final FocusNode topNode = FocusNode(debugLabel: 'Header');
      final FocusNode bottomNode = FocusNode(debugLabel: 'Footer');
      final ScrollController controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              Focus(focusNode: topNode, child: Container(height: 100)),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.vertical,
                  controller: controller,
                  children: items.map<Widget>((int item) {
                    return Focus(
                      focusNode: nodes[item],
                      child: Container(height: 100),
                    );
                  }).toList(),
                ),
              ),
              Focus(focusNode: bottomNode, child: Container(height: 100)),
            ],
          ),
        ),
      );

      // Start at the top
      expect(controller.offset, equals(0.0));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(topNode.hasPrimaryFocus, isTrue);
      expect(controller.offset, equals(0.0));

      // Enter the list.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nodes[0].hasPrimaryFocus, isTrue);
      expect(controller.offset, equals(0.0));

      // Go down until we hit the bottom of the visible area.
      for (int i = 1; i <= 4; ++i) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(controller.offset, equals(0.0), reason: 'Focusing item $i caused a scroll');
      }

      // Now keep going down, and the scrollable should scroll automatically.
      for (int i = 5; i <= 10; ++i) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        final double expectedOffset = 100.0 * (i - 5) + 200.0;
        expect(controller.offset, equals(expectedOffset), reason: "Focusing item $i didn't cause a scroll to $expectedOffset");
      }

      // Now go one more, and see that the footer gets focused.

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(bottomNode.hasPrimaryFocus, isTrue);
      expect(controller.offset, equals(100.0 * (10 - 5) + 200.0));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(nodes[10].hasPrimaryFocus, isTrue);
      expect(controller.offset, equals(100.0 * (10 - 5) + 200.0));

      // Now reverse directions and go back to the top.

      // These should not cause a scroll.
      final double lowestOffset = controller.offset;
      for (int i = 10; i >= 8; --i) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        expect(controller.offset, equals(lowestOffset), reason: 'Focusing item $i caused a scroll');
      }

      // These should all cause a scroll.
      for (int i = 7; i >= 1; --i) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        final double expectedOffset = 100.0 * (i - 1);
        expect(controller.offset, equals(expectedOffset), reason: "Focusing item $i didn't cause a scroll");
      }

      // Back at the top.
      expect(nodes[0].hasPrimaryFocus, isTrue);
      expect(controller.offset, equals(0.0));

      // Now we jump to the header.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(topNode.hasPrimaryFocus, isTrue);
      expect(controller.offset, equals(0.0));
    }, skip: isBrowser, variant: KeySimulatorTransitModeVariant.all()); // https://github.com/flutter/flutter/issues/35347

    testWidgets('Focus traversal inside a horizontal scrollable scrolls to stay visible.', (WidgetTester tester) async {
      final List<int> items = List<int>.generate(11, (int index) => index).toList();
      final List<FocusNode> nodes = List<FocusNode>.generate(11, (int index) => FocusNode(debugLabel: 'Item ${index + 1}')).toList();
      final FocusNode leftNode = FocusNode(debugLabel: 'Left Side');
      final FocusNode rightNode = FocusNode(debugLabel: 'Right Side');
      final ScrollController controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: <Widget>[
              Focus(focusNode: leftNode, child: Container(width: 100)),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  controller: controller,
                  children: items.map<Widget>((int item) {
                    return Focus(
                      focusNode: nodes[item],
                      child: Container(width: 100),
                    );
                  }).toList(),
                ),
              ),
              Focus(focusNode: rightNode, child: Container(width: 100)),
            ],
          ),
        ),
      );

      // Start at the right
      expect(controller.offset, equals(0.0));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(leftNode.hasPrimaryFocus, isTrue);
      expect(controller.offset, equals(0.0));

      // Enter the list.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[0].hasPrimaryFocus, isTrue);
      expect(controller.offset, equals(0.0));

      // Go right until we hit the right of the visible area.
      for (int i = 1; i <= 6; ++i) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(controller.offset, equals(0.0), reason: 'Focusing item $i caused a scroll');
      }

      // Now keep going right, and the scrollable should scroll automatically.
      for (int i = 7; i <= 10; ++i) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        final double expectedOffset = 100.0 * (i - 5);
        expect(controller.offset, equals(expectedOffset), reason: "Focusing item $i didn't cause a scroll to $expectedOffset");
      }

      // Now go one more, and see that the right edge gets focused.

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(rightNode.hasPrimaryFocus, isTrue);
      expect(controller.offset, equals(100.0 * 5));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(nodes[10].hasPrimaryFocus, isTrue);
      expect(controller.offset, equals(100.0 * 5));

      // Now reverse directions and go back to the left.

      // These should not cause a scroll.
      final double lowestOffset = controller.offset;
      for (int i = 10; i >= 7; --i) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        expect(controller.offset, equals(lowestOffset), reason: 'Focusing item $i caused a scroll');
      }

      // These should all cause a scroll.
      for (int i = 6; i >= 1; --i) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        final double expectedOffset = 100.0 * (i - 1);
        expect(controller.offset, equals(expectedOffset), reason: "Focusing item $i didn't cause a scroll");
      }

      // Back at the left side of the scrollable.
      expect(nodes[0].hasPrimaryFocus, isTrue);
      expect(controller.offset, equals(0.0));

      // Now we jump to the left edge of the app.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(leftNode.hasPrimaryFocus, isTrue);
      expect(controller.offset, equals(0.0));
    }, skip: isBrowser, variant: KeySimulatorTransitModeVariant.all()); // https://github.com/flutter/flutter/issues/35347

    testWidgets('Arrow focus traversal actions can be re-enabled for text fields.', (WidgetTester tester) async {
      final GlobalKey upperLeftKey = GlobalKey(debugLabel: 'upperLeftKey');
      final GlobalKey upperRightKey = GlobalKey(debugLabel: 'upperRightKey');
      final GlobalKey lowerLeftKey = GlobalKey(debugLabel: 'lowerLeftKey');
      final GlobalKey lowerRightKey = GlobalKey(debugLabel: 'lowerRightKey');

      final TextEditingController controller1 = TextEditingController();
      final TextEditingController controller2 = TextEditingController();
      final TextEditingController controller3 = TextEditingController();
      final TextEditingController controller4 = TextEditingController();

      final FocusNode focusNodeUpperLeft = FocusNode(debugLabel: 'upperLeft');
      final FocusNode focusNodeUpperRight = FocusNode(debugLabel: 'upperRight');
      final FocusNode focusNodeLowerLeft = FocusNode(debugLabel: 'lowerLeft');
      final FocusNode focusNodeLowerRight = FocusNode(debugLabel: 'lowerRight');

      Widget generateTestWidgets(bool ignoreTextFields) {
        final Map<ShortcutActivator, Intent> shortcuts = <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(TraversalDirection.left, ignoreTextFields: ignoreTextFields),
          const SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(TraversalDirection.right, ignoreTextFields: ignoreTextFields),
          const SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down, ignoreTextFields: ignoreTextFields),
          const SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up, ignoreTextFields: ignoreTextFields),
        };

        return MaterialApp(
          home: Shortcuts(
            shortcuts: shortcuts,
            child: FocusScope(
              debugLabel: 'scope',
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: EditableText(
                          autofocus: true,
                          key: upperLeftKey,
                          controller: controller1,
                          focusNode: focusNodeUpperLeft,
                          cursorColor: const Color(0xffffffff),
                          backgroundCursorColor: const Color(0xff808080),
                          style: const TextStyle(),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: EditableText(
                          key: upperRightKey,
                          controller: controller2,
                          focusNode: focusNodeUpperRight,
                          cursorColor: const Color(0xffffffff),
                          backgroundCursorColor: const Color(0xff808080),
                          style: const TextStyle(),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: EditableText(
                          key: lowerLeftKey,
                          controller: controller3,
                          focusNode: focusNodeLowerLeft,
                          cursorColor: const Color(0xffffffff),
                          backgroundCursorColor: const Color(0xff808080),
                          style: const TextStyle(),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: EditableText(
                          key: lowerRightKey,
                          controller: controller4,
                          focusNode: focusNodeLowerRight,
                          cursorColor: const Color(0xffffffff),
                          backgroundCursorColor: const Color(0xff808080),
                          style: const TextStyle(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(generateTestWidgets(false));

      expect(focusNodeUpperLeft.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(focusNodeUpperRight.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusNodeLowerRight.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(focusNodeLowerLeft.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(focusNodeUpperLeft.hasPrimaryFocus, isTrue);

      await tester.pumpWidget(generateTestWidgets(true));

      expect(focusNodeUpperLeft.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(focusNodeUpperRight.hasPrimaryFocus, isFalse);
      expect(focusNodeUpperLeft.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusNodeLowerRight.hasPrimaryFocus, isFalse);
      expect(focusNodeUpperLeft.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(focusNodeLowerLeft.hasPrimaryFocus, isFalse);
      expect(focusNodeUpperLeft.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(focusNodeUpperLeft.hasPrimaryFocus, isTrue);
    }, variant: KeySimulatorTransitModeVariant.all());

    testWidgets('Focus traversal does not break when no focusable is available on a MaterialApp', (WidgetTester tester) async {
      final List<Object> events = <Object>[];

      await tester.pumpWidget(MaterialApp(home: Container()));

      RawKeyboard.instance.addListener((RawKeyEvent event) {
        events.add(event);
      });

      await tester.idle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.idle();

      expect(events.length, 2);
    }, variant: KeySimulatorTransitModeVariant.all());

    testWidgets('Focus traversal does not throw when no focusable is available in a group', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ListTile(title: Text('title')))));
      final FocusNode? initialFocus = primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(primaryFocus, equals(initialFocus));
    });

    testWidgets('Focus traversal does not break when no focusable is available on a WidgetsApp', (WidgetTester tester) async {
      final List<RawKeyEvent> events = <RawKeyEvent>[];

      await tester.pumpWidget(
        WidgetsApp(
          color: Colors.white,
          onGenerateRoute: (RouteSettings settings) => PageRouteBuilder<void>(
            settings: settings,
            pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
              return const Placeholder();
            },
          ),
        ),
      );

      RawKeyboard.instance.addListener((RawKeyEvent event) {
        events.add(event);
      });

      await tester.idle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.idle();

      expect(events.length, 2);
    }, variant: KeySimulatorTransitModeVariant.all());
  });
  group(FocusTraversalGroup, () {
    testWidgets("Focus traversal group doesn't introduce a Semantics node", (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      await tester.pumpWidget(FocusTraversalGroup(child: Container()));
      final TestSemantics expectedSemantics = TestSemantics.root();
      expect(semantics, hasSemantics(expectedSemantics));
    });
    testWidgets("Descendants of FocusTraversalGroup aren't focusable if descendantsAreFocusable is false.", (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final FocusNode focusNode = FocusNode();
      bool? gotFocus;
      await tester.pumpWidget(
        FocusTraversalGroup(
          descendantsAreFocusable: false,
          child: Focus(
            onFocusChange: (bool focused) => gotFocus = focused,
            child: Focus(
              key: key1,
              focusNode: focusNode,
              child: Container(key: key2),
            ),
          ),
        ),
      );

      final Element childWidget = tester.element(find.byKey(key1));
      final FocusNode unfocusableNode = Focus.of(childWidget);
      final Element containerWidget = tester.element(find.byKey(key2));
      final FocusNode containerNode = Focus.of(containerWidget);

      unfocusableNode.requestFocus();
      await tester.pump();

      expect(gotFocus, isNull);
      expect(containerNode.hasFocus, isFalse);
      expect(unfocusableNode.hasFocus, isFalse);

      containerNode.requestFocus();
      await tester.pump();

      expect(gotFocus, isNull);
      expect(containerNode.hasFocus, isFalse);
      expect(unfocusableNode.hasFocus, isFalse);
    });
    testWidgets("Nested FocusTraversalGroup with unfocusable children doesn't assert.", (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final FocusNode focusNode = FocusNode();
      bool? gotFocus;
      await tester.pumpWidget(
        FocusTraversalGroup(
          child: Column(
            children: <Widget>[
              Focus(
                autofocus: true,
                child: Container(),
              ),
              FocusTraversalGroup(
                descendantsAreFocusable: false,
                child: Focus(
                  onFocusChange: (bool focused) => gotFocus = focused,
                  child: Focus(
                    key: key1,
                    focusNode: focusNode,
                    child: Container(key: key2),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      final Element childWidget = tester.element(find.byKey(key1));
      final FocusNode unfocusableNode = Focus.of(childWidget);
      final Element containerWidget = tester.element(find.byKey(key2));
      final FocusNode containerNode = Focus.of(containerWidget);

      await tester.pump();
      primaryFocus!.nextFocus();

      expect(gotFocus, isNull);
      expect(containerNode.hasFocus, isFalse);
      expect(unfocusableNode.hasFocus, isFalse);

      containerNode.requestFocus();
      await tester.pump();

      expect(gotFocus, isNull);
      expect(containerNode.hasFocus, isFalse);
      expect(unfocusableNode.hasFocus, isFalse);
    });
    testWidgets("Empty FocusTraversalGroup doesn't cause an exception.", (WidgetTester tester) async {
      final GlobalKey key = GlobalKey(debugLabel: 'Test Key');
      final FocusNode focusNode = FocusNode(debugLabel: 'Test Node');
      await tester.pumpWidget(
        FocusTraversalGroup(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: <Widget>[
                FocusTraversalGroup(
                  child: Container(key: key),
                ),
                Focus(
                  focusNode: focusNode,
                  autofocus: true,
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      primaryFocus!.nextFocus();
      await tester.pump();
      expect(primaryFocus, equals(focusNode));
    });
  });
  group(RawKeyboardListener, () {
    testWidgets('Raw keyboard listener introduces a Semantics node by default', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      final FocusNode focusNode = FocusNode();
      await tester.pumpWidget(
        RawKeyboardListener(
          focusNode: focusNode,
          child: Container(),
        ),
      );
      final TestSemantics expectedSemantics = TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics.rootChild(
            flags: <SemanticsFlag>[
              SemanticsFlag.isFocusable,
            ],
          ),
        ],
      );
      expect(semantics, hasSemantics(
        expectedSemantics,
        ignoreId: true,
        ignoreRect: true,
        ignoreTransform: true,
      ));
    });
    testWidgets("Raw keyboard listener doesn't introduce a Semantics node when specified", (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      final FocusNode focusNode = FocusNode();
      await tester.pumpWidget(
          RawKeyboardListener(
              focusNode: focusNode,
              includeSemantics: false,
              child: Container(),
          ),
      );
      final TestSemantics expectedSemantics = TestSemantics.root();
      expect(semantics, hasSemantics(expectedSemantics));
    });
  });
}

class TestRoute extends PageRouteBuilder<void> {
  TestRoute({required Widget child})
      : super(
          pageBuilder: (BuildContext _, Animation<double> __, Animation<double> ___) {
            return child;
          },
        );
}
