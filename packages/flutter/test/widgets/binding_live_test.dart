// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// This file is for tests for WidgetsBinding that require a `LiveTestWidgetsFlutterBinding`.
void main() {
  LiveTestWidgetsFlutterBinding();
  testWidgets('ReportTiming callback records the sendFramesToEngine when it was scheduled', (WidgetTester tester) async {
    // This test needs LiveTestWidgetsFlutterBinding for multiple reasons.
    // First, this was the environment that this bug was discovered.
    // Second, LiveTestWidgetsFlutterBinding doesn't override
    // scheduleWarmUpFrame, so that the test can start with no frames rendered
    // allowing deferFirstFrame to work (see below).

    // At the beginning of a `testWidgets`, `TestWidgetsFlutterBinding` pumps a
    // fixed dummy widget using `runApp`, then `resetFirstFrameSent`. Although
    // the dummy widget is rendered, its reportTiming callback from the engine
    // has not arrived yet.
    //
    // Note that the `runApp` call also schedules a warm up frame, which would
    // have directly rendered the frame if the test had used
    // `AutomatedTestWidgetsFlutterBinding`.
    expect(tester.binding.sendFramesToEngine, true);
    // Push the widget with runApp instead of tester.pump, avoiding rendering a
    // frame, which is needed for `deferFirstFrame` later to work.
    runApp(const DummyWidget());
    // Ensure that no widget tree is built and nothing is rendered.
    expect(find.text('First frame'), findsNothing);
    // Defer the first frame, making sendFramesToEngine false, and widget tree
    // will be built but not sent to the engine.
    tester.binding.deferFirstFrame();
    expect(tester.binding.sendFramesToEngine, false);
    // Wait for the reportTiming callback (which completes the future below) to
    // run. If the reportTiming callback were to assume that
    // `sendFramesToEngine` is true, the callback would crash.
    await tester.binding.waitUntilFirstFrameRasterized;
    expect(find.text('First frame'), findsOne);
  });
}

class DummyWidget extends StatelessWidget {
  const DummyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Text('First frame'),
      ),
    );
  }
}
