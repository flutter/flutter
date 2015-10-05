import 'package:sky/animation.dart';
import 'package:test/test.dart';

void main() {
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

    scheduler.beginFrame(16.0);

    expect(firstCallbackRan, isTrue);
    expect(secondCallbackRan, isFalse);

    firstCallbackRan = false;
    secondCallbackRan = false;

    scheduler.beginFrame(32.0);

    expect(firstCallbackRan, isFalse);
    expect(secondCallbackRan, isFalse);
  });
}
