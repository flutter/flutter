// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'semantics_tester.dart';

void main() {
  group(CustomPainter, () {
    _defineTests();
  });
}

void _defineTests() {
  testWidgets('provides semantics', (WidgetTester tester) async {
    final SemanticsTester semanticsTester = new SemanticsTester(tester);

    await tester.pumpWidget(new CustomPaint(
      painter: new _PainterWithSemantics(
        label: 'background'
      ),
      foregroundPainter: new _PainterWithSemantics(
        label: 'foreground'
      ),
    ));

    expect(semanticsTester, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            rect: TestSemantics.fullScreen,
            children: <TestSemantics>[
              new TestSemantics(
                id: 2,
                label: 'background',
                rect: new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
              ),
              new TestSemantics(
                id: 3,
                label: 'foreground',
                rect: new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
              ),
            ],
          ),
        ],
      ),
    ));

    semanticsTester.dispose();
  });

  testWidgets('diffs semantic node list correctly', (WidgetTester tester) async {
    Future<Null> diff({Map<String, String> from, Map<String, String> to}) async {
      final SemanticsTester semanticsTester = new SemanticsTester(tester);

      TestSemantics createExpectations(Map<String, String> labelsAndKeys) {
        final List<TestSemantics> children = <TestSemantics>[];
        labelsAndKeys.forEach((String label, String key) {
          children.add(
            new TestSemantics(
              label: label,
            ),
          );
        });

        return new TestSemantics.root(
          children: <TestSemantics>[
            new TestSemantics.rootChild(
              rect: TestSemantics.fullScreen,
              children: children,
            ),
          ],
        );
      }

      await tester.pumpWidget(new CustomPaint(
        painter: new _SemanticsDiffTest(from),
      ));
      doNotIgnoreId();
      expect(semanticsTester, hasSemantics(createExpectations(from), ignoreId: true));

      await tester.pumpWidget(new CustomPaint(
        painter: new _SemanticsDiffTest(to),
      ));
      expect(semanticsTester, hasSemantics(createExpectations(from), ignoreId: true));

      semanticsTester.dispose();
    }

    await diff(
      from: <String, String>{},
      to: <String, String>{
        'a': null,
      },
    );
  });
}

class _SemanticsDiffTest extends CustomPainter {
  _SemanticsDiffTest(this.data);

  final Map<String, String> data;

  @override
  void paint(Canvas canvas, Size size) {
    // We don't test painting.
  }

  @override
  List<CustomPainterSemantics> buildSemantics(Size size) {
    final List<CustomPainterSemantics> semantics = <CustomPainterSemantics>[];
    data.forEach((String label, String key) {
      semantics.add(
        new CustomPainterSemantics(
          rect: new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
          key: new ValueKey<String>(key),
          properties: new SemanticsProperties(
            label: label,
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    });
    return semantics;
  }

  @override
  bool shouldRepaint(_SemanticsDiffTest oldPainter) => true;
}

class _PainterWithSemantics extends CustomPainter {
  _PainterWithSemantics({ this.label });

  final String label;

  @override
  void paint(Canvas canvas, Size size) {
    // We don't test painting.
  }

  @override
  List<CustomPainterSemantics> buildSemantics(Size size) {
    return <CustomPainterSemantics>[
      new CustomPainterSemantics(
        rect: new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
        properties: new SemanticsProperties(
          label: label,
          textDirection: TextDirection.rtl,
        ),
      ),
    ];
  }

  @override
  bool shouldRepaint(_PainterWithSemantics oldPainter) => true;
}
