// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

void main() {
  late StreamController<int> controller;
  late StreamSplitter splitter;
  setUp(() {
    controller = StreamController<int>();
    splitter = StreamSplitter<int>(controller.stream);
  });

  test("a branch that's created before the stream starts to replay it",
      () async {
    var events = [];
    var branch = splitter.split();
    splitter.close();
    branch.listen(events.add);

    controller.add(1);
    await flushMicrotasks();
    expect(events, equals([1]));

    controller.add(2);
    await flushMicrotasks();
    expect(events, equals([1, 2]));

    controller.add(3);
    await flushMicrotasks();
    expect(events, equals([1, 2, 3]));

    controller.close();
  });

  test('a branch replays error events as well as data events', () {
    var branch = splitter.split();
    splitter.close();

    controller.add(1);
    controller.addError('error');
    controller.add(3);
    controller.close();

    var count = 0;
    branch.listen(
        expectAsync1((value) {
          expect(count, anyOf(0, 2));
          expect(value, equals(count + 1));
          count++;
        }, count: 2), onError: expectAsync1((error) {
      expect(count, equals(1));
      expect(error, equals('error'));
      count++;
    }), onDone: expectAsync0(() {
      expect(count, equals(3));
    }));
  });

  test("a branch that's created in the middle of a stream replays it",
      () async {
    controller.add(1);
    controller.add(2);
    await flushMicrotasks();

    var branch = splitter.split();
    splitter.close();

    controller.add(3);
    controller.add(4);
    controller.close();

    expect(branch.toList(), completion(equals([1, 2, 3, 4])));
  });

  test("a branch that's created after the stream is finished replays it",
      () async {
    controller.add(1);
    controller.add(2);
    controller.add(3);
    controller.close();
    await flushMicrotasks();

    expect(splitter.split().toList(), completion(equals([1, 2, 3])));
    splitter.close();
  });

  test('creates single-subscription branches', () async {
    var branch = splitter.split();
    expect(branch.isBroadcast, isFalse);
    branch.listen(null);
    expect(() => branch.listen(null), throwsStateError);
    expect(() => branch.listen(null), throwsStateError);
  });

  test('multiple branches each replay the stream', () async {
    var branch1 = splitter.split();
    controller.add(1);
    controller.add(2);
    await flushMicrotasks();

    var branch2 = splitter.split();
    controller.add(3);
    controller.close();
    await flushMicrotasks();

    var branch3 = splitter.split();
    splitter.close();

    expect(branch1.toList(), completion(equals([1, 2, 3])));
    expect(branch2.toList(), completion(equals([1, 2, 3])));
    expect(branch3.toList(), completion(equals([1, 2, 3])));
  });

  test("a branch doesn't close until the source stream closes", () async {
    var branch = splitter.split();
    splitter.close();

    var closed = false;
    branch.last.then((_) => closed = true);

    controller.add(1);
    controller.add(2);
    controller.add(3);
    await flushMicrotasks();
    expect(closed, isFalse);

    controller.close();
    await flushMicrotasks();
    expect(closed, isTrue);
  });

  test("the source stream isn't listened to until a branch is", () async {
    expect(controller.hasListener, isFalse);

    var branch = splitter.split();
    splitter.close();
    await flushMicrotasks();
    expect(controller.hasListener, isFalse);

    branch.listen(null);
    await flushMicrotasks();
    expect(controller.hasListener, isTrue);
  });

  test('the source stream is paused when all branches are paused', () async {
    var branch1 = splitter.split();
    var branch2 = splitter.split();
    var branch3 = splitter.split();
    splitter.close();

    var subscription1 = branch1.listen(null);
    var subscription2 = branch2.listen(null);
    var subscription3 = branch3.listen(null);

    subscription1.pause();
    await flushMicrotasks();
    expect(controller.isPaused, isFalse);

    subscription2.pause();
    await flushMicrotasks();
    expect(controller.isPaused, isFalse);

    subscription3.pause();
    await flushMicrotasks();
    expect(controller.isPaused, isTrue);

    subscription2.resume();
    await flushMicrotasks();
    expect(controller.isPaused, isFalse);
  });

  test('the source stream is paused when all branches are canceled', () async {
    var branch1 = splitter.split();
    var branch2 = splitter.split();
    var branch3 = splitter.split();

    var subscription1 = branch1.listen(null);
    var subscription2 = branch2.listen(null);
    var subscription3 = branch3.listen(null);

    subscription1.cancel();
    await flushMicrotasks();
    expect(controller.isPaused, isFalse);

    subscription2.cancel();
    await flushMicrotasks();
    expect(controller.isPaused, isFalse);

    subscription3.cancel();
    await flushMicrotasks();
    expect(controller.isPaused, isTrue);

    var branch4 = splitter.split();
    splitter.close();
    await flushMicrotasks();
    expect(controller.isPaused, isTrue);

    branch4.listen(null);
    await flushMicrotasks();
    expect(controller.isPaused, isFalse);
  });

  test(
      "the source stream is canceled when it's closed after all branches have "
      'been canceled', () async {
    var branch1 = splitter.split();
    var branch2 = splitter.split();
    var branch3 = splitter.split();

    var subscription1 = branch1.listen(null);
    var subscription2 = branch2.listen(null);
    var subscription3 = branch3.listen(null);

    subscription1.cancel();
    await flushMicrotasks();
    expect(controller.hasListener, isTrue);

    subscription2.cancel();
    await flushMicrotasks();
    expect(controller.hasListener, isTrue);

    subscription3.cancel();
    await flushMicrotasks();
    expect(controller.hasListener, isTrue);

    splitter.close();
    expect(controller.hasListener, isFalse);
  });

  test(
      'the source stream is canceled when all branches are canceled after it '
      'has been closed', () async {
    var branch1 = splitter.split();
    var branch2 = splitter.split();
    var branch3 = splitter.split();
    splitter.close();

    var subscription1 = branch1.listen(null);
    var subscription2 = branch2.listen(null);
    var subscription3 = branch3.listen(null);

    subscription1.cancel();
    await flushMicrotasks();
    expect(controller.hasListener, isTrue);

    subscription2.cancel();
    await flushMicrotasks();
    expect(controller.hasListener, isTrue);

    subscription3.cancel();
    await flushMicrotasks();
    expect(controller.hasListener, isFalse);
  });

  test(
      "a splitter that's closed before any branches are added never listens "
      'to the source stream', () {
    splitter.close();

    // This would throw an error if the stream had already been listened to.
    controller.stream.listen(null);
  });

  test(
      'splitFrom splits a source stream into the designated number of '
      'branches', () {
    var branches = StreamSplitter.splitFrom(controller.stream, 5);

    controller.add(1);
    controller.add(2);
    controller.add(3);
    controller.close();

    expect(branches[0].toList(), completion(equals([1, 2, 3])));
    expect(branches[1].toList(), completion(equals([1, 2, 3])));
    expect(branches[2].toList(), completion(equals([1, 2, 3])));
    expect(branches[3].toList(), completion(equals([1, 2, 3])));
    expect(branches[4].toList(), completion(equals([1, 2, 3])));
  });
}

/// Wait for all microtasks to complete.
Future flushMicrotasks() => Future.delayed(Duration.zero);
