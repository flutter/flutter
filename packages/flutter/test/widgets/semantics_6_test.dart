// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('can change semantics in a branch blocked by BlockSemantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          label: 'hello',
          textDirection: TextDirection.ltr,
          rect: TestSemantics.fullScreen,
        )
      ],
    );

    await tester.pumpWidget(buildWidget(
      invisibleText: 'one',
    ));

    expect(semantics, hasSemantics(expectedSemantics));

    // The purpose of the test is to ensure that this change does not throw.
    await tester.pumpWidget(buildWidget(
        invisibleText: 'two',
    ));

    expect(semantics, hasSemantics(expectedSemantics));
    semantics.dispose();
  });
}

Widget buildWidget({ @required String invisibleText }) {
  assert(invisibleText != null);
  return new Directionality(
    textDirection: TextDirection.ltr,
    child: new Stack(
        fit: StackFit.expand,
        children: <Widget>[
          new ListView(
            children: <Widget>[
              new Text(invisibleText),
            ],
          ),
          new BlockSemantics(
            child: new Semantics(
              label: 'hello',
              container: true,
            ),
          ),
        ]
    ),
  );
}
