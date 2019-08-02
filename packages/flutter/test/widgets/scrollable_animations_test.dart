// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

void main() {
  Widget boilerplate(ScrollController controller) {
    final List<Widget> listWidgets = <Widget>[];
    for (int i = 0; i < 80; i++)
      listWidgets.add(Text('$i', textDirection: TextDirection.ltr));
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ListView(
        children: listWidgets,
        controller: controller,
      ),
    );
  }

  testWidgets('Does not animate if already at target position', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(boilerplate(controller));

    expectNoAnimation();
    final double currentPosition = controller.position.pixels;
    controller.position.animateTo(currentPosition, duration: const Duration(seconds: 10), curve: Curves.linear);

    expectNoAnimation();
    expect(controller.position.pixels, currentPosition);
  });

  testWidgets('Does not animate if already at target position within tolerance', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(boilerplate(controller));

    expectNoAnimation();

    final double halfTolerance = controller.position.physics.tolerance.distance / 2;
    expect(halfTolerance, isNonZero);
    final double targetPosition = controller.position.pixels + halfTolerance;
    controller.position.animateTo(targetPosition, duration: const Duration(seconds: 10), curve: Curves.linear);

    expectNoAnimation();
    expect(controller.position.pixels, targetPosition);
  });

  testWidgets('Animates if going to a position outside of tolerance', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(boilerplate(controller));

    expectNoAnimation();

    final double doubleTolerance = controller.position.physics.tolerance.distance * 2;
    expect(doubleTolerance, isNonZero);
    final double targetPosition = controller.position.pixels + doubleTolerance;
    controller.position.animateTo(targetPosition, duration: const Duration(seconds: 10), curve: Curves.linear);

    expect(SchedulerBinding.instance.transientCallbackCount, equals(1), reason: 'Expected an animation.');
  });

  // Regression test for https://github.com/flutter/flutter/issues/14452
  testWidgets('Gesture interrupted by animation does not crash from errant idle notification', (WidgetTester tester) async {
    // This crash is more easily triggered using BouncingScrollPhysics
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final ScrollController controller = ScrollController();

    bool animateForIdle(ScrollNotification notification) {
      if (notification is UserScrollNotification && notification.direction == ScrollDirection.idle) {
        controller.position.animateTo(
          200.0,
          duration: const Duration(seconds: 10),
          curve: Curves.linear,
        );
      }
      return true;
    }

    await tester.pumpWidget(NotificationListener<ScrollNotification>(
      onNotification: animateForIdle,
      child: boilerplate(controller),
    ));

    expectNoAnimation();

    await tester.drag(find.byType(ListView), const Offset(0.0, 10.0));
    await tester.pump();
    await tester.press(find.byType(ListView));
    expect(tester.takeException(), null);
    debugDefaultTargetPlatformOverride = null;
  });
}

void expectNoAnimation() {
  expect(SchedulerBinding.instance.transientCallbackCount, equals(0), reason: 'Expected no animation.');
}
