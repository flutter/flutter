import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:test/test.dart';

void main() {
  test('Should recognize pan', () {
    PointerRouter router = new PointerRouter();
    PanGestureRecognizer pan = new PanGestureRecognizer(router: router);
    TapGestureRecognizer tap = new TapGestureRecognizer(router: router);

    bool didStartPan = false;
    pan.onStart = (_) {
      didStartPan = true;
    };

    ui.Offset updatedScrollDelta;
    pan.onUpdate = (ui.Offset offset) {
      updatedScrollDelta = offset;
    };

    bool didEndPan = false;
    pan.onEnd = (ui.Offset velocity) {
      didEndPan = true;
    };

    bool didTap = false;
    tap.onTap = () {
      didTap = true;
    };

    TestPointer pointer = new TestPointer(5);
    PointerInputEvent down = pointer.down(new Point(10.0, 10.0));
    pan.addPointer(down);
    tap.addPointer(down);
    GestureArena.instance.close(5);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    router.route(down);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    router.route(pointer.move(new Point(20.0, 20.0)));
    expect(didStartPan, isTrue);
    didStartPan = false;
    expect(updatedScrollDelta, new ui.Offset(10.0, 10.0));
    updatedScrollDelta = null;
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    router.route(pointer.move(new Point(20.0, 25.0)));
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, new ui.Offset(0.0, 5.0));
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
