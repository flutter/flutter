// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group(Focusable, () {
    testWidgets('Focusable.of stops at the nearest FocusableScope.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final GlobalKey key3 = GlobalKey(debugLabel: '3');
      final GlobalKey key4 = GlobalKey(debugLabel: '4');
      final GlobalKey key5 = GlobalKey(debugLabel: '5');
      final GlobalKey key6 = GlobalKey(debugLabel: '6');
      await tester.pumpWidget(
        Focusable(
          key: key1,
          debugLabel: 'Key 1',
          child: Container(
            key: key2,
            child: Focusable(
              debugLabel: 'Key 3',
              key: key3,
              child: Container(
                key: key4,
                child: Focusable(
                  debugLabel: 'Key 5',
                  key: key5,
                  child: Container(
                    key: key6,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final Element element1 = tester.element(find.byKey(key1));
      final Element element2 = tester.element(find.byKey(key2));
      final Element element3 = tester.element(find.byKey(key3));
      final Element element4 = tester.element(find.byKey(key4));
      final Element element5 = tester.element(find.byKey(key5));
      final Element element6 = tester.element(find.byKey(key6));
      final FocusNode root = element1.owner.focusManager.rootScope;

      expect(Focusable.of(element1), equals(root));
      expect(Focusable.of(element2).parent, equals(root));
      expect(Focusable.of(element3).parent, equals(root));
      expect(Focusable.of(element4).parent.parent, equals(root));
      expect(Focusable.of(element4).parent.parent, equals(root));
      expect(Focusable.of(element5).parent.parent, equals(root));
      expect(Focusable.of(element6).parent.parent.parent, equals(root));
    });
    testWidgets('Can traverse Focusable children.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      final GlobalKey key2 = GlobalKey(debugLabel: '2');
      final GlobalKey key3 = GlobalKey(debugLabel: '3');
      final GlobalKey key4 = GlobalKey(debugLabel: '4');
      final GlobalKey key5 = GlobalKey(debugLabel: '5');
      final GlobalKey key6 = GlobalKey(debugLabel: '6');
      final GlobalKey key7 = GlobalKey(debugLabel: '7');
      final GlobalKey key8 = GlobalKey(debugLabel: '8');
      await tester.pumpWidget(
        Focusable(
          child: Column(
            key: key1,
            children: <Widget>[
              Focusable(
                key: key2,
                child: Container(
                  child: Focusable(
                    key: key3,
                    child: Container(),
                  ),
                ),
              ),
              Focusable(
                key: key4,
                child: Container(
                  child: Focusable(
                    key: key5,
                    child: Container(),
                  ),
                ),
              ),
              Focusable(
                key: key6,
                child: Column(
                  children: <Widget>[
                    Focusable(
                      key: key7,
                      child: Container(),
                    ),
                    Focusable(
                      key: key8,
                      child: Container(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      final Element firstScope = tester.element(find.byKey(key1));
      final List<FocusNode> nodes = <FocusNode>[];
      final List<Key> keys = <Key>[];
      bool visitor(FocusNode node) {
        nodes.add(node);
        keys.add(node.context.widget.key);
        return true;
      }

      await tester.pump();

      Focusable.of(firstScope).descendants.forEach(visitor);
      expect(nodes.length, equals(7));
      expect(keys.length, equals(7));
      // Depth first.
      expect(keys, equals(<Key>[key3, key2, key5, key4, key7, key8, key6]));

      // Just traverses a sub-tree.
      final Element secondScope = tester.element(find.byKey(key7));
      nodes.clear();
      keys.clear();
      Focusable.of(secondScope).descendants.forEach(visitor);
      expect(nodes.length, equals(2));
      expect(keys, equals(<Key>[key7, key8]));
    });
    testWidgets('Can set focus.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      bool gotFocus;
      await tester.pumpWidget(
        Focusable(
          onFocusChange: (bool focused) => gotFocus = focused,
          child: Container(key: key1),
        ),
      );

      final Element firstNode = tester.element(find.byKey(key1));
      final FocusNode node = Focusable.of(firstNode);
      node.requestFocus();

      await tester.pump();

      expect(gotFocus, isTrue);
      expect(node.hasFocus, isTrue);
    });
    testWidgets('Can focus root node.', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey(debugLabel: '1');
      await tester.pumpWidget(
        Focusable(
          key: key1,
          child: Container(),
        ),
      );

      final Element firstElement = tester.element(find.byKey(key1));
      final FocusNode rootNode = Focusable.of(firstElement);
      rootNode.requestFocus();

      await tester.pump();

      expect(rootNode.hasFocus, isTrue);
      expect(rootNode, equals(firstElement.owner.focusManager.rootScope));
    });
  });
}
