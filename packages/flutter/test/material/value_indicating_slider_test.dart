// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Slider value indicator', (final WidgetTester tester) async {
    await _buildValueIndicatorStaticSlider(
      tester,
      value: 0,
      useMaterial3: true,
    );

    await _pressStartThumb(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('slider_m3_start_text_scale_1_width_0.png'),
    );

    await _buildValueIndicatorStaticSlider(
      tester,
      value: 0.5,
      useMaterial3: true,
    );

    await _pressMiddleThumb(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('slider_m3_middle_text_scale_1_width_0.png'),
    );

    await _buildValueIndicatorStaticSlider(
      tester,
      value: 1,
      useMaterial3: true,
    );

    await _pressEndThumb(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('slider_m3_end_text_scale_1_width_0.png'),
    );
  });

  testWidgets('Slider value indicator wide text', (final WidgetTester tester) async {
    await _buildValueIndicatorStaticSlider(
      tester,
      value: 0,
      decimalCount: 5,
      useMaterial3: true,
    );

    await _pressStartThumb(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('slider_m3_start_text_scale_1_width_5.png'),
    );

    await _buildValueIndicatorStaticSlider(
      tester,
      value: 0.5,
      decimalCount: 5,
      useMaterial3: true,
    );

    await _pressMiddleThumb(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('slider_m3_middle_text_scale_1_width_5.png'),
    );

    await _buildValueIndicatorStaticSlider(
      tester,
      value: 1,
      decimalCount: 5,
      useMaterial3: true,
    );

    await _pressEndThumb(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('slider_m3_end_text_scale_1_width_5.png'),
    );
  });

  testWidgets('Slider value indicator large text scale', (final WidgetTester tester) async {
    await _buildValueIndicatorStaticSlider(
      tester,
      value: 0,
      textScale: 3,
      useMaterial3: true,
    );

    await _pressStartThumb(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('slider_m3_start_text_scale_4_width_0.png'),
    );

    await _buildValueIndicatorStaticSlider(
      tester,
      value: 0.5,
      textScale: 3,
      useMaterial3: true,
    );

    await _pressMiddleThumb(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('slider_m3_middle_text_scale_4_width_0.png'),
    );

    await _buildValueIndicatorStaticSlider(
      tester,
      value: 1,
      textScale: 3,
      useMaterial3: true,
    );

    await _pressEndThumb(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('slider_m3_end_text_scale_4_width_0.png'),
    );
  });

  testWidgets('Slider value indicator large text scale and wide text',
      (final WidgetTester tester) async {
    await _buildValueIndicatorStaticSlider(
      tester,
      value: 0,
      textScale: 3,
      decimalCount: 5,
      useMaterial3: true,
    );

    await _pressStartThumb(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('slider_m3_start_text_scale_4_width_5.png'),
    );

    await _buildValueIndicatorStaticSlider(
      tester,
      value: 0.5,
      textScale: 3,
      decimalCount: 5,
      useMaterial3: true,
    );

    await _pressMiddleThumb(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('slider_m3_middle_text_scale_4_width_5.png'),
    );

    await _buildValueIndicatorStaticSlider(
      tester,
      value: 1,
      textScale: 3,
      decimalCount: 5,
      useMaterial3: true,
    );

    await _pressEndThumb(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('slider_m3_end_text_scale_4_width_5.png'),
    );
  });

  group('Material 2', () {
    // Tests that are only relevant for Material 2. Once ThemeData.useMaterial3
    // is turned on by default, these tests can be removed.

    testWidgets('Slider value indicator', (final WidgetTester tester) async {
      await _buildValueIndicatorStaticSlider(
        tester,
        value: 0,
      );

      await _pressStartThumb(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('slider_start_text_scale_1_width_0.png'),
      );

      await _buildValueIndicatorStaticSlider(
        tester,
        value: 0.5,
      );

      await _pressMiddleThumb(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('slider_middle_text_scale_1_width_0.png'),
      );

      await _buildValueIndicatorStaticSlider(
        tester,
        value: 1,
      );

      await _pressEndThumb(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('slider_end_text_scale_1_width_0.png'),
      );
    });

    testWidgets('Slider value indicator wide text', (final WidgetTester tester) async {
      await _buildValueIndicatorStaticSlider(
        tester,
        value: 0,
        decimalCount: 5,
      );

      await _pressStartThumb(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('slider_start_text_scale_1_width_5.png'),
      );

      await _buildValueIndicatorStaticSlider(
        tester,
        value: 0.5,
        decimalCount: 5,
      );

      await _pressMiddleThumb(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('slider_middle_text_scale_1_width_5.png'),
      );

      await _buildValueIndicatorStaticSlider(
        tester,
        value: 1,
        decimalCount: 5,
      );

      await _pressEndThumb(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('slider_end_text_scale_1_width_5.png'),
      );
    });

    testWidgets('Slider value indicator large text scale', (final WidgetTester tester) async {
      await _buildValueIndicatorStaticSlider(
        tester,
        value: 0,
        textScale: 3,
      );

      await _pressStartThumb(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('slider_start_text_scale_4_width_0.png'),
      );

      await _buildValueIndicatorStaticSlider(
        tester,
        value: 0.5,
        textScale: 3,
      );

      await _pressMiddleThumb(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('slider_middle_text_scale_4_width_0.png'),
      );

      await _buildValueIndicatorStaticSlider(
        tester,
        value: 1,
        textScale: 3,
      );

      await _pressEndThumb(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('slider_end_text_scale_4_width_0.png'),
      );
    });

    testWidgets('Slider value indicator large text scale and wide text',
        (final WidgetTester tester) async {
      await _buildValueIndicatorStaticSlider(
        tester,
        value: 0,
        textScale: 3,
        decimalCount: 5,
      );

      await _pressStartThumb(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('slider_start_text_scale_4_width_5.png'),
      );

      await _buildValueIndicatorStaticSlider(
        tester,
        value: 0.5,
        textScale: 3,
        decimalCount: 5,
      );

      await _pressMiddleThumb(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('slider_middle_text_scale_4_width_5.png'),
      );

      await _buildValueIndicatorStaticSlider(
        tester,
        value: 1,
        textScale: 3,
        decimalCount: 5,
      );

      await _pressEndThumb(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('slider_end_text_scale_4_width_5.png'),
      );
    });
  });
}

Future<void> _pressStartThumb(final WidgetTester tester) async {
  final Offset bottomLeft = tester.getBottomLeft(find.byType(Slider));
  final Offset topLeft = tester.getTopLeft(find.byType(Slider));
  final Offset left = (bottomLeft + topLeft) / 2;
  final Offset start = left + const Offset(24, 0);
  await tester.startGesture(start);
  await tester.pumpAndSettle();
}

Future<void> _pressMiddleThumb(final WidgetTester tester) async {
  await tester.press(find.byType(Slider));
  await tester.pumpAndSettle();
}

Future<void> _pressEndThumb(final WidgetTester tester) async {
  final Offset bottomRight = tester.getBottomRight(find.byType(Slider));
  final Offset topRight = tester.getTopRight(find.byType(Slider));
  final Offset right = (bottomRight + topRight) / 2;
  final Offset start = right - const Offset(24, 0);
  await tester.startGesture(start);
  await tester.pumpAndSettle();
}

Future<void> _buildValueIndicatorStaticSlider(
  final WidgetTester tester, {
  required final double value,
  final double textScale = 1.0,
  final int decimalCount = 0,
  final bool useMaterial3 = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: useMaterial3),
      home: Scaffold(
        body: Builder(
          builder: (final BuildContext context) {
            return Center(
              child: MediaQuery(
                data: MediaQueryData(textScaleFactor: textScale),
                child: SliderTheme(
                  data: Theme.of(context).sliderTheme.copyWith(
                    showValueIndicator: ShowValueIndicator.always,
                  ),
                  child: Slider(
                    value: value,
                    label: value.toStringAsFixed(decimalCount),
                    onChanged: (final double newValue) {},
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
