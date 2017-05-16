// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show SemanticsFlags;

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
              children: <Widget>[
                const Semantics(
                  checked: true
                ),
                const Semantics(
                  label: 'label'
                )
              ]
            )
          )
        )
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        flags: SemanticsFlags.hasCheckedState.index | SemanticsFlags.isChecked.index,
        label: 'label',
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
              children: <Widget>[
                const Semantics(
                  label: 'label'
                ),
                const Semantics(
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
        flags: SemanticsFlags.hasCheckedState.index | SemanticsFlags.isChecked.index,
        label: 'label',
      )
    ));

    semantics.dispose();
  });
}
