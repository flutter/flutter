// Copyright (c) 2016, Alexandre Roux Tekartik. All rights reserved. Use of this source code

// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:synchronized/src/basic_lock.dart';
import 'package:synchronized/synchronized.dart';
import 'package:test/test.dart';

import 'lock_factory.dart';

void main() {
  lockMain(BasicLockFactory());
}

void lockMain(LockFactory lockFactory) {
  Lock newLock() => lockFactory.newLock();

  group('synchronized', () {
    test('two_locks', () async {
      var lock1 = newLock();
      var lock2 = newLock();

      bool? ok;
      await lock1.synchronized(() async {
        await lock2.synchronized(() async {
          expect(lock2.locked, isTrue);
          ok = true;
        });
      });
      expect(ok, isTrue);
    });

    test('order', () async {
      final lock = newLock();
      final list = <int>[];
      final future1 = lock.synchronized(() async {
        list.add(1);
      });
      final future2 = lock.synchronized(() async {
        await sleep(10);
        list.add(2);
        return 'text';
      });
      final future3 = lock.synchronized(() {
        list.add(3);
        return 1234;
      });
      expect(list, [1]);
      await Future.wait([future1, future2, future3]);
      expect(await future1, isNull);
      expect(await future2, 'text');
      expect(await future3, 1234);
      expect(list, [1, 2, 3]);
    });

    test('queued_value', () async {
      final lock = newLock();
      final value1 = lock.synchronized(() async {
        await sleep(1);
        return 'value1';
      });
      expect(await lock.synchronized(() => 'value2'), 'value2');
      expect(await value1, 'value1');
    });

    group('perf', () {
      final operationCount = 10000;

      test('$operationCount operations', () async {
        var count = operationCount;
        int j;

        final sw1 = Stopwatch();
        j = 0;
        sw1.start();
        for (var i = 0; i < count; i++) {
          j += i;
        }
        sw1.stop();
        expect(j, count * (count - 1) / 2);

        final sw2 = Stopwatch();
        j = 0;
        sw2.start();
        for (var i = 0; i < count; i++) {
          await () async {
            j += i;
          }();
        }
        sw2.stop();
        expect(j, count * (count - 1) / 2);

        var lock = newLock();
        final sw3 = Stopwatch();
        j = 0;
        sw3.start();
        for (var i = 0; i < count; i++) {
          // ignore: unawaited_futures
          lock.synchronized(() {
            j += i;
          });
        }
        // final wait
        await lock.synchronized(() => {});
        expect(lock.locked, isFalse);
        sw3.stop();
        expect(j, count * (count - 1) / 2);

        final sw4 = Stopwatch();
        j = 0;
        sw4.start();
        for (var i = 0; i < count; i++) {
          await lock.synchronized(() async {
            await Future.value();
            j += i;
          });
        }
        // final wait
        expect(lock.locked, isFalse);
        sw4.stop();
        expect(j, count * (count - 1) / 2);

        print('  none ${sw1.elapsed}');
        print(' await ${sw2.elapsed}');
        print(' syncd ${sw3.elapsed}');
        print('asyncd ${sw4.elapsed}');
      });
    });

    group('timeout', () {
      test('1_ms', () async {
        final lock = newLock();
        final completer = Completer();
        final future = lock.synchronized(() async {
          await completer.future;
        });
        try {
          await lock.synchronized(() {},
              timeout: const Duration(milliseconds: 1));
          fail('should fail');
        } on TimeoutException catch (_) {}
        completer.complete();
        await future;
      });

      test('100_ms', () async {
        // var isNewTiming = await isDart2AsyncTiming();
        // hoping timint is ok...
        final lock = newLock();

        var ran1 = false;
        var ran2 = false;
        var ran3 = false;
        var ran4 = false;
        // hold for 5ms
        // ignore: unawaited_futures
        lock.synchronized(() async {
          await sleep(1000);
        });

        try {
          await lock.synchronized(() {
            ran1 = true;
          }, timeout: const Duration(milliseconds: 1));
        } on TimeoutException catch (_) {}

        try {
          await lock.synchronized(() async {
            await sleep(5000);
            ran2 = true;
          }, timeout: const Duration(milliseconds: 1));
          // fail('should fail');
        } on TimeoutException catch (_) {}

        try {
          // ignore: unawaited_futures
          lock.synchronized(() {
            ran4 = true;
          }, timeout: const Duration(milliseconds: 2000));
        } on TimeoutException catch (_) {}

        // waiting long enough
        await lock.synchronized(() {
          ran3 = true;
        }, timeout: const Duration(milliseconds: 2000));

        expect(ran1, isFalse, reason: 'ran1 should be false');
        expect(ran2, isFalse, reason: 'ran2 should be false');
        expect(ran3, isTrue, reason: 'ran3 should be true');
        expect(ran4, isTrue, reason: 'ran4 should be true');
      });

      test('1_ms_with_error', () async {
        var ok = false;
        var okTimeout = false;
        try {
          final lock = newLock();
          final completer = Completer();
          unawaited(lock.synchronized(() async {
            await completer.future;
          }).catchError((e) {}));
          try {
            await lock.synchronized(() {},
                timeout: const Duration(milliseconds: 1));
            fail('should fail');
          } on TimeoutException catch (_) {}
          completer.completeError('error');
          // await future;
          // await lock.synchronized(null, timeout: Duration(milliseconds: 1000));

          // Make sure these block ran
          await lock.synchronized(() {
            ok = true;
          });
          await lock.synchronized(() {
            okTimeout = true;
          }, timeout: const Duration(milliseconds: 1000));
        } catch (_) {}
        expect(ok, isTrue);
        expect(okTimeout, isTrue);
      });
    });

    group('error', () {
      test('throw', () async {
        final lock = newLock();
        try {
          await lock.synchronized(() {
            throw 'throwing';
          });
          fail('should throw'); // ignore: dead_code
        } catch (e) {
          expect(e is TestFailure, isFalse);
        }

        var ok = false;
        await lock.synchronized(() {
          ok = true;
        });
        expect(ok, isTrue);
      });

      test('queued_throw', () async {
        final lock = newLock();

        // delay so that it is queued
        // ignore: unawaited_futures
        lock.synchronized(() {
          return sleep(1);
        });
        try {
          await lock.synchronized(() async {
            throw 'throwing';
          });
          fail('should throw'); // ignore: dead_code
        } catch (e) {
          expect(e is TestFailure, isFalse);
        }

        var ok = false;
        await lock.synchronized(() {
          ok = true;
        });
        expect(ok, isTrue);
      });

      test('throw_async', () async {
        final lock = newLock();
        try {
          await lock.synchronized(() async {
            throw 'throwing';
          });
          fail('should throw'); // ignore: dead_code
        } catch (e) {
          expect(e is TestFailure, isFalse);
        }
      });
    });

    group('immediacity', () {
      test('sync', () async {
        var lock = newLock();
        int? value;
        final future = lock.synchronized(() {
          value = 1;
          return Future.value().then((_) {
            value = 2;
          });
        });
        // A sync method is executed right away!
        expect(value, 1);
        await future;
        expect(value, 2);
      });

      test('async', () async {
        var lock = newLock();
        int? value;
        final future = lock.synchronized(() async {
          value = 1;
          return Future.value().then((_) {
            value = 2;
          });
        });
        // A sync method is executed right away!
        expect(value, 1);

        await future;
        expect(value, 2);
      });
    });

    group('locked', () {
      test('simple', () async {
        // Make sure the lock state is made immediately
        // when the function is not async
        var lock = newLock();
        expect(lock.locked, isFalse);
        final future = lock.synchronized(() => {});
        expect(lock.locked, isFalse);
        await future;
        expect(lock.locked, isFalse);
      });

      test('simple_async', () async {
        // Make sure the lock state is lazy for async method
        var lock = newLock();
        expect(lock.locked, isFalse);
        final future = lock.synchronized(() async => {});
        expect(lock.locked, isTrue);
        await future;
        expect(lock.locked, isFalse);
      });
    });
    group('locked_in_lock', () {
      test('two', () async {
        var lock = newLock();

        expect(lock.locked, isFalse);
        expect(lock.inLock, isFalse);
        await lock.synchronized(() async {
          expect(lock.locked, isTrue);
          expect(lock.inLock, isTrue);
        });
        expect(lock.locked, isFalse);
        expect(lock.inLock, isFalse);

        unawaited(lock.synchronized(() async {
          await sleep(1);
          expect(lock.locked, isTrue);
          expect(lock.inLock, isTrue);
        }));

        await lock.synchronized(() async {
          await sleep(1);
          expect(lock.locked, isTrue);
          expect(lock.inLock, isTrue);
        });
        expect(lock.locked, isFalse);
        expect(lock.inLock, isFalse);
      });

      test('simple', () async {
        var lock = newLock();

        expect(lock.locked, isFalse);
        expect(lock.inLock, isFalse);
        await lock.synchronized(() async {
          expect(lock.locked, isTrue);
          expect(lock.inLock, isTrue);
        });
        expect(lock.locked, isFalse);
        expect(lock.inLock, isFalse);
      });

      test('locked', () async {
        final lock = newLock();
        final completer = Completer();
        expect(lock.locked, isFalse);
        expect(lock.inLock, isFalse);
        final future = lock.synchronized(() async {
          await completer.future;
        });
        expect(lock.locked, isTrue);
        if (lock is BasicLock) {
          expect(lock.inLock, isTrue);
        }
        completer.complete();
        await future;
        expect(lock.locked, isFalse);
        expect(lock.inLock, isFalse);
      });

      test('locked_with_timeout', () async {
        final lock = newLock();
        final completer = Completer();

        // Lock it forever
        final future = lock.synchronized(() async {
          await completer.future;
        });
        expect(lock.locked, isTrue);

        // Expect a time out exception
        var hasTimeoutException = false;
        try {
          await lock.synchronized(() {},
              timeout: const Duration(milliseconds: 100));
          fail('should fail');
        } on TimeoutException catch (_) {
          // Timeout exception expected
          hasTimeoutException = true;
        }
        expect(hasTimeoutException, isTrue);
        expect(lock.locked, isTrue);
        // Release the forever waiting lock
        completer.complete();
        await future;
        expect(lock.locked, isFalse);

        // Should succeed right away
        await lock.synchronized(() {}, timeout: const Duration(seconds: 10));
      });
    });
  });
}
