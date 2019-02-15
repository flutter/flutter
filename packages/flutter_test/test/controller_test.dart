// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

void main() {
  testWidgets(
    'WidgetTester.drag must break the offset into multiple parallel components if'
    'the drag goes outside the touch slop values',
    (WidgetTester tester) async {
      // The first Offset in every sub array (ie. offsetResults[i][0]) is (touchSlopX, touchSlopY).
      // The second Offset ... (ie. offsetResults[i][1]) will be the total move offset.
      // The remaining values ... are the expected separated drag offsets.
      final List<List<Offset>> offsetResults = <List<Offset>>[
        <Offset>[
          const Offset(10, 10),
          const Offset(-150, 200),
          const Offset(-7.5, 10),
          const Offset(-2.5, 3.333333333333333),
          const Offset(-140.0, 186.66666666666666),
        ],
        <Offset>[
          const Offset(10, 10),
          const Offset(150, -200),
          const Offset(7.5, -10),
          const Offset(2.5, -3.333333333333333),
          const Offset(140.0, -186.66666666666666),
        ],
        <Offset>[
          const Offset(10, 10),
          const Offset(-200, 150),
          const Offset(-10, 7.5),
          const Offset(-3.333333333333333, 2.5),
          const Offset(-186.66666666666666, 140.0),
        ],
        <Offset>[
          const Offset(10, 10),
          const Offset(200, -150),
          const Offset(10, -7.5),
          const Offset(3.333333333333333, -2.5),
          const Offset(186.66666666666666, -140.0),
        ],
        <Offset>[
          const Offset(10, 10),
          const Offset(-150, -200),
          const Offset(-7.5, -10),
          const Offset(-2.5, -3.333333333333333),
          const Offset(-140.0, -186.66666666666666),
        ],
        <Offset>[
          const Offset(10, 10),
          const Offset(8, 3),
          const Offset(8, 3),
        ],
        <Offset>[
          const Offset(10, 10),
          const Offset(3, 8),
          const Offset(3, 8),
        ],
        <Offset>[
          const Offset(10, 10),
          const Offset(20, 5),
          const Offset(10, 2.5),
          const Offset(10, 2.5),
        ],
        <Offset>[
          const Offset(10, 10),
          const Offset(5, 20),
          const Offset(2.5, 10),
          const Offset(2.5, 10),
        ],
        <Offset>[
          const Offset(10, 10),
          const Offset(20, 15),
          const Offset(10, 7.5),
          const Offset(3.333333333333333, 2.5),
          const Offset(6.666666666666668, 5),
        ],
        <Offset>[
          const Offset(10, 10),
          const Offset(15, 20),
          const Offset(7.5, 10),
          const Offset(2.5, 3.333333333333333),
          const Offset(5, 6.666666666666668),
        ],
        <Offset>[
          const Offset(10, 10),
          const Offset(20, 20),
          const Offset(10, 10),
          const Offset(10, 10),
        ],
        <Offset>[
          const Offset(10, 10),
          const Offset(0, 5),
          const Offset(0, 5),
        ],

        //// [VARYING TOUCH SLOP] ////
        <Offset>[
          const Offset(12, 5),
          const Offset(0, 5),
          const Offset(0, 5),
        ],
        <Offset>[
          const Offset(12, 5),
          const Offset(20, 5),
          const Offset(12, 3),
          const Offset(8, 2),
        ],
        <Offset>[
          const Offset(12, 5),
          const Offset(5, 20),
          const Offset(1.25, 5),
          const Offset(3.75, 15),
        ],
        <Offset>[
          const Offset(5, 12),
          const Offset(5, 20),
          const Offset(3, 12),
          const Offset(2, 8),
        ],
        <Offset>[
          const Offset(5, 12),
          const Offset(20, 5),
          const Offset(5, 1.25),
          const Offset(15, 3.75),
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
        final List<Offset> testResult = offsetResults[resultI];
        await spyController.drag(
          find.text('test'),
          testResult[1],
          touchSlopX: testResult[0].dx,
          touchSlopY: testResult[0].dy,
        );
        final List<Offset> dragOffsets = spyController.testGestureSpy.offsets;
        expect(
          offsetResults[resultI].length - 2,
          dragOffsets.length,

          reason:
            'There is a difference in the number of expected and actual split offsets for the drag with:\n'
            'Touch Slop: ' + testResult[0].toString() + '\n'
            'Delta:      ' + testResult[1].toString() + '\n',
        );
        for (int valueI = 2; valueI < offsetResults[resultI].length; valueI += 1) {
          expect(
            offsetResults[resultI][valueI],
            dragOffsets[valueI - 2],
            reason:
              'There is a difference in the expected and actual value of the ' +
              (valueI == 2 ? 'first' : valueI == 3 ? 'second' : 'third') +
              ' split offset for the drag with:\n'
              'Touch slop: ' + testResult[0].toString() + '\n'
              'Delta:      ' + testResult[1].toString() + '\n',
          );
        }
        spyController.testGestureSpy.clearOffsets();
      }
    },
  );
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
