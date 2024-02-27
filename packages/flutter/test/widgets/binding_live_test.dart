// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// This file is for tests for WidgetsBinding that require a `LiveTestWidgetsFlutterBinding`
void main() {
  LiveTestWidgetsFlutterBinding();
  testWidgets('ReportTiming callback records the sendFramesToEngine when it was scheduled', (WidgetTester tester) async {
    // At the beginning of a `testWidgets`, `TestWidgetsFlutterBinding` pumps a
    // fixed dummy widget, then `resetFirstFrameSent`. Although the dummy widget
    // is rendered, its reportTiming callback from the engine has not arrived
    // yet.
    expect(tester.binding.sendFramesToEngine, true);

    // Push the widget with runApp instead of tester.pump, avoiding rendering a
    // frame is rendered, which is needed for `deferFirstFrame` later to work.
    runApp(const DummyWidget());
    // Ensure that no widget tree is built and nothing is rendered.
    expect(find.text('First frame'), findsNothing);
    // Defer the first frame, making sendFramesToEngine false, and widget tree
    // will be built but not sent to the engine.
    tester.binding.deferFirstFrame();
    // Pump a while, letting the reportTiming callback to run. If it had not
    // recorded the `sendFramesToEngine` when it was scheduled, it would have
    // crashed seeing `sendFramesToEngine` being now false!
    await tester.pump(const Duration(milliseconds: 1));
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
