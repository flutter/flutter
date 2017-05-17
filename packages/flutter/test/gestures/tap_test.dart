// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:test/test.dart';

import 'gesture_tester.dart';

class TestGestureArenaMember extends GestureArenaMember {
  @override
  void acceptGesture(int key) {}

  @override
  void rejectGesture(int key) {}
}

void main() {
  setUp(ensureGestureBinding);

  // Down/up pair 1: normal tap sequence
  const PointerDownEvent down1 = const PointerDownEvent(
    pointer: 1,
    position: const Offset(10.0, 10.0)
  );

  const PointerUpEvent up1 = const PointerUpEvent(
    pointer: 1,
    position: const Offset(11.0, 9.0)
  );

  // Down/up pair 2: normal tap sequence far away from pair 1
  const PointerDownEvent down2 = const PointerDownEvent(
    pointer: 2,
    position: const Offset(30.0, 30.0)
  );

  const PointerUpEvent up2 = const PointerUpEvent(
    pointer: 2,
    position: const Offset(31.0, 29.0)
  );

  // Down/move/up sequence 3: intervening motion
  const PointerDownEvent down3 = const PointerDownEvent(
    pointer: 3,
    position: const Offset(10.0, 10.0)
  );

  const PointerMoveEvent move3 = const PointerMoveEvent(
    pointer: 3,
    position: const Offset(25.0, 25.0)
  );

  const PointerUpEvent up3 = const PointerUpEvent(
    pointer: 3,
    position: const Offset(25.0, 25.0)
  );

  testGesture('Should recognize tap', (GestureTester tester) {
    final TapGestureRecognizer tap = new TapGestureRecognizer();

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    tap.addPointer(down1);
    tester.closeArena(1);
    expect(tapRecognized, isFalse);
    tester.route(down1);
    expect(tapRecognized, isFalse);

    tester.route(up1);
    expect(tapRecognized, isTrue);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(tapRecognized, isTrue);

    tap.dispose();
  });

  testGesture('No duplicate tap events', (GestureTester tester) {
    final TapGestureRecognizer tap = new TapGestureRecognizer();

    int tapsRecognized = 0;
    tap.onTap = () {
      tapsRecognized++;
    };

    tap.addPointer(down1);
    tester.closeArena(1);
    expect(tapsRecognized, 0);
    tester.route(down1);
    expect(tapsRecognized, 0);

    tester.route(up1);
    expect(tapsRecognized, 1);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(tapsRecognized, 1);

    tap.addPointer(down1);
    tester.closeArena(1);
    expect(tapsRecognized, 1);
    tester.route(down1);
    expect(tapsRecognized, 1);

    tester.route(up1);
    expect(tapsRecognized, 2);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(tapsRecognized, 2);

    tap.dispose();
  });

  testGesture('Should not recognize two overlapping taps', (GestureTester tester) {
    final TapGestureRecognizer tap = new TapGestureRecognizer();

    int tapsRecognized = 0;
    tap.onTap = () {
      tapsRecognized++;
    };

    tap.addPointer(down1);
    tester.closeArena(1);
    expect(tapsRecognized, 0);
    tester.route(down1);
    expect(tapsRecognized, 0);

    tap.addPointer(down2);
    tester.closeArena(2);
    expect(tapsRecognized, 0);
    tester.route(down1);
    expect(tapsRecognized, 0);


    tester.route(up1);
    expect(tapsRecognized, 1);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(tapsRecognized, 1);

    tester.route(up2);
    expect(tapsRecognized, 1);
    GestureBinding.instance.gestureArena.sweep(2);
    expect(tapsRecognized, 1);

    tap.dispose();
  });

  testGesture('Distance cancels tap', (GestureTester tester) {
    final TapGestureRecognizer tap = new TapGestureRecognizer();

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };
    bool tapCanceled = false;
    tap.onTapCancel = () {
      tapCanceled = true;
    };

    tap.addPointer(down3);
    tester.closeArena(3);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isFalse);
    tester.route(down3);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isFalse);

    tester.route(move3);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isTrue);
    tester.route(up3);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isTrue);
    GestureBinding.instance.gestureArena.sweep(3);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isTrue);

    tap.dispose();
  });

  testGesture('Timeout does not cancel tap', (GestureTester tester) {
    final TapGestureRecognizer tap = new TapGestureRecognizer();

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    tap.addPointer(down1);
    tester.closeArena(1);
    expect(tapRecognized, isFalse);
    tester.route(down1);
    expect(tapRecognized, isFalse);

    tester.async.elapse(const Duration(milliseconds: 500));
    expect(tapRecognized, isFalse);
    tester.route(up1);
    expect(tapRecognized, isTrue);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(tapRecognized, isTrue);

    tap.dispose();
  });

  testGesture('Should yield to other arena members', (GestureTester tester) {
    final TapGestureRecognizer tap = new TapGestureRecognizer();

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    tap.addPointer(down1);
    final TestGestureArenaMember member = new TestGestureArenaMember();
    final GestureArenaEntry entry = GestureBinding.instance.gestureArena.add(1, member);
    GestureBinding.instance.gestureArena.hold(1);
    tester.closeArena(1);
    expect(tapRecognized, isFalse);
    tester.route(down1);
    expect(tapRecognized, isFalse);

    tester.route(up1);
    expect(tapRecognized, isFalse);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(tapRecognized, isFalse);

    entry.resolve(GestureDisposition.accepted);
    expect(tapRecognized, isFalse);

    tap.dispose();
  });

  testGesture('Should trigger on release of held arena', (GestureTester tester) {
    final TapGestureRecognizer tap = new TapGestureRecognizer();

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    tap.addPointer(down1);
    final TestGestureArenaMember member = new TestGestureArenaMember();
    final GestureArenaEntry entry = GestureBinding.instance.gestureArena.add(1, member);
    GestureBinding.instance.gestureArena.hold(1);
    tester.closeArena(1);
    expect(tapRecognized, isFalse);
    tester.route(down1);
    expect(tapRecognized, isFalse);

    tester.route(up1);
    expect(tapRecognized, isFalse);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(tapRecognized, isFalse);

    entry.resolve(GestureDisposition.rejected);
    tester.async.flushMicrotasks();
    expect(tapRecognized, isTrue);

    tap.dispose();
  });

  testGesture('Should log exceptions from callbacks', (GestureTester tester) {
    final TapGestureRecognizer tap = new TapGestureRecognizer();

    tap.onTap = () {
      throw new Exception(test);
    };

    final FlutterExceptionHandler previousErrorHandler = FlutterError.onError;
    bool gotError = false;
    FlutterError.onError = (FlutterErrorDetails details) {
      gotError = true;
    };

    tap.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    expect(gotError, isFalse);

    tester.route(up1);
    expect(gotError, isTrue);

    FlutterError.onError = previousErrorHandler;
    tap.dispose();
  });

  testGesture('No duplicate tap events', (GestureTester tester) {
    final TapGestureRecognizer tapA = new TapGestureRecognizer();
    final TapGestureRecognizer tapB = new TapGestureRecognizer();

    final List<String> log = <String>[];
    tapA.onTapDown = (TapDownDetails details) { log.add('tapA onTapDown'); };
    tapA.onTapUp = (TapUpDetails details) { log.add('tapA onTapUp'); };
    tapA.onTap = () { log.add('tapA onTap'); };
    tapA.onTapCancel = () { log.add('tapA onTapCancel'); };
    tapB.onTapDown = (TapDownDetails details) { log.add('tapB onTapDown'); };
    tapB.onTapUp = (TapUpDetails details) { log.add('tapB onTapUp'); };
    tapB.onTap = () { log.add('tapB onTap'); };
    tapB.onTapCancel = () { log.add('tapB onTapCancel'); };

    log.add('start');
    tapA.addPointer(down1);
    log.add('added 1 to A');
    tapB.addPointer(down1);
    log.add('added 1 to B');
    tester.closeArena(1);
    log.add('closed 1');
    tester.route(down1);
    log.add('routed 1 down');
    tester.route(up1);
    log.add('routed 1 up');
    GestureBinding.instance.gestureArena.sweep(1);
    log.add('swept 1');
    tapA.addPointer(down2);
    log.add('down 2 to A');
    tapB.addPointer(down2);
    log.add('down 2 to B');
    tester.closeArena(2);
    log.add('closed 2');
    tester.route(down2);
    log.add('routed 2 down');
    tester.route(up2);
    log.add('routed 2 up');
    GestureBinding.instance.gestureArena.sweep(2);
    log.add('swept 2');
    tapA.dispose();
    log.add('disposed A');
    tapB.dispose();
    log.add('disposed B');

    expect(log, <String>[
      'start',
      'added 1 to A',
      'added 1 to B',
      'closed 1',
      'routed 1 down',
      'routed 1 up',
      'tapA onTapDown',
      'tapA onTapUp',
      'tapA onTap',
      'tapB onTapCancel',
      'swept 1',
      'down 2 to A',
      'down 2 to B',
      'closed 2',
      'routed 2 down',
      'routed 2 up',
      'tapA onTapDown',
      'tapA onTapUp',
      'tapA onTap',
      'tapB onTapCancel',
      'swept 2',
      'disposed A',
      'disposed B',
    ]);
  });
}
