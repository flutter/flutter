// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Semantics 8 - Merging with reset', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new MergeSemantics(
        child: new Semantics(
          container: true,
          child: new Semantics(
            container: true,
            child: new Stack(
              textDirection: TextDirection.ltr,
              children: <Widget>[
                new Semantics(
                  checked: true,
                ),
                new Semantics(
                  label: 'label',
                  textDirection: TextDirection.ltr,
                )
              ]
            )
          )
        )
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            flags: SemanticsFlag.hasCheckedState.index | SemanticsFlag.isChecked.index,
            label: 'label',
            textDirection: TextDirection.ltr,
            rect: TestSemantics.fullScreen,
          )
        ]
      )
    ));

    // switch the order of the inner Semantics node to trigger a reset
    await tester.pumpWidget(
      new MergeSemantics(
        child: new Semantics(
          container: true,
          child: new Semantics(
            container: true,
            child: new Stack(
              textDirection: TextDirection.ltr,
              children: <Widget>[
                new Semantics(
                  label: 'label',
                  textDirection: TextDirection.ltr,
                ),
                new Semantics(
                  checked: true
                )
              ]
            )
          )
        )
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            flags: SemanticsFlag.hasCheckedState.index | SemanticsFlag.isChecked.index,
            label: 'label',
            textDirection: TextDirection.ltr,
            rect: TestSemantics.fullScreen,
          )
        ],
      ),
    ));

    semantics.dispose();
  });
}
