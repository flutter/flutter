// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('SemanticNode.rect is clipped', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Container(
          width: 100.0,
          child: Flex(
            direction: Axis.horizontal,
            children: <Widget>[
              Container(
                width: 75.0,
                child: const Text('1'),
              ),
              Container(
                width: 75.0,
                child: const Text('2'),
              ),
              Container(
                width: 75.0,
                child: const Text('3'),
              ),
            ],
          ),
        ),
      ),
    ));

    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(exception.diagnostics.first.level, DiagnosticLevel.summary);
    expect(exception.diagnostics.first.toString(), contains('overflowed'));

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics(
            label: '1',
            rect: const Rect.fromLTRB(0.0, 0.0, 75.0, 14.0),
          ),
          TestSemantics(
            label: '2',
            rect: const Rect.fromLTRB(0.0, 0.0, 25.0, 14.0), // clipped form original 75.0 to 25.0
          ),
          // node with Text 3 not present.
        ],
      ),
      ignoreTransform: true,
      ignoreId: true,
    ));

    semantics.dispose();
  });

  testWidgets('SemanticsNode is not removed if out of bounds and merged into something within bounds', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Container(
          width: 100.0,
          child: Flex(
            direction: Axis.horizontal,
            children: <Widget>[
              Container(
                width: 75.0,
                child: const Text('1'),
              ),
              MergeSemantics(
                child: Flex(
                  direction: Axis.horizontal,
                  children: <Widget>[
                    Container(
                      width: 75.0,
                      child: const Text('2'),
                    ),
                    Container(
                      width: 75.0,
                      child: const Text('3'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));

    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(exception.diagnostics.first.level, DiagnosticLevel.summary);
    expect(exception.diagnostics.first.toString(), contains('overflowed'));

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics(
            label: '1',
            rect: const Rect.fromLTRB(0.0, 0.0, 75.0, 14.0),
          ),
          TestSemantics(
            label: '2\n3',
            rect: const Rect.fromLTRB(0.0, 0.0, 25.0, 14.0), // clipped form original 75.0 to 25.0
          ),
        ],
      ),
      ignoreTransform: true,
      ignoreId: true,
    ));

    semantics.dispose();
  });
}
