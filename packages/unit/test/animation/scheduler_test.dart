import 'package:flutter/animation.dart';
import 'package:test/test.dart';

void main() {
  test("Check for a time dilation being in effect", () {
    expect(timeDilation, equals(1.0));
  });

  test("Can cancel queued callback", () {
    int secondId;

    bool firstCallbackRan = false;
    bool secondCallbackRan = false;

    void firstCallback(Duration timeStamp) {
      expect(firstCallbackRan, isFalse);
      expect(secondCallbackRan, isFalse);
      expect(timeStamp.inMilliseconds, equals(16));
      firstCallbackRan = true;
      scheduler.cancelAnimationFrame(secondId);
    }

    void secondCallback(Duration timeStamp) {
      expect(firstCallbackRan, isTrue);
      expect(secondCallbackRan, isFalse);
      expect(timeStamp.inMilliseconds, equals(16));
      secondCallbackRan = true;
    }

    scheduler.requestAnimationFrame(firstCallback);
    secondId = scheduler.requestAnimationFrame(secondCallback);

    scheduler.beginFrame(const Duration(milliseconds: 16));

    expect(firstCallbackRan, isTrue);
    expect(secondCallbackRan, isFalse);

    firstCallbackRan = false;
    secondCallbackRan = false;

    scheduler.beginFrame(const Duration(milliseconds: 32));

    expect(firstCallbackRan, isFalse);
    expect(secondCallbackRan, isFalse);
  });
}
