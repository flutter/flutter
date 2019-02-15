// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

void main() {
  group('text', () {
    testWidgets('finds Text widgets', (WidgetTester tester) async {
      // The first value in every sub array (ie. offsetResults[i][0]) will be the total move offset.
      // The remaining values will be the expected drags.
      final List<List<Offset>> offsetResults = <List<Offset>>[
        <Offset>[
          const Offset(-150, 200),
          const Offset(-7.5, 10),
          const Offset(-2.5, 3.333333333333333),
          const Offset(-140.0, 186.66666666666666),
        ],
        <Offset>[
          const Offset(150, -200),
          const Offset(7.5, -10),
          const Offset(2.5, -3.333333333333333),
          const Offset(140.0, -186.66666666666666),
        ],
        <Offset>[
          const Offset(-200, 150),
          const Offset(-10, 7.5),
          const Offset(-3.333333333333333, 2.5),
          const Offset(-186.66666666666666, 140.0),
        ],
        <Offset>[
          const Offset(200, -150),
          const Offset(10, -7.5),
          const Offset(3.333333333333333, -2.5),
          const Offset(186.66666666666666, -140.0),
        ],
        <Offset>[
          const Offset(-150, -200),
          const Offset(-7.5, -10),
          const Offset(-2.5, -3.333333333333333),
          const Offset(-140.0, -186.66666666666666),
        ],
        <Offset>[
          const Offset(8, 3),
          const Offset(8, 3),
        ],
        <Offset>[
          const Offset(3, 8),
          const Offset(3, 8),
        ],
        <Offset>[
          const Offset(20, 5),
          const Offset(10, 2.5),
          const Offset(10, 2.5),
        ],
        <Offset>[
          const Offset(5, 20),
          const Offset(2.5, 10),
          const Offset(2.5, 10),
        ],
        <Offset>[
          const Offset(20, 15),
          const Offset(10, 7.5),
          const Offset(3.333333333333333, 2.5),
          const Offset(6.666666666666668, 5),
        ],
        <Offset>[
          const Offset(15, 20),
          const Offset(7.5, 10),
          const Offset(2.5, 3.333333333333333),
          const Offset(5, 6.666666666666668),
        ],
        <Offset>[
          const Offset(20, 20),
          const Offset(10, 10),
          const Offset(10, 10),
        ],
        <Offset>[
          const Offset(0, 5),
          const Offset(0, 5),
        ],
      ];

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('test'),
        ),
      );

      final WidgetControllerSpy spyController = WidgetControllerSpy(tester.binding);

      for (int resultI = 0; resultI < offsetResults.length; resultI += 1) {
        await spyController.drag(
          find.text('test'),
          offsetResults[resultI][0],
          touchSlopX: 10,
          touchSlopY: 10,
        );
        final List<Offset> dragOffsets = spyController.testGestureSpy.offsets;
        for (int valueI = 1; valueI < offsetResults[resultI].length; valueI += 1) {
          expect(offsetResults[resultI].length - 1, dragOffsets.length);
          expect(
            offsetResults[resultI][valueI],
            dragOffsets[valueI - 1],
          );
        }
        spyController.testGestureSpy.clearOffsets();
      }
    });
  });
}

class WidgetControllerSpy extends WidgetController {
  WidgetControllerSpy(
    TestWidgetsFlutterBinding binding
  ) : super(binding) {
    _binding = binding;
  }

  TestWidgetsFlutterBinding _binding;

  @override
  Future<void> pump(Duration duration) async {
    if (duration != null)
      await Future<void>.delayed(duration);
    _binding.scheduleFrame();
    await _binding.endOfFrame;
  }

  int _getNextPointer() {
    final int result = nextPointer;
    nextPointer += 1;
    return result;
  }

  @override
  Future<void> sendEventToBinding(PointerEvent event, HitTestResult result) {
    return TestAsyncUtils.guard<void>(() async {
      _binding.dispatchEvent(event, result, source: TestBindingEventSource.test);
    });
  }

  TestGestureSpy testGestureSpy;

  @override
  Future<TestGesture> createGesture({int pointer, PointerDeviceKind kind = PointerDeviceKind.touch}) async {
    return testGestureSpy = TestGestureSpy(
      pointer: pointer ?? _getNextPointer(),
      kind: kind,
      dispatcher: sendEventToBinding,
      hitTester: hitTestOnBinding
    );
  }
}

class TestGestureSpy extends TestGesture {
  TestGestureSpy({
    int pointer,
    PointerDeviceKind kind,
    EventDispatcher dispatcher,
    HitTester hitTester
  }) : super(
        pointer: pointer,
        kind: kind,
        dispatcher: dispatcher,
        hitTester: hitTester
      );

  List<Offset> offsets = <Offset>[];

  void clearOffsets() {
    offsets = <Offset>[];
  }

  @override
  Future<void> moveBy(Offset offset, {Duration timeStamp = Duration.zero}) {
    offsets.add(offset);
    return super.moveBy(offset, timeStamp: timeStamp);
  }
}