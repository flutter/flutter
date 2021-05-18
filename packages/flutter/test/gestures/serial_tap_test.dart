// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gesture_tester.dart';

void main() {
  setUp(ensureGestureBinding);

  late List<String> events;
  late SerialTapGestureRecognizer serial;

  setUp(() {
    events = <String>[];
    serial = SerialTapGestureRecognizer()
      ..onSerialTapDown = (SerialTapDownDetails details) {
        events.add('down#${details.count}');
      }
      ..onSerialTapCancel = (SerialTapCancelDetails details) {
        events.add('cancel#${details.count}');
      }
      ..onSerialTapUp = (SerialTapUpDetails details) {
        events.add('up#${details.count}');
      };
  });

  // Down/up pair 1: normal tap sequence
  const PointerDownEvent down1 = PointerDownEvent(
    pointer: 1,
    position: Offset(10.0, 10.0),
  );

  const PointerCancelEvent cancel1 = PointerCancelEvent(
    pointer: 1,
  );

  const PointerUpEvent up1 = PointerUpEvent(
    pointer: 1,
    position: Offset(11.0, 9.0),
  );

  // Down/up pair 2: normal tap sequence close to pair 1
  const PointerDownEvent down2 = PointerDownEvent(
    pointer: 2,
    position: Offset(12.0, 12.0),
  );

  const PointerUpEvent up2 = PointerUpEvent(
    pointer: 2,
    position: Offset(13.0, 11.0),
  );

  // Down/up pair 3: normal tap sequence close to pair 1
  const PointerDownEvent down3 = PointerDownEvent(
    pointer: 3,
    position: Offset(12.0, 12.0),
  );

  const PointerUpEvent up3 = PointerUpEvent(
    pointer: 3,
    position: Offset(13.0, 11.0),
  );

  // Down/up pair 4: normal tap sequence far away from pair 1
  const PointerDownEvent down4 = PointerDownEvent(
    pointer: 4,
    position: Offset(130.0, 130.0),
  );

  const PointerUpEvent up4 = PointerUpEvent(
    pointer: 4,
    position: Offset(131.0, 129.0),
  );

  // Down/move/up sequence 5: intervening motion
  const PointerDownEvent down5 = PointerDownEvent(
    pointer: 5,
    position: Offset(10.0, 10.0),
  );

  const PointerMoveEvent move5 = PointerMoveEvent(
    pointer: 5,
    position: Offset(25.0, 25.0),
  );

  const PointerUpEvent up5 = PointerUpEvent(
    pointer: 5,
    position: Offset(25.0, 25.0),
  );

  // Down/up pair 7: normal tap sequence close to pair 1 but on secondary button
  const PointerDownEvent down6 = PointerDownEvent(
    pointer: 6,
    position: Offset(10.0, 10.0),
    buttons: kSecondaryMouseButton,
  );

  const PointerUpEvent up6 = PointerUpEvent(
    pointer: 6,
    position: Offset(11.0, 9.0),
  );

  testGesture('Recognizes serial taps', (GestureTester tester) {
    serial.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    tester.route(up1);
    GestureBinding.instance!.gestureArena.sweep(1);
    expect(events, <String>['down#1', 'up#1']);

    events.clear();
    tester.async.elapse(const Duration(milliseconds: 100));
    serial.addPointer(down2);
    tester.closeArena(2);
    tester.route(down2);
    tester.route(up2);
    GestureBinding.instance!.gestureArena.sweep(2);
    expect(events, <String>['down#2', 'up#2']);

    events.clear();
    tester.async.elapse(const Duration(milliseconds: 100));
    serial.addPointer(down3);
    tester.closeArena(3);
    tester.route(down3);
    tester.route(up3);
    GestureBinding.instance!.gestureArena.sweep(3);
    expect(events, <String>['down#3', 'up#3']);
  });

  testGesture('Does not steal tap gesture below it in the tree', (GestureTester tester) {
    bool recognizedSingleTap = false;
    final TapGestureRecognizer singleTap = TapGestureRecognizer()
      ..onTap = () {
        recognizedSingleTap = true;
      };

    singleTap.addPointer(down1);
    serial.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    tester.route(up1);
    GestureBinding.instance!.gestureArena.sweep(1);
    expect(events, <String>['down#1', 'up#1']);
    expect(recognizedSingleTap, isTrue);
  });

  testGesture('Fires cancel if competing recognizer declares victory', (GestureTester tester) {
    final WinningGestureRecognizer winner = WinningGestureRecognizer();
    winner.addPointer(down1);
    serial.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    tester.route(up1);
    GestureBinding.instance!.gestureArena.sweep(1);
    expect(events, <String>['down#1', 'cancel#1']);
  });

  testGesture('Fires cancel on second tap and resets if competing with double-tap recognizer', (GestureTester tester) {
    bool recognizedDoubleTap = false;
    final DoubleTapGestureRecognizer doubleTap = DoubleTapGestureRecognizer()
      ..onDoubleTap = () {
        recognizedDoubleTap = true;
      };

    doubleTap.addPointer(down1);
    serial.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    tester.route(up1);
    GestureBinding.instance!.gestureArena.sweep(1);
    expect(events, <String>['down#1', 'up#1']);
    expect(recognizedDoubleTap, isFalse);

    // Second tap will be won explicitly by the double-tap, causing a cancel event.
    events.clear();
    tester.async.elapse(const Duration(milliseconds: 100));
    doubleTap.addPointer(down2);
    serial.addPointer(down2);
    tester.closeArena(2);
    tester.route(down2);
    tester.route(up2);
    GestureBinding.instance!.gestureArena.sweep(2);
    expect(events, <String>['down#2', 'cancel#2']);
    expect(recognizedDoubleTap, isTrue);

    // Due to the earlier cancel, the third tap will be recognized as a first tap.
    events.clear();
    tester.async.elapse(const Duration(milliseconds: 100));
    serial.addPointer(down3);
    tester.closeArena(3);
    tester.route(down3);
    tester.route(up3);
    GestureBinding.instance!.gestureArena.sweep(3);
    expect(events, <String>['down#1', 'up#1']);
  });

  testGesture('Fires cancel and resets for PointerCancelEvent', (GestureTester tester) {
    serial.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    tester.route(cancel1);
    GestureBinding.instance!.gestureArena.sweep(1);
    expect(events, <String>['down#1', 'cancel#1']);

    events.clear();
    tester.async.elapse(const Duration(milliseconds: 100));
    serial.addPointer(down2);
    tester.closeArena(2);
    tester.route(down2);
    tester.route(up2);
    GestureBinding.instance!.gestureArena.sweep(2);
    expect(events, <String>['down#1', 'up#1']);
  });

  testGesture('Fires cancel and resets when pointer dragged past slop tolerance', (GestureTester tester) {
    serial.addPointer(down5);
    tester.closeArena(5);
    tester.route(down5);
    tester.route(move5);
    tester.route(up5);
    GestureBinding.instance!.gestureArena.sweep(5);
    expect(events, <String>['down#1', 'cancel#1']);

    events.clear();
    tester.async.elapse(const Duration(milliseconds: 1000));
    serial.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    tester.route(up1);
    GestureBinding.instance!.gestureArena.sweep(1);
    expect(events, <String>['down#1', 'up#1']);
  });

  testGesture('Resets if times out in between taps', (GestureTester tester) {
    serial.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    tester.route(up1);
    GestureBinding.instance!.gestureArena.sweep(1);
    expect(events, <String>['down#1', 'up#1']);

    events.clear();
    tester.async.elapse(const Duration(milliseconds: 1000));
    serial.addPointer(down2);
    tester.closeArena(2);
    tester.route(down2);
    tester.route(up2);
    GestureBinding.instance!.gestureArena.sweep(2);
    expect(events, <String>['down#1', 'up#1']);
  });

  testGesture('Resets if taps are far apart', (GestureTester tester) {
    serial.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    tester.route(up1);
    GestureBinding.instance!.gestureArena.sweep(1);
    expect(events, <String>['down#1', 'up#1']);

    events.clear();
    tester.async.elapse(const Duration(milliseconds: 100));
    serial.addPointer(down4);
    tester.closeArena(4);
    tester.route(down4);
    tester.route(up4);
    GestureBinding.instance!.gestureArena.sweep(4);
    expect(events, <String>['down#1', 'up#1']);
  });

  testGesture('Serial taps with different buttons will start a new tap sequence', (GestureTester tester) {
    serial.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    tester.route(up1);
    GestureBinding.instance!.gestureArena.sweep(1);
    expect(events, <String>['down#1', 'up#1']);

    events.clear();
    tester.async.elapse(const Duration(milliseconds: 1000));
    serial.addPointer(down6);
    tester.closeArena(6);
    tester.route(down6);
    tester.route(up6);
    GestureBinding.instance!.gestureArena.sweep(6);
    expect(events, <String>['down#1', 'up#1']);
  });

  testGesture('Is no-op if no callbacks are specified', (GestureTester tester) {
    serial = SerialTapGestureRecognizer();
    serial.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    expect(serial.isTrackingPointer, isFalse);
    tester.route(up1);
    GestureBinding.instance!.gestureArena.sweep(1);
    expect(events, <String>[]);
  });

  testGesture('Works for non-primary button', (GestureTester tester) {
    serial.addPointer(down6);
    tester.closeArena(6);
    tester.route(down6);
    tester.route(up6);
    GestureBinding.instance!.gestureArena.sweep(6);
    expect(events, <String>['down#1', 'up#1']);
  });
}

class WinningGestureRecognizer extends PrimaryPointerGestureRecognizer {
  @override
  String get debugDescription => 'winner';

  @override
  void handlePrimaryPointer(PointerEvent event) {
    resolve(GestureDisposition.accepted);
  }
}
