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
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          label: 'test1',
          textDirection: TextDirection.ltr,
        )
      ],
    );

    await tester.pumpWidget(
      new Container(
        child: new Semantics(
          label: 'test1',
          textDirection: TextDirection.ltr,
          child: new Container()
        )
      )
    );

    expect(semantics, hasSemantics(
      expectedSemantics,
      ignoreTransform: true,
      ignoreRect: true,
      ignoreId: true,
    ));

    semantics.dispose();
    semantics = null;

    expect(tester.binding.hasScheduledFrame, isFalse);
    semantics = new SemanticsTester(tester);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();

    expect(semantics, hasSemantics(
      expectedSemantics,
      ignoreTransform: true,
      ignoreRect: true,
      ignoreId: true,
    ));
    semantics.dispose();
  });

  testWidgets('Detach and reattach assert', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    final GlobalKey key = new GlobalKey();

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Container(
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
    ));

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            label: 'test1',
            children: <TestSemantics>[
              new TestSemantics(
                label: 'test2a',
              )
            ]
          )
        ]
      ),
      ignoreId: true,
      ignoreRect: true,
      ignoreTransform: true,
    ));

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Container(
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
    ));

    expect(semantics, hasSemantics(
      new TestSemantics.root(
          children: <TestSemantics>[
            new TestSemantics.rootChild(
                label: 'test1',
                children: <TestSemantics>[
                  new TestSemantics(
                    label: 'middle',
                    children: <TestSemantics>[
                      new TestSemantics(
                        label: 'test2b',
                      ),
                    ],
                  )
                ]
            )
          ]
      ),
      ignoreId: true,
      ignoreRect: true,
      ignoreTransform: true,
    ));

    semantics.dispose();
  });

  testWidgets('Semantics and Directionality - RTL', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Semantics(
          label: 'test1',
          child: new Container(),
        ),
      ),
    );

    expect(semantics, includesNodeWith(label: 'test1', textDirection: TextDirection.rtl));
  });

  testWidgets('Semantics and Directionality - LTR', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Semantics(
          label: 'test1',
          child: new Container(),
        ),
      ),
    );

    expect(semantics, includesNodeWith(label: 'test1', textDirection: TextDirection.ltr));
  });

  testWidgets('Semantics and Directionality - cannot override RTL with LTR', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          label: 'test1',
          textDirection: TextDirection.ltr,
        )
      ]
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Semantics(
          label: 'test1',
          textDirection: TextDirection.ltr,
          child: new Container(),
        ),
      ),
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true));
  });

  testWidgets('Semantics and Directionality - cannot override LTR with RTL', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final TestSemantics expectedSemantics = new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            label: 'test1',
            textDirection: TextDirection.rtl,
          )
        ]
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Semantics(
          label: 'test1',
          textDirection: TextDirection.rtl,
          child: new Container(),
        ),
      ),
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreTransform: true, ignoreRect: true, ignoreId: true));
  });
}
