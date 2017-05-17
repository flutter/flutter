// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show SemanticsFlags;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Semantics 4', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    //    O
    //   / \       O=root
    //  L   L      L=node with label
    //     / \     C=node with checked
    //    C   C*   *=node removed next pass
    //
    await tester.pumpWidget(
      new Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const Semantics(
            label: 'L1',
          ),
          new Semantics(
            label: 'L2',
            child: new Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const Semantics(
                  checked: true,
                ),
                const Semantics(
                  checked: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            label: 'L1',
            rect: TestSemantics.fullScreen,
          ),
          new TestSemantics.rootChild(
            id: 2,
            label: 'L2',
            rect: TestSemantics.fullScreen,
            children: <TestSemantics>[
              new TestSemantics(
                id: 3,
                flags: SemanticsFlags.hasCheckedState.index | SemanticsFlags.isChecked.index,
                rect: TestSemantics.fullScreen,
              ),
              new TestSemantics(
                id: 4,
                flags: SemanticsFlags.hasCheckedState.index,
                rect: TestSemantics.fullScreen,
              ),
            ]
          ),
        ],
      )
    ));

    //    O        O=root
    //   / \       L=node with label
    //  L* LC      C=node with checked
    //             *=node removed next pass
    //
    await tester.pumpWidget(
      new Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const Semantics(
            label: 'L1',
          ),
          new Semantics(
            label: 'L2',
            child: new Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const Semantics(
                  checked: true,
                ),
                const Semantics(),
              ],
            ),
          ),
        ],
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            label: 'L1',
            rect: TestSemantics.fullScreen,
          ),
          new TestSemantics.rootChild(
            id: 2,
            label: 'L2',
            flags: SemanticsFlags.hasCheckedState.index | SemanticsFlags.isChecked.index,
            rect: TestSemantics.fullScreen,
          ),
        ],
      )
    ));

    //             O=root
    //    OLC      L=node with label
    //             C=node with checked
    //
    await tester.pumpWidget(
      new Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const Semantics(),
          new Semantics(
            label: 'L2',
            child: new Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const Semantics(
                  checked: true,
                ),
                const Semantics(),
              ],
            ),
          ),
        ],
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        label: 'L2',
        flags: SemanticsFlags.hasCheckedState.index | SemanticsFlags.isChecked.index,
      )
    ));

    semantics.dispose();
  });
}
