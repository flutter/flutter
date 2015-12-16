// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:test/test.dart';

void main() {
  test('Should route pointers', () {
    bool callbackRan = false;
    void callback(PointerEvent event) {
      callbackRan = true;
    }

    TestPointer pointer2 = new TestPointer(2);
    TestPointer pointer3 = new TestPointer(3);

    PointerRouter router = new PointerRouter();
    router.addRoute(3, callback);
    router.route(pointer2.down(Point.origin));
    expect(callbackRan, isFalse);
    router.route(pointer3.down(Point.origin));
    expect(callbackRan, isTrue);
    callbackRan = false;
    router.removeRoute(3, callback);
    router.route(pointer3.up());
    expect(callbackRan, isFalse);
  });
}
