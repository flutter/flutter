// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  testWidgets('$TabController dispatches creation in constructor.', (
    WidgetTester widgetTester,
  ) async {
    await expectLater(
      await memoryEvents(
        () async => TabController(length: 1, vsync: const TestVSync()).dispose(),
        TabController,
      ),
      areCreateAndDispose,
    );
  });

  testWidgets('$TabController exposes the selected index change timing.', (
    WidgetTester widgetTester,
  ) async {
    const animationDuration = Duration(milliseconds: 100);
    const customDuration = Duration(seconds: 2);
    final controller = TabController(
      length: 3,
      animationDuration: animationDuration,
      vsync: widgetTester,
    );

    expect(controller.indexChangeDuration, animationDuration);
    expect(controller.indexChangeCurve, Curves.ease);

    controller.animateTo(1, duration: customDuration, curve: Curves.linear);

    expect(controller.indexChangeDuration, customDuration);
    expect(controller.indexChangeCurve, Curves.linear);
    await widgetTester.pump(customDuration);

    controller.animateTo(2);

    expect(controller.indexChangeDuration, animationDuration);
    expect(controller.indexChangeCurve, Curves.ease);
    await widgetTester.pump(animationDuration);

    controller.index = 0;

    expect(controller.indexChangeDuration, animationDuration);
    expect(controller.indexChangeCurve, Curves.ease);

    controller.dispose();
  });
}
