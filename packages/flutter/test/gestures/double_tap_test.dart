// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:quiver/testing/async.dart';
import 'package:test/test.dart';

class TestGestureArenaMember extends GestureArenaMember {
  void acceptGesture(Object key) {
    accepted = true;
  }
  void rejectGesture(Object key) {
    rejected = true;
  }
  bool accepted = false;
  bool rejected = false;
}

void main() {

  // Down/up pair 1: normal tap sequence
  const PointerDownEvent down1 = const PointerDownEvent(
    pointer: 1,
    position: const Point(10.0, 10.0)
  );

  const PointerUpEvent up1 = const PointerUpEvent(
    pointer: 1,
    position: const Point(11.0, 9.0)
  );

  // Down/up pair 2: normal tap sequence close to pair 1
  const PointerDownEvent down2 = const PointerDownEvent(
    pointer: 2,
    position: const Point(12.0, 12.0)
  );

  const PointerUpEvent up2 = const PointerUpEvent(
    pointer: 2,
    position: const Point(13.0, 11.0)
  );

  // Down/up pair 3: normal tap sequence far away from pair 1
  const PointerDownEvent down3 = const PointerDownEvent(
    pointer: 3,
    position: const Point(130.0, 130.0)
  );

  const PointerUpEvent up3 = const PointerUpEvent(
    pointer: 3,
    position: const Point(131.0, 129.0)
  );

  // Down/move/up sequence 4: intervening motion
  const PointerDownEvent down4 = const PointerDownEvent(
    pointer: 4,
    position: const Point(10.0, 10.0)
  );

  const PointerMoveEvent move4 = const PointerMoveEvent(
    pointer: 4,
    position: const Point(25.0, 25.0)
  );

  const PointerUpEvent up4 = const PointerUpEvent(
    pointer: 4,
    position: const Point(25.0, 25.0)
  );

  // Down/up pair 5: normal tap sequence identical to pair 1 with different pointer
  const PointerDownEvent down5 = const PointerDownEvent(
    pointer: 5,
    position: const Point(10.0, 10.0)
  );

  const PointerUpEvent up5 = const PointerUpEvent(
    pointer: 5,
    position: const Point(11.0, 9.0)
  );

  test('Should recognize double tap', () {
    PointerRouter router = new PointerRouter();
    GestureArena gestureArena = new GestureArena();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(
      router: router,
      gestureArena: gestureArena
    );

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down1);
    gestureArena.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    gestureArena.sweep(1);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down2);
    gestureArena.close(2);
    expect(doubleTapRecognized, isFalse);
    router.route(down2);
    expect(doubleTapRecognized, isFalse);

    router.route(up2);
    expect(doubleTapRecognized, isTrue);
    gestureArena.sweep(2);
    expect(doubleTapRecognized, isTrue);

    tap.dispose();
  });

  test('Inter-tap distance cancels double tap', () {
    PointerRouter router = new PointerRouter();
    GestureArena gestureArena = new GestureArena();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(
      router: router,
      gestureArena: gestureArena
    );

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down1);
    gestureArena.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    gestureArena.sweep(1);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down3);
    gestureArena.close(3);
    expect(doubleTapRecognized, isFalse);
    router.route(down3);
    expect(doubleTapRecognized, isFalse);

    router.route(up3);
    expect(doubleTapRecognized, isFalse);
    gestureArena.sweep(3);
    expect(doubleTapRecognized, isFalse);

    tap.dispose();
  });

  test('Intra-tap distance cancels double tap', () {
    PointerRouter router = new PointerRouter();
    GestureArena gestureArena = new GestureArena();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(
      router: router,
      gestureArena: gestureArena
    );

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down4);
    gestureArena.close(4);
    expect(doubleTapRecognized, isFalse);
    router.route(down4);
    expect(doubleTapRecognized, isFalse);

    router.route(move4);
    expect(doubleTapRecognized, isFalse);
    router.route(up4);
    expect(doubleTapRecognized, isFalse);
    gestureArena.sweep(4);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down1);
    gestureArena.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down2);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    gestureArena.sweep(1);
    expect(doubleTapRecognized, isFalse);

    tap.dispose();
  });

  test('Inter-tap delay cancels double tap', () {
    PointerRouter router = new PointerRouter();
    GestureArena gestureArena = new GestureArena();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(
      router: router,
      gestureArena: gestureArena
    );

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    new FakeAsync().run((FakeAsync async) {
      tap.addPointer(down1);
      gestureArena.close(1);
      expect(doubleTapRecognized, isFalse);
      router.route(down1);
      expect(doubleTapRecognized, isFalse);

      router.route(up1);
      expect(doubleTapRecognized, isFalse);
      gestureArena.sweep(1);
      expect(doubleTapRecognized, isFalse);

      async.elapse(new Duration(milliseconds: 5000));
      tap.addPointer(down2);
      gestureArena.close(2);
      expect(doubleTapRecognized, isFalse);
      router.route(down2);
      expect(doubleTapRecognized, isFalse);

      router.route(up2);
      expect(doubleTapRecognized, isFalse);
      gestureArena.sweep(2);
      expect(doubleTapRecognized, isFalse);
    });

    tap.dispose();
  });

  test('Inter-tap delay resets double tap, allowing third tap to be a double-tap', () {
    PointerRouter router = new PointerRouter();
    GestureArena gestureArena = new GestureArena();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(
      router: router,
      gestureArena: gestureArena
    );

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    new FakeAsync().run((FakeAsync async) {
      tap.addPointer(down1);
      gestureArena.close(1);
      expect(doubleTapRecognized, isFalse);
      router.route(down1);
      expect(doubleTapRecognized, isFalse);

      router.route(up1);
      expect(doubleTapRecognized, isFalse);
      gestureArena.sweep(1);
      expect(doubleTapRecognized, isFalse);

      async.elapse(new Duration(milliseconds: 5000));
      tap.addPointer(down2);
      gestureArena.close(2);
      expect(doubleTapRecognized, isFalse);
      router.route(down2);
      expect(doubleTapRecognized, isFalse);

      router.route(up2);
      expect(doubleTapRecognized, isFalse);
      gestureArena.sweep(2);
      expect(doubleTapRecognized, isFalse);

      async.elapse(new Duration(milliseconds: 100));
      tap.addPointer(down5);
      gestureArena.close(5);
      expect(doubleTapRecognized, isFalse);
      router.route(down5);
      expect(doubleTapRecognized, isFalse);

      router.route(up5);
      expect(doubleTapRecognized, isTrue);
      gestureArena.sweep(5);
      expect(doubleTapRecognized, isTrue);
    });

    tap.dispose();
  });

  test('Intra-tap delay does not cancel double tap', () {
    PointerRouter router = new PointerRouter();
    GestureArena gestureArena = new GestureArena();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(
      router: router,
      gestureArena: gestureArena
    );

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    new FakeAsync().run((FakeAsync async) {
      tap.addPointer(down1);
      gestureArena.close(1);
      expect(doubleTapRecognized, isFalse);
      router.route(down1);
      expect(doubleTapRecognized, isFalse);

      async.elapse(new Duration(milliseconds: 1000));
      router.route(up1);
      expect(doubleTapRecognized, isFalse);
      gestureArena.sweep(1);
      expect(doubleTapRecognized, isFalse);

      tap.addPointer(down2);
      gestureArena.close(2);
      expect(doubleTapRecognized, isFalse);
      router.route(down2);
      expect(doubleTapRecognized, isFalse);

      router.route(up2);
      expect(doubleTapRecognized, isTrue);
      gestureArena.sweep(2);
      expect(doubleTapRecognized, isTrue);
    });

    tap.dispose();
  });

  test('Should not recognize two overlapping taps', () {
    PointerRouter router = new PointerRouter();
    GestureArena gestureArena = new GestureArena();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(
      router: router,
      gestureArena: gestureArena
    );

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down1);
    gestureArena.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down2);
    gestureArena.close(2);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    gestureArena.sweep(1);
    expect(doubleTapRecognized, isFalse);

    router.route(up2);
    expect(doubleTapRecognized, isFalse);
    gestureArena.sweep(2);
    expect(doubleTapRecognized, isFalse);

    tap.dispose();
  });

  test('Should recognize one tap of group followed by second tap', () {
    PointerRouter router = new PointerRouter();
    GestureArena gestureArena = new GestureArena();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(
      router: router,
      gestureArena: gestureArena
    );

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down1);
    gestureArena.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down2);
    gestureArena.close(2);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    gestureArena.sweep(1);
    expect(doubleTapRecognized, isFalse);

    router.route(up2);
    expect(doubleTapRecognized, isFalse);
    gestureArena.sweep(2);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down1);
    gestureArena.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isTrue);
    gestureArena.sweep(1);
    expect(doubleTapRecognized, isTrue);

    tap.dispose();

  });

  test('Should cancel on arena reject during first tap', () {
    PointerRouter router = new PointerRouter();
    GestureArena gestureArena = new GestureArena();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(
      router: router,
      gestureArena: gestureArena
    );

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down1);
    TestGestureArenaMember member = new TestGestureArenaMember();
    GestureArenaEntry entry = gestureArena.add(1, member);
    gestureArena.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    entry.resolve(GestureDisposition.accepted);
    expect(member.accepted, isTrue);
    expect(doubleTapRecognized, isFalse);
    gestureArena.sweep(1);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down2);
    gestureArena.close(2);
    expect(doubleTapRecognized, isFalse);
    router.route(down2);
    expect(doubleTapRecognized, isFalse);

    router.route(up2);
    expect(doubleTapRecognized, isFalse);
    gestureArena.sweep(2);
    expect(doubleTapRecognized, isFalse);

    tap.dispose();
  });

  test('Should cancel on arena reject between taps', () {
    PointerRouter router = new PointerRouter();
    GestureArena gestureArena = new GestureArena();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(
      router: router,
      gestureArena: gestureArena
    );

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down1);
    TestGestureArenaMember member = new TestGestureArenaMember();
    GestureArenaEntry entry = gestureArena.add(1, member);
    gestureArena.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    gestureArena.sweep(1);
    expect(doubleTapRecognized, isFalse);

    entry.resolve(GestureDisposition.accepted);
    expect(member.accepted, isTrue);

    tap.addPointer(down2);
    gestureArena.close(2);
    expect(doubleTapRecognized, isFalse);
    router.route(down2);
    expect(doubleTapRecognized, isFalse);

    router.route(up2);
    expect(doubleTapRecognized, isFalse);
    gestureArena.sweep(2);
    expect(doubleTapRecognized, isFalse);

    tap.dispose();
  });

  test('Should cancel on arena reject during last tap', () {
    PointerRouter router = new PointerRouter();
    GestureArena gestureArena = new GestureArena();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(
      router: router,
      gestureArena: gestureArena
    );

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down1);
    TestGestureArenaMember member = new TestGestureArenaMember();
    GestureArenaEntry entry = gestureArena.add(1, member);
    gestureArena.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    gestureArena.sweep(1);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down2);
    gestureArena.close(2);
    expect(doubleTapRecognized, isFalse);
    router.route(down2);
    expect(doubleTapRecognized, isFalse);

    entry.resolve(GestureDisposition.accepted);
    expect(member.accepted, isTrue);

    router.route(up2);
    expect(doubleTapRecognized, isFalse);
    gestureArena.sweep(2);
    expect(doubleTapRecognized, isFalse);

    tap.dispose();
  });

  test('Passive gesture should trigger on double tap cancel', () {
    PointerRouter router = new PointerRouter();
    GestureArena gestureArena = new GestureArena();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(
      router: router,
      gestureArena: gestureArena
    );

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    new FakeAsync().run((FakeAsync async) {
      tap.addPointer(down1);
      TestGestureArenaMember member = new TestGestureArenaMember();
      gestureArena.add(1, member);
      gestureArena.close(1);
      expect(doubleTapRecognized, isFalse);
      router.route(down1);
      expect(doubleTapRecognized, isFalse);

      router.route(up1);
      expect(doubleTapRecognized, isFalse);
      gestureArena.sweep(1);
      expect(doubleTapRecognized, isFalse);

      expect(member.accepted, isFalse);

      async.elapse(const Duration(milliseconds: 5000));

      expect(member.accepted, isTrue);
    });

    tap.dispose();
  });

}
