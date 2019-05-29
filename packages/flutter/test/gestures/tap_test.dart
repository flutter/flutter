// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import '../flutter_test_alternative.dart';
import 'gesture_tester.dart';

class TestGestureArenaMember extends GestureArenaMember {
  @override
  void acceptGesture(int key) { }

  @override
  void rejectGesture(int key) { }
}

void main() {
  setUp(ensureGestureBinding);

  // Down/up pair 1: normal tap sequence
  const PointerDownEvent down1 = PointerDownEvent(
    pointer: 1,
    position: Offset(10.0, 10.0),
  );

  const PointerUpEvent up1 = PointerUpEvent(
    pointer: 1,
    position: Offset(11.0, 9.0),
  );

  // Down/up pair 2: normal tap sequence far away from pair 1
  const PointerDownEvent down2 = PointerDownEvent(
    pointer: 2,
    position: Offset(30.0, 30.0),
  );

  const PointerUpEvent up2 = PointerUpEvent(
    pointer: 2,
    position: Offset(31.0, 29.0),
  );

  // Down/move/up sequence 3: intervening motion, more than kTouchSlop. (~21px)
  const PointerDownEvent down3 = PointerDownEvent(
    pointer: 3,
    position: Offset(10.0, 10.0),
  );

  const PointerMoveEvent move3 = PointerMoveEvent(
    pointer: 3,
    position: Offset(25.0, 25.0),
  );

  const PointerUpEvent up3 = PointerUpEvent(
    pointer: 3,
    position: Offset(25.0, 25.0),
  );

  // Down/move/up sequence 4: intervening motion, less than kTouchSlop. (~17px)
  const PointerDownEvent down4 = PointerDownEvent(
    pointer: 4,
    position: Offset(10.0, 10.0),
  );

  const PointerMoveEvent move4 = PointerMoveEvent(
    pointer: 4,
    position: Offset(22.0, 22.0),
  );

  const PointerUpEvent up4 = PointerUpEvent(
    pointer: 4,
    position: Offset(22.0, 22.0),
  );

  // Down/up sequence 5: tap sequence with secondary button
  const PointerDownEvent down5 = PointerDownEvent(
    pointer: 5,
    position: Offset(20.0, 20.0),
    buttons: kSecondaryButton,
  );

  const PointerUpEvent up5 = PointerUpEvent(
    pointer: 5,
    position: Offset(20.0, 20.0),
  );

  testGesture('Should recognize tap', (GestureTester tester) {
    final TapGestureRecognizer tap = TapGestureRecognizer();

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
    final TapGestureRecognizer tap = TapGestureRecognizer();

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
    final TapGestureRecognizer tap = TapGestureRecognizer();

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
    final TapGestureRecognizer tap = TapGestureRecognizer();

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

  testGesture('Short distance does not cancel tap', (GestureTester tester) {
    final TapGestureRecognizer tap = TapGestureRecognizer();

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };
    bool tapCanceled = false;
    tap.onTapCancel = () {
      tapCanceled = true;
    };

    tap.addPointer(down4);
    tester.closeArena(4);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isFalse);
    tester.route(down4);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isFalse);

    tester.route(move4);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isFalse);
    tester.route(up4);
    expect(tapRecognized, isTrue);
    expect(tapCanceled, isFalse);
    GestureBinding.instance.gestureArena.sweep(4);
    expect(tapRecognized, isTrue);
    expect(tapCanceled, isFalse);

    tap.dispose();
  });

  testGesture('Timeout does not cancel tap', (GestureTester tester) {
    final TapGestureRecognizer tap = TapGestureRecognizer();

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
    final TapGestureRecognizer tap = TapGestureRecognizer();

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    tap.addPointer(down1);
    final TestGestureArenaMember member = TestGestureArenaMember();
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
    final TapGestureRecognizer tap = TapGestureRecognizer();

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    tap.addPointer(down1);
    final TestGestureArenaMember member = TestGestureArenaMember();
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
    final TapGestureRecognizer tap = TapGestureRecognizer();

    tap.onTap = () {
      throw Exception(test);
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
    final TapGestureRecognizer tapA = TapGestureRecognizer();
    final TapGestureRecognizer tapB = TapGestureRecognizer();

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
      'swept 1',
      'down 2 to A',
      'down 2 to B',
      'closed 2',
      'routed 2 down',
      'routed 2 up',
      'tapA onTapDown',
      'tapA onTapUp',
      'tapA onTap',
      'swept 2',
      'disposed A',
      'disposed B',
    ]);
  });

  testGesture('PointerCancelEvent cancels tap', (GestureTester tester) {
    const PointerDownEvent down = PointerDownEvent(
        pointer: 5,
        position: Offset(10.0, 10.0),
    );
    const PointerCancelEvent cancel = PointerCancelEvent(
        pointer: 5,
        position: Offset(10.0, 10.0),
    );

    final TapGestureRecognizer tap = TapGestureRecognizer();

    final List<String> recognized = <String>[];
    tap.onTapDown = (_) {
      recognized.add('down');
    };
    tap.onTapUp = (_) {
      recognized.add('up');
    };
    tap.onTap = () {
      recognized.add('tap');
    };
    tap.onTapCancel = () {
      recognized.add('cancel');
    };

    tap.addPointer(down);
    tester.closeArena(5);
    tester.async.elapse(const Duration(milliseconds: 5000));
    expect(recognized, <String>['down']);
    tester.route(cancel);
    expect(recognized, <String>['down', 'cancel']);

    tap.dispose();
  });

  testGesture('PointerCancelEvent after exceeding deadline cancels tap', (GestureTester tester) {
    const PointerDownEvent down = PointerDownEvent(
        pointer: 5,
        position: Offset(10.0, 10.0),
    );
    const PointerCancelEvent cancel = PointerCancelEvent(
        pointer: 5,
        position: Offset(10.0, 10.0),
    );

    final TapGestureRecognizer tap = TapGestureRecognizer();
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer()
      ..onStart = (_) {}; // Need a callback to compete

    final List<String> recognized = <String>[];
    tap.onTapDown = (_) {
      recognized.add('down');
    };
    tap.onTapUp = (_) {
      recognized.add('up');
    };
    tap.onTap = () {
      recognized.add('tap');
    };
    tap.onTapCancel = () {
      recognized.add('cancel');
    };

    tap.addPointer(down);
    drag.addPointer(down);
    tester.closeArena(5);
    tester.route(down);
    expect(recognized, <String>[]);
    tester.async.elapse(const Duration(milliseconds: 1000));
    expect(recognized, <String>['down']);
    tester.route(cancel);
    expect(recognized, <String>['down', 'cancel']);

    tap.dispose();
    drag.dispose();
  });

  testGesture('losing tap gesture recognizer does not send onTapCancel', (GestureTester tester) {
    final TapGestureRecognizer tap = TapGestureRecognizer();
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer();

    final List<String> recognized = <String>[];
    tap.onTapDown = (_) {
      recognized.add('down');
    };
    tap.onTapUp = (_) {
      recognized.add('up');
    };
    tap.onTap = () {
      recognized.add('tap');
    };
    tap.onTapCancel = () {
      recognized.add('cancel');
    };

    tap.addPointer(down3);
    drag.addPointer(down3);
    tester.closeArena(3);
    tester.route(move3);
    GestureBinding.instance.gestureArena.sweep(3);
    expect(recognized, isEmpty);

    tap.dispose();
    drag.dispose();
  });

  group('Enforce consistent-button restriction:', () {
    // Change buttons during down-up sequence 1
    const PointerMoveEvent move1lr = PointerMoveEvent(
      pointer: 1,
      position: Offset(10.0, 10.0),
      buttons: kPrimaryMouseButton | kSecondaryMouseButton,
    );
    const PointerMoveEvent move1r = PointerMoveEvent(
      pointer: 1,
      position: Offset(10.0, 10.0),
      buttons: kSecondaryMouseButton,
    );

    final List<String> recognized = <String>[];
    TapGestureRecognizer tap;
    setUp(() {
      tap = TapGestureRecognizer()
        ..onTapDown = (TapDownDetails details) {
          recognized.add('down');
        }
        ..onTapUp = (TapUpDetails details) {
          recognized.add('up');
        }
        ..onTapCancel = () {
          recognized.add('cancel');
        };
    });

    tearDown(() {
      tap.dispose();
      recognized.clear();
    });

    testGesture('changing buttons before TapDown should cancel gesture without sending cancel', (GestureTester tester) {
      tap.addPointer(down1);
      tester.closeArena(1);
      expect(recognized, <String>[]);

      tester.route(move1lr);
      expect(recognized, <String>[]);

      tester.route(move1r);
      expect(recognized, <String>[]);

      tester.route(up1);
      expect(recognized, <String>[]);

      tap.dispose();
    });

    testGesture('changing buttons before TapDown should not prevent the next tap', (GestureTester tester) {
      tap.addPointer(down1);
      tester.closeArena(1);

      tester.route(move1lr);
      tester.route(move1r);
      tester.route(up1);
      expect(recognized, <String>[]);

      tap.addPointer(down2);
      tester.closeArena(2);
      tester.async.elapse(const Duration(milliseconds: 1000));
      tester.route(up2);
      expect(recognized, <String>['down', 'up']);

      tap.dispose();
    });

    testGesture('changing buttons after TapDown should cancel gesture and send cancel', (GestureTester tester) {
      tap.addPointer(down1);
      tester.closeArena(1);
      expect(recognized, <String>[]);
      tester.async.elapse(const Duration(milliseconds: 1000));
      expect(recognized, <String>['down']);

      tester.route(move1lr);
      expect(recognized, <String>['down', 'cancel']);

      tester.route(move1r);
      expect(recognized, <String>['down', 'cancel']);

      tester.route(up1);
      expect(recognized, <String>['down', 'cancel']);

      tap.dispose();
    });

    testGesture('changing buttons after TapDown should not prevent the next tap', (GestureTester tester) {
      tap.addPointer(down1);
      tester.closeArena(1);
      tester.async.elapse(const Duration(milliseconds: 1000));

      tester.route(move1lr);
      tester.route(move1r);
      tester.route(up1);
      GestureBinding.instance.gestureArena.sweep(1);
      expect(recognized, <String>['down', 'cancel']);

      tap.addPointer(down2);
      tester.closeArena(2);
      tester.async.elapse(const Duration(milliseconds: 1000));
      tester.route(up2);
      GestureBinding.instance.gestureArena.sweep(2);
      expect(recognized, <String>['down', 'cancel', 'down', 'up']);

      tap.dispose();
    });
  });

  group('Recognizers listening on different buttons do not form competition:', () {
    // If a tap gesture has no competitors, a pointer down event triggers
    // onTapDown immediately; if there are competitors, onTapDown is triggered
    // after a timeout. The following tests make sure that tap recognizers
    // listening on different buttons do not form competition.

    final List<String> recognized = <String>[];
    TapGestureRecognizer primary;
    TapGestureRecognizer primary2;
    TapGestureRecognizer secondary;
    setUp(() {
      primary = TapGestureRecognizer()
        ..onTapDown = (TapDownDetails details) {
          recognized.add('primaryDown');
        }
        ..onTapUp = (TapUpDetails details) {
          recognized.add('primaryUp');
        }
        ..onTapCancel = () {
          recognized.add('primaryCancel');
        };
      primary2 = TapGestureRecognizer()
        ..onTapDown = (TapDownDetails details) {
          recognized.add('primary2Down');
        }
        ..onTapUp = (TapUpDetails details) {
          recognized.add('primary2Up');
        }
        ..onTapCancel = () {
          recognized.add('primary2Cancel');
        };
      secondary = TapGestureRecognizer()
        ..onSecondaryTapDown = (TapDownDetails details) {
          recognized.add('secondaryDown');
        }
        ..onSecondaryTapUp = (TapUpDetails details) {
          recognized.add('secondaryUp');
        }
        ..onSecondaryTapCancel = () {
          recognized.add('secondaryCancel');
        };
    });

    tearDown(() {
      recognized.clear();
      primary.dispose();
      primary2.dispose();
      secondary.dispose();
    });

    testGesture('A primary tap recognizer does not form competition with a secondary tap recognizer', (GestureTester tester) {
      primary.addPointer(down1);
      secondary.addPointer(down1);
      tester.closeArena(1);

      tester.route(down1);
      expect(recognized, <String>['primaryDown']);
      recognized.clear();

      tester.route(up1);
      expect(recognized, <String>['primaryUp']);
    });

    testGesture('A primary tap recognizer forms competition with another primary tap recognizer', (GestureTester tester) {
      primary.addPointer(down1);
      primary2.addPointer(down1);
      tester.closeArena(1);

      tester.route(down1);
      expect(recognized, <String>[]);

      tester.async.elapse(const Duration(milliseconds: 500));
      expect(recognized, <String>['primaryDown', 'primary2Down']);
    });
  });

  group('Gestures of different buttons trigger correct callbacks:', () {
    final List<String> recognized = <String>[];
    TapGestureRecognizer tap;
    const PointerCancelEvent cancel1 = PointerCancelEvent(
      pointer: 1,
    );
    const PointerCancelEvent cancel5 = PointerCancelEvent(
      pointer: 5,
    );

    setUp(() {
      tap = TapGestureRecognizer()
        ..onTapDown = (TapDownDetails details) {
          recognized.add('primaryDown');
        }
        ..onTap = () {
          recognized.add('primary');
        }
        ..onTapUp = (TapUpDetails details) {
          recognized.add('primaryUp');
        }
        ..onTapCancel = () {
          recognized.add('primaryCancel');
        }
        ..onSecondaryTapDown = (TapDownDetails details) {
          recognized.add('secondaryDown');
        }
        ..onSecondaryTapUp = (TapUpDetails details) {
          recognized.add('secondaryUp');
        }
        ..onSecondaryTapCancel = () {
          recognized.add('secondaryCancel');
        };
    });

    tearDown(() {
      recognized.clear();
      tap.dispose();
    });

    testGesture('A primary tap should trigger primary callbacks', (GestureTester tester) {
      tap.addPointer(down1);
      tester.closeArena(down1.pointer);
      expect(recognized, <String>[]);
      tester.async.elapse(const Duration(milliseconds: 500));
      expect(recognized, <String>['primaryDown']);
      recognized.clear();

      tester.route(up1);
      expect(recognized, <String>['primaryUp', 'primary']);
      GestureBinding.instance.gestureArena.sweep(down1.pointer);
    });

    testGesture('A primary tap cancel trigger primary callbacks', (GestureTester tester) {
      tap.addPointer(down1);
      tester.closeArena(down1.pointer);
      expect(recognized, <String>[]);
      tester.async.elapse(const Duration(milliseconds: 500));
      expect(recognized, <String>['primaryDown']);
      recognized.clear();

      tester.route(cancel1);
      expect(recognized, <String>['primaryCancel']);
      GestureBinding.instance.gestureArena.sweep(down1.pointer);
    });

    testGesture('A secondary tap should trigger secondary callbacks', (GestureTester tester) {
      tap.addPointer(down5);
      tester.closeArena(down5.pointer);
      expect(recognized, <String>[]);
      tester.async.elapse(const Duration(milliseconds: 500));
      expect(recognized, <String>['secondaryDown']);
      recognized.clear();

      tester.route(up5);
      GestureBinding.instance.gestureArena.sweep(down5.pointer);
      expect(recognized, <String>['secondaryUp']);
    });

    testGesture('A secondary tap cancel should trigger secondary callbacks', (GestureTester tester) {
      tap.addPointer(down5);
      tester.closeArena(down5.pointer);
      expect(recognized, <String>[]);
      tester.async.elapse(const Duration(milliseconds: 500));
      expect(recognized, <String>['secondaryDown']);
      recognized.clear();

      tester.route(cancel5);
      GestureBinding.instance.gestureArena.sweep(down5.pointer);
      expect(recognized, <String>['secondaryCancel']);
    });
  });
}
