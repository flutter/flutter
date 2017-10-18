// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Simple tree is simple', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      const Center(
          child: const Text('Hello!', textDirection: TextDirection.ltr)
      ),
    );

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          label: 'Hello!',
          textDirection: TextDirection.ltr,
          rect: new Rect.fromLTRB(0.0, 0.0, 84.0, 14.0),
          transform: new Matrix4.translationValues(358.0, 293.0, 0.0),
        )
      ],
    )));

    semantics.dispose();
  });

  testWidgets('Simple tree is simple - material', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(new MaterialApp(
      home: const Center(child: const Text('Hello!')),
    ));

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 2,
          label: 'Hello!',
          textDirection: TextDirection.ltr,
          rect: new Rect.fromLTRB(0.0, 0.0, 288.0, 48.0),
          transform: new Matrix4.translationValues(256.0, 276.0, 0.0),
        )
      ],
    )));

    semantics.dispose();
  });
}
