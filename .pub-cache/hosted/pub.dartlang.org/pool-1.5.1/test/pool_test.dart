// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:pool/pool.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

void main() {
  group('request()', () {
    test('resources can be requested freely up to the limit', () {
      var pool = Pool(50);
      for (var i = 0; i < 50; i++) {
        expect(pool.request(), completes);
      }
    });

    test('resources block past the limit', () {
      FakeAsync().run((async) {
        var pool = Pool(50);
        for (var i = 0; i < 50; i++) {
          expect(pool.request(), completes);
        }
        expect(pool.request(), doesNotComplete);

        async.elapse(const Duration(seconds: 1));
      });
    });

    test('a blocked resource is allocated when another is released', () {
      FakeAsync().run((async) {
        var pool = Pool(50);
        for (var i = 0; i < 49; i++) {
          expect(pool.request(), completes);
        }

        pool.request().then((lastAllocatedResource) {
          // This will only complete once [lastAllocatedResource] is released.
          expect(pool.request(), completes);

          Future.delayed(const Duration(microseconds: 1)).then((_) {
            lastAllocatedResource.release();
          });
        });

        async.elapse(const Duration(seconds: 1));
      });
    });
  });

  group('withResource()', () {
    test('can be called freely up to the limit', () {
      var pool = Pool(50);
      for (var i = 0; i < 50; i++) {
        pool.withResource(expectAsync0(() => Completer().future));
      }
    });

    test('blocks the callback past the limit', () {
      FakeAsync().run((async) {
        var pool = Pool(50);
        for (var i = 0; i < 50; i++) {
          pool.withResource(expectAsync0(() => Completer().future));
        }
        pool.withResource(expectNoAsync());

        async.elapse(const Duration(seconds: 1));
      });
    });

    test('a blocked resource is allocated when another is released', () {
      FakeAsync().run((async) {
        var pool = Pool(50);
        for (var i = 0; i < 49; i++) {
          pool.withResource(expectAsync0(() => Completer().future));
        }

        var completer = Completer();
        pool.withResource(() => completer.future);
        var blockedResourceAllocated = false;
        pool.withResource(() {
          blockedResourceAllocated = true;
        });

        Future.delayed(const Duration(microseconds: 1)).then((_) {
          expect(blockedResourceAllocated, isFalse);
          completer.complete();
          return Future.delayed(const Duration(microseconds: 1));
        }).then((_) {
          expect(blockedResourceAllocated, isTrue);
        });

        async.elapse(const Duration(seconds: 1));
      });
    });

    // Regression test for #3.
    test('can be called immediately before close()', () async {
      var pool = Pool(1);
      unawaited(pool.withResource(expectAsync0(() {})));
      await pool.close();
    });
  });

  group('with a timeout', () {
    test("doesn't time out if there are no pending requests", () {
      FakeAsync().run((async) {
        var pool = Pool(50, timeout: const Duration(seconds: 5));
        for (var i = 0; i < 50; i++) {
          expect(pool.request(), completes);
        }

        async.elapse(const Duration(seconds: 6));
      });
    });

    test('resets the timer if a resource is returned', () {
      FakeAsync().run((async) {
        var pool = Pool(50, timeout: const Duration(seconds: 5));
        for (var i = 0; i < 49; i++) {
          expect(pool.request(), completes);
        }

        pool.request().then((lastAllocatedResource) {
          // This will only complete once [lastAllocatedResource] is released.
          expect(pool.request(), completes);

          Future.delayed(const Duration(seconds: 3)).then((_) {
            lastAllocatedResource.release();
            expect(pool.request(), doesNotComplete);
          });
        });

        async.elapse(const Duration(seconds: 6));
      });
    });

    test('resets the timer if a resource is requested', () {
      FakeAsync().run((async) {
        var pool = Pool(50, timeout: const Duration(seconds: 5));
        for (var i = 0; i < 50; i++) {
          expect(pool.request(), completes);
        }
        expect(pool.request(), doesNotComplete);

        Future.delayed(const Duration(seconds: 3)).then((_) {
          expect(pool.request(), doesNotComplete);
        });

        async.elapse(const Duration(seconds: 6));
      });
    });

    test('times out if nothing happens', () {
      FakeAsync().run((async) {
        var pool = Pool(50, timeout: const Duration(seconds: 5));
        for (var i = 0; i < 50; i++) {
          expect(pool.request(), completes);
        }
        expect(pool.request(), throwsA(const TypeMatcher<TimeoutException>()));

        async.elapse(const Duration(seconds: 6));
      });
    });
  });

  group('allowRelease()', () {
    test('runs the callback once the resource limit is exceeded', () async {
      var pool = Pool(50);
      for (var i = 0; i < 49; i++) {
        expect(pool.request(), completes);
      }

      var resource = await pool.request();
      var onReleaseCalled = false;
      resource.allowRelease(() => onReleaseCalled = true);
      await Future.delayed(Duration.zero);
      expect(onReleaseCalled, isFalse);

      expect(pool.request(), completes);
      await Future.delayed(Duration.zero);
      expect(onReleaseCalled, isTrue);
    });

    test('runs the callback immediately if there are blocked requests',
        () async {
      var pool = Pool(1);
      var resource = await pool.request();

      // This will be blocked until [resource.allowRelease] is called.
      expect(pool.request(), completes);

      var onReleaseCalled = false;
      resource.allowRelease(() => onReleaseCalled = true);
      await Future.delayed(Duration.zero);
      expect(onReleaseCalled, isTrue);
    });

    test('blocks the request until the callback completes', () async {
      var pool = Pool(1);
      var resource = await pool.request();

      var requestComplete = false;
      unawaited(pool.request().then((_) => requestComplete = true));

      var completer = Completer();
      resource.allowRelease(() => completer.future);
      await Future.delayed(Duration.zero);
      expect(requestComplete, isFalse);

      completer.complete();
      await Future.delayed(Duration.zero);
      expect(requestComplete, isTrue);
    });

    test('completes requests in request order regardless of callback order',
        () async {
      var pool = Pool(2);
      var resource1 = await pool.request();
      var resource2 = await pool.request();

      var request1Complete = false;
      unawaited(pool.request().then((_) => request1Complete = true));
      var request2Complete = false;
      unawaited(pool.request().then((_) => request2Complete = true));

      var onRelease1Called = false;
      var completer1 = Completer();
      resource1.allowRelease(() {
        onRelease1Called = true;
        return completer1.future;
      });
      await Future.delayed(Duration.zero);
      expect(onRelease1Called, isTrue);

      var onRelease2Called = false;
      var completer2 = Completer();
      resource2.allowRelease(() {
        onRelease2Called = true;
        return completer2.future;
      });
      await Future.delayed(Duration.zero);
      expect(onRelease2Called, isTrue);
      expect(request1Complete, isFalse);
      expect(request2Complete, isFalse);

      // Complete the second resource's onRelease callback first. Even though it
      // was triggered by the second blocking request, it should complete the
      // first one to preserve ordering.
      completer2.complete();
      await Future.delayed(Duration.zero);
      expect(request1Complete, isTrue);
      expect(request2Complete, isFalse);

      completer1.complete();
      await Future.delayed(Duration.zero);
      expect(request1Complete, isTrue);
      expect(request2Complete, isTrue);
    });

    test('runs onRequest in the zone it was created', () async {
      var pool = Pool(1);
      var resource = await pool.request();

      var outerZone = Zone.current;
      runZoned(() {
        var innerZone = Zone.current;
        expect(innerZone, isNot(equals(outerZone)));

        resource.allowRelease(expectAsync0(() {
          expect(Zone.current, equals(innerZone));
        }));
      });

      await pool.request();
    });
  });

  test("done doesn't complete without close", () async {
    var pool = Pool(1);
    unawaited(pool.done.then(expectAsync1((_) {}, count: 0)));

    var resource = await pool.request();
    resource.release();

    await Future.delayed(Duration.zero);
  });

  group('close()', () {
    test('disallows request() and withResource()', () {
      var pool = Pool(1)..close();
      expect(pool.request, throwsStateError);
      expect(() => pool.withResource(() {}), throwsStateError);
    });

    test('pending requests are fulfilled', () async {
      var pool = Pool(1);
      var resource1 = await pool.request();
      expect(
          pool.request().then((resource2) {
            resource2.release();
          }),
          completes);
      expect(pool.done, completes);
      expect(pool.close(), completes);
      resource1.release();
    });

    test('pending requests are fulfilled with allowRelease', () async {
      var pool = Pool(1);
      var resource1 = await pool.request();

      var completer = Completer();
      expect(
          pool.request().then((resource2) {
            expect(completer.isCompleted, isTrue);
            resource2.release();
          }),
          completes);
      expect(pool.close(), completes);

      resource1.allowRelease(() => completer.future);
      await Future.delayed(Duration.zero);

      completer.complete();
    });

    test("doesn't complete until all resources are released", () async {
      var pool = Pool(2);
      var resource1 = await pool.request();
      var resource2 = await pool.request();
      var resource3Future = pool.request();

      var resource1Released = false;
      var resource2Released = false;
      var resource3Released = false;
      expect(
          pool.close().then((_) {
            expect(resource1Released, isTrue);
            expect(resource2Released, isTrue);
            expect(resource3Released, isTrue);
          }),
          completes);

      resource1Released = true;
      resource1.release();
      await Future.delayed(Duration.zero);

      resource2Released = true;
      resource2.release();
      await Future.delayed(Duration.zero);

      var resource3 = await resource3Future;
      resource3Released = true;
      resource3.release();
    });

    test('active onReleases complete as usual', () async {
      var pool = Pool(1);
      var resource = await pool.request();

      // Set up an onRelease callback whose completion is controlled by
      // [completer].
      var completer = Completer();
      resource.allowRelease(() => completer.future);
      expect(
          pool.request().then((_) {
            expect(completer.isCompleted, isTrue);
          }),
          completes);

      await Future.delayed(Duration.zero);
      unawaited(pool.close());

      await Future.delayed(Duration.zero);
      completer.complete();
    });

    test('inactive onReleases fire', () async {
      var pool = Pool(2);
      var resource1 = await pool.request();
      var resource2 = await pool.request();

      var completer1 = Completer();
      resource1.allowRelease(() => completer1.future);
      var completer2 = Completer();
      resource2.allowRelease(() => completer2.future);

      expect(
          pool.close().then((_) {
            expect(completer1.isCompleted, isTrue);
            expect(completer2.isCompleted, isTrue);
          }),
          completes);

      await Future.delayed(Duration.zero);
      completer1.complete();

      await Future.delayed(Duration.zero);
      completer2.complete();
    });

    test('new allowReleases fire immediately', () async {
      var pool = Pool(1);
      var resource = await pool.request();

      var completer = Completer();
      expect(
          pool.close().then((_) {
            expect(completer.isCompleted, isTrue);
          }),
          completes);

      await Future.delayed(Duration.zero);
      resource.allowRelease(() => completer.future);

      await Future.delayed(Duration.zero);
      completer.complete();
    });

    test('an onRelease error is piped to the return value', () async {
      var pool = Pool(1);
      var resource = await pool.request();

      var completer = Completer();
      resource.allowRelease(() => completer.future);

      expect(pool.done, throwsA('oh no!'));
      expect(pool.close(), throwsA('oh no!'));

      await Future.delayed(Duration.zero);
      completer.completeError('oh no!');
    });
  });

  group('forEach', () {
    late Pool pool;

    tearDown(() async {
      await pool.close();
    });

    const delayedToStringDuration = Duration(milliseconds: 10);

    Future<String> delayedToString(int i) =>
        Future.delayed(delayedToStringDuration, () => i.toString());

    for (var itemCount in [0, 5]) {
      for (var poolSize in [1, 5, 6]) {
        test('poolSize: $poolSize, itemCount: $itemCount', () async {
          pool = Pool(poolSize);

          var finishedItems = 0;

          await for (var item in pool.forEach(
              Iterable.generate(itemCount, (i) {
                expect(i, lessThanOrEqualTo(finishedItems + poolSize),
                    reason: 'the iterator should be called lazily');
                return i;
              }),
              delayedToString)) {
            expect(int.parse(item), lessThan(itemCount));
            finishedItems++;
          }

          expect(finishedItems, itemCount);
        });
      }
    }

    test('pool closed before listen', () async {
      pool = Pool(2);

      var stream = pool.forEach(Iterable<int>.generate(5), delayedToString);

      await pool.close();

      expect(stream.toList(), throwsStateError);
    });

    test('completes even if the pool is partially used', () async {
      pool = Pool(2);

      var resource = await pool.request();

      var stream = pool.forEach(<int>[], delayedToString);

      expect(await stream.length, 0);

      resource.release();
    });

    test('stream paused longer than timeout', () async {
      pool = Pool(2, timeout: delayedToStringDuration);

      var resource = await pool.request();

      var stream = pool.forEach<int, int>(
          Iterable.generate(100, (i) {
            expect(i, lessThan(20),
                reason: 'The timeout should happen '
                    'before the entire iterable is iterated.');
            return i;
          }), (i) async {
        await Future.delayed(Duration(milliseconds: i));
        return i;
      });

      await expectLater(
          stream.toList,
          throwsA(const TypeMatcher<TimeoutException>().having(
              (te) => te.message,
              'message',
              contains('Pool deadlock: '
                  'all resources have been allocated for too long.'))));

      resource.release();
    });

    group('timing and timeout', () {
      for (var poolSize in [2, 8, 64]) {
        for (var otherTaskCount
            in [0, 1, 7, 63].where((otc) => otc < poolSize)) {
          test('poolSize: $poolSize, otherTaskCount: $otherTaskCount',
              () async {
            final itemCount = 128;
            pool = Pool(poolSize, timeout: const Duration(milliseconds: 20));

            var otherTasks = await Future.wait(
                Iterable<int>.generate(otherTaskCount)
                    .map((i) => pool.request()));

            try {
              var finishedItems = 0;

              var watch = Stopwatch()..start();

              await for (var item in pool.forEach(
                  Iterable.generate(itemCount, (i) {
                    expect(i, lessThanOrEqualTo(finishedItems + poolSize),
                        reason: 'the iterator should be called lazily');
                    return i;
                  }),
                  delayedToString)) {
                expect(int.parse(item), lessThan(itemCount));
                finishedItems++;
              }

              expect(finishedItems, itemCount);

              final expectedElapsed =
                  delayedToStringDuration.inMicroseconds * 4;

              expect((watch.elapsed ~/ itemCount).inMicroseconds,
                  lessThan(expectedElapsed / (poolSize - otherTaskCount)),
                  reason: 'Average time per task should be '
                      'proportionate to the available pool resources.');
            } finally {
              for (var task in otherTasks) {
                task.release();
              }
            }
          });
        }
      }
    }, testOn: 'vm');

    test('partial iteration', () async {
      pool = Pool(5);
      var stream = pool.forEach(Iterable<int>.generate(100), delayedToString);
      expect(await stream.take(10).toList(), hasLength(10));
    });

    test('pool close during data with waiting to be done', () async {
      pool = Pool(5);

      var stream = pool.forEach(Iterable<int>.generate(100), delayedToString);

      var dataCount = 0;
      var subscription = stream.listen((data) {
        dataCount++;
        pool.close();
      });

      await subscription.asFuture();
      expect(dataCount, 100);
      await subscription.cancel();
    });

    test('pause and resume ', () async {
      var generatedCount = 0;
      var dataCount = 0;
      final poolSize = 5;

      pool = Pool(poolSize);

      var stream = pool.forEach(
          Iterable<int>.generate(40, (i) {
            expect(generatedCount, lessThanOrEqualTo(dataCount + 2 * poolSize),
                reason: 'The iterator should not be called '
                    'much faster than the data is consumed.');
            generatedCount++;
            return i;
          }),
          delayedToString);

      // ignore: cancel_subscriptions
      late StreamSubscription subscription;

      subscription = stream.listen(
        (data) {
          dataCount++;

          if (int.parse(data) % 3 == 1) {
            subscription.pause(Future(() async {
              await Future.delayed(const Duration(milliseconds: 100));
            }));
          }
        },
        onError: registerException,
        onDone: expectAsync0(() {
          expect(dataCount, 40);
        }),
      );
    });

    group('cancel', () {
      final dataSize = 32;
      for (var i = 1; i < 5; i++) {
        test('with pool size $i', () async {
          pool = Pool(i);

          var stream =
              pool.forEach(Iterable<int>.generate(dataSize), delayedToString);

          var cancelCompleter = Completer<void>();

          StreamSubscription subscription;

          var eventCount = 0;
          subscription = stream.listen((data) {
            eventCount++;
            if (int.parse(data) == dataSize ~/ 2) {
              cancelCompleter.complete();
            }
          }, onError: registerException);

          await cancelCompleter.future;

          await subscription.cancel();

          expect(eventCount, 1 + dataSize ~/ 2);
        });
      }
    });

    group('errors', () {
      Future<void> errorInIterator({
        bool Function(int item, Object error, StackTrace stack)? onError,
      }) async {
        pool = Pool(20);

        var listFuture = pool
            .forEach(
                Iterable.generate(100, (i) {
                  if (i == 50) {
                    throw StateError('error while generating item in iterator');
                  }

                  return i;
                }),
                delayedToString,
                onError: onError)
            .toList();

        await expectLater(() async => listFuture, throwsStateError);
      }

      test('iteration, no onError', () async {
        await errorInIterator();
      });
      test('iteration, with onError', () async {
        await errorInIterator(onError: (i, e, s) => false);
      });

      test('error in action, no onError', () async {
        pool = Pool(20);

        var listFuture = pool.forEach(Iterable<int>.generate(100), (i) async {
          await Future.delayed(const Duration(milliseconds: 10));
          if (i == 10) {
            throw UnsupportedError('10 is not supported');
          }
          return i.toString();
        }).toList();

        await expectLater(() async => listFuture, throwsUnsupportedError);
      });

      test('error in action, no onError', () async {
        pool = Pool(20);

        var list = await pool.forEach(Iterable<int>.generate(100),
            (int i) async {
          await Future.delayed(const Duration(milliseconds: 10));
          if (i % 10 == 0) {
            throw UnsupportedError('Multiples of 10 not supported');
          }
          return i.toString();
        },
            onError: (item, error, stack) =>
                error is! UnsupportedError).toList();

        expect(list, hasLength(90));
      });
    });
  });

  test('throw error when pool limit <= 0', () {
    expect(() => Pool(-1), throwsArgumentError);
    expect(() => Pool(0), throwsArgumentError);
  });
}

/// Returns a function that will cause the test to fail if it's called.
///
/// This should only be called within a [FakeAsync.run] zone.
void Function() expectNoAsync() {
  var stack = Trace.current(1);
  return () => registerException(
      TestFailure('Expected function not to be called.'), stack);
}

/// A matcher for Futures that asserts that they don't complete.
///
/// This should only be called within a [FakeAsync.run] zone.
Matcher get doesNotComplete => predicate((Future future) {
      var stack = Trace.current(1);
      future.then((_) => registerException(
          TestFailure('Expected future not to complete.'), stack));
      return true;
    });
