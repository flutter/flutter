// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Semantics shutdown and restart', (WidgetTester tester) async {
    SemanticsTester semantics = new SemanticsTester(tester);

    final TestSemantics expectedSemantics = new TestSemantics.root(
      label: 'test1',
    );

    await tester.pumpWidget(
      new Container(
        child: new Semantics(
          label: 'test1',
          child: new Container()
        )
      )
    );

    expect(semantics, hasSemantics(expectedSemantics));

    semantics.dispose();
    semantics = null;

    expect(tester.binding.hasScheduledFrame, isFalse);
    semantics = new SemanticsTester(tester);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();

    expect(semantics, hasSemantics(expectedSemantics));
    semantics.dispose();
  });

  testWidgets('Detach and reattach assert', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    final GlobalKey key = new GlobalKey();

    await tester.pumpWidget(
      new Container(
        child: new Semantics(
          label: 'test1',
          child: new Semantics(
            key: key,
            container: true,
            label: 'test2a',
            child: new Container()
          )
        )
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        label: 'test1',
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            label: 'test2a',
            rect: TestSemantics.fullScreen,
          )
        ]
      )
    ));

    await tester.pumpWidget(
      new Container(
        child: new Semantics(
          label: 'test1',
          child: new Semantics(
            container: true,
            label: 'middle',
            child: new Semantics(
              key: key,
              container: true,
              label: 'test2b',
              child: new Container()
            )
          )
        )
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        label: 'test1',
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 2,
            label: 'middle',
            rect: TestSemantics.fullScreen,
            children: <TestSemantics>[
              new TestSemantics(
                id: 1,
                label: 'test2b',
                rect: TestSemantics.fullScreen,
              )
            ]
          )
        ]
      )
    ));

    semantics.dispose();
  });
}
