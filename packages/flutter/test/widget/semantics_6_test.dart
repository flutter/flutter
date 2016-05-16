// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Semantics 6 - SemanticsDebugger smoke test', (WidgetTester tester) async {

    // This is a smoketest to verify that adding a debugger doesn't crash.

    await tester.pumpWidget(
      new Stack(
        children: <Widget>[
          new Semantics(),
          new Semantics(
            container: true
          ),
          new Semantics(
            label: 'label'
          ),
        ]
      )
    );

    await tester.pumpWidget(
      new SemanticsDebugger(
        child: new Stack(
          children: <Widget>[
            new Semantics(),
            new Semantics(
              container: true
            ),
            new Semantics(
              label: 'label'
            ),
          ]
        )
      )
    );

    expect(true, isTrue); // expect that we reach here without crashing

  });
}
