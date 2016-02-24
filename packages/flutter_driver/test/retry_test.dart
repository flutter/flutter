// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:quiver/testing/async.dart';

import 'package:flutter_driver/src/retry.dart';

main() {
  group('retry', () {
    test('retries until succeeds', () {
      new FakeAsync().run((FakeAsync fakeAsync) {
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

    test('times out returning last error', () async {
      bool timedOut = false;
      int retryCount = 0;
      dynamic lastError;
      dynamic lastStackTrace;

      await retry(
        () {
          retryCount++;
          throw 'error';
        },
        new Duration(milliseconds: 9),
        new Duration(milliseconds: 2)
      ).catchError((error, stackTrace) {
        timedOut = true;
        lastError = error;
        lastStackTrace = stackTrace;
      });

      expect(timedOut, isTrue);
      expect(lastError, 'error');
      expect(lastStackTrace, isNotNull);
      expect(retryCount, 4);
    }, skip: "Flaky. See https://github.com/flutter/flutter/issues/2133");
  });
}
