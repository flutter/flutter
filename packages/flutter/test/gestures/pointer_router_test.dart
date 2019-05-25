// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

void main() {
  test('Should route pointers', () {
    bool callbackRan = false;
    void callback(PointerEvent event) {
      callbackRan = true;
    }

    final TestPointer pointer2 = TestPointer(2);
    final TestPointer pointer3 = TestPointer(3);

    final PointerRouter router = PointerRouter();
    router.addRoute(3, callback);
    router.route(pointer2.down(Offset.zero));
    expect(callbackRan, isFalse);
    router.route(pointer3.down(Offset.zero));
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
    final PointerRouter router = PointerRouter();
    router.addRoute(2, (PointerEvent event) {
      router.removeRoute(2, callback);
    });
    router.addRoute(2, callback);
    final TestPointer pointer2 = TestPointer(2);
    router.route(pointer2.down(Offset.zero));
    expect(callbackRan, isFalse);
  });

  test('Supports global callbacks', () {
    bool secondCallbackRan = false;
    void secondCallback(PointerEvent event) {
      secondCallbackRan = true;
    }

    bool firstCallbackRan = false;
    final PointerRouter router = PointerRouter();
    router.addGlobalRoute((PointerEvent event) {
      firstCallbackRan = true;
      router.addGlobalRoute(secondCallback);
    });

    final TestPointer pointer2 = TestPointer(2);
    router.route(pointer2.down(Offset.zero));
    expect(firstCallbackRan, isTrue);
    expect(secondCallbackRan, isFalse);
  });

  test('Supports re-entrant global cancellation', () {
    bool callbackRan = false;
    void callback(PointerEvent event) {
      callbackRan = true;
    }
    final PointerRouter router = PointerRouter();
    router.addGlobalRoute((PointerEvent event) {
      router.removeGlobalRoute(callback);
    });
    router.addGlobalRoute(callback);
    final TestPointer pointer2 = TestPointer(2);
    router.route(pointer2.down(Offset.zero));
    expect(callbackRan, isFalse);
  });

  test('Per-pointer callbacks cannot re-entrantly add global routes', () {
    bool callbackRan = false;
    void callback(PointerEvent event) {
      callbackRan = true;
    }
    final PointerRouter router = PointerRouter();
    bool perPointerCallbackRan = false;
    router.addRoute(2, (PointerEvent event) {
      perPointerCallbackRan = true;
      router.addGlobalRoute(callback);
    });
    final TestPointer pointer2 = TestPointer(2);
    router.route(pointer2.down(Offset.zero));
    expect(perPointerCallbackRan, isTrue);
    expect(callbackRan, isFalse);
  });

  test('Per-pointer callbacks happen before global callbacks', () {
    final List<String> log = <String>[];
    final PointerRouter router = PointerRouter();
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
    final TestPointer pointer2 = TestPointer(2);
    router.route(pointer2.down(Offset.zero));
    expect(log, equals(<String>[
      'per-pointer 1',
      'per-pointer 2',
      'global 1',
      'global 2',
    ]));
  });

  test('Exceptions do not stop pointer routing', () {
    final List<String> log = <String>[];
    final PointerRouter router = PointerRouter();
    router.addRoute(2, (PointerEvent event) {
      log.add('per-pointer 1');
    });
    router.addRoute(2, (PointerEvent event) {
      log.add('per-pointer 2');
      throw 'Having a bad day!';
    });
    router.addRoute(2, (PointerEvent event) {
      log.add('per-pointer 3');
    });

    final FlutterExceptionHandler previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      log.add('error report');
    };

    final TestPointer pointer2 = TestPointer(2);
    router.route(pointer2.down(Offset.zero));
    expect(log, equals(<String>[
      'per-pointer 1',
      'per-pointer 2',
      'error report',
      'per-pointer 3',
    ]));

    FlutterError.onError = previousErrorHandler;
  });
}
