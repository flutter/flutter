// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('overflow indicator is not shown when not overflowing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: UnconstrainedBox(
          child: SizedBox(width: 200.0, height: 200.0),
        ),
      ),
    );

    expect(find.byType(UnconstrainedBox), isNot(paints..rect()));
  });

  testWidgets('overflow indicator is shown when overflowing', (WidgetTester tester) async {
    const UnconstrainedBox box = UnconstrainedBox(
      child: SizedBox(width: 200.0, height: 200.0),
    );
    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          height: 100.0,
          child: box,
        ),
      ),
    );

    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(exception.diagnostics.first.level, DiagnosticLevel.summary);
    expect(exception.diagnostics.first.toString(), startsWith('A RenderUnconstrainedBox overflowed by '));
    expect(find.byType(UnconstrainedBox), paints..rect());

    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          height: 100.0,
          child: box,
        ),
      ),
    );

    // Doesn't throw the exception a second time, because we didn't reset
    // overflowReportNeeded.
    expect(tester.takeException(), isNull);
    expect(find.byType(UnconstrainedBox), paints..rect());
  });

  testWidgets('overflow indicator is not shown when constraint size is zero.', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          height: 0.0,
          child: UnconstrainedBox(
            child: SizedBox(width: 200.0, height: 200.0),
          ),
        ),
      ),
    );

    expect(find.byType(UnconstrainedBox), isNot(paints..rect()));
  });
}
