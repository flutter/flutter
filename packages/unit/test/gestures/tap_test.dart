import 'package:flutter/gestures.dart';
import 'package:quiver/testing/async.dart';
import 'package:test/test.dart';

class TestGestureArenaMember extends GestureArenaMember {
  void acceptGesture(Object key) {}
  void rejectGesture(Object key) {}
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

  // Down/up pair 2: normal tap sequence far away from pair 1
  const PointerDownEvent down2 = const PointerDownEvent(
    pointer: 2,
    position: const Point(30.0, 30.0)
  );

  const PointerUpEvent up2 = const PointerUpEvent(
    pointer: 2,
    position: const Point(31.0, 29.0)
  );

  // Down/move/up sequence 3: intervening motion
  const PointerDownEvent down3 = const PointerDownEvent(
    pointer: 3,
    position: const Point(10.0, 10.0)
  );

  const PointerMoveEvent move3 = const PointerMoveEvent(
    pointer: 3,
    position: const Point(25.0, 25.0)
  );

  const PointerUpEvent up3 = const PointerUpEvent(
    pointer: 3,
    position: const Point(25.0, 25.0)
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
    bool tapCanceled = false;
    tap.onTapCancel = () {
      tapCanceled = true;
    };

    tap.addPointer(down3);
    GestureArena.instance.close(3);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isFalse);
    router.route(down3);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isFalse);

    router.route(move3);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isTrue);
    router.route(up3);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isTrue);
    GestureArena.instance.sweep(3);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isTrue);

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
