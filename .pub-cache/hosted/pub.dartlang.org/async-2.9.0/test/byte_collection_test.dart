// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:async/async.dart';

void main() {
  group('collectBytes', () {
    test('simple list and overflow', () {
      var result = collectBytes(Stream.fromIterable([
        [0],
        [1],
        [2],
        [256]
      ]));
      expect(result, completion([0, 1, 2, 0]));
    });

    test('no events', () {
      var result = collectBytes(Stream.fromIterable([]));
      expect(result, completion([]));
    });

    test('empty events', () {
      var result = collectBytes(Stream.fromIterable([[], []]));
      expect(result, completion([]));
    });

    test('error event', () {
      var result = collectBytes(Stream.fromIterable(
          Iterable.generate(3, (n) => n == 2 ? throw 'badness' : [n])));
      expect(result, throwsA('badness'));
    });
  });

  group('collectBytes', () {
    test('simple list and overflow', () {
      var result = collectBytesCancelable(Stream.fromIterable([
        [0],
        [1],
        [2],
        [256]
      ]));
      expect(result.value, completion([0, 1, 2, 0]));
    });

    test('no events', () {
      var result = collectBytesCancelable(Stream.fromIterable([]));
      expect(result.value, completion([]));
    });

    test('empty events', () {
      var result = collectBytesCancelable(Stream.fromIterable([[], []]));
      expect(result.value, completion([]));
    });

    test('error event', () {
      var result = collectBytesCancelable(Stream.fromIterable(
          Iterable.generate(3, (n) => n == 2 ? throw 'badness' : [n])));
      expect(result.value, throwsA('badness'));
    });

    test('cancelled', () async {
      var sc = StreamController<List<int>>();
      var result = collectBytesCancelable(sc.stream);
      // Value never completes.
      result.value.whenComplete(expectAsync0(() {}, count: 0));

      expect(sc.hasListener, isTrue);
      sc.add([1, 2]);
      await nextTimerTick();
      expect(sc.hasListener, isTrue);
      sc.add([3, 4]);
      await nextTimerTick();
      expect(sc.hasListener, isTrue);
      result.cancel();
      expect(sc.hasListener, isFalse); // Cancelled immediately.
      var replacement = await result.valueOrCancellation();
      expect(replacement, isNull);
      await nextTimerTick();
      sc.close();
      await nextTimerTick();
    });
  });
}

Future nextTimerTick() => Future(() {});
