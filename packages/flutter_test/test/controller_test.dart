// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('text', () {
    testWidgets('finds Text widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('test'),
        ),
      );
      expect(find.text('test'), findsOneWidget);

      final TestControllerSpy spyController = TestControllerSpy(tester.binding);
      await spyController.drag(find.text('test'), const Offset(-150, 200), touchSlopX: 10, touchSlopY: 10);
      final GestureSpy spy = spyController.spy;

      print(spy.offsets[0]);
    });
  });
}

class TestControllerSpy extends WidgetController {

  TestControllerSpy(WidgetsBinding binding) : super(binding);

  @override
  Future<void> pump(Duration duration) async {
    if (duration != null)
      await Future<void>.delayed(duration);
    binding.scheduleFrame();
    await binding.endOfFrame;
  }

  GestureSpy spy;

  @override
  Future<GestureSpy> startGesture(Offset downLocation, {int pointer}) async {
    spy = await super.startGesture(downLocation, pointer: pointer);
    return spy;
  }

}

class GestureSpy extends TestGesture {

  GestureSpy(){
    offsets = <Offset>[];
  }

  List<Offset> offsets;

  @override
  Future<void> moveBy(Offset offset, {Duration timeStamp = Duration.zero}) {
    offsets.add(offset);
    return super.moveBy(offset, timeStamp: timeStamp);
  }
}