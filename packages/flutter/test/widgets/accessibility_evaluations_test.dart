// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/widgets/_accessibility_evaluations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  group('UnlabeledImageEvaluation', () {
    const evaluation = UnlabeledImageEvaluation();

    Future<List<Violation>> evaluate(WidgetTester tester, Widget home) async {
      await tester.pumpWidget(TestWidgetsApp(home: home));
      final EvaluationResult result = await evaluation.evaluate(tester.binding);
      return result.violations;
    }

    Widget image({String label = '', String value = '', String hint = '', String tooltip = ''}) {
      return Semantics(
        container: true,
        image: true,
        label: label,
        value: value,
        hint: hint,
        tooltip: tooltip,
        child: const SizedBox.square(dimension: 10.0),
      );
    }

    testWidgets('passes if image has label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      expect(await evaluate(tester, image(label: 'A cat')), isEmpty);
      handle.dispose();
    });

    testWidgets('passes if image has only a value', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      expect(await evaluate(tester, image(value: '50%')), isEmpty);
      handle.dispose();
    });

    testWidgets('passes if image has only a hint', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      expect(await evaluate(tester, image(hint: 'A cat')), isEmpty);
      handle.dispose();
    });

    testWidgets('passes if image has only a tooltip', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      expect(await evaluate(tester, image(tooltip: 'A cat')), isEmpty);
      handle.dispose();
    });

    testWidgets('fails if image has no label, value, hint, or tooltip', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<Violation> violations = await evaluate(tester, image());
      expect(violations, hasLength(1));
      expect(
        violations.first.reason,
        contains(
          'expected image node to have a label, value, hint, or tooltip, but none was found.',
        ),
      );
      handle.dispose();
    });

    testWidgets('fails if image label is only whitespace', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      expect(await evaluate(tester, image(label: '   ')), hasLength(1));
      handle.dispose();
    });

    testWidgets('fails for Image with empty semanticLabel', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<Violation> violations = await evaluate(
        tester,
        Image(image: _TestImageProvider(), semanticLabel: ''),
      );
      expect(violations, hasLength(1));
      expect(violations.first.node.getSemanticsData().flagsCollection.isImage, isTrue);
      handle.dispose();
    });

    testWidgets('fails for FadeInImage with empty imageSemanticLabel', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<Violation> violations = await evaluate(
        tester,
        FadeInImage(
          placeholder: _TestImageProvider(),
          image: _TestImageProvider(),
          imageSemanticLabel: '',
        ),
      );
      expect(violations, hasLength(1));
      handle.dispose();
    });

    testWidgets('skips Image excluded from semantics', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      expect(
        await evaluate(tester, Image(image: _TestImageProvider(), excludeFromSemantics: true)),
        isEmpty,
      );
      handle.dispose();
    });

    testWidgets('skips hidden nodes', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<Violation> violations = await evaluate(
        tester,
        Semantics(
          container: true,
          image: true,
          hidden: true,
          child: const SizedBox.square(dimension: 10.0),
        ),
      );
      expect(violations, isEmpty);
      handle.dispose();
    });

    testWidgets('skips tappable images', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<Violation> violations = await evaluate(
        tester,
        Semantics(
          container: true,
          image: true,
          onTap: () {},
          child: const SizedBox.square(dimension: 10.0),
        ),
      );
      expect(violations, isEmpty);
      handle.dispose();
    });

    testWidgets('skips buttons', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<Violation> violations = await evaluate(
        tester,
        Semantics(
          container: true,
          image: true,
          button: true,
          child: const SizedBox.square(dimension: 10.0),
        ),
      );
      expect(violations, isEmpty);
      handle.dispose();
    });

    testWidgets('reports each unlabeled image node', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<Violation> violations = await evaluate(
        tester,
        Semantics(container: true, child: Column(children: <Widget>[image(), image()])),
      );
      expect(violations, hasLength(2));
      handle.dispose();
    });

    testWidgets('reports merged images once', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<Violation> violations = await evaluate(
        tester,
        MergeSemantics(child: Column(children: <Widget>[image(), image()])),
      );
      expect(violations, hasLength(1));
      handle.dispose();
    });

    testWidgets('passes for Image absorbed into a labeled container', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // The Image has no node of its own, so the container's label counts for it.
      final List<Violation> violations = await evaluate(
        tester,
        Semantics(
          container: true,
          label: 'Profile',
          child: Image(image: _TestImageProvider()),
        ),
      );
      expect(violations, isEmpty);
      handle.dispose();
    });
  });
}

class _TestImageProvider extends ImageProvider<Object> {
  @override
  Future<Object> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_TestImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(Object key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
  }
}
