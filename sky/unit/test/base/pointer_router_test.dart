import 'dart:sky' as sky;

import 'package:sky/base/hit_test.dart';
import 'package:sky/base/pointer_router.dart';
import 'package:test/test.dart';

class TestPointerEvent extends sky.PointerEvent {
  TestPointerEvent({ this.pointer });

  final int pointer;
}

void main() {
  test('Should route pointers', () {
    bool callbackRan = false;
    void callback(sky.PointerEvent event) {
      callbackRan = true;
    }

    PointerRouter router = new PointerRouter();
    router.addRoute(3, callback);
    expect(router.handleEvent(new TestPointerEvent(pointer: 2), null), equals(EventDisposition.ignored));
    expect(callbackRan, isFalse);
    expect(router.handleEvent(new TestPointerEvent(pointer: 3), null), equals(EventDisposition.processed));
    expect(callbackRan, isTrue);
    callbackRan = false;
    router.removeRoute(3, callback);
    expect(router.handleEvent(new TestPointerEvent(pointer: 3), null), equals(EventDisposition.ignored));
    expect(callbackRan, isFalse);
  });
}
