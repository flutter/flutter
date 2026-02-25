// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/src/foundation/_features.dart';
import 'package:flutter/src/widgets/_accessibility_evaluations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets_app_tester.dart';

void main() {
  group('MinimumTapTargetEvaluation', () {
    late final Set<String> originalFeatureFlags;
    setUpAll(() {
      originalFeatureFlags = {...debugEnabledFeatureFlags};
      debugEnabledFeatureFlags.add('accessibility_evaluations');
    });
    tearDownAll(() {
      debugEnabledFeatureFlags.clear();
      debugEnabledFeatureFlags.addAll(originalFeatureFlags);
    });

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
  });

  group('LabeledTapTargetEvaluation', () {
    late final Set<String> originalFeatureFlags;
    setUpAll(() {
      originalFeatureFlags = {...debugEnabledFeatureFlags};
      debugEnabledFeatureFlags.add('accessibility_evaluations');
    });
    tearDownAll(() {
      debugEnabledFeatureFlags.clear();
      debugEnabledFeatureFlags.addAll(originalFeatureFlags);
    });
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
    late final Set<String> originalFeatureFlags;
    setUpAll(() {
      originalFeatureFlags = {...debugEnabledFeatureFlags};
      debugEnabledFeatureFlags.add('accessibility_evaluations');
    });
    tearDownAll(() {
      debugEnabledFeatureFlags.clear();
      debugEnabledFeatureFlags.addAll(originalFeatureFlags);
    });
    const evaluation = MinimumTextContrastEvaluation(
      minNormalTextContrastRatio: 4.5,
      minLargeTextContrastRatio: 3.0,
    );

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
        return await evaluation.evaluate(tester.binding);
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
        return await evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, hasLength(1));
      expect(result.violations.first.reason, contains('Expected contrast ratio of at least 4.5'));
      handle.dispose();
    });
  });

  group('UnlabeledLeafNodeEvaluation', () {
    late final Set<String> originalFeatureFlags;
    setUpAll(() {
      originalFeatureFlags = {...debugEnabledFeatureFlags};
      debugEnabledFeatureFlags.add('accessibility_evaluations');
    });
    tearDownAll(() {
      debugEnabledFeatureFlags.clear();
      debugEnabledFeatureFlags.addAll(originalFeatureFlags);
    });

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
          home: Semantics(container: true, child: const SizedBox(width: 10.0, height: 10.0)),
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

    testWidgets('Passes if node is not a leaf', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Semantics(
            container: true,
            child: Column(
              children: <Widget>[
                Semantics(label: 'Child 1', child: const SizedBox(width: 10, height: 10)),
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
                Semantics(label: 'Child 1', child: const SizedBox(width: 10, height: 10)),
              ],
            ),
          ),
        ),
      );
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      expect(result.violations, isEmpty); // Should pass (merged node has label from child)
      handle.dispose();
    });

    testWidgets('Fails if node merges descendants but has no label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: MergeSemantics(
            child: Semantics(container: true, child: const SizedBox(width: 10, height: 10)),
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
}
