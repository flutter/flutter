// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/progress_indicator/linear_progress_indicator.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Determinate and Indeterminate LinearProgressIndicators',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ProgressIndicatorExampleApp(),
    );

    expect(find.text('Determinate LinearProgressIndicator'), findsOneWidget);
    expect(find.text('Indeterminate LinearProgressIndicator'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));

    // Test determinate LinearProgressIndicator.
    LinearProgressIndicator determinateIndicator = tester.firstWidget(
      find.byType(LinearProgressIndicator).first,
    );
    expect(determinateIndicator.value, equals(0.0));

    // Advance the animation by 2 seconds.
    await tester.pump(const Duration(seconds: 2));
    determinateIndicator = tester.firstWidget(
      find.byType(LinearProgressIndicator).first,
    );
    expect(determinateIndicator.value, equals(0.4));

    // Test indeterminate LinearProgressIndicator.
    final LinearProgressIndicator indeterminateIndicator = tester.firstWidget(
      find.byType(LinearProgressIndicator).last,
    );
    expect(indeterminateIndicator.value, null);
  });
}
