// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:test/test.dart';

void main() {
  test('Should recognize pan', () {
    PointerRouter router = new PointerRouter();
    GestureArena gestureArena = new GestureArena();
    PanGestureRecognizer pan = new PanGestureRecognizer(
      router: router,
      gestureArena: gestureArena
    );
    TapGestureRecognizer tap = new TapGestureRecognizer(
      router: router,
      gestureArena: gestureArena
    );

    bool didStartPan = false;
    pan.onStart = (_) {
      didStartPan = true;
    };

    Offset updatedScrollDelta;
    pan.onUpdate = (Offset offset) {
      updatedScrollDelta = offset;
    };

    bool didEndPan = false;
    pan.onEnd = (Offset velocity) {
      didEndPan = true;
    };

    bool didTap = false;
    tap.onTap = () {
      didTap = true;
    };

    TestPointer pointer = new TestPointer(5);
    PointerDownEvent down = pointer.down(const Point(10.0, 10.0));
    pan.addPointer(down);
    tap.addPointer(down);
    gestureArena.close(5);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    router.route(down);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    router.route(pointer.move(const Point(20.0, 20.0)));
    expect(didStartPan, isTrue);
    didStartPan = false;
    expect(updatedScrollDelta, const Offset(10.0, 10.0));
    updatedScrollDelta = null;
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    router.route(pointer.move(const Point(20.0, 25.0)));
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, const Offset(0.0, 5.0));
    updatedScrollDelta = null;
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    router.route(pointer.up());
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isTrue);
    didEndPan = false;
    expect(didTap, isFalse);

    pan.dispose();
    tap.dispose();
  });
}
