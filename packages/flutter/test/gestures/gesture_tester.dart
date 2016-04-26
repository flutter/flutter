// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:test/test.dart';
import 'package:quiver/testing/async.dart';

class TestGestureFlutterBinding extends BindingBase with GestureBinding { }

void ensureGestureBinding() {
  if (GestureBinding.instance == null)
    new TestGestureFlutterBinding();
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

typedef void GestureTest(GestureTester tester);

void testGesture(String description, GestureTest callback) {
  test(description, () {
    new FakeAsync().run((FakeAsync async) {
      callback(new GestureTester._(async));
    });
  });
}
