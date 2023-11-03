// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  testWidgetsWithLeakTracking('Placeholder intrinsics', (WidgetTester tester) async {
    await tester.pumpWidget(const Placeholder());
    expect(tester.renderObject<RenderBox>(find.byType(Placeholder)).getMinIntrinsicWidth(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(Placeholder)).getMaxIntrinsicWidth(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(Placeholder)).getMinIntrinsicHeight(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(Placeholder)).getMaxIntrinsicHeight(double.infinity), 0.0);
  });

  testWidgetsWithLeakTracking('ConstrainedBox intrinsics - minHeight', (WidgetTester tester) async {
    await tester.pumpWidget(
      ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 20.0,
        ),
        child: const Placeholder(),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicWidth(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicWidth(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicHeight(double.infinity), 20.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicHeight(double.infinity), 20.0);
  });

  testWidgetsWithLeakTracking('ConstrainedBox intrinsics - minWidth', (WidgetTester tester) async {
    await tester.pumpWidget(
      ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 20.0,
        ),
        child: const Placeholder(),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicWidth(double.infinity), 20.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicWidth(double.infinity), 20.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicHeight(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicHeight(double.infinity), 0.0);
  });

  testWidgetsWithLeakTracking('ConstrainedBox intrinsics - maxHeight', (WidgetTester tester) async {
    await tester.pumpWidget(
      ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 20.0,
        ),
        child: const Placeholder(),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicWidth(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicWidth(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicHeight(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicHeight(double.infinity), 0.0);
  });

  testWidgetsWithLeakTracking('ConstrainedBox intrinsics - maxWidth', (WidgetTester tester) async {
    await tester.pumpWidget(
      ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 20.0,
        ),
        child: const Placeholder(),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicWidth(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicWidth(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicHeight(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicHeight(double.infinity), 0.0);
  });

  testWidgetsWithLeakTracking('ConstrainedBox intrinsics - tight', (WidgetTester tester) async {
    await tester.pumpWidget(
      ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 10.0, height: 30.0),
        child: const Placeholder(),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicWidth(double.infinity), 10.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicWidth(double.infinity), 10.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicHeight(double.infinity), 30.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicHeight(double.infinity), 30.0);
  });


  testWidgetsWithLeakTracking('ConstrainedBox intrinsics - minHeight - with infinite width', (WidgetTester tester) async {
    await tester.pumpWidget(
      ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: double.infinity,
          minHeight: 20.0,
        ),
        child: const Placeholder(),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicWidth(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicWidth(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicHeight(double.infinity), 20.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicHeight(double.infinity), 20.0);
  });

  testWidgetsWithLeakTracking('ConstrainedBox intrinsics - minWidth - with infinite height', (WidgetTester tester) async {
    await tester.pumpWidget(
      ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 20.0,
          minHeight: double.infinity,
        ),
        child: const Placeholder(),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicWidth(double.infinity), 20.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicWidth(double.infinity), 20.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicHeight(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicHeight(double.infinity), 0.0);
  });

  testWidgetsWithLeakTracking('ConstrainedBox intrinsics - infinite', (WidgetTester tester) async {
    await tester.pumpWidget(
      ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: double.infinity, height: double.infinity),
        child: const Placeholder(),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicWidth(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicWidth(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMinIntrinsicHeight(double.infinity), 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(ConstrainedBox)).getMaxIntrinsicHeight(double.infinity), 0.0);
  });

  testWidgets('RenderConstrainedBox returning widget constrains dimension passed to get intrinsic dimension', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/137546

    const Key key = Key('widget');

    await tester.pumpWidget(
     Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: IntrinsicHeight(
            key: key,
            child: SizedBox(
              width: 100,
              child: Wrap(
                children: List<Widget>.filled(5, const SizedBox(width: 50, height: 10)),
              ),
            ),
          ),
        ),
     ),
    );

    final RenderBox renderBox = tester.renderObject<RenderBox>(find.byKey(key));

    // Rectangles 50x10 will fit in a 100x100 square with intrinsic height like that:
    // +----------+
    // |<===><===>|
    // |<===><===>|
    // |<===>     |
    // +----------+
    expect(renderBox.size, const Size(100, 30));
  });
}
