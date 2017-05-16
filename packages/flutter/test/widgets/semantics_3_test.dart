// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show SemanticsFlags;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Semantics 3', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    // implicit annotators
    await tester.pumpWidget(
      new Container(
        child: new Semantics(
          label: 'test',
          child: new Container(
            child: const Semantics(
              checked: true
            )
          )
        )
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        flags: SemanticsFlags.hasCheckedState.index | SemanticsFlags.isChecked.index,
        label: 'test',
      )
    ));

    // remove one
    await tester.pumpWidget(
      new Container(
        child: new Container(
          child: const Semantics(
            checked: true
          )
        )
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        flags: SemanticsFlags.hasCheckedState.index | SemanticsFlags.isChecked.index,
      )
    ));

    // change what it says
    await tester.pumpWidget(
      new Container(
        child: new Container(
          child: const Semantics(
            label: 'test'
          )
        )
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        label: 'test',
      )
    ));

    // add a node
    await tester.pumpWidget(
      new Container(
        child: new Semantics(
          checked: true,
          child: new Container(
            child: const Semantics(
              label: 'test'
            )
          )
        )
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        flags: SemanticsFlags.hasCheckedState.index | SemanticsFlags.isChecked.index,
        label: 'test',
      )
    ));

    int changeCount = 0;
    tester.binding.pipelineOwner.semanticsOwner.addListener(() {
      changeCount += 1;
    });

    // make no changes
    await tester.pumpWidget(
      new Container(
        child: new Semantics(
          checked: true,
          child: new Container(
            child: const Semantics(
              label: 'test'
            )
          )
        )
      )
    );

    expect(changeCount, 0);

    semantics.dispose();
  });
}
