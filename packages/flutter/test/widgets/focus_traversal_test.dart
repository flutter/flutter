// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  group(WidgetOrderFocusTraversalPolicy, () {
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
          policy: const WidgetOrderFocusTraversalPolicy(),
          child: Focusable(
            debugLabel: 'key1',
            key: key1,
            onFocusChange: (bool focus) => focus1 = focus,
            child: Column(
              children: <Widget>[
                FocusableScope(
                  debugLabel: 'key2',
                  key: key2,
                  onFocusChange: (bool focus) => focus2 = focus,
                  child: Column(
                    children: <Widget>[
                      Focusable(
                        debugLabel: 'key3',
                        key: key3,
                        onFocusChange: (bool focus) => focus3 = focus,
                        child: Container(key: key4),
                      ),
                      Focusable(
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
      final FocusableNode firstFocusableNode = Focusable.of(firstChild);
      final FocusableNode secondFocusableNode = Focusable.of(secondChild);
      final FocusableNode scope = Focusable.of(firstChild).enclosingScope;
      firstFocusableNode.requestFocus();

      await tester.pump();

      expect(focus1, isTrue);
      expect(focus2, isTrue);
      expect(focus3, isTrue);
      expect(focus5, isNull);
      expect(firstFocusableNode.hasFocus, isTrue);
      expect(secondFocusableNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);

      focus1 = null;
      focus2 = null;
      focus3 = null;
      focus5 = null;

      Focusable.of(firstChild).nextFocus();

      await tester.pump();

      expect(focus1, isNull);
      expect(focus2, isNull);
      expect(focus3, isFalse);
      expect(focus5, isTrue);
      expect(firstFocusableNode.hasFocus, isFalse);
      expect(secondFocusableNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);

      focus1 = null;
      focus2 = null;
      focus3 = null;
      focus5 = null;

      Focusable.of(firstChild).nextFocus();

      await tester.pump();

      expect(focus1, isNull);
      expect(focus2, isNull);
      expect(focus3, isTrue);
      expect(focus5, isFalse);
      expect(firstFocusableNode.hasFocus, isTrue);
      expect(secondFocusableNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);

      focus1 = null;
      focus2 = null;
      focus3 = null;
      focus5 = null;

      // Tests that can still move back to original node.
      Focusable.of(firstChild).previousFocus();

      await tester.pump();

      expect(focus1, isNull);
      expect(focus2, isNull);
      expect(focus3, isFalse);
      expect(focus5, isTrue);
      expect(firstFocusableNode.hasFocus, isFalse);
      expect(secondFocusableNode.hasFocus, isTrue);
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
          policy: const WidgetOrderFocusTraversalPolicy(),
          child: Focusable(
            key: key1,
            child: Column(
              children: <Widget>[
                FocusableScope(
                  key: key2,
                  child: Column(
                    children: <Widget>[
                      Focusable(
                        key: key3,
                        child: Container(key: key4),
                      ),
                      Focusable(
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
      final FocusableNode firstFocusableNode = Focusable.of(firstChild);
      final FocusableNode secondFocusableNode = Focusable.of(secondChild);
      final FocusableNode scope = Focusable.of(firstChild).enclosingScope;
      secondFocusableNode.requestFocus();

      await tester.pump();

      expect(firstFocusableNode.hasFocus, isFalse);
      expect(secondFocusableNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);

      Focusable.of(firstChild).previousFocus();

      await tester.pump();

      expect(firstFocusableNode.hasFocus, isTrue);
      expect(secondFocusableNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);

      Focusable.of(firstChild).previousFocus();

      await tester.pump();

      expect(firstFocusableNode.hasFocus, isFalse);
      expect(secondFocusableNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);

      // Tests that can still move back to original node.
      Focusable.of(firstChild).nextFocus();

      await tester.pump();

      expect(firstFocusableNode.hasFocus, isTrue);
      expect(secondFocusableNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
    });
  });
  group(ReadingOrderTraversalPolicy, () {
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
            policy: const ReadingOrderTraversalPolicy(),
            child: Focusable(
              debugLabel: 'key1',
              key: key1,
              onFocusChange: (bool focus) => focus1 = focus,
              child: Column(
                children: <Widget>[
                  FocusableScope(
                    debugLabel: 'key2',
                    key: key2,
                    onFocusChange: (bool focus) => focus2 = focus,
                    child: Row(
                      children: <Widget>[
                        Focusable(
                          debugLabel: 'key3',
                          key: key3,
                          onFocusChange: (bool focus) => focus3 = focus,
                          child: Container(key: key4),
                        ),
                        Focusable(
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
      final FocusableNode firstFocusableNode = Focusable.of(firstChild);
      final FocusableNode secondFocusableNode = Focusable.of(secondChild);
      final FocusableNode scope = Focusable.of(firstChild).enclosingScope;
      firstFocusableNode.requestFocus();

      await tester.pump();

      expect(focus1, isTrue);
      expect(focus2, isTrue);
      expect(focus3, isTrue);
      expect(focus5, isNull);
      expect(firstFocusableNode.hasFocus, isTrue);
      expect(secondFocusableNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
      clear();

      Focusable.of(firstChild).nextFocus();

      await tester.pump();

      expect(focus1, isNull);
      expect(focus2, isNull);
      expect(focus3, isFalse);
      expect(focus5, isTrue);
      expect(firstFocusableNode.hasFocus, isFalse);
      expect(secondFocusableNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);
      clear();

      Focusable.of(firstChild).nextFocus();

      await tester.pump();

      expect(focus1, isNull);
      expect(focus2, isNull);
      expect(focus3, isTrue);
      expect(focus5, isFalse);
      expect(firstFocusableNode.hasFocus, isTrue);
      expect(secondFocusableNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
      clear();

      // Tests that can still move back to original node.
      Focusable.of(firstChild).previousFocus();

      await tester.pump();

      expect(focus1, isNull);
      expect(focus2, isNull);
      expect(focus3, isFalse);
      expect(focus5, isTrue);
      expect(firstFocusableNode.hasFocus, isFalse);
      expect(secondFocusableNode.hasFocus, isTrue);
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
          policy: const ReadingOrderTraversalPolicy(),
          child: Focusable(
            key: key1,
            child: Column(
              children: <Widget>[
                FocusableScope(
                  key: key2,
                  child: Column(
                    children: <Widget>[
                      Focusable(
                        key: key3,
                        child: Container(key: key4),
                      ),
                      Focusable(
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
      final FocusableNode firstFocusableNode = Focusable.of(firstChild);
      final FocusableNode secondFocusableNode = Focusable.of(secondChild);
      final FocusableNode scope = Focusable.of(firstChild).enclosingScope;
      secondFocusableNode.requestFocus();

      await tester.pump();

      expect(firstFocusableNode.hasFocus, isFalse);
      expect(secondFocusableNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);

      Focusable.of(firstChild).previousFocus();

      await tester.pump();

      expect(firstFocusableNode.hasFocus, isTrue);
      expect(secondFocusableNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);

      Focusable.of(firstChild).previousFocus();

      await tester.pump();

      expect(firstFocusableNode.hasFocus, isFalse);
      expect(secondFocusableNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);

      // Tests that can still move back to original node.
      Focusable.of(firstChild).nextFocus();

      await tester.pump();

      expect(firstFocusableNode.hasFocus, isTrue);
      expect(secondFocusableNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
    });
  });
  group(DirectionalFocusTraversalPolicyMixin, () {
    testWidgets('Move reading focus to the right node.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final GlobalKey key3 = GlobalKey(debugLabel: '3');
      final GlobalKey key4 = GlobalKey(debugLabel: '5');
      final GlobalKey key5 = GlobalKey(debugLabel: '4');
      bool focus1;
      bool focus2;
      bool focus3;
      bool focus4;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultFocusTraversal(
            policy: const ReadingOrderTraversalPolicy(),
            child: Focusable(
              debugLabel: 'key1',
              key: key1,
              onFocusChange: (bool focus) => focus1 = focus,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Focusable(
                        debugLabel: 'key3',
                        key: key3,
                        onFocusChange: (bool focus) => focus3 = focus,
                        child: Container(key: key2),
                      ),
                      Focusable(
                        debugLabel: 'key4',
                        key: key4,
                        onFocusChange: (bool focus) => focus4 = focus,
                        child: Container(key: key5),
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
        focus1 = null;
        focus2 = null;
        focus3 = null;
        focus4 = null;
      }

      final Element firstChild = tester.element(find.byKey(key2));
      final Element secondChild = tester.element(find.byKey(key5));
      final FocusableNode firstFocusableNode = Focusable.of(firstChild);
      final FocusableNode secondFocusableNode = Focusable.of(secondChild);
      final FocusableNode scope = Focusable.of(firstChild).enclosingScope;
      firstFocusableNode.requestFocus();

      await tester.pump();

      expect(focus1, isTrue);
      expect(focus2, isNull);
      expect(focus3, isTrue);
      expect(focus4, isNull);
      expect(firstFocusableNode.hasFocus, isTrue);
      expect(secondFocusableNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
      clear();

      Focusable.of(firstChild).nextFocus();

      await tester.pump();

      expect(focus1, isNull);
      expect(focus2, isNull);
      expect(focus3, isFalse);
      expect(focus4, isTrue);
      expect(firstFocusableNode.hasFocus, isFalse);
      expect(secondFocusableNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);
      clear();

      Focusable.of(firstChild).nextFocus();

      await tester.pump();

      expect(focus1, isNull);
      expect(focus2, isNull);
      expect(focus3, isNull);
      expect(focus4, isFalse);
      expect(firstFocusableNode.hasFocus, isFalse);
      expect(secondFocusableNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
      clear();

      // Tests that can still move back to original node.
      Focusable.of(firstChild).previousFocus();

      await tester.pump();

      expect(focus1, isNull);
      expect(focus2, isNull);
      expect(focus3, isNull);
      expect(focus4, isTrue);
      expect(firstFocusableNode.hasFocus, isFalse);
      expect(secondFocusableNode.hasFocus, isTrue);
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
          policy: const ReadingOrderTraversalPolicy(),
          child: Focusable(
            key: key1,
            child: Column(
              children: <Widget>[
                FocusableScope(
                  key: key2,
                  child: Column(
                    children: <Widget>[
                      Focusable(
                        key: key3,
                        child: Container(key: key4),
                      ),
                      Focusable(
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
      final FocusableNode firstFocusableNode = Focusable.of(firstChild);
      final FocusableNode secondFocusableNode = Focusable.of(secondChild);
      final FocusableNode scope = Focusable.of(firstChild).enclosingScope;
      secondFocusableNode.requestFocus();

      await tester.pump();

      expect(firstFocusableNode.hasFocus, isFalse);
      expect(secondFocusableNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);

      Focusable.of(firstChild).previousFocus();

      await tester.pump();

      expect(firstFocusableNode.hasFocus, isTrue);
      expect(secondFocusableNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);

      Focusable.of(firstChild).previousFocus();

      await tester.pump();

      expect(firstFocusableNode.hasFocus, isFalse);
      expect(secondFocusableNode.hasFocus, isTrue);
      expect(scope.hasFocus, isTrue);

      // Tests that can still move back to original node.
      Focusable.of(firstChild).nextFocus();

      await tester.pump();

      expect(firstFocusableNode.hasFocus, isTrue);
      expect(secondFocusableNode.hasFocus, isFalse);
      expect(scope.hasFocus, isTrue);
    });
  });
}
