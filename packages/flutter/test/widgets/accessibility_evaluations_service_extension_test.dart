// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/foundation/_features.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets_app_tester.dart';

class AccessibilityEvaluationTestBinding extends AutomatedTestWidgetsFlutterBinding {
  static AccessibilityEvaluationTestBinding? _instance;

  static AccessibilityEvaluationTestBinding ensureInitialized() {
    return _instance ??= AccessibilityEvaluationTestBinding();
  }

  final Map<String, ServiceExtensionCallback> extensions = .new();

  @override
  @protected
  void registerServiceExtension({
    required String name,
    required ServiceExtensionCallback callback,
  }) {
    extensions[name] = callback;
    super.registerServiceExtension(name: name, callback: callback);
  }

  Future<Map<String, Object?>> testExtension(String name, Map<String, String> arguments) async {
    if (!extensions.containsKey(name)) {
      throw StateError('Extension $name not found');
    }
    return (await extensions[name]!(arguments)).cast<String, Object?>();
  }
}

void main() {
  AccessibilityEvaluationTestBinding.ensureInitialized();

  late final Set<String> originalFeatureFlags;
  setUpAll(() {
    originalFeatureFlags = <String>{...debugEnabledFeatureFlags};
    debugEnabledFeatureFlags.add('accessibility_evaluations');
  });

  tearDownAll(() {
    debugEnabledFeatureFlags.clear();
    debugEnabledFeatureFlags.addAll(originalFeatureFlags);
  });

  testWidgets(
    'accessibilityEvaluations service extension returns violations for MinimumTapTargetEvaluation',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      // Pump a widget with a small tap target
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Center(
            child: SizedBox.square(
              dimension: 40.0,
              child: Semantics(label: 'small button', onTap: () {}),
            ),
          ),
        ),
      );

      // Run MinimumTapTargetEvaluation
      final Map<String, Object?> tapTargetResult = await _runEvaluation(tester, <String, String>{
        'type': 'MinimumTapTargetEvaluation',
        'targetSize': '48.0',
      });

      expect(tapTargetResult, contains('result'));
      final tapTargetViolations = tapTargetResult['result']! as List<Object?>;
      expect(tapTargetViolations, isNotEmpty);
      expect(
        tapTargetViolations.any(
          (Object? v) => (v! as Map<String, Object?>)['message'].toString().contains(
            'expected tap target size',
          ),
        ),
        isTrue,
      );

      handle.dispose();
    },
  );

  testWidgets(
    'accessibilityEvaluations service extension returns violations for LabeledTapTargetEvaluation',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      // Pump a widget with an unlabeled button
      await tester.pumpWidget(
        TestWidgetsApp(
          home: Center(
            child: SizedBox.square(dimension: 48.0, child: Semantics(onTap: () {})),
          ),
        ),
      );

      // Run LabeledTapTargetEvaluation
      final Map<String, Object?> labeledResult = await _runEvaluation(tester, <String, String>{
        'type': 'LabeledTapTargetEvaluation',
      });

      expect(labeledResult.keys, contains('result'));
      final labeledViolations = labeledResult['result']! as List<Object?>;
      expect(labeledViolations, isNotEmpty);
      expect(
        labeledViolations.any(
          (Object? v) => (v! as Map<String, Object?>)['message'].toString().contains(
            'expected tappable node to have semantic label',
          ),
        ),
        isTrue,
      );

      handle.dispose();
    },
  );

  testWidgets(
    'accessibilityEvaluations service extension returns violations for MinimumTextContrastEvaluation',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      // Pump a widget with low contrast text
      await tester.pumpWidget(
        const TestWidgetsApp(
          home: ColoredBox(
            color: Color(0xFFFFFFFF),
            child: Center(
              child: SizedBox.square(
                dimension: 100,
                child: Center(
                  child: Text(
                    'low contrast',
                    style: TextStyle(color: Color(0xFFEEEEEE), fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Run MinimumTextContrastEvaluation
      final Map<String, Object?> contrastResult = await _runEvaluation(tester, <String, String>{
        'type': 'MinimumTextContrastEvaluation',
        'minNormalTextContrastRatio': '4.5',
        'minLargeTextContrastRatio': '3.0',
      });

      expect(contrastResult.keys, contains('result'));
      final contrastViolations = contrastResult['result']! as List<Object?>;
      expect(contrastViolations, isNotEmpty);
      expect(
        contrastViolations.any(
          (Object? v) => (v! as Map<String, Object?>)['message'].toString().contains(
            'Expected contrast ratio',
          ),
        ),
        isTrue,
      );

      handle.dispose();
    },
  );

  testWidgets('accessibilityEvaluations service extension returns empty lists when no violations', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    // Pump a widget with NO violations
    await tester.pumpWidget(
      TestWidgetsApp(
        home: Center(
          child: SizedBox.square(
            dimension: 48.0,
            child: Semantics(label: 'valid button', onTap: () {}),
          ),
        ),
      ),
    );

    // Run MinimumTapTargetEvaluation
    final Map<String, Object?> tapTargetResult = await _runEvaluation(tester, <String, String>{
      'type': 'MinimumTapTargetEvaluation',
      'targetSize': '48.0',
    });
    expect(tapTargetResult['result'], isEmpty);

    // Run LabeledTapTargetEvaluation
    final Map<String, Object?> labeledResult = await _runEvaluation(tester, <String, String>{
      'type': 'LabeledTapTargetEvaluation',
    });
    expect(labeledResult['result'], isEmpty);

    // Run MinimumTextContrastEvaluation
    final Map<String, Object?> contrastResult = await _runEvaluation(tester, <String, String>{
      'type': 'MinimumTextContrastEvaluation',
      'minNormalTextContrastRatio': '4.5',
      'minLargeTextContrastRatio': '3.0',
    });
    expect(contrastResult['result'], isEmpty);

    handle.dispose();
  });

  testWidgets('accessibilityEvaluations service extension honors targetSize parameter', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    // Pump a widget that satisfies the default Android size (48x48) but not a larger custom size (e.g., 50x50)
    await tester.pumpWidget(
      TestWidgetsApp(
        home: Center(
          child: SizedBox.square(
            dimension: 48.0,
            child: Semantics(label: 'button', onTap: () {}),
          ),
        ),
      ),
    );

    // Run MinimumTapTargetEvaluation with default size - should pass (no violations)
    final Map<String, Object?> defaultResult = await _runEvaluation(tester, <String, String>{
      'type': 'MinimumTapTargetEvaluation',
      'targetSize': '48.0',
    });

    expect(defaultResult['result'], isEmpty);

    // Run MinimumTapTargetEvaluation with custom size 50 - should fail (violations)
    final Map<String, Object?> customResult = await _runEvaluation(tester, <String, String>{
      'type': 'MinimumTapTargetEvaluation',
      'targetSize': '50.0',
    });

    expect(customResult['result'], isNotEmpty);
    final List<Map<String, Object?>> violations = (customResult['result']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(
      violations[0]['message'].toString(),
      contains('expected tap target size of at least Size(50.0, 50.0)'),
    );

    handle.dispose();
  });

  testWidgets('accessibilityEvaluations service extension returns error when type is missing', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _pumpTestWidget(tester);

    expect(
      () async {
        await _runEvaluation(tester, <String, String>{});
      },
      throwsA(
        isA<Exception>().having(
          (Exception e) => e.toString(),
          'message',
          contains('type parameter is required'),
        ),
      ),
    );

    handle.dispose();
  });

  testWidgets('accessibilityEvaluations service extension returns error when type is unknown', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _pumpTestWidget(tester);

    expect(
      () async {
        await _runEvaluation(tester, <String, String>{'type': 'UnknownType'});
      },
      throwsA(
        isA<Exception>().having(
          (Exception e) => e.toString(),
          'message',
          contains('unknown type: UnknownType'),
        ),
      ),
    );

    handle.dispose();
  });

  testWidgets(
    'accessibilityEvaluations service extension returns error when MinimumTextContrastEvaluation params are missing',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpTestWidget(tester);

      expect(
        () async {
          await _runEvaluation(tester, <String, String>{'type': 'MinimumTextContrastEvaluation'});
        },
        throwsA(
          isA<Exception>().having(
            (Exception e) => e.toString(),
            'message',
            contains('Invalid arguments'),
          ),
        ),
      );

      handle.dispose();
    },
  );

  testWidgets(
    'accessibilityEvaluations service extension returns error when MinimumTextContrastEvaluation params are malformed',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpTestWidget(tester);

      expect(() async {
        await _runEvaluation(tester, <String, String>{
          'type': 'MinimumTextContrastEvaluation',
          'minNormalTextContrastRatio': 'foo',
          'minLargeTextContrastRatio': '3.0',
        });
      }, throwsA(isA<FormatException>()));

      handle.dispose();
    },
  );

  testWidgets(
    'accessibilityEvaluations service extension returns error when MinimumTapTargetEvaluation targetSize is missing',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpTestWidget(tester);

      expect(
        () async {
          await _runEvaluation(tester, <String, String>{'type': 'MinimumTapTargetEvaluation'});
        },
        throwsA(
          isA<Exception>().having(
            (Exception e) => e.toString(),
            'message',
            contains('Invalid arguments'),
          ),
        ),
      );

      handle.dispose();
    },
  );

  testWidgets(
    'accessibilityEvaluations service extension returns error when MinimumTapTargetEvaluation targetSize is malformed',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpTestWidget(tester);

      expect(() async {
        await _runEvaluation(tester, <String, String>{
          'type': 'MinimumTapTargetEvaluation',
          'targetSize': 'foo',
        });
      }, throwsA(isA<FormatException>()));

      handle.dispose();
    },
  );
}

Future<void> _pumpTestWidget(WidgetTester tester) async {
  await tester.pumpWidget(
    TestWidgetsApp(
      home: Center(
        child: SizedBox.square(
          dimension: 48.0,
          child: Semantics(label: 'button', onTap: () {}),
        ),
      ),
    ),
  );
}

Future<Map<String, Object?>> _runEvaluation(WidgetTester tester, Map<String, String> params) async {
  Object? error;
  final Map<String, Object?>? result = await tester.runAsync<Map<String, Object?>?>(() async {
    try {
      final binding = tester.binding as AccessibilityEvaluationTestBinding;
      return await binding.testExtension('accessibilityEvaluations', params);
    } catch (e) {
      error = e;
      return null;
    }
  });
  if (error != null) {
    throw error!;
  }
  return result ?? <String, Object?>{};
}
