// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Semantics 5', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Stack(
        children: <Widget>[
          const Semantics(
            // this tests that empty nodes disappear
          ),
          const Semantics(
            // this tests whether you can have a container with no other semantics
            container: true
          ),
          const Semantics(
            label: 'label' // (force a fork)
          ),
        ]
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics(
        id: 0,
        children: <TestSemantics>[
          new TestSemantics(
            id: 1,
          ),
          new TestSemantics(
            id: 2,
            label: 'label',
          ),
        ]
      )
    ));

    semantics.dispose();
  });
}
