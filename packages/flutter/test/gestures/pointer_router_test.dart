// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

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

  test('Supports re-entrant cancellation', () {
    bool callbackRan = false;
    void callback(PointerEvent event) {
      callbackRan = true;
    }
    PointerRouter router = new PointerRouter();
    router.addRoute(2, (PointerEvent event) {
      router.removeRoute(2, callback);
    });
    router.addRoute(2, callback);
    TestPointer pointer2 = new TestPointer(2);
    router.route(pointer2.down(Point.origin));
    expect(callbackRan, isFalse);
  });

  test('Supports global callbacks', () {
    bool secondCallbackRan = false;
    void secondCallback(PointerEvent event) {
      secondCallbackRan = true;
    }

    bool firstCallbackRan = false;
    PointerRouter router = new PointerRouter();
    router.addGlobalRoute((PointerEvent event) {
      firstCallbackRan = true;
      router.addGlobalRoute(secondCallback);
    });

    TestPointer pointer2 = new TestPointer(2);
    router.route(pointer2.down(Point.origin));
    expect(firstCallbackRan, isTrue);
    expect(secondCallbackRan, isFalse);
  });

  test('Supports re-entrant global cancellation', () {
    bool callbackRan = false;
    void callback(PointerEvent event) {
      callbackRan = true;
    }
    PointerRouter router = new PointerRouter();
    router.addGlobalRoute((PointerEvent event) {
      router.removeGlobalRoute(callback);
    });
    router.addGlobalRoute(callback);
    TestPointer pointer2 = new TestPointer(2);
    router.route(pointer2.down(Point.origin));
    expect(callbackRan, isFalse);
  });

  test('Per-pointer callbacks cannot re-entrantly add global routes', () {
    bool callbackRan = false;
    void callback(PointerEvent event) {
      callbackRan = true;
    }
    PointerRouter router = new PointerRouter();
    bool perPointerCallbackRan = false;
    router.addRoute(2, (PointerEvent event) {
      perPointerCallbackRan = true;
      router.addGlobalRoute(callback);
    });
    TestPointer pointer2 = new TestPointer(2);
    router.route(pointer2.down(Point.origin));
    expect(perPointerCallbackRan, isTrue);
    expect(callbackRan, isFalse);
  });

  test('Per-pointer callbacks happen before global callbacks', () {
    List<String> log = <String>[];
    PointerRouter router = new PointerRouter();
    router.addGlobalRoute((PointerEvent event) {
      log.add('global 1');
    });
    router.addRoute(2, (PointerEvent event) {
      log.add('per-pointer 1');
    });
    router.addGlobalRoute((PointerEvent event) {
      log.add('global 2');
    });
    router.addRoute(2, (PointerEvent event) {
      log.add('per-pointer 2');
    });
    TestPointer pointer2 = new TestPointer(2);
    router.route(pointer2.down(Point.origin));
    expect(log, equals(<String>[
      'per-pointer 1',
      'per-pointer 2',
      'global 1',
      'global 2',
    ]));
  });
}
