// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

      // Test to make sure that we follow the same path backwards and forwards.
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
  });
}
