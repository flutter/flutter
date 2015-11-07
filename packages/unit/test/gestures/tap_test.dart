import 'package:flutter/gestures.dart';
import 'package:quiver/testing/async.dart';
import 'package:test/test.dart';

class TestGestureArenaMember extends GestureArenaMember {
  void acceptGesture(Object key) {}
  void rejectGesture(Object key) {}
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

  // Down/up pair 2: normal tap sequence far away from pair 1
  final PointerInputEvent down2 = new PointerInputEvent(
    pointer: 2,
    type: 'pointerdown',
    x: 30.0,
    y: 30.0
  );

  final PointerInputEvent up2 = new PointerInputEvent(
    pointer: 2,
    type: 'pointerup',
    x: 31.0,
    y: 29.0
  );

  // Down/move/up sequence 3: intervening motion
  final PointerInputEvent down3 = new PointerInputEvent(
    pointer: 3,
    type: 'pointerdown',
    x: 10.0,
    y: 10.0
  );

  final PointerInputEvent move3 = new PointerInputEvent(
    pointer: 3,
    type: 'pointermove',
    x: 25.0,
    y: 25.0
  );

  final PointerInputEvent up3 = new PointerInputEvent(
    pointer: 3,
    type: 'pointerup',
    x: 25.0,
    y: 25.0
  );

  test('Should recognize tap', () {
    PointerRouter router = new PointerRouter();
    TapGestureRecognizer tap = new TapGestureRecognizer(router: router);

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    tap.addPointer(down1);
    GestureArena.instance.close(1);
    expect(tapRecognized, isFalse);
    router.route(down1);
    expect(tapRecognized, isFalse);

    router.route(up1);
    expect(tapRecognized, isTrue);
    GestureArena.instance.sweep(1);
    expect(tapRecognized, isTrue);

    tap.dispose();
  });

  test('No duplicate tap events', () {
    PointerRouter router = new PointerRouter();
    TapGestureRecognizer tap = new TapGestureRecognizer(router: router);

    int tapsRecognized = 0;
    tap.onTap = () {
      tapsRecognized++;
    };

    tap.addPointer(down1);
    GestureArena.instance.close(1);
    expect(tapsRecognized, 0);
    router.route(down1);
    expect(tapsRecognized, 0);

    router.route(up1);
    expect(tapsRecognized, 1);
    GestureArena.instance.sweep(1);
    expect(tapsRecognized, 1);

    tap.addPointer(down1);
    GestureArena.instance.close(1);
    expect(tapsRecognized, 1);
    router.route(down1);
    expect(tapsRecognized, 1);

    router.route(up1);
    expect(tapsRecognized, 2);
    GestureArena.instance.sweep(1);
    expect(tapsRecognized, 2);

    tap.dispose();
  });

  test('Should not recognize two overlapping taps', () {
    PointerRouter router = new PointerRouter();
    TapGestureRecognizer tap = new TapGestureRecognizer(router: router);

    int tapsRecognized = 0;
    tap.onTap = () {
      tapsRecognized++;
    };

    tap.addPointer(down1);
    GestureArena.instance.close(1);
    expect(tapsRecognized, 0);
    router.route(down1);
    expect(tapsRecognized, 0);

    tap.addPointer(down2);
    GestureArena.instance.close(2);
    expect(tapsRecognized, 0);
    router.route(down1);
    expect(tapsRecognized, 0);


    router.route(up1);
    expect(tapsRecognized, 1);
    GestureArena.instance.sweep(1);
    expect(tapsRecognized, 1);

    router.route(up2);
    expect(tapsRecognized, 1);
    GestureArena.instance.sweep(2);
    expect(tapsRecognized, 1);

    tap.dispose();
  });

  test('Distance cancels tap', () {
    PointerRouter router = new PointerRouter();
    TapGestureRecognizer tap = new TapGestureRecognizer(router: router);

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    tap.addPointer(down3);
    GestureArena.instance.close(3);
    expect(tapRecognized, isFalse);
    router.route(down3);
    expect(tapRecognized, isFalse);

    router.route(move3);
    expect(tapRecognized, isFalse);
    router.route(up3);
    expect(tapRecognized, isFalse);
    GestureArena.instance.sweep(3);
    expect(tapRecognized, isFalse);

    tap.dispose();
  });

  test('Timeout does not cancel tap', () {
    PointerRouter router = new PointerRouter();
    TapGestureRecognizer tap = new TapGestureRecognizer(router: router);

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    new FakeAsync().run((FakeAsync async) {
      tap.addPointer(down1);
      GestureArena.instance.close(1);
      expect(tapRecognized, isFalse);
      router.route(down1);
      expect(tapRecognized, isFalse);

      async.elapse(new Duration(milliseconds: 500));
      expect(tapRecognized, isFalse);
      router.route(up1);
      expect(tapRecognized, isTrue);
      GestureArena.instance.sweep(1);
      expect(tapRecognized, isTrue);
    });

    tap.dispose();
  });

  test('Should yield to other arena members', () {
    PointerRouter router = new PointerRouter();
    TapGestureRecognizer tap = new TapGestureRecognizer(router: router);

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    tap.addPointer(down1);
    TestGestureArenaMember member = new TestGestureArenaMember();
    GestureArenaEntry entry = GestureArena.instance.add(1, member);
    GestureArena.instance.hold(1);
    GestureArena.instance.close(1);
    expect(tapRecognized, isFalse);
    router.route(down1);
    expect(tapRecognized, isFalse);

    router.route(up1);
    expect(tapRecognized, isFalse);
    GestureArena.instance.sweep(1);
    expect(tapRecognized, isFalse);

    entry.resolve(GestureDisposition.accepted);
    expect(tapRecognized, isFalse);

    tap.dispose();
  });

  test('Should trigger on release of held arena', () {
    PointerRouter router = new PointerRouter();
    TapGestureRecognizer tap = new TapGestureRecognizer(router: router);

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    tap.addPointer(down1);
    TestGestureArenaMember member = new TestGestureArenaMember();
    GestureArenaEntry entry = GestureArena.instance.add(1, member);
    GestureArena.instance.hold(1);
    GestureArena.instance.close(1);
    expect(tapRecognized, isFalse);
    router.route(down1);
    expect(tapRecognized, isFalse);

    router.route(up1);
    expect(tapRecognized, isFalse);
    GestureArena.instance.sweep(1);
    expect(tapRecognized, isFalse);

    entry.resolve(GestureDisposition.rejected);
    expect(tapRecognized, isTrue);

    tap.dispose();
  });

}
