// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // `StretchingOverscrollIndicator` uses a different algorithm when
  // shader is available, therefore the tests must be different depending
  // on shader support.
  final bool shaderSupported = ui.ImageFilter.isShaderFilterSupported;
  final bool shaderStretchEnabled = StretchEffect.useShaderStretchEffect;

  testWidgets('Stretch effect uses translation when shader stretch is disabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: 100,
          width: 100,
          child: StretchEffect(
            stretchStrength: 0.5,
            axis: Axis.vertical,
            child: SizedBox(height: 50, width: 50),
          ),
        ),
      ),
    );

    expect(find.byType(Transform), findsOneWidget);
    final Transform transform = tester.widget<Transform>(find.byType(Transform));
    final Matrix4 matrix = transform.transform!;
    expect(matrix.entry(0, 0), 1.0);
    expect(matrix.entry(1, 1), 1.0);
    expect(matrix.entry(0, 3), 0.0);
    final double layoutExtent = tester.getSize(find.byType(LayoutBuilder)).height;
    expect(
      matrix.entry(1, 3),
      0.5 * layoutExtent * StretchEffect.maxTransformTranslationFraction,
    );
    expect(find.byType(ImageFiltered), findsNothing);
  });

  testWidgets(
    'Stretch effect covers full viewport',
    (WidgetTester tester) async {
      // This test verifies that when the stretch effect is applied to a scrollable widget,
      // it should cover the entire scrollable area (e.g., full height of the scroll view),
      // even if the actual content inside has a smaller height.
      //
      // Without this behavior, the shader is clipped only to the content area,
      // causing the stretch effect to render incorrectly or be invisible
      // when the content doesn't fill the scroll view.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StretchEffect(
            stretchStrength: 1,
            axis: Axis.vertical,
            child: Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                Container(height: 100),
                Container(height: 50, color: const Color.fromRGBO(255, 0, 0, 1)),
              ],
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(StretchEffect),
        matchesGoldenFile('stretch_effect_covers_full_viewport.png'),
      );
    },
    // Skips this test when fragment shaders are not used for stretch.
    skip: !shaderSupported || !shaderStretchEnabled,
  );
}
