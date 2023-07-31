import 'package:synchronized/synchronized.dart';
import 'package:test/test.dart';

import 'lock_factory.dart';

void main() {
  group('BasicLock', () {
    run(BasicLockFactory());
  });
  group('ReentrantLock', () {
    run(ReentrantLockFactory());
  });
}

void run(LockFactory factory) {
  Lock newLock() => factory.newLock();
  final operationCount = 500000;

  test('$operationCount operations', () async {
    final count = operationCount;
    int j;

    var sw = Stopwatch();
    j = 0;
    sw.start();
    for (var i = 0; i < count; i++) {
      j += i;
    }
    print(' none ${sw.elapsed}');
    expect(j, count * (count - 1) / 2);

    sw = Stopwatch();
    j = 0;
    sw.start();
    for (var i = 0; i < count; i++) {
      await () async {
        j += i;
      }();
    }
    print('await ${sw.elapsed}');
    expect(j, count * (count - 1) / 2);

    var lock = newLock();
    sw = Stopwatch();
    j = 0;
    sw.start();
    for (var i = 0; i < count; i++) {
      // ignore: unawaited_futures
      lock.synchronized(() {
        j += i;
      });
    }
    // final wait
    await lock.synchronized(() => {});
    print('syncd ${sw.elapsed}');
    expect(j, count * (count - 1) / 2);
  });
}
