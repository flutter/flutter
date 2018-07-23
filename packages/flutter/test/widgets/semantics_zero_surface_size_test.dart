// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('has only root node if surface size is 0x0', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(new Semantics(
      selected: true,
    ));

    expect(semantics, hasSemantics(
      new TestSemantics(
        id: 0,
        rect: new Rect.fromLTRB(0.0, 0.0, 2400.0, 1800.0),
        children: <TestSemantics>[
          new TestSemantics(
            id: 1,
            rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 600.0),
            flags: <SemanticsFlag>[SemanticsFlag.isSelected],
          ),
        ],
      ), ignoreTransform: true,
    ));

    await tester.binding.setSurfaceSize(const Size(0.0, 0.0));
    await tester.pumpAndSettle();

    expect(semantics, hasSemantics(
      new TestSemantics(
        id: 0,
        rect: new Rect.fromLTRB(0.0, 0.0, 0.0, 0.0),
      ), ignoreTransform: true,
    ));

    await tester.binding.setSurfaceSize(null);
    semantics.dispose();
  });
}
