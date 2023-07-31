// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2js chain tests are separated out because dart2js stack traces are
// inconsistent due to inlining and browser differences. These tests don't
// assert anything about the content of the traces, just the number of traces in
// a chain.
@TestOn('js')

import 'dart:async';

import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('capture() with onError catches exceptions', () {
    test('thrown synchronously', () async {
      var chain = await captureFuture(() => throw 'error');
      expect(chain.traces, hasLength(1));
    });

    test('thrown in a microtask', () async {
      var chain = await captureFuture(() => inMicrotask(() => throw 'error'));
      expect(chain.traces, hasLength(2));
    });

    test('thrown in a one-shot timer', () async {
      var chain =
          await captureFuture(() => inOneShotTimer(() => throw 'error'));
      expect(chain.traces, hasLength(2));
    });

    test('thrown in a periodic timer', () async {
      var chain =
          await captureFuture(() => inPeriodicTimer(() => throw 'error'));
      expect(chain.traces, hasLength(2));
    });

    test('thrown in a nested series of asynchronous operations', () async {
      var chain = await captureFuture(() {
        inPeriodicTimer(() {
          inOneShotTimer(() => inMicrotask(() => throw 'error'));
        });
      });

      expect(chain.traces, hasLength(4));
    });

    test('thrown in a long future chain', () async {
      var chain = await captureFuture(() => inFutureChain(() => throw 'error'));

      // Despite many asynchronous operations, there's only one level of
      // nested calls, so there should be only two traces in the chain. This
      // is important; programmers expect stack trace memory consumption to be
      // O(depth of program), not O(length of program).
      expect(chain.traces, hasLength(2));
    });

    test('thrown in new Future()', () async {
      var chain = await captureFuture(() => inNewFuture(() => throw 'error'));
      expect(chain.traces, hasLength(3));
    });

    test('thrown in new Future.sync()', () async {
      var chain = await captureFuture(() {
        inMicrotask(() => inSyncFuture(() => throw 'error'));
      });

      expect(chain.traces, hasLength(3));
    });

    test('multiple times', () {
      var completer = Completer();
      var first = true;

      Chain.capture(() {
        inMicrotask(() => throw 'first error');
        inPeriodicTimer(() => throw 'second error');
      }, onError: (error, chain) {
        try {
          if (first) {
            expect(error, equals('first error'));
            expect(chain.traces, hasLength(2));
            first = false;
          } else {
            expect(error, equals('second error'));
            expect(chain.traces, hasLength(2));
            completer.complete();
          }
        } on Object catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      });

      return completer.future;
    });

    test('passed to a completer', () async {
      var trace = Trace.current();
      var chain = await captureFuture(() {
        inMicrotask(() => completerErrorFuture(trace));
      });

      expect(chain.traces, hasLength(3));

      // The first trace is the trace that was manually reported for the
      // error.
      expect(chain.traces.first.toString(), equals(trace.toString()));
    });

    test('passed to a completer with no stack trace', () async {
      var chain = await captureFuture(() {
        inMicrotask(completerErrorFuture);
      });

      expect(chain.traces, hasLength(2));
    });

    test('passed to a stream controller', () async {
      var trace = Trace.current();
      var chain = await captureFuture(() {
        inMicrotask(() => controllerErrorStream(trace).listen(null));
      });

      expect(chain.traces, hasLength(3));
      expect(chain.traces.first.toString(), equals(trace.toString()));
    });

    test('passed to a stream controller with no stack trace', () async {
      var chain = await captureFuture(() {
        inMicrotask(() => controllerErrorStream().listen(null));
      });

      expect(chain.traces, hasLength(2));
    });

    test('and relays them to the parent zone', () {
      var completer = Completer();

      runZonedGuarded(() {
        Chain.capture(() {
          inMicrotask(() => throw 'error');
        }, onError: (error, chain) {
          expect(error, equals('error'));
          expect(chain.traces, hasLength(2));
          throw error;
        });
      }, (error, chain) {
        try {
          expect(error, equals('error'));
          expect(chain,
              isA<Chain>().having((c) => c.traces, 'traces', hasLength(2)));
          completer.complete();
        } on Object catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      });

      return completer.future;
    });
  });

  test('capture() without onError passes exceptions to parent zone', () {
    var completer = Completer();

    runZonedGuarded(() {
      Chain.capture(() => inMicrotask(() => throw 'error'));
    }, (error, chain) {
      try {
        expect(error, equals('error'));
        expect(chain,
            isA<Chain>().having((c) => c.traces, 'traces', hasLength(2)));
        completer.complete();
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  });

  group('current() within capture()', () {
    test('called in a microtask', () async {
      var completer = Completer<Chain>();
      Chain.capture(() {
        inMicrotask(() => completer.complete(Chain.current()));
      });

      var chain = await completer.future;
      expect(chain.traces, hasLength(2));
    });

    test('called in a one-shot timer', () async {
      var completer = Completer<Chain>();
      Chain.capture(() {
        inOneShotTimer(() => completer.complete(Chain.current()));
      });

      var chain = await completer.future;
      expect(chain.traces, hasLength(2));
    });

    test('called in a periodic timer', () async {
      var completer = Completer<Chain>();
      Chain.capture(() {
        inPeriodicTimer(() => completer.complete(Chain.current()));
      });

      var chain = await completer.future;
      expect(chain.traces, hasLength(2));
    });

    test('called in a nested series of asynchronous operations', () async {
      var completer = Completer<Chain>();
      Chain.capture(() {
        inPeriodicTimer(() {
          inOneShotTimer(() {
            inMicrotask(() => completer.complete(Chain.current()));
          });
        });
      });

      var chain = await completer.future;
      expect(chain.traces, hasLength(4));
    });

    test('called in a long future chain', () async {
      var completer = Completer<Chain>();
      Chain.capture(() {
        inFutureChain(() => completer.complete(Chain.current()));
      });

      var chain = await completer.future;
      expect(chain.traces, hasLength(2));
    });
  });

  test(
    'current() outside of capture() returns a chain wrapping the current trace',
    () =>
        // The test runner runs all tests with chains enabled.
        Chain.disable(() async {
      var completer = Completer<Chain>();
      inMicrotask(() => completer.complete(Chain.current()));

      var chain = await completer.future;
      // Since the chain wasn't loaded within [Chain.capture], the full stack
      // chain isn't available and it just returns the current stack when
      // called.
      expect(chain.traces, hasLength(1));
    }),
  );

  group('forTrace() within capture()', () {
    test('called for a stack trace from a microtask', () async {
      var chain = await Chain.capture(
          () => chainForTrace(inMicrotask, () => throw 'error'));

      // Because [chainForTrace] has to set up a future chain to capture the
      // stack trace while still showing it to the zone specification, it adds
      // an additional level of async nesting and so an additional trace.
      expect(chain.traces, hasLength(3));
    });

    test('called for a stack trace from a one-shot timer', () async {
      var chain = await Chain.capture(
          () => chainForTrace(inOneShotTimer, () => throw 'error'));

      expect(chain.traces, hasLength(3));
    });

    test('called for a stack trace from a periodic timer', () async {
      var chain = await Chain.capture(
          () => chainForTrace(inPeriodicTimer, () => throw 'error'));

      expect(chain.traces, hasLength(3));
    });

    test(
        'called for a stack trace from a nested series of asynchronous '
        'operations', () async {
      var chain = await Chain.capture(() => chainForTrace((callback) {
            inPeriodicTimer(() => inOneShotTimer(() => inMicrotask(callback)));
          }, () => throw 'error'));

      expect(chain.traces, hasLength(5));
    });

    test('called for a stack trace from a long future chain', () async {
      var chain = await Chain.capture(
          () => chainForTrace(inFutureChain, () => throw 'error'));

      expect(chain.traces, hasLength(3));
    });

    test(
        'called for an unregistered stack trace returns a chain wrapping that '
        'trace', () {
      late StackTrace trace;
      var chain = Chain.capture(() {
        try {
          throw 'error';
        } catch (_, stackTrace) {
          trace = stackTrace;
          return Chain.forTrace(stackTrace);
        }
      });

      expect(chain.traces, hasLength(1));
      expect(
          chain.traces.first.toString(), equals(Trace.from(trace).toString()));
    });
  });

  test(
      'forTrace() outside of capture() returns a chain wrapping the given '
      'trace', () {
    late StackTrace trace;
    var chain = Chain.capture(() {
      try {
        throw 'error';
      } catch (_, stackTrace) {
        trace = stackTrace;
        return Chain.forTrace(stackTrace);
      }
    });

    expect(chain.traces, hasLength(1));
    expect(chain.traces.first.toString(), equals(Trace.from(trace).toString()));
  });
}
