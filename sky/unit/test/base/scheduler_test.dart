import 'package:sky/base/scheduler.dart' as scheduler;
import 'package:test/test.dart';

void main() {
  test("Can cancel queued callback", () {
    int secondId;

    bool firstCallbackRan = false;
    bool secondCallbackRan = false;

    void firstCallback(double timeStamp) {
      expect(firstCallbackRan, isFalse);
      expect(secondCallbackRan, isFalse);
      expect(timeStamp, equals(16.0));
      firstCallbackRan = true;
      scheduler.cancelAnimationFrame(secondId);
    }

    void secondCallback(double timeStamp) {
      expect(firstCallbackRan, isTrue);
      expect(secondCallbackRan, isFalse);
      expect(timeStamp, equals(16.0));
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
