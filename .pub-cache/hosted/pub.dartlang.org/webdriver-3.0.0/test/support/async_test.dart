// Copyright 2015 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library webdriver.support.async_test;

import 'dart:async' show Future;

import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';
import 'package:webdriver/support/async.dart';

void main() {
  group('Lock', () {
    test('basic acquire/release', () async {
      var lock = Lock();
      expect(lock.isHeld, isFalse);
      await lock.acquire();
      expect(lock.isHeld, isTrue);
      lock.release();
      expect(lock.isHeld, isFalse);
      await lock.acquire();
      expect(lock.isHeld, isTrue);
      lock.release();
    });

    test('release without acquiring fails', () {
      var lock = Lock();
      expect(() => lock.release(), throwsA(isA<StateError>()));
    });

    test('locking prevents acquisition of lock', () async {
      var lock = Lock();
      var secondLockAcquired = false;
      await lock.acquire();
      unawaited(lock.acquire().then((_) => secondLockAcquired = true));
      // Make sure that lock is not unacquired just because of timing
      await Future.delayed(const Duration(seconds: 1));
      expect(secondLockAcquired, isFalse);
      lock.release();
      // Make sure that enough time has occurred that lock is acquired
      await Future.delayed(const Duration(seconds: 1));
      expect(secondLockAcquired, isTrue);
    });

    test('awaitChecking throws exception on acquire of held lock', () async {
      var lock = Lock(awaitChecking: true);
      await lock.acquire();
      expect(lock.acquire(), throwsA(anything));
      lock.release();
      await lock.acquire();
      lock.release();
    });
  });

  group('Clock.waitFor', () {
    var clock = FakeClock();

    test('that returns a string', () async {
      var count = 0;
      var result = await clock.waitFor(() {
        if (count == 2) return 'webdriver - Google Search';
        count++;
        return count;
      }, matcher: equals('webdriver - Google Search'));

      expect(result, equals('webdriver - Google Search'));
    });

    test('that returns null', () async {
      var count = 0;
      var result = await clock.waitFor(() {
        if (count == 2) return null;
        count++;
        return count;
      }, matcher: isNull);
      expect(result, isNull);
    });

    test('that returns false', () async {
      var count = 0;
      var result = await clock.waitFor(() {
        if (count == 2) return false;
        count++;
        return count;
      }, matcher: isFalse);
      expect(result, isFalse);
    });

    test('that returns a string, default matcher', () async {
      var count = 0;
      var result = await clock.waitFor(() {
        if (count == 2) return 'Google';
        count++;
        throw '';
      });
      expect(result, equals('Google'));
    });

    test('throws if condition throws and timeouts', () async {
      Object? exception;

      try {
        await clock.waitFor(() => throw 'an exception');
      } catch (e) {
        exception = e;
      }
      expect(exception, 'an exception');
    });

    test('throws if condition never matches', () async {
      Object? exception;
      try {
        await clock.waitFor(() => null, matcher: isNotNull);
      } catch (e) {
        exception = e;
      }
      expect(exception, isNotNull);
    });

    test('uses Future value', () async {
      var result = await clock.waitFor(() => Future.value('a value'),
          matcher: 'a value');
      expect(result, 'a value');
    });

    test('works with Future exceptions', () async {
      Object? exception;

      try {
        await clock.waitFor(() => Future.error('an exception'));
      } catch (e) {
        exception = e;
      }
      expect(exception, 'an exception');
    });

    test('sanity test with real Clock -- successful', () async {
      var clock = const Clock();
      var count = 0;
      var result = await clock.waitFor(() {
        if (count < 2) {
          count++;
          return null;
        } else {
          return 'a value';
        }
      }, matcher: isNotNull);
      expect(result, 'a value');
    });

    test('sanity test with real Clock -- throws', () async {
      var clock = const Clock();
      Object? exception;
      try {
        await clock.waitFor(() => throw 'an exception');
      } catch (e) {
        exception = e;
      }
      expect(exception, 'an exception');
    });

    test('sanity test with real Clock -- never matches', () async {
      var clock = const Clock();
      Object? exception;
      try {
        await clock.waitFor(() => null, matcher: isNotNull);
      } catch (e) {
        exception = e;
      }
      expect(exception, isNotNull);
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}

/// FakeClock for testing waitFor functionality.
class FakeClock extends Clock {
  var _now = DateTime(2020);

  @override
  DateTime get now => _now;

  @override
  Future sleep([Duration interval = defaultInterval]) {
    _now = _now.add(interval);
    return Future.value();
  }
}
