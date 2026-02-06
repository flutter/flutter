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

    const evaluation = MinimumTapTargetEvaluation(size: Size(48.0, 48.0), link: 'link');

    testWidgets('passes for valid targets', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: SizedBox(
            width: 48.0,
            height: 48.0,
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
            child: SizedBox(
              width: 40.0,
              height: 40.0,
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
          home: SizedBox(
            width: 40.0,
            height: 40.0,
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
          home: SizedBox(
            width: 48.0,
            height: 48.0,
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
    const evaluation = MinimumTextContrastEvaluation();

    testWidgets('passes for high contrast', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const TestWidgetsApp(
          home: SizedBox(
            width: 100,
            height: 100,
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
          home: SizedBox(
            width: 100,
            height: 100,
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

  group('MinimumTextContrastEvaluationAAA', () {
    late final Set<String> originalFeatureFlags;
    setUpAll(() {
      originalFeatureFlags = {...debugEnabledFeatureFlags};
      debugEnabledFeatureFlags.add('accessibility_evaluations');
    });
    tearDownAll(() {
      debugEnabledFeatureFlags.clear();
      debugEnabledFeatureFlags.addAll(originalFeatureFlags);
    });
    const evaluation = MinimumTextContrastEvaluationAAA();

    testWidgets('passes for very high contrast', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const TestWidgetsApp(
          home: SizedBox(
            width: 100,
            height: 100,
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

    testWidgets('fails for normal contrast (AA but not AAA)', (WidgetTester tester) async {
      // Gray on white: 0xFF777777 on 0xFFFFFFFF
      // Contrast is ~4.5:1 which passes AA but fails AAA (needs 7:1)
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const TestWidgetsApp(
          home: SizedBox(
            width: 100,
            height: 100,
            child: ColoredBox(
              color: Color(0xFFFFFFFF),
              child: Center(
                child: Text('test', style: TextStyle(color: Color(0xFF767676), fontSize: 14)),
              ),
            ),
          ),
        ),
      );
      final EvaluationResult? result = await tester.runAsync<EvaluationResult>(() async {
        return await evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, isNotEmpty);
      expect(result.violations.first.reason, contains('Expected contrast ratio of at least 7'));
      handle.dispose();
    });
  });
}
