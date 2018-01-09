// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show SemanticsFlag;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Card can take semantic text from multiple children', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Material(
          child: new Center(
            child: new Card(
              child: new Column(
                children: <Widget>[
                  const Text('I am text!'),
                  const Text('Moar text!!1'),
                  new MaterialButton(
                    child: const Text('Button'),
                    onPressed: () { },
                  )
                ],
              )
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
            label: 'I am text!\nMoar text!!1',
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              new TestSemantics(
                id: 2,
                label: 'Button',
                textDirection: TextDirection.ltr,
                actions: <SemanticsAction>[
                  SemanticsAction.tap,
                ],
                flags: <SemanticsFlag>[
                  SemanticsFlag.isButton,
                  SemanticsFlag.hasEnabledState,
                  SemanticsFlag.isEnabled,
                ],
              ),
            ],
          ),
        ],
      ),
      ignoreTransform: true,
      ignoreRect: true,
    ));

    semantics.dispose();
  });

}
