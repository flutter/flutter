// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show SemanticsFlags;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Semantics 7 - Merging', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    String label;

    label = '1';
    await tester.pumpWidget(
      new Stack(
        fit: StackFit.expand,
        children: <Widget>[
          new MergeSemantics(
            child: new Semantics(
              checked: true,
              container: true,
              child: new Semantics(
                container: true,
                label: label,
              )
            )
          ),
          new MergeSemantics(
            child: new Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const Semantics(
                  checked: true,
                ),
                new Semantics(
                  label: label,
                ),
              ]
            )
          ),
        ]
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            flags: SemanticsFlags.hasCheckedState.index | SemanticsFlags.isChecked.index,
            label: label,
            rect: TestSemantics.fullScreen,
          ),
          // IDs 2 and 3 are used up by the nodes that get merged in
          new TestSemantics.rootChild(
            id: 4,
            flags: SemanticsFlags.hasCheckedState.index | SemanticsFlags.isChecked.index,
            label: label,
            rect: TestSemantics.fullScreen,
          ),
          // IDs 5 and 6 are used up by the nodes that get merged in
        ],
      )
    ));

    label = '2';
    await tester.pumpWidget(
      new Stack(
        fit: StackFit.expand,
        children: <Widget>[
          new MergeSemantics(
            child: new Semantics(
              checked: true,
              container: true,
              child: new Semantics(
                container: true,
                label: label,
              )
            )
          ),
          new MergeSemantics(
            child: new Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const Semantics(
                  checked: true,
                ),
                new Semantics(
                  label: label,
                )
              ]
            )
          ),
        ]
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            flags: SemanticsFlags.hasCheckedState.index | SemanticsFlags.isChecked.index,
            label: label,
            rect: TestSemantics.fullScreen,
          ),
          // IDs 2 and 3 are used up by the nodes that get merged in
          new TestSemantics.rootChild(
            id: 4,
            flags: SemanticsFlags.hasCheckedState.index | SemanticsFlags.isChecked.index,
            label: label,
            rect: TestSemantics.fullScreen,
          ),
          // IDs 5 and 6 are used up by the nodes that get merged in
        ],
      )
    ));

    semantics.dispose();
  });
}
