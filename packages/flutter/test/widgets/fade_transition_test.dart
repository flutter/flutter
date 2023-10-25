// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  testWidgetsWithLeakTracking('FadeTransition', (WidgetTester tester) async {
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
}
