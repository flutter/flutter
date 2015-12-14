// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:test/test.dart';

class TestSchedulerBinding extends BindingBase with Scheduler { }

void main() {
  Scheduler scheduler = new TestSchedulerBinding();

  test("Check for a time dilation being in effect", () {
    expect(timeDilation, equals(1.0));
  });

  test("Can cancel queued callback", () {
    int secondId;

    bool firstCallbackRan = false;
    bool secondCallbackRan = false;

    void firstCallback(Duration timeStamp) {
      expect(firstCallbackRan, isFalse);
      expect(secondCallbackRan, isFalse);
      expect(timeStamp.inMilliseconds, equals(16));
      firstCallbackRan = true;
      scheduler.cancelFrameCallbackWithId(secondId);
    }

    void secondCallback(Duration timeStamp) {
      expect(firstCallbackRan, isTrue);
      expect(secondCallbackRan, isFalse);
      expect(timeStamp.inMilliseconds, equals(16));
      secondCallbackRan = true;
    }

    scheduler.scheduleFrameCallback(firstCallback);
    secondId = scheduler.scheduleFrameCallback(secondCallback);

    scheduler.handleBeginFrame(const Duration(milliseconds: 16));

    expect(firstCallbackRan, isTrue);
    expect(secondCallbackRan, isFalse);

    firstCallbackRan = false;
    secondCallbackRan = false;

    scheduler.handleBeginFrame(const Duration(milliseconds: 32));

    expect(firstCallbackRan, isFalse);
    expect(secondCallbackRan, isFalse);
  });
}
