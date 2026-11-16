// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show FlutterView;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EvaluationResult supports const construction', () {
    const result = EvaluationResult(<Violation>[]);
    expect(result.violations, isEmpty);
  });

  group('MinimumTapTargetEvaluation', () {
    const evaluation = MinimumTapTargetEvaluation(size: Size(48.0, 48.0));

    testWidgets('passes for valid targets', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: SizedBox.square(
            dimension: 48.0,
            child: Semantics(label: 'button', onTap: () {}),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('fails for small targets', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Center(
            child: SizedBox.square(
              dimension: 40.0,
              child: Semantics(label: 'button', onTap: () {}),
            ),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, hasLength(1));
      expect(
        result.violations.first.reason,
        contains('expected tap target size of at least Size(48.0, 48.0)'),
      );
      handle.dispose();
    });

    testWidgets('skips hidden nodes', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: SizedBox.square(
            dimension: 40.0,
            child: Semantics(label: 'button', onTap: () {}, hidden: true),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('respects custom shouldSkipNode callback', (WidgetTester tester) async {
      final customEvaluation = MinimumTapTargetEvaluation(
        size: const Size(48.0, 48.0),
        shouldSkipNode: (SemanticsNode node) =>
            MinimumTapTargetEvaluation.defaultShouldSkipNode(node) ||
            node.getSemanticsData().tooltip == 'Exempt',
      );
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox.square(
                  dimension: 32.0,
                  child: Semantics(container: true, tooltip: 'Exempt', onTap: () {}),
                ),
                const SizedBox(height: 16.0),
                SizedBox.square(
                  dimension: 32.0,
                  child: Semantics(container: true, tooltip: 'Required', onTap: () {}),
                ),
              ],
            ),
          ),
        ),
      );
      final EvaluationResult result = await customEvaluation.evaluate(tester.binding);
      expect(result.violations, hasLength(1));
      expect(result.violations.single.node.tooltip, 'Required');
      handle.dispose();
    });

    testWidgets('custom shouldSkipNode can opt in links skipped by default', (
      WidgetTester tester,
    ) async {
      final includeLinksEvaluation = MinimumTapTargetEvaluation(
        size: const Size(48.0, 48.0),
        shouldSkipNode: (SemanticsNode node) {
          final SemanticsData data = node.getSemanticsData();
          return (!data.hasAction(SemanticsAction.longPress) &&
                  !data.hasAction(SemanticsAction.tap)) ||
              data.flagsCollection.isHidden;
        },
      );
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Center(
            child: SizedBox.square(
              dimension: 32.0,
              child: Semantics(container: true, link: true, onTap: () {}),
            ),
          ),
        ),
      );
      final EvaluationResult defaultResult = await evaluation.evaluate(tester.binding);
      expect(defaultResult.violations, isEmpty);

      final EvaluationResult customResult = await includeLinksEvaluation.evaluate(tester.binding);
      expect(customResult.violations, hasLength(1));
      handle.dispose();
    });
  });

  group('LabeledTapTargetEvaluation', () {
    const evaluation = LabeledTapTargetEvaluation();

    testWidgets('passes for labeled targets', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: SizedBox.square(
            dimension: 48.0,
            child: Semantics(label: 'button', onTap: () {}),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('fails for unlabeled targets', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: SizedBox(width: 48.0, height: 48.0, child: Semantics(onTap: () {})),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, hasLength(1));
      expect(
        result.violations.first.reason,
        contains('expected tappable node to have semantic label'),
      );
      handle.dispose();
    });
  });

  group('MinimumTextContrastEvaluation', () {
    const evaluation = MinimumTextContrastEvaluation();

    testWidgets('passes for high contrast', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const TestWidgetsApp(
          home: SizedBox.square(
            dimension: 100.0,
            child: ColoredBox(
              color: Color(0xFFFFFFFF),
              child: Center(
                child: Text('test', style: TextStyle(color: Color(0xFF000000), fontSize: 14)),
              ),
            ),
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('fails for low contrast', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const TestWidgetsApp(
          home: SizedBox.square(
            dimension: 100,
            child: ColoredBox(
              color: Color(0xFFFFFFFF),
              child: Center(
                child: Text('test', style: TextStyle(color: Color(0xFFEEEEEE), fontSize: 14)),
              ),
            ),
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, hasLength(1));
      expect(result.violations.first.reason, contains('Expected contrast ratio of at least 4.5'));
      handle.dispose();
    });

    testWidgets('skips non-hit-testable text', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const TestWidgetsApp(
          home: Stack(
            children: <Widget>[
              Center(
                child: Text('obscured', style: TextStyle(color: Color(0xFF000000), fontSize: 14)),
              ),
              Positioned.fill(child: ColoredBox(color: Color(0xFFFFFFFF))),
            ],
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('reports low-contrast child under labeled ancestor node', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: Center(
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                label: 'Labeled parent container',
                child: SizedBox(
                  width: 200.0,
                  height: 100.0,
                  child: Center(
                    child: Semantics(
                      container: true,
                      child: const Text(
                        'low contrast child',
                        style: TextStyle(fontSize: 14.0, color: Color(0xFFEEEEEE)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, hasLength(1));
      expect(result.violations.first.reason, contains('Expected contrast ratio of at least 4.5'));
      handle.dispose();
    });

    testWidgets('reports violations from both labeled ancestor and child nodes', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: Center(
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                label: 'parent text',
                child: SizedBox(
                  width: 200.0,
                  height: 150.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      const ExcludeSemantics(
                        child: Text(
                          'parent text',
                          style: TextStyle(fontSize: 14.0, color: Color(0xFFEEEEEE)),
                        ),
                      ),
                      Semantics(
                        container: true,
                        child: const Text(
                          'child text',
                          style: TextStyle(fontSize: 14.0, color: Color(0xFFEEEEEE)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, hasLength(2));
      expect(result.violations.map((Violation v) => v.node.label), <String>[
        'child text',
        'parent text',
      ]);
      handle.dispose();
    });

    testWidgets('respects custom shouldSkipNode, targetContrastRatio, and isNodeOffScreen', (
      WidgetTester tester,
    ) async {
      final customEvaluation = MinimumTextContrastEvaluation(
        shouldSkipNode: (SemanticsNode node) =>
            MinimumTextContrastEvaluation.defaultShouldSkipNode(node) || node.label == 'exempt',
        targetContrastRatio: (double? fontSize, {required bool bold}) => 10.0,
        isNodeOffScreen: (Rect paintBounds, FlutterView window) => false,
      );
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const TestWidgetsApp(
          home: ColoredBox(
            color: Color(0xFFF0F0F0),
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: 10,
                  left: 10,
                  child: Text('exempt', style: TextStyle(fontSize: 14.0, color: Color(0xFFEEEEEE))),
                ),
                Positioned(
                  top: 60,
                  left: 10,
                  child: Text('medium', style: TextStyle(fontSize: 14.0, color: Color(0xFF5252FF))),
                ),
                Positioned(
                  top: 120,
                  left: -60,
                  child: SizedBox(
                    width: 200,
                    height: 40,
                    child: Text(
                      'partially offscreen',
                      style: TextStyle(fontSize: 14.0, color: Color(0xFFEEEEEE)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final EvaluationResult? defaultResult = await tester.runAsync<EvaluationResult>(() async {
        return evaluation.evaluate(tester.binding);
      });
      expect(defaultResult!.violations.map((Violation v) => v.node.label), <String>['exempt']);

      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return customEvaluation.evaluate(tester.binding);
      });
      expect(result!.violations.map((Violation v) => v.node.label), <String>[
        'medium',
        'partially offscreen',
      ]);
      handle.dispose();
    });
  });

  group('UnlabeledLeafNodeEvaluation', () {
    const evaluation = UnlabeledLeafNodeEvaluation();

    testWidgets('Passes if node has label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Semantics(
            container: true,
            label: 'test',
            child: const SizedBox(width: 10.0, height: 10.0),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('Passes if node has tooltip', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Semantics(
            container: true,
            tooltip: 'test',
            child: const SizedBox(width: 10.0, height: 10.0),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, isEmpty);
      handle.dispose();
    });
    testWidgets('Passes if node has value', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Semantics(
            container: true,
            onTap: () {},
            value: 'test',
            child: const SizedBox(width: 10.0, height: 10.0),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('Passes if node has hint', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Semantics(
            container: true,
            onTap: () {},
            hint: 'test',
            child: const SizedBox(width: 10.0, height: 10.0),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('Fails if node has no label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Semantics(
            container: true,
            onTap: () {},
            child: const SizedBox(width: 10.0, height: 10.0),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, hasLength(1));
      expect(
        result.violations.first.reason,
        contains('expected leaf semantics node to have a label'),
      );
      handle.dispose();
    });

    testWidgets('Fails if button node has no label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Semantics(
            container: true,
            button: true,
            child: const SizedBox(width: 10.0, height: 10.0),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, hasLength(1));
      expect(
        result.violations.first.reason,
        contains('expected leaf semantics node to have a label'),
      );
      handle.dispose();
    });

    testWidgets('Fails if focusable node has no label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Semantics(
            container: true,
            focusable: true,
            child: const SizedBox(width: 10.0, height: 10.0),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, hasLength(1));
      expect(
        result.violations.first.reason,
        contains('expected leaf semantics node to have a label'),
      );
      handle.dispose();
    });

    testWidgets('Passes if actionable node is hidden', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Semantics(
            container: true,
            hidden: true,
            button: true,
            child: const SizedBox(width: 10.0, height: 10.0),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('Passes if node is not focusable or actionable', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // For a container without any actions or focusable flags, even though it has no label,
      // it should not produce a violation because it is not "important".
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Semantics(container: true, child: const SizedBox(width: 10.0, height: 10.0)),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('Passes if node is not a leaf', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Semantics(
            container: true,
            onTap: () {},
            child: Column(
              children: <Widget>[
                Semantics(
                  label: 'Child 1',
                  onTap: () {},
                  child: const SizedBox(width: 10, height: 10),
                ),
              ],
            ),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('Passes if node merges descendants', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: MergeSemantics(
            child: Column(
              children: <Widget>[
                Semantics(
                  label: 'Child 1',
                  onTap: () {},
                  child: const SizedBox(width: 10, height: 10),
                ),
              ],
            ),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, isEmpty); // merged node has label from child.
      handle.dispose();
    });

    testWidgets('Fails if node merges descendants but has no label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: MergeSemantics(
            child: Semantics(
              container: true,
              onTap: () {},
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, hasLength(1));
      expect(
        result.violations.first.reason,
        contains('expected leaf semantics node to have a label'),
      );
      handle.dispose();
    });
  });

  group('MinimumNonTextContrastEvaluation', () {
    const evaluation = MinimumNonTextContrastEvaluation();

    testWidgets('passes for high contrast button', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: SizedBox.square(
            dimension: 100,
            child: ColoredBox(
              color: const Color(0xFFFFFFFF),
              child: Center(
                child: Semantics(
                  button: true,
                  container: true,
                  child: const SizedBox.square(
                    dimension: 50,
                    child: ColoredBox(color: Color(0xFF000000)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('fails for low contrast button', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: SizedBox.square(
            dimension: 100,
            child: ColoredBox(
              color: const Color(0xFFFFFFFF),
              child: Center(
                child: Semantics(
                  button: true,
                  container: true,
                  child: const SizedBox.square(
                    dimension: 50,
                    child: ColoredBox(color: Color(0xFFEEEEEE)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, hasLength(1));
      expect(
        result.violations.first.reason,
        contains('Expected non-text control contrast ratio of at least 3.0'),
      );
      handle.dispose();
    });

    testWidgets('passes when transparent and background is uniform', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: SizedBox.square(
            dimension: 100,
            child: ColoredBox(
              color: const Color(0xFFFFFFFF),
              child: Center(
                child: Semantics(
                  button: true,
                  container: true,
                  child: const SizedBox.square(dimension: 50),
                ),
              ),
            ),
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('fails for low contrast slider', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: SizedBox.square(
            dimension: 100,
            child: ColoredBox(
              color: const Color(0xFFFFFFFF),
              child: Center(
                child: Semantics(
                  slider: true,
                  container: true,
                  child: const SizedBox.square(
                    dimension: 50,
                    child: ColoredBox(color: Color(0xFFEEEEEE)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, hasLength(1));
      expect(
        result.violations.first.reason,
        contains('Expected non-text control contrast ratio of at least 3.0'),
      );
      handle.dispose();
    });

    testWidgets('passes for high contrast textfield', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: SizedBox.square(
            dimension: 100,
            child: ColoredBox(
              color: const Color(0xFFFFFFFF),
              child: Center(
                child: Semantics(
                  textField: true,
                  container: true,
                  child: const SizedBox.square(
                    dimension: 50,
                    child: ColoredBox(color: Color(0xFF000000)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('fails for low contrast node with onTap', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: SizedBox.square(
            dimension: 100,
            child: ColoredBox(
              color: const Color(0xFFFFFFFF),
              child: Center(
                child: Semantics(
                  onTap: () {},
                  container: true,
                  child: const SizedBox.square(
                    dimension: 50,
                    child: ColoredBox(color: Color(0xFFEEEEEE)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, hasLength(1));
      expect(
        result.violations.first.reason,
        contains('Expected non-text control contrast ratio of at least 3.0'),
      );
      handle.dispose();
    });

    testWidgets('reports low-contrast child control under high-contrast ancestor control', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: Center(
              child: Semantics(
                onTap: () {},
                container: true,
                explicitChildNodes: true,
                child: SizedBox(
                  width: 160,
                  height: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const SizedBox.square(
                        dimension: 60,
                        child: ColoredBox(color: Color(0xFF000000)),
                      ),
                      Semantics(
                        button: true,
                        container: true,
                        child: const SizedBox.square(
                          dimension: 50,
                          child: ColoredBox(color: Color(0xFFEEEEEE)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, hasLength(1));
      expect(
        result.violations.first.reason,
        contains('Expected non-text control contrast ratio of at least 3.0'),
      );
      handle.dispose();
    });

    testWidgets('reports violations from both low-contrast ancestor and child controls', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: Center(
              child: Semantics(
                onTap: () {},
                container: true,
                explicitChildNodes: true,
                child: SizedBox.square(
                  dimension: 100,
                  child: ColoredBox(
                    color: const Color(0xFFEEEEEE),
                    child: Center(
                      child: Semantics(
                        button: true,
                        container: true,
                        child: const SizedBox.square(
                          dimension: 40,
                          child: ColoredBox(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, hasLength(2));
      expect(result.violations.map((Violation v) => v.node.flagsCollection.isButton), <bool>[
        true,
        false,
      ]);
      handle.dispose();
    });

    testWidgets('respects custom shouldSkipNode, minContrastRatio, and isNodeOffScreen', (
      WidgetTester tester,
    ) async {
      final customEvaluation = MinimumNonTextContrastEvaluation(
        minContrastRatio: 5.0,
        shouldSkipNode: (SemanticsNode node) =>
            MinimumNonTextContrastEvaluation.defaultShouldSkipNode(node) ||
            node.tooltip == 'exempt',
        isNodeOffScreen: (Rect paintBounds, FlutterView window) => false,
      );
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        TestWidgetsApp(
          home: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  top: 10,
                  left: 10,
                  child: Semantics(
                    button: true,
                    container: true,
                    tooltip: 'exempt',
                    child: const SizedBox.square(
                      dimension: 50,
                      child: ColoredBox(color: Color(0xFFEEEEEE)),
                    ),
                  ),
                ),
                Positioned(
                  top: 80,
                  left: 10,
                  child: Semantics(
                    button: true,
                    container: true,
                    tooltip: 'medium',
                    child: const SizedBox.square(
                      dimension: 50,
                      child: ColoredBox(color: Color(0xFF767676)),
                    ),
                  ),
                ),
                Positioned(
                  top: 150,
                  left: -60,
                  child: Semantics(
                    button: true,
                    container: true,
                    tooltip: 'offscreen',
                    child: const SizedBox(
                      width: 120,
                      height: 50,
                      child: ColoredBox(color: Color(0xFFEEEEEE)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final EvaluationResult? defaultResult = await tester.runAsync<EvaluationResult>(() async {
        return evaluation.evaluate(tester.binding);
      });
      expect(defaultResult!.violations.map((Violation v) => v.node.tooltip), <String>['exempt']);

      final EvaluationResult? customResult = await tester.runAsync<EvaluationResult>(() async {
        return customEvaluation.evaluate(tester.binding);
      });
      expect(customResult!.violations.map((Violation v) => v.node.tooltip), <String>[
        'medium',
        'offscreen',
      ]);
      handle.dispose();
    });
  });

  group('TitleEvaluation', () {
    const evaluation = TitleEvaluation();

    testWidgets('passes if there is at least one title widget', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Title(title: 'Title', color: const Color(0xFF000000), child: const SizedBox()),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return await evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('passes if title widget is deeply nested (recursive check)', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: SizedBox(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Title(
                  title: 'Nested Title',
                  color: const Color(0xFF000000),
                  child: const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return await evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, isEmpty);
      handle.dispose();
    });

    testWidgets('fails if there is no title widget', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const Directionality(textDirection: TextDirection.ltr, child: SizedBox()),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return await evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, hasLength(1));
      expect(
        result.violations.first.reason,
        contains('Expected to find at least one Title widget, but none was found.'),
      );
      handle.dispose();
    });

    testWidgets('fails if title widget is missing in deeply nested tree', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: Text('No title here')),
            ),
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return await evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, hasLength(1));
      expect(
        result.violations.first.reason,
        contains('Expected to find at least one Title widget, but none was found.'),
      );
      handle.dispose();
    });
  });
}
