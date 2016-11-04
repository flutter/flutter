// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Does FlatButton contribute semantics', (WidgetTester tester) async {
    SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new FlatButton(
            onPressed: () { },
            child: new Text('Hello')
          )
        )
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics(
        id: 0,
        children: <TestSemantics>[
          new TestSemantics(
            id: 1,
            actions: SemanticsAction.tap.index,
            label: 'Hello',
            rect: new Rect.fromLTRB(0.0, 0.0, 88.0, 36.0),
            transform: new Matrix4.translationValues(356.0, 282.0, 0.0)
          )
        ]
      )
    ));

    semantics.dispose();
  });
}
