// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Reproduce issue 78683 - velocity tracker timestamp backwards', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              return Container(height: 100.0, color: index.isEven ? Colors.blue : Colors.red);
            },
          ),
        ),
      ),
    );

    // Save original values to restore in finally block.
    final Duration originalSamplingOffset = GestureBinding.instance.samplingOffset;
    GestureBinding.instance.resamplingEnabled = true;
    GestureBinding.instance.samplingOffset = const Duration(milliseconds: -5);

    const bootTimeStamp = Duration(seconds: 100);

    // Send a pointer down event.
    final packet1 = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(
          viewId: tester.view.viewId,
          change: ui.PointerChange.add,
          timeStamp: bootTimeStamp,
        ),
        ui.PointerData(
          viewId: tester.view.viewId,
          change: ui.PointerChange.down,
          timeStamp: bootTimeStamp,
        ),
      ],
    );
    GestureBinding.instance.platformDispatcher.onPointerDataPacket!(packet1);

    // Now, run the frame callbacks with the bootTimeStamp time to process the down event.
    tester.binding.handleBeginFrame(bootTimeStamp);
    tester.binding.handleDrawFrame();

    // Send a pointer move event.
    final Duration moveTimeStamp = bootTimeStamp + const Duration(milliseconds: 10);
    final packet2 = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(
          viewId: tester.view.viewId,
          change: ui.PointerChange.move,
          physicalY: -50.0,
          timeStamp: moveTimeStamp,
        ),
      ],
    );
    GestureBinding.instance.platformDispatcher.onPointerDataPacket!(packet2);

    // Sample the move event.
    try {
      tester.binding.handleBeginFrame(moveTimeStamp);
      tester.binding.handleDrawFrame();
    } finally {
      // Clean up to cancel the resampling timer and restore original values.
      GestureBinding.instance.resamplingEnabled = false;
      GestureBinding.instance.samplingOffset = originalSamplingOffset;
      await tester.pump(const Duration(milliseconds: 20));
    }
  });
}
