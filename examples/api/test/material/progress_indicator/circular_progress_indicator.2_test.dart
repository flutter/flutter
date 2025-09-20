// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/progress_indicator/circular_progress_indicator.2.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Buttons work', (WidgetTester tester) async {
    await tester.pumpWidget(const example.ProgressIndicatorExampleApp());

    expect(find.byType(CircularProgressIndicator), findsOne);

    await tester.tap(find.text('More indicators'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

    await tester.tap(find.text('More indicators'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNWidgets(3));

    await tester.tap(find.text('Fewer indicators'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

    expect(find.text('Theme controller? Yes'), findsOne);
    await tester.tap(find.text('Toggle'));
    await tester.pump();
    expect(find.text('Theme controller? No'), findsOne);
  });

  testWidgets('Theme controller can coordinate progress', (WidgetTester tester) async {
    final AnimationController controller = AnimationController(vsync: tester, value: 0.5);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      Theme(
        data: ThemeData(progressIndicatorTheme: ProgressIndicatorThemeData(controller: controller)),
        child: const example.ManyProgressIndicators(indicatorNum: 4),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsNWidgets(4));
    for (int i = 0; i < 4; i++) {
      expect(
        find.byType(CircularProgressIndicator).at(i),
        paints..arc(startAngle: 1.5707963267948966, sweepAngle: 0.001),
      );
    }
  });
}
