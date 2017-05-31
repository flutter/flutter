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
}
