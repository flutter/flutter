// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('overflow indicator is not shown when not overflowing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const UnconstrainedBox(
          child: const SizedBox(width: 200.0, height: 200.0),
        ),
      ),
    );

    expect(find.byType(UnconstrainedBox), isNot(paints..rect()));
  });

  testWidgets('overflow indicator is shown when overflowing', (WidgetTester tester) async {
    final UnconstrainedBox box = const UnconstrainedBox(
      child: const SizedBox(width: 200.0, height: 200.0),
    );
    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          height: 100.0,
          child: box,
        ),
      ),
    );

    expect(tester.takeException(), contains('A RenderUnconstrainedBox overflowed by'));
    expect(find.byType(UnconstrainedBox), paints..rect());

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          height: 100.0,
          child: box,
        ),
      ),
    );

    // Doesn't throw the exception a second time, because we didn't reset
    // overflowReportNeeded.
    expect(tester.takeException(), isNull);
    expect(find.byType(UnconstrainedBox), paints..rect());

    final RenderUnconstrainedBox boxRenderer = tester.renderObject(find.byType(UnconstrainedBox));
    expect(boxRenderer.overflowReportNeeded, false);
    expect(boxRenderer.overflowContainerRect, isNotNull);
    expect(boxRenderer.overflowContainerRect, equals(new ui.Rect.fromLTRB(0.0, 0.0, 200.0, 100.0)));
    expect(boxRenderer.overflowChildRect, equals(new ui.Rect.fromLTRB(0.0, -50.0, 200.0, 150.0)));
    expect(boxRenderer.overflow, equals(const RelativeRect.fromLTRB(0.0, 50.0, 0.0, 50.0)));
    expect(boxRenderer.isOverflowing, isTrue);
  });

  testWidgets('overflow indicator is not shown when constraint size is zero.', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const SizedBox(
          height: 0.0,
          child: const UnconstrainedBox(
            child: const SizedBox(width: 200.0, height: 200.0),
          ),
        ),
      ),
    );

    expect(find.byType(UnconstrainedBox), isNot(paints..rect()));
  });
}
