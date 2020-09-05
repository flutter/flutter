// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:meta/meta.dart';
import 'package:fake_async/fake_async.dart';

import '../flutter_test_alternative.dart';

class TestGestureFlutterBinding extends BindingBase with GestureBinding { }

void ensureGestureBinding() {
  if (GestureBinding.instance == null)
    TestGestureFlutterBinding();
  assert(GestureBinding.instance != null);
}

class GestureTester {
  GestureTester._(this.async);

  final FakeAsync async;

  void closeArena(int pointer) {
    GestureBinding.instance.gestureArena.close(pointer);
  }

  void route(PointerEvent event) {
    GestureBinding.instance.pointerRouter.route(event);
    async.flushMicrotasks();
  }
}

typedef GestureTest = void Function(GestureTester tester);

@isTest
void testGesture(String description, GestureTest callback) {
  test(description, () {
    FakeAsync().run((FakeAsync async) {
      callback(GestureTester._(async));
    });
  });
}
