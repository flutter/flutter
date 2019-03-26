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
      // The second Offset in every sub array (ie. offsetResults[i][1]) will be the total move offset.
      // The remaining values in every sub array are the expected separated drag offsets.

      // This test checks to make sure that the total drag will be correctly split into
      // pieces such that the first (and potentially second) moveBy function call(s) in
      // controller.drag() will never have a component greater than the touch
      // slop in that component's respective axis.
      final List<List<Offset>> offsetResults = <List<Offset>>[
        <Offset>[
          const Offset(10.0, 10.0),
          const Offset(-150.0, 200.0),
          const Offset(-7.5, 10.0),
          const Offset(-2.5, 3.333333333333333),
          const Offset(-140.0, 186.66666666666666),
        ],
        <Offset>[
          const Offset(10.0, 10.0),
          const Offset(150, -200),
          const Offset(7.5, -10),
          const Offset(2.5, -3.333333333333333),
          const Offset(140.0, -186.66666666666666),
        ],
        <Offset>[
          const Offset(10.0, 10.0),
          const Offset(-200, 150),
          const Offset(-10, 7.5),
          const Offset(-3.333333333333333, 2.5),
          const Offset(-186.66666666666666, 140.0),
        ],
        <Offset>[
          const Offset(10.0, 10.0),
          const Offset(200.0, -150.0),
          const Offset(10, -7.5),
          const Offset(3.333333333333333, -2.5),
          const Offset(186.66666666666666, -140.0),
        ],
        <Offset>[
          const Offset(10.0, 10.0),
          const Offset(-150.0, -200.0),
          const Offset(-7.5, -10.0),
          const Offset(-2.5, -3.333333333333333),
          const Offset(-140.0, -186.66666666666666),
        ],
        <Offset>[
          const Offset(10.0, 10.0),
          const Offset(8.0, 3.0),
          const Offset(8.0, 3.0),
        ],
        <Offset>[
          const Offset(10.0, 10.0),
          const Offset(3.0, 8.0),
          const Offset(3.0, 8.0),
        ],
        <Offset>[
          const Offset(10.0, 10.0),
          const Offset(20.0, 5.0),
          const Offset(10.0, 2.5),
          const Offset(10.0, 2.5),
        ],
        <Offset>[
          const Offset(10.0, 10.0),
          const Offset(5.0, 20.0),
          const Offset(2.5, 10.0),
          const Offset(2.5, 10.0),
        ],
        <Offset>[
          const Offset(10.0, 10.0),
          const Offset(20.0, 15.0),
          const Offset(10.0, 7.5),
          const Offset(3.333333333333333, 2.5),
          const Offset(6.666666666666668, 5.0),
        ],
        <Offset>[
          const Offset(10.0, 10.0),
          const Offset(15.0, 20.0),
          const Offset(7.5, 10.0),
          const Offset(2.5, 3.333333333333333),
          const Offset(5.0, 6.666666666666668),
        ],
        <Offset>[
          const Offset(10.0, 10.0),
          const Offset(20.0, 20.0),
          const Offset(10.0, 10.0),
          const Offset(10.0, 10.0),
        ],
        <Offset>[
          const Offset(10.0, 10.0),
          const Offset(0.0, 5.0),
          const Offset(0.0, 5.0),
        ],

        //// [VARYING TOUCH SLOP] ////
        <Offset>[
          const Offset(12.0, 5.0),
          const Offset(0.0, 5.0),
          const Offset(0.0, 5.0),
        ],
        <Offset>[
          const Offset(12.0, 5.0),
          const Offset(20.0, 5.0),
          const Offset(12.0, 3.0),
          const Offset(8.0, 2.0),
        ],
        <Offset>[
          const Offset(12.0, 5.0),
          const Offset(5.0, 20.0),
          const Offset(1.25, 5.0),
          const Offset(3.75, 15.0),
        ],
        <Offset>[
          const Offset(5.0, 12.0),
          const Offset(5.0, 20.0),
          const Offset(3.0, 12.0),
          const Offset(2.0, 8.0),
        ],
        <Offset>[
          const Offset(5.0, 12.0),
          const Offset(20.0, 5.0),
          const Offset(5.0, 1.25),
          const Offset(15.0, 3.75),
        ],
        <Offset>[
          const Offset(18.0, 18.0),
          const Offset(0.0, 150.0),
          const Offset(0.0, 18.0),
          const Offset(0.0, 132.0),
        ],
        <Offset>[
          const Offset(18.0, 18.0),
          const Offset(0.0, -150.0),
          const Offset(0.0, -18.0),
          const Offset(0.0, -132.0),
        ],
        <Offset>[
          const Offset(18.0, 18.0),
          const Offset(-150.0, 0.0),
          const Offset(-18.0, 0.0),
          const Offset(-132.0, 0.0),
        ],
        <Offset>[
          const Offset(0.0, 0.0),
          const Offset(-150.0, 0.0),
          const Offset(-150.0, 0.0),
        ],
        <Offset>[
          const Offset(18.0, 18.0),
          const Offset(-32.0, 0.0),
          const Offset(-18.0, 0.0),
          const Offset(-14.0, 0.0),
        ],
      ];

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('test'),
        ),
      );

      final WidgetControllerSpy spyController = WidgetControllerSpy(tester.binding);

      for (int resultIndex = 0; resultIndex < offsetResults.length; resultIndex += 1) {
        final List<Offset> testResult = offsetResults[resultIndex];
        await spyController.drag(
          find.text('test'),
          testResult[1],
          touchSlopX: testResult[0].dx,
          touchSlopY: testResult[0].dy,
        );
        final List<Offset> dragOffsets = spyController.testGestureSpy.offsets;
        expect(
          offsetResults[resultIndex].length - 2,
          dragOffsets.length,

          reason:
            'There is a difference in the number of expected and actual split offsets for the drag with:\n'
            'Touch Slop: ' + testResult[0].toString() + '\n'
            'Delta:      ' + testResult[1].toString() + '\n',
        );
        for (int valueIndex = 2; valueIndex < offsetResults[resultIndex].length; valueIndex += 1) {
          expect(
            offsetResults[resultIndex][valueIndex],
            dragOffsets[valueIndex - 2],
            reason:
              'There is a difference in the expected and actual value of the ' +
              (valueIndex == 2 ? 'first' : valueIndex == 3 ? 'second' : 'third') +
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
    TestWidgetsFlutterBinding binding,
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
      hitTester: hitTestOnBinding,
    );
  }
}

class TestGestureSpy extends TestGesture {
  TestGestureSpy({
    int pointer,
    PointerDeviceKind kind,
    EventDispatcher dispatcher,
    HitTester hitTester,
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
