// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  group(WidgetOrderFocusTraversalPolicy, () {
    testWidgets('Find the initial focus if there is none yet.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final GlobalKey key3 = GlobalKey(debugLabel: '3');
      final GlobalKey key4 = GlobalKey(debugLabel: '4');
      final GlobalKey key5 = GlobalKey(debugLabel: '5');
      await tester.pumpWidget(DefaultFocusTraversal(
        policy: WidgetOrderFocusTraversalPolicy(),
        child: FocusScope(
          key: key1,
          child: Column(
            children: <Widget>[
              Focus(
                key: key2,
                child: Container(key: key3, width: 100, height: 100),
              ),
              Focus(
                key: key4,
                child: Container(key: key5, width: 100, height: 100),
              ),
            ],
          ),
        ),
      ));

      final Element firstChild = tester.element(find.byKey(key3));
      final Element secondChild = tester.element(find.byKey(key5));
      final FocusNode firstFocusNode = Focus.of(firstChild);
      final FocusNode secondFocusNode = Focus.of(secondChild);
      final FocusNode scope = Focus.of(firstChild).enclosingScope;
      secondFocusNode.nextFocus();

      await tester.pump();

      expect(firstFocusNode.hasFocus, isTrue);
      expect(secondFocusNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
    });

    testWidgets('Move focus to next node.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final GlobalKey key3 = GlobalKey(debugLabel: '3');
      final GlobalKey key4 = GlobalKey(debugLabel: '4');
      final GlobalKey key5 = GlobalKey(debugLabel: '5');
      final GlobalKey key6 = GlobalKey(debugLabel: '6');
      bool focus1;
      bool focus2;
      bool focus3;
      bool focus5;
      await tester.pumpWidget(
        DefaultFocusTraversal(
          policy: WidgetOrderFocusTraversalPolicy(),
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
      final FocusNode scope = Focus.of(firstChild).enclosingScope;
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
        DefaultFocusTraversal(
          policy: WidgetOrderFocusTraversalPolicy(),
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
      final FocusNode scope = Focus.of(firstChild).enclosingScope;
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

    testWidgets('Find the initial focus when a route is pushed or popped.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final FocusNode testNode1 = FocusNode(debugLabel: 'First Focus Node');
      final FocusNode testNode2 = FocusNode(debugLabel: 'Second Focus Node');
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultFocusTraversal(
            policy: WidgetOrderFocusTraversalPolicy(),
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
      final FocusNode scope = Focus.of(firstChild).enclosingScope;
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
      await tester.pumpWidget(DefaultFocusTraversal(
        policy: ReadingOrderTraversalPolicy(),
        child: FocusScope(
          key: key1,
          child: Column(
            children: <Widget>[
              Focus(
                key: key2,
                child: Container(key: key3, width: 100, height: 100),
              ),
              Focus(
                key: key4,
                child: Container(key: key5, width: 100, height: 100),
              ),
            ],
          ),
        ),
      ));

      final Element firstChild = tester.element(find.byKey(key3));
      final Element secondChild = tester.element(find.byKey(key5));
      final FocusNode firstFocusNode = Focus.of(firstChild);
      final FocusNode secondFocusNode = Focus.of(secondChild);
      final FocusNode scope = Focus.of(firstChild).enclosingScope;
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
      bool focus1;
      bool focus2;
      bool focus3;
      bool focus5;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultFocusTraversal(
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
      final FocusNode scope = Focus.of(firstChild).enclosingScope;
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
        DefaultFocusTraversal(
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
      final FocusNode scope = Focus.of(firstChild).enclosingScope;
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
  });

  group(DirectionalFocusTraversalPolicyMixin, () {
    testWidgets('Move focus in all directions.', (WidgetTester tester) async {
      final GlobalKey upperLeftKey = GlobalKey(debugLabel: 'upperLeftKey');
      final GlobalKey upperRightKey = GlobalKey(debugLabel: 'upperRightKey');
      final GlobalKey lowerLeftKey = GlobalKey(debugLabel: 'lowerLeftKey');
      final GlobalKey lowerRightKey = GlobalKey(debugLabel: 'lowerRightKey');
      bool focusUpperLeft;
      bool focusUpperRight;
      bool focusLowerLeft;
      bool focusLowerRight;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultFocusTraversal(
            policy: WidgetOrderFocusTraversalPolicy(),
            child: FocusScope(
              debugLabel: 'Scope',
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Focus(
                        debugLabel: 'upperLeft',
                        onFocusChange: (bool focus) => focusUpperLeft = focus,
                        child: Container(width: 100, height: 100, key: upperLeftKey),
                      ),
                      Focus(
                        debugLabel: 'upperRight',
                        onFocusChange: (bool focus) => focusUpperRight = focus,
                        child: Container(width: 100, height: 100, key: upperRightKey),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Focus(
                        debugLabel: 'lowerLeft',
                        onFocusChange: (bool focus) => focusLowerLeft = focus,
                        child: Container(width: 100, height: 100, key: lowerLeftKey),
                      ),
                      Focus(
                        debugLabel: 'lowerRight',
                        onFocusChange: (bool focus) => focusLowerRight = focus,
                        child: Container(width: 100, height: 100, key: lowerRightKey),
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
      final FocusNode scope = upperLeftNode.enclosingScope;
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

    testWidgets('Directional focus avoids hysterisis.', (WidgetTester tester) async {
      final List<GlobalKey> keys = <GlobalKey>[
        GlobalKey(debugLabel: 'row 1:1'),
        GlobalKey(debugLabel: 'row 2:1'),
        GlobalKey(debugLabel: 'row 2:2'),
        GlobalKey(debugLabel: 'row 3:1'),
        GlobalKey(debugLabel: 'row 3:2'),
        GlobalKey(debugLabel: 'row 3:3'),
      ];
      List<bool> focus = List<bool>.generate(keys.length, (int _) => null);
      Focus makeFocus(int index) {
        return Focus(
          debugLabel: keys[index].toString(),
          onFocusChange: (bool isFocused) => focus[index] = isFocused,
          child: Container(width: 100, height: 100, key: keys[index]),
        );
      }

      /// Layout is:
      ///           keys[0]
      ///       keys[1] keys[2]
      ///    keys[3] keys[4] keys[5]
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultFocusTraversal(
            policy: WidgetOrderFocusTraversalPolicy(),
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
        focus = List<bool>.generate(keys.length, (int _) => null);
      }

      final List<FocusNode> nodes = keys.map<FocusNode>((GlobalKey key) => Focus.of(tester.element(find.byKey(key)))).toList();
      final FocusNode scope = nodes[0].enclosingScope;
      nodes[4].requestFocus();

      void expectState(List<bool> states) {
        for (int index = 0; index < states.length; ++index) {
          expect(focus[index], states[index] == null ? isNull : (states[index] ? isTrue : isFalse));
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
      expectState(<bool>[null, null, null, null, true, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.up), isTrue);
      await tester.pump();

      expectState(<bool>[null, null, true, null, false, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.up), isTrue);
      await tester.pump();

      expectState(<bool>[true, null, false, null, null, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.down), isTrue);
      await tester.pump();

      expectState(<bool>[false, null, true, null, null, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.down), isTrue);
      await tester.pump();
      expectState(<bool>[null, null, false, null, true, null]);
      clear();

      // Make sure that moving in a different axis clears the history.
      expect(scope.focusInDirection(TraversalDirection.left), isTrue);
      await tester.pump();
      expectState(<bool>[null, null, null, true, false, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.up), isTrue);
      await tester.pump();

      expectState(<bool>[null, true, null, false, null, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.up), isTrue);
      await tester.pump();

      expectState(<bool>[true, false, null, null, null, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.down), isTrue);
      await tester.pump();

      expectState(<bool>[false, true, null, null, null, null]);
      clear();

      expect(scope.focusInDirection(TraversalDirection.down), isTrue);
      await tester.pump();
      expectState(<bool>[null, false, null, true, null, null]);
      clear();
    });

    testWidgets('Can find first focus in all directions.', (WidgetTester tester) async {
      final GlobalKey upperLeftKey = GlobalKey(debugLabel: 'upperLeftKey');
      final GlobalKey upperRightKey = GlobalKey(debugLabel: 'upperRightKey');
      final GlobalKey lowerLeftKey = GlobalKey(debugLabel: 'lowerLeftKey');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultFocusTraversal(
            policy: WidgetOrderFocusTraversalPolicy(),
            child: FocusScope(
              debugLabel: 'scope',
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Focus(
                        debugLabel: 'upperLeft',
                        child: Container(width: 100, height: 100, key: upperLeftKey),
                      ),
                      Focus(
                        debugLabel: 'upperRight',
                        child: Container(width: 100, height: 100, key: upperRightKey),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Focus(
                        debugLabel: 'lowerLeft',
                        child: Container(width: 100, height: 100, key: lowerLeftKey),
                      ),
                      Focus(
                        debugLabel: 'lowerRight',
                        child: Container(width: 100, height: 100),
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
      final FocusNode scope = upperLeftNode.enclosingScope;

      await tester.pump();

      final FocusTraversalPolicy policy = DefaultFocusTraversal.of(upperLeftKey.currentContext);

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
      await tester.pumpWidget(DefaultFocusTraversal(
        policy: policy,
        child: FocusScope(
          debugLabel: 'Scope',
          child: Column(
            children: <Widget>[
              Focus(focusNode: focusTop, child: Container(width: 100, height: 100)),
              Focus(focusNode: focusCenter, child: Container(width: 100, height: 100)),
              Focus(focusNode: focusBottom, child: Container(width: 100, height: 100)),
            ],
          ),
        ),
      ));

      focusTop.requestFocus();
      final FocusNode scope = focusTop.enclosingScope;

      scope.focusInDirection(TraversalDirection.down);
      scope.focusInDirection(TraversalDirection.down);

      await tester.pump();
      expect(focusBottom.hasFocus, isTrue);

      // Remove center focus node.
      await tester.pumpWidget(DefaultFocusTraversal(
        policy: policy,
        child: FocusScope(
          debugLabel: 'Scope',
          child: Column(
            children: <Widget>[
              Focus(focusNode: focusTop, child: Container(width: 100, height: 100)),
              Focus(focusNode: focusBottom, child: Container(width: 100, height: 100)),
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
                            child: Container(width: 100, height: 100, key: upperLeftKey),
                          ),
                          Focus(
                            debugLabel: 'upperRight',
                            child: Container(width: 100, height: 100, key: upperRightKey),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Focus(
                            debugLabel: 'lowerLeft',
                            child: Container(width: 100, height: 100, key: lowerLeftKey),
                          ),
                          Focus(
                            debugLabel: 'lowerRight',
                            child: Container(width: 100, height: 100, key: lowerRightKey),
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

      expect(Focus.of(upperLeftKey.currentContext).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(Focus.of(upperRightKey.currentContext).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(Focus.of(lowerLeftKey.currentContext).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(Focus.of(lowerRightKey.currentContext).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(Focus.of(upperLeftKey.currentContext).hasPrimaryFocus, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      expect(Focus.of(lowerRightKey.currentContext).hasPrimaryFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      expect(Focus.of(lowerLeftKey.currentContext).hasPrimaryFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      expect(Focus.of(upperRightKey.currentContext).hasPrimaryFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      expect(Focus.of(upperLeftKey.currentContext).hasPrimaryFocus, isTrue);

      // Traverse in a direction
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(Focus.of(upperRightKey.currentContext).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(Focus.of(lowerRightKey.currentContext).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(Focus.of(lowerLeftKey.currentContext).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(Focus.of(upperLeftKey.currentContext).hasPrimaryFocus, isTrue);
    }, skip: kIsWeb);

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
    }, skip: kIsWeb);

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
    }, skip: kIsWeb);

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
        final Map<LogicalKeySet, Intent> shortcuts = <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(TraversalDirection.left, ignoreTextFields: ignoreTextFields),
          LogicalKeySet(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(TraversalDirection.right, ignoreTextFields: ignoreTextFields),
          LogicalKeySet(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down, ignoreTextFields: ignoreTextFields),
          LogicalKeySet(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up, ignoreTextFields: ignoreTextFields),
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
                      Container(
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
                      Container(
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
                      Container(
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
                      Container(
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
    });

    testWidgets('Focus traversal does not break when no focusable is available on a MaterialApp', (WidgetTester tester) async {
      final List<RawKeyEvent> events = <RawKeyEvent>[];

      await tester.pumpWidget(MaterialApp(home: Container()));

      RawKeyboard.instance.addListener((RawKeyEvent event) {
        events.add(event);
      });

      await tester.idle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.idle();

      expect(events.length, 2);
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
    });
  });
}

class TestRoute extends PageRouteBuilder<void> {
  TestRoute({Widget child})
      : super(
          pageBuilder: (BuildContext _, Animation<double> __, Animation<double> ___) {
            return child;
          },
        );
}
