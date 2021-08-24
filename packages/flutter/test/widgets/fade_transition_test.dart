// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FadeTransition', (WidgetTester tester) async {
    final DebugPrintCallback oldPrint = debugPrint;
    final List<String> log = <String>[];
    debugPrint = (String? message, { int? wrapWidth }) {
      log.add(message!);
    };
    debugPrintBuildScope = true;
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 2),
    );
    await tester.pumpWidget(FadeTransition(
      opacity: controller,
      child: const Placeholder(),
    ));
    expect(log, hasLength(2));
    expect(log.last, 'buildScope finished');
    await tester.pump();
    expect(log, hasLength(2));
    controller.forward();
    await tester.pumpAndSettle();
    expect(log, hasLength(2));
    debugPrint = oldPrint;
    debugPrintBuildScope = false;
  });

  testWidgets('alwaysPaintChild test', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/85944
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 2),
    );
    Widget buildFrame(Color color) {
      return FadeTransition(
        opacity: controller,
        alwaysPaintChild: true,
        child: Text(
          'I love Flutter!',
          textDirection: TextDirection.rtl,
          style: TextStyle(color: color),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(const Color(0x01010101)));
    // Changing color does not do trigger RenderParagraph layout
    await tester.pumpWidget(buildFrame(const Color(0x01010102)));

    await tester.tap(find.text('I love Flutter!'));
    // If the child RO do not be painted will throw during hit-test.
    expect(tester.takeException(), isNull);
  });

  testWidgets('alwaysPaintChild update test', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/85944
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 2),
    );
    Widget buildFrame(bool alwaysPaintChild) {
      return FadeTransition(
        opacity: controller,
        alwaysPaintChild: alwaysPaintChild,
        child: const Text(
            'I love Flutter!',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: Color(0x01010101))),
      );
    }

    await tester.pumpWidget(buildFrame(false));
    // This will trigger `markNeedsCompositingBitsUpdate` and the `paint()` will
    // check whether the `needsCompositing` updating properly.
    await tester.pumpWidget(buildFrame(true));
    expect(tester.takeException(), isNull);
  });
}
