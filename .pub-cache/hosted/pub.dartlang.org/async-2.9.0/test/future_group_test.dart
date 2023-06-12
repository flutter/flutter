// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/src/future_group.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late FutureGroup futureGroup;
  setUp(() {
    futureGroup = FutureGroup();
  });

  group('with no futures', () {
    test('never completes if nothing happens', () async {
      var completed = false;
      futureGroup.future.then((_) => completed = true);

      await flushMicrotasks();
      expect(completed, isFalse);
    });

    test("completes once it's closed", () {
      expect(futureGroup.future, completion(isEmpty));
      expect(futureGroup.isClosed, isFalse);
      futureGroup.close();
      expect(futureGroup.isClosed, isTrue);
    });
  });

  group('with a future that already completed', () {
    test('never completes if nothing happens', () async {
      futureGroup.add(Future.value());
      await flushMicrotasks();

      var completed = false;
      futureGroup.future.then((_) => completed = true);

      await flushMicrotasks();
      expect(completed, isFalse);
    });

    test("completes once it's closed", () async {
      futureGroup.add(Future.value());
      await flushMicrotasks();

      expect(futureGroup.future, completes);
      expect(futureGroup.isClosed, isFalse);
      futureGroup.close();
      expect(futureGroup.isClosed, isTrue);
    });

    test("completes to that future's value", () {
      futureGroup.add(Future.value(1));
      futureGroup.close();
      expect(futureGroup.future, completion(equals([1])));
    });

    test("completes to that future's error, even if it's not closed", () {
      futureGroup.add(Future.error('error'));
      expect(futureGroup.future, throwsA('error'));
    });
  });

  test('completes once all contained futures complete', () async {
    var completer1 = Completer();
    var completer2 = Completer();
    var completer3 = Completer();

    futureGroup.add(completer1.future);
    futureGroup.add(completer2.future);
    futureGroup.add(completer3.future);
    futureGroup.close();

    var completed = false;
    futureGroup.future.then((_) => completed = true);

    completer1.complete();
    await flushMicrotasks();
    expect(completed, isFalse);

    completer2.complete();
    await flushMicrotasks();
    expect(completed, isFalse);

    completer3.complete();
    await flushMicrotasks();
    expect(completed, isTrue);
  });

  test('completes to the values of the futures in order of addition', () {
    var completer1 = Completer();
    var completer2 = Completer();
    var completer3 = Completer();

    futureGroup.add(completer1.future);
    futureGroup.add(completer2.future);
    futureGroup.add(completer3.future);
    futureGroup.close();

    // Complete the completers in reverse order to prove that that doesn't
    // affect the result order.
    completer3.complete(3);
    completer2.complete(2);
    completer1.complete(1);
    expect(futureGroup.future, completion(equals([1, 2, 3])));
  });

  test("completes to the first error to be emitted, even if it's not closed",
      () {
    var completer1 = Completer();
    var completer2 = Completer();
    var completer3 = Completer();

    futureGroup.add(completer1.future);
    futureGroup.add(completer2.future);
    futureGroup.add(completer3.future);

    completer2.completeError('error 2');
    completer1.completeError('error 1');
    expect(futureGroup.future, throwsA('error 2'));
  });

  group('onIdle:', () {
    test('emits an event when the last pending future completes', () async {
      var idle = false;
      futureGroup.onIdle.listen((_) => idle = true);

      var completer1 = Completer();
      var completer2 = Completer();
      var completer3 = Completer();

      futureGroup.add(completer1.future);
      futureGroup.add(completer2.future);
      futureGroup.add(completer3.future);

      await flushMicrotasks();
      expect(idle, isFalse);
      expect(futureGroup.isIdle, isFalse);

      completer1.complete();
      await flushMicrotasks();
      expect(idle, isFalse);
      expect(futureGroup.isIdle, isFalse);

      completer2.complete();
      await flushMicrotasks();
      expect(idle, isFalse);
      expect(futureGroup.isIdle, isFalse);

      completer3.complete();
      await flushMicrotasks();
      expect(idle, isTrue);
      expect(futureGroup.isIdle, isTrue);
    });

    test('emits an event each time it becomes idle', () async {
      var idle = false;
      futureGroup.onIdle.listen((_) => idle = true);

      var completer = Completer();
      futureGroup.add(completer.future);

      completer.complete();
      await flushMicrotasks();
      expect(idle, isTrue);
      expect(futureGroup.isIdle, isTrue);

      idle = false;
      completer = Completer();
      futureGroup.add(completer.future);

      await flushMicrotasks();
      expect(idle, isFalse);
      expect(futureGroup.isIdle, isFalse);

      completer.complete();
      await flushMicrotasks();
      expect(idle, isTrue);
      expect(futureGroup.isIdle, isTrue);
    });

    test('emits an event when the group closes', () async {
      // It's important that the order of events here stays consistent over
      // time, since code may rely on it in subtle ways.
      var idle = false;
      var onIdleDone = false;
      var futureFired = false;

      futureGroup.onIdle.listen(expectAsync1((_) {
        expect(futureFired, isFalse);
        idle = true;
      }), onDone: expectAsync0(() {
        expect(idle, isTrue);
        expect(futureFired, isFalse);
        onIdleDone = true;
      }));

      futureGroup.future.then(expectAsync1((_) {
        expect(idle, isTrue);
        expect(onIdleDone, isTrue);
        futureFired = true;
      }));

      var completer = Completer();
      futureGroup.add(completer.future);
      futureGroup.close();

      await flushMicrotasks();
      expect(idle, isFalse);
      expect(futureGroup.isIdle, isFalse);

      completer.complete();
      await flushMicrotasks();
      expect(idle, isTrue);
      expect(futureGroup.isIdle, isTrue);
      expect(futureFired, isTrue);
    });
  });
}
