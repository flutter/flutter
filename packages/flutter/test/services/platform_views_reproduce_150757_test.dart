// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockPointerCancelEvent extends PointerCancelEvent {
  const _MockPointerCancelEvent({
    super.timeStamp,
    super.pointer,
    super.position,
    this.customPlatformData = 0,
  });

  final int customPlatformData;

  @override
  int get platformData => customPlatformData;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PlatformView routes ACTION_CANCEL when multiple pointers are canceled in a batch', (
    WidgetTester tester,
  ) async {
    final log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      MethodCall methodCall,
    ) async {
      log.add(methodCall);
      return null;
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform_views,
        null,
      );
    });

    final AndroidViewController viewController = PlatformViewsService.initSurfaceAndroidView(
      id: 7,
      viewType: 'web',
      layoutDirection: TextDirection.ltr,
    );
    viewController.pointTransformer = (Offset offset) => offset;
    addTearDown(() {
      viewController.dispose();
    });

    // Dispatch PointerDownEvent for pointer 0 and 1. Note: pointer 0 is default.
    await viewController.dispatchPointerEvent(
      const PointerDownEvent(timeStamp: Duration(milliseconds: 1), position: Offset(10.0, 10.0)),
    );
    await viewController.dispatchPointerEvent(
      const PointerDownEvent(
        timeStamp: Duration(milliseconds: 1),
        pointer: 1,
        position: Offset(20.0, 20.0),
      ),
    );

    // Clear log before cancel sequence
    log.clear();

    // Pointer event platform data constant from _AndroidMotionEventConverter
    const kPointerDataFlagMultiple = 2;
    const pointerCount = 2;

    // Dispatch PointerCancelEvent for pointer 0 and 1 as a batch of multiple pointer cancel events. Note: pointer 0 is default.
    await viewController.dispatchPointerEvent(
      const _MockPointerCancelEvent(
        timeStamp: Duration(milliseconds: 2),
        position: Offset(10.0, 10.0),
        customPlatformData: kPointerDataFlagMultiple | (pointerCount << 8),
      ),
    );
    await viewController.dispatchPointerEvent(
      const _MockPointerCancelEvent(
        timeStamp: Duration(milliseconds: 2),
        pointer: 1,
        position: Offset(20.0, 20.0),
        customPlatformData: kPointerDataFlagMultiple | (pointerCount << 8),
      ),
    );

    // Indexes in the list returned by AndroidMotionEvent._asList
    const kAndroidMotionEventListIndexAction = 3;
    const kAndroidMotionEventListIndexPointerCount = 4;

    final List<MethodCall> cancelCalls = log.where((MethodCall call) {
      if (call.method != 'touch') {
        return false;
      }
      final args = call.arguments as List<dynamic>;
      return args[kAndroidMotionEventListIndexAction] == AndroidViewController.kActionCancel;
    }).toList();

    // The _AndroidMotionEventConverter should yield exactly one touch event containing both pointers with action cancel.
    expect(cancelCalls, hasLength(1));
    final cancelArgs = cancelCalls.single.arguments as List<dynamic>;
    expect(cancelArgs[kAndroidMotionEventListIndexPointerCount], equals(pointerCount));
  });
}
