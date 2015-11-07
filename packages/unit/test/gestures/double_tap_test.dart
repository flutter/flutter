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
  final PointerInputEvent down1 = new PointerInputEvent(
    pointer: 1,
    type: 'pointerdown',
    x: 10.0,
    y: 10.0
  );

  final PointerInputEvent up1 = new PointerInputEvent(
    pointer: 1,
    type: 'pointerup',
    x: 11.0,
    y: 9.0
  );

  // Down/up pair 2: normal tap sequence close to pair 1
  final PointerInputEvent down2 = new PointerInputEvent(
    pointer: 2,
    type: 'pointerdown',
    x: 12.0,
    y: 12.0
  );

  final PointerInputEvent up2 = new PointerInputEvent(
    pointer: 2,
    type: 'pointerup',
    x: 13.0,
    y: 11.0
  );

  // Down/up pair 3: normal tap sequence far away from pair 1
  final PointerInputEvent down3 = new PointerInputEvent(
    pointer: 3,
    type: 'pointerdown',
    x: 130.0,
    y: 130.0
  );

  final PointerInputEvent up3 = new PointerInputEvent(
    pointer: 3,
    type: 'pointerup',
    x: 131.0,
    y: 129.0
  );

  // Down/move/up sequence 4: intervening motion
  final PointerInputEvent down4 = new PointerInputEvent(
    pointer: 4,
    type: 'pointerdown',
    x: 10.0,
    y: 10.0
  );

  final PointerInputEvent move4 = new PointerInputEvent(
    pointer: 4,
    type: 'pointermove',
    x: 25.0,
    y: 25.0
  );

  final PointerInputEvent up4 = new PointerInputEvent(
    pointer: 4,
    type: 'pointerup',
    x: 25.0,
    y: 25.0
  );

  // Down/up pair 5: normal tap sequence identical to pair 1 with different pointer
  final PointerInputEvent down5 = new PointerInputEvent(
    pointer: 5,
    type: 'pointerdown',
    x: 10.0,
    y: 10.0
  );

  final PointerInputEvent up5 = new PointerInputEvent(
    pointer: 5,
    type: 'pointerup',
    x: 11.0,
    y: 9.0
  );

  test('Should recognize double tap', () {
    PointerRouter router = new PointerRouter();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(router: router);

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down1);
    GestureArena.instance.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    GestureArena.instance.sweep(1);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down2);
    GestureArena.instance.close(2);
    expect(doubleTapRecognized, isFalse);
    router.route(down2);
    expect(doubleTapRecognized, isFalse);

    router.route(up2);
    expect(doubleTapRecognized, isTrue);
    GestureArena.instance.sweep(2);
    expect(doubleTapRecognized, isTrue);

    tap.dispose();
  });

  test('Inter-tap distance cancels double tap', () {
    PointerRouter router = new PointerRouter();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(router: router);

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down1);
    GestureArena.instance.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    GestureArena.instance.sweep(1);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down3);
    GestureArena.instance.close(3);
    expect(doubleTapRecognized, isFalse);
    router.route(down3);
    expect(doubleTapRecognized, isFalse);

    router.route(up3);
    expect(doubleTapRecognized, isFalse);
    GestureArena.instance.sweep(3);
    expect(doubleTapRecognized, isFalse);

    tap.dispose();
  });

  test('Intra-tap distance cancels double tap', () {
    PointerRouter router = new PointerRouter();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(router: router);

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down4);
    GestureArena.instance.close(4);
    expect(doubleTapRecognized, isFalse);
    router.route(down4);
    expect(doubleTapRecognized, isFalse);

    router.route(move4);
    expect(doubleTapRecognized, isFalse);
    router.route(up4);
    expect(doubleTapRecognized, isFalse);
    GestureArena.instance.sweep(4);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down1);
    GestureArena.instance.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down2);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    GestureArena.instance.sweep(1);
    expect(doubleTapRecognized, isFalse);

    tap.dispose();
  });

  test('Inter-tap delay cancels double tap', () {
    PointerRouter router = new PointerRouter();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(router: router);

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    new FakeAsync().run((FakeAsync async) {
      tap.addPointer(down1);
      GestureArena.instance.close(1);
      expect(doubleTapRecognized, isFalse);
      router.route(down1);
      expect(doubleTapRecognized, isFalse);

      router.route(up1);
      expect(doubleTapRecognized, isFalse);
      GestureArena.instance.sweep(1);
      expect(doubleTapRecognized, isFalse);

      async.elapse(new Duration(milliseconds: 5000));
      tap.addPointer(down2);
      GestureArena.instance.close(2);
      expect(doubleTapRecognized, isFalse);
      router.route(down2);
      expect(doubleTapRecognized, isFalse);

      router.route(up2);
      expect(doubleTapRecognized, isFalse);
      GestureArena.instance.sweep(2);
      expect(doubleTapRecognized, isFalse);
    });

    tap.dispose();
  });

  test('Inter-tap delay resets double tap, allowing third tap to be a double-tap', () {
    PointerRouter router = new PointerRouter();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(router: router);

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    new FakeAsync().run((FakeAsync async) {
      tap.addPointer(down1);
      GestureArena.instance.close(1);
      expect(doubleTapRecognized, isFalse);
      router.route(down1);
      expect(doubleTapRecognized, isFalse);

      router.route(up1);
      expect(doubleTapRecognized, isFalse);
      GestureArena.instance.sweep(1);
      expect(doubleTapRecognized, isFalse);

      async.elapse(new Duration(milliseconds: 5000));
      tap.addPointer(down2);
      GestureArena.instance.close(2);
      expect(doubleTapRecognized, isFalse);
      router.route(down2);
      expect(doubleTapRecognized, isFalse);

      router.route(up2);
      expect(doubleTapRecognized, isFalse);
      GestureArena.instance.sweep(2);
      expect(doubleTapRecognized, isFalse);

      async.elapse(new Duration(milliseconds: 100));
      tap.addPointer(down5);
      GestureArena.instance.close(5);
      expect(doubleTapRecognized, isFalse);
      router.route(down5);
      expect(doubleTapRecognized, isFalse);

      router.route(up5);
      expect(doubleTapRecognized, isTrue);
      GestureArena.instance.sweep(5);
      expect(doubleTapRecognized, isTrue);
    });

    tap.dispose();
  });

  test('Intra-tap delay does not cancel double tap', () {
    PointerRouter router = new PointerRouter();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(router: router);

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    new FakeAsync().run((FakeAsync async) {
      tap.addPointer(down1);
      GestureArena.instance.close(1);
      expect(doubleTapRecognized, isFalse);
      router.route(down1);
      expect(doubleTapRecognized, isFalse);

      async.elapse(new Duration(milliseconds: 1000));
      router.route(up1);
      expect(doubleTapRecognized, isFalse);
      GestureArena.instance.sweep(1);
      expect(doubleTapRecognized, isFalse);

      tap.addPointer(down2);
      GestureArena.instance.close(2);
      expect(doubleTapRecognized, isFalse);
      router.route(down2);
      expect(doubleTapRecognized, isFalse);

      router.route(up2);
      expect(doubleTapRecognized, isTrue);
      GestureArena.instance.sweep(2);
      expect(doubleTapRecognized, isTrue);
    });

    tap.dispose();
  });

  test('Should not recognize two overlapping taps', () {
    PointerRouter router = new PointerRouter();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(router: router);

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down1);
    GestureArena.instance.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down2);
    GestureArena.instance.close(2);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    GestureArena.instance.sweep(1);
    expect(doubleTapRecognized, isFalse);

    router.route(up2);
    expect(doubleTapRecognized, isFalse);
    GestureArena.instance.sweep(2);
    expect(doubleTapRecognized, isFalse);

    tap.dispose();
  });

  test('Should recognize one tap of group followed by second tap', () {
    PointerRouter router = new PointerRouter();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(router: router);

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down1);
    GestureArena.instance.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down2);
    GestureArena.instance.close(2);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    GestureArena.instance.sweep(1);
    expect(doubleTapRecognized, isFalse);

    router.route(up2);
    expect(doubleTapRecognized, isFalse);
    GestureArena.instance.sweep(2);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down1);
    GestureArena.instance.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isTrue);
    GestureArena.instance.sweep(1);
    expect(doubleTapRecognized, isTrue);

    tap.dispose();

  });

  test('Should cancel on arena reject during first tap', () {
    PointerRouter router = new PointerRouter();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(router: router);

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down1);
    TestGestureArenaMember member = new TestGestureArenaMember();
    GestureArenaEntry entry = GestureArena.instance.add(1, member);
    GestureArena.instance.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    entry.resolve(GestureDisposition.accepted);
    expect(member.accepted, isTrue);
    expect(doubleTapRecognized, isFalse);
    GestureArena.instance.sweep(1);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down2);
    GestureArena.instance.close(2);
    expect(doubleTapRecognized, isFalse);
    router.route(down2);
    expect(doubleTapRecognized, isFalse);

    router.route(up2);
    expect(doubleTapRecognized, isFalse);
    GestureArena.instance.sweep(2);
    expect(doubleTapRecognized, isFalse);

    tap.dispose();
  });

  test('Should cancel on arena reject between taps', () {
    PointerRouter router = new PointerRouter();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(router: router);

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down1);
    TestGestureArenaMember member = new TestGestureArenaMember();
    GestureArenaEntry entry = GestureArena.instance.add(1, member);
    GestureArena.instance.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    GestureArena.instance.sweep(1);
    expect(doubleTapRecognized, isFalse);

    entry.resolve(GestureDisposition.accepted);
    expect(member.accepted, isTrue);

    tap.addPointer(down2);
    GestureArena.instance.close(2);
    expect(doubleTapRecognized, isFalse);
    router.route(down2);
    expect(doubleTapRecognized, isFalse);

    router.route(up2);
    expect(doubleTapRecognized, isFalse);
    GestureArena.instance.sweep(2);
    expect(doubleTapRecognized, isFalse);

    tap.dispose();
  });

  test('Should cancel on arena reject during last tap', () {
    PointerRouter router = new PointerRouter();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(router: router);

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    tap.addPointer(down1);
    TestGestureArenaMember member = new TestGestureArenaMember();
    GestureArenaEntry entry = GestureArena.instance.add(1, member);
    GestureArena.instance.close(1);
    expect(doubleTapRecognized, isFalse);
    router.route(down1);
    expect(doubleTapRecognized, isFalse);

    router.route(up1);
    expect(doubleTapRecognized, isFalse);
    GestureArena.instance.sweep(1);
    expect(doubleTapRecognized, isFalse);

    tap.addPointer(down2);
    GestureArena.instance.close(2);
    expect(doubleTapRecognized, isFalse);
    router.route(down2);
    expect(doubleTapRecognized, isFalse);

    entry.resolve(GestureDisposition.accepted);
    expect(member.accepted, isTrue);

    router.route(up2);
    expect(doubleTapRecognized, isFalse);
    GestureArena.instance.sweep(2);
    expect(doubleTapRecognized, isFalse);

    tap.dispose();
  });

  test('Passive gesture should trigger on double tap cancel', () {
    PointerRouter router = new PointerRouter();
    DoubleTapGestureRecognizer tap = new DoubleTapGestureRecognizer(router: router);

    bool doubleTapRecognized = false;
    tap.onDoubleTap = () {
      doubleTapRecognized = true;
    };

    new FakeAsync().run((FakeAsync async) {
      tap.addPointer(down1);
      TestGestureArenaMember member = new TestGestureArenaMember();
      GestureArena.instance.add(1, member);
      GestureArena.instance.close(1);
      expect(doubleTapRecognized, isFalse);
      router.route(down1);
      expect(doubleTapRecognized, isFalse);

      router.route(up1);
      expect(doubleTapRecognized, isFalse);
      GestureArena.instance.sweep(1);
      expect(doubleTapRecognized, isFalse);

      expect(member.accepted, isFalse);

      async.elapse(new Duration(milliseconds: 5000));

      expect(member.accepted, isTrue);
    });

    tap.dispose();
  });

}
