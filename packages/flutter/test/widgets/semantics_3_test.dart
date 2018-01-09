// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Semantics 3', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    // implicit annotators
    await tester.pumpWidget(
      new Semantics(
        container: true,
        child: new Container(
          child: new Semantics(
            label: 'test',
            textDirection: TextDirection.ltr,
            child: new Container(
              child: new Semantics(
                checked: true
              ),
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            flags: SemanticsFlag.hasCheckedState.index | SemanticsFlag.isChecked.index,
            label: 'test',
            rect: TestSemantics.fullScreen,
          )
        ]
      )
    ));

    // remove one
    await tester.pumpWidget(
      new Semantics(
        container: true,
        child: new Container(
          child: new Semantics(
             checked: true,
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            flags: SemanticsFlag.hasCheckedState.index | SemanticsFlag.isChecked.index,
            rect: TestSemantics.fullScreen,
          ),
        ]
      )
    ));

    // change what it says
    await tester.pumpWidget(
      new Semantics(
        container: true,
        child: new Container(
          child: new Semantics(
            label: 'test',
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            label: 'test',
            textDirection: TextDirection.ltr,
            rect: TestSemantics.fullScreen,
          ),
        ]
      )
    ));

    // add a node
    await tester.pumpWidget(
      new Semantics(
        container: true,
        child: new Container(
          child: new Semantics(
            checked: true,
            child: new Semantics(
              label: 'test',
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            flags: SemanticsFlag.hasCheckedState.index | SemanticsFlag.isChecked.index,
            label: 'test',
            rect: TestSemantics.fullScreen,
          )
        ],
      ),
    ));

    int changeCount = 0;
    tester.binding.pipelineOwner.semanticsOwner.addListener(() {
      changeCount += 1;
    });

    // make no changes
    await tester.pumpWidget(
      new Semantics(
        container: true,
        child: new Container(
          child: new Semantics(
            checked: true,
            child: new Semantics(
              label: 'test',
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    );

    expect(changeCount, 0);

    semantics.dispose();
  });
}
