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
            label: 'layer#1',
            child: new Container(),
          ),
          const BlockSemantics(),
          new Semantics(
            label: 'layer#2',
            child: new Container(),
          ),
        ],
      ));

      expect(semantics, isNot(includesNodeWithLabel('layer#1')));

      await tester.pumpWidget(new Stack(
        children: <Widget>[
          new Semantics(
            label: 'layer#1',
            child: new Container(),
          ),
        ],
      ));

      expect(semantics, includesNodeWithLabel('layer#1'));

      semantics.dispose();
    });

    testWidgets('does not hides semantic nodes of siblings outside the current semantic boundary', (WidgetTester tester) async {
      final SemanticsTester semantics = new SemanticsTester(tester);

      await tester.pumpWidget(new Stack(
        children: <Widget>[
          new Semantics(
            label: '#1',
            child: new Container(),
          ),
          new Semantics(
            label: '#2',
            container: true,
            child: new Stack(
              children: <Widget>[
                new Semantics(
                  label: 'NOT#2.1',
                  child: new Container(),
                ),
                new Semantics(
                  label: '#2.2',
                  child: new BlockSemantics(
                    child: new Semantics(
                      container: true,
                      label: '#2.2.1',
                      child: new Container(),
                    ),
                  ),
                ),
                new Semantics(
                  label: '#2.3',
                  child: new Container(),
                ),
              ],
            ),
          ),
          new Semantics(
            label: '#3',
            child: new Container(),
          ),
        ],
      ));

      expect(semantics, includesNodeWithLabel('#1'));
      expect(semantics, includesNodeWithLabel('#2'));
      expect(semantics, isNot(includesNodeWithLabel('NOT#2.1')));
      expect(semantics, includesNodeWithLabel('#2.2'));
      expect(semantics, includesNodeWithLabel('#2.2.1'));
      expect(semantics, includesNodeWithLabel('#2.3'));
      expect(semantics, includesNodeWithLabel('#3'));

      semantics.dispose();
    });
  });
}
