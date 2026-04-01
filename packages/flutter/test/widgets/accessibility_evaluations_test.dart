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
    late final Set<String> originalFeatureFlags;
    setUpAll(() {
      originalFeatureFlags = {...debugEnabledFeatureFlags};
      debugEnabledFeatureFlags.add('accessibility_evaluations');
    });
    tearDownAll(() {
      debugEnabledFeatureFlags.clear();
      debugEnabledFeatureFlags.addAll(originalFeatureFlags);
    });
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
        return await evaluation.evaluate(tester.binding);
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
        return await evaluation.evaluate(tester.binding);
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
        return await evaluation.evaluate(tester.binding);
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
        return await evaluation.evaluate(tester.binding);
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
        return await evaluation.evaluate(tester.binding);
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
        return await evaluation.evaluate(tester.binding);
      });
      expect(result!.violations, hasLength(1));
      expect(
        result.violations.first.reason,
        contains('Expected non-text control contrast ratio of at least 3.0'),
      );
      handle.dispose();
    });
  });

  group('TitleEvaluation', () {
    late final Set<String> originalFeatureFlags;
    setUpAll(() {
      originalFeatureFlags = <String>{...debugEnabledFeatureFlags};
      debugEnabledFeatureFlags.add('accessibility_evaluations');
    });
    tearDownAll(() {
      debugEnabledFeatureFlags.clear();
      debugEnabledFeatureFlags.addAll(originalFeatureFlags);
    });

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
