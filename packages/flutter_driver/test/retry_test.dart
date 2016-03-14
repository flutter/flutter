// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:quiver/time.dart';
import 'package:quiver/testing/async.dart';
import 'package:quiver/testing/time.dart';

import 'package:flutter_driver/src/retry.dart';

void main() {
  group('retry', () {
    FakeAsync fakeAsync;

    setUp(() {
      fakeAsync = new FakeAsync();
      Clock fakeClock = fakeAsync.getClock(new DateTime.now());
      stopwatchFactory = () {
        return new FakeStopwatch(
          () => fakeClock.now().millisecondsSinceEpoch,
          1000
        );
      };
    });

    test('retries until succeeds', () {
      fakeAsync.run((_) {
        int retryCount = 0;

        expect(
          retry(
            () async {
              retryCount++;
              if (retryCount < 2) {
                throw 'error';
              } else {
                return retryCount;
              }
            },
            new Duration(milliseconds: 30),
            new Duration(milliseconds: 10)
          ),
          completion(2)
        );

        fakeAsync.elapse(new Duration(milliseconds: 50));

        // Check that we didn't retry more times than necessary
        expect(retryCount, 2);
      });
    });

    test('obeys predicates', () {
      fakeAsync.run((_) {
        int retryCount = 0;

        expect(
          // The predicate requires that the returned value is 2, so we expect
          // that `retry` keeps trying until the counter reaches 2.
          retry(
            () async => retryCount++,
            new Duration(milliseconds: 30),
            new Duration(milliseconds: 10),
            predicate: (int value) => value == 2
          ),
          completion(2)
        );

        fakeAsync.elapse(new Duration(milliseconds: 50));
      });
    });

    test('times out returning last error', () async {
      fakeAsync.run((_) {
        bool timedOut = false;
        int retryCount = 0;
        dynamic lastError;
        dynamic lastStackTrace;

        retry(
          () {
            retryCount++;
            throw 'error';
          },
          new Duration(milliseconds: 7),
          new Duration(milliseconds: 2)
        ).catchError((dynamic error, dynamic stackTrace) {
          timedOut = true;
          lastError = error;
          lastStackTrace = stackTrace;
        });

        fakeAsync.elapse(new Duration(milliseconds: 10));

        expect(timedOut, isTrue);
        expect(lastError, 'error');
        expect(lastStackTrace, isNotNull);
        expect(retryCount, 4);
      });
    });
  });
}
