// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  group('BlockSemantics', () {
    testWidgets('hides semantic nodes of siblings', (WidgetTester tester) async {
      final SemanticsTester semantics = new SemanticsTester(tester);

      await tester.pumpWidget(new Stack(
        children: <Widget>[
          new Semantics(
            label: 'not included in tree',
            child: new Container(),
          ),
          const BlockSemantics(),
          new Semantics(
            label: 'included in tree',
            child: new Container(),
          ),
        ],
      ));

      expect(semantics, isNot(includesNodeWithLabel('not included in tree')));

      semantics.dispose();
    });
  });

  group('BlockSemantics', () {
    testWidgets('does not hides semantic nodes of siblings outside the current semantic boundary', (WidgetTester tester) async {
      final SemanticsTester semantics = new SemanticsTester(tester);

      await tester.pumpWidget(new Stack(
        children: <Widget>[
          new Semantics(
            label: 'in the tree #1',
            child: new Container(),
          ),
          new Semantics(
            label: 'in the tree #4',
            container: true,
            child: new Stack(
                children: <Widget>[
                  new Semantics(
                    label: 'NOT in the tree #1',
                    child: new Container(),
                  ),
                  const BlockSemantics(),
                  new Semantics(
                    label: 'in the tree #3',
                    child: new Container(),
                  ),
                ],
            ),
          ),
          new Semantics(
            label: 'in the tree #2',
            child: new Container(),
          ),
        ],
      ));

      expect(semantics, includesNodeWithLabel('in the tree #1'));
      expect(semantics, includesNodeWithLabel('in the tree #2'));
      expect(semantics, includesNodeWithLabel('in the tree #3'));
      expect(semantics, includesNodeWithLabel('in the tree #4'));
      expect(semantics, isNot(includesNodeWithLabel('NOT in the tree #1')));

      semantics.dispose();
    });
  });

}
