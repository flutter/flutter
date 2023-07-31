// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async/async.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  test('runs the callback once the duration has elapsed', () {
    FakeAsync().run((async) {
      var fired = false;
      RestartableTimer(Duration(seconds: 5), () {
        fired = true;
      });

      async.elapse(Duration(seconds: 4));
      expect(fired, isFalse);

      async.elapse(Duration(seconds: 1));
      expect(fired, isTrue);
    });
  });

  test("doesn't run the callback if the timer is canceled", () {
    FakeAsync().run((async) {
      var fired = false;
      var timer = RestartableTimer(Duration(seconds: 5), () {
        fired = true;
      });

      async.elapse(Duration(seconds: 4));
      expect(fired, isFalse);
      timer.cancel();

      async.elapse(Duration(seconds: 4));
      expect(fired, isFalse);
    });
  });

  test('resets the duration if the timer is reset before it fires', () {
    FakeAsync().run((async) {
      var fired = false;
      var timer = RestartableTimer(Duration(seconds: 5), () {
        fired = true;
      });

      async.elapse(Duration(seconds: 4));
      expect(fired, isFalse);
      timer.reset();

      async.elapse(Duration(seconds: 4));
      expect(fired, isFalse);

      async.elapse(Duration(seconds: 1));
      expect(fired, isTrue);
    });
  });

  test('re-runs the callback if the timer is reset after firing', () {
    FakeAsync().run((async) {
      var fired = 0;
      var timer = RestartableTimer(Duration(seconds: 5), () {
        fired++;
      });

      async.elapse(Duration(seconds: 5));
      expect(fired, equals(1));
      timer.reset();

      async.elapse(Duration(seconds: 5));
      expect(fired, equals(2));
      timer.reset();

      async.elapse(Duration(seconds: 5));
      expect(fired, equals(3));
    });
  });

  test('runs the callback if the timer is reset after being canceled', () {
    FakeAsync().run((async) {
      var fired = false;
      var timer = RestartableTimer(Duration(seconds: 5), () {
        fired = true;
      });

      async.elapse(Duration(seconds: 4));
      expect(fired, isFalse);
      timer.cancel();

      async.elapse(Duration(seconds: 4));
      expect(fired, isFalse);
      timer.reset();

      async.elapse(Duration(seconds: 5));
      expect(fired, isTrue);
    });
  });

  test("only runs the callback once if the timer isn't reset", () {
    FakeAsync().run((async) {
      RestartableTimer(Duration(seconds: 5), expectAsync0(() {}, count: 1));
      async.elapse(Duration(seconds: 10));
    });
  });
}
