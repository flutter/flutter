// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: file_names

import 'dart:async';
import 'dart:math' show Random;

import 'package:async/async.dart';
import 'package:test/test.dart';

final someStack = StackTrace.current;

Result<int> res(int n) => Result<int>.value(n);

Result err(int n) => ErrorResult('$n', someStack);

/// Helper function creating an iterable of futures.
Iterable<Future<int>> futures(int count,
    {bool Function(int index)? throwWhen}) sync* {
  for (var i = 0; i < count; i++) {
    if (throwWhen != null && throwWhen(i)) {
      yield Future<int>.error('$i', someStack);
    } else {
      yield Future<int>.value(i);
    }
  }
}

void main() {
  test('empty', () async {
    var all = await Result.captureAll<int>(futures(0));
    expect(all, []);
  });

  group('futures only,', () {
    test('single', () async {
      var all = await Result.captureAll<int>(futures(1));
      expect(all, [res(0)]);
    });

    test('multiple', () async {
      var all = await Result.captureAll<int>(futures(3));
      expect(all, [res(0), res(1), res(2)]);
    });

    test('error only', () async {
      var all =
          await Result.captureAll<int>(futures(1, throwWhen: (_) => true));
      expect(all, [err(0)]);
    });

    test('multiple error only', () async {
      var all =
          await Result.captureAll<int>(futures(3, throwWhen: (_) => true));
      expect(all, [err(0), err(1), err(2)]);
    });

    test('mixed error and value', () async {
      var all =
          await Result.captureAll<int>(futures(4, throwWhen: (x) => x.isOdd));
      expect(all, [res(0), err(1), res(2), err(3)]);
    });

    test('completion permutation 1-2-3', () async {
      var cs = List.generate(3, (_) => Completer<int>());
      var all = Result.captureAll<int>(cs.map((c) => c.future));
      expect(all, completion([res(1), res(2), err(3)]));
      await _microTask();
      cs[0].complete(1);
      await _microTask();
      cs[1].complete(2);
      await _microTask();
      cs[2].completeError('3', someStack);
    });

    test('completion permutation 1-3-2', () async {
      var cs = List.generate(3, (_) => Completer<int>());
      var all = Result.captureAll<int>(cs.map((c) => c.future));
      expect(all, completion([res(1), res(2), err(3)]));
      await _microTask();
      cs[0].complete(1);
      await _microTask();
      cs[2].completeError('3', someStack);
      await _microTask();
      cs[1].complete(2);
    });

    test('completion permutation 2-1-3', () async {
      var cs = List.generate(3, (_) => Completer<int>());
      var all = Result.captureAll<int>(cs.map((c) => c.future));
      expect(all, completion([res(1), res(2), err(3)]));
      await _microTask();
      cs[1].complete(2);
      await _microTask();
      cs[0].complete(1);
      await _microTask();
      cs[2].completeError('3', someStack);
    });

    test('completion permutation 2-3-1', () async {
      var cs = List.generate(3, (_) => Completer<int>());
      var all = Result.captureAll<int>(cs.map((c) => c.future));
      expect(all, completion([res(1), res(2), err(3)]));
      await _microTask();
      cs[1].complete(2);
      await _microTask();
      cs[2].completeError('3', someStack);
      await _microTask();
      cs[0].complete(1);
    });

    test('completion permutation 3-1-2', () async {
      var cs = List.generate(3, (_) => Completer<int>());
      var all = Result.captureAll<int>(cs.map((c) => c.future));
      expect(all, completion([res(1), res(2), err(3)]));
      await _microTask();
      cs[2].completeError('3', someStack);
      await _microTask();
      cs[0].complete(1);
      await _microTask();
      cs[1].complete(2);
    });

    test('completion permutation 3-2-1', () async {
      var cs = List.generate(3, (_) => Completer<int>());
      var all = Result.captureAll<int>(cs.map((c) => c.future));
      expect(all, completion([res(1), res(2), err(3)]));
      await _microTask();
      cs[2].completeError('3', someStack);
      await _microTask();
      cs[1].complete(2);
      await _microTask();
      cs[0].complete(1);
    });

    var seed = Random().nextInt(0x100000000);
    var n = 25; // max 32, otherwise rnd.nextInt(1<<n) won't work.
    test('randomized #$n seed:${seed.toRadixString(16)}', () async {
      var cs = List.generate(n, (_) => Completer<int>());
      var all = Result.captureAll<int>(cs.map((c) => c.future));
      var rnd = Random(seed);
      var throwFlags = rnd.nextInt(1 << n); // Bit-flag for throwing.
      bool throws(int index) => (throwFlags & (1 << index)) != 0;
      var expected = List.generate(n, (x) => throws(x) ? err(x) : res(x));

      expect(all, completion(expected));

      var completeFunctions = List<Function()>.generate(n, (i) {
        var c = cs[i];
        return () =>
            throws(i) ? c.completeError('$i', someStack) : c.complete(i);
      });
      completeFunctions.shuffle(rnd);
      for (var i = 0; i < n; i++) {
        await _microTask();
        completeFunctions[i]();
      }
    });
  });
  group('values only,', () {
    test('single', () async {
      var all = await Result.captureAll<int>(<int>[1]);
      expect(all, [res(1)]);
    });
    test('multiple', () async {
      var all = await Result.captureAll<int>(<int>[1, 2, 3]);
      expect(all, [res(1), res(2), res(3)]);
    });
  });
  group('mixed futures and values,', () {
    test('no error', () async {
      var all = await Result.captureAll<int>(<FutureOr<int>>[
        1,
        Future<int>(() => 2),
        3,
        Future<int>.value(4),
      ]);
      expect(all, [res(1), res(2), res(3), res(4)]);
    });
    test('error', () async {
      var all = await Result.captureAll<int>(<FutureOr<int>>[
        1,
        Future<int>(() => 2),
        3,
        Future<int>(() async => await Future.error('4', someStack)),
        Future<int>.value(5)
      ]);
      expect(all, [res(1), res(2), res(3), err(4), res(5)]);
    });
  });
}

Future<void> _microTask() => Future.microtask(() {});
