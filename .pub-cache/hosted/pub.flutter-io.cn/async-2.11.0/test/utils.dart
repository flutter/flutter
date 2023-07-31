// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper utilities for testing.
import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

/// A zero-millisecond timer should wait until after all microtasks.
Future flushMicrotasks() => Future.delayed(Duration.zero);

typedef OptionalArgAction = void Function([dynamic a, dynamic b]);

/// A generic unreachable callback function.
///
/// Returns a function that fails the test if it is ever called.
OptionalArgAction unreachable(String name) =>
    ([a, b]) => fail('Unreachable: $name');

/// A matcher that runs a callback in its own zone and asserts that that zone
/// emits an error that matches [matcher].
Matcher throwsZoned(Matcher matcher) => predicate((void Function() callback) {
      var firstError = true;
      runZonedGuarded(
          callback,
          expectAsync2((error, stackTrace) {
            if (firstError) {
              expect(error, matcher);
              firstError = false;
            } else {
              registerException(error, stackTrace);
            }
          }, max: -1));
      return true;
    });

/// A matcher that runs a callback in its own zone and asserts that that zone
/// emits a [TypeError].
final throwsZonedTypeError = throwsZoned(TypeMatcher<TypeError>());

/// A matcher that matches a callback or future that throws a [TypeError].
final throwsTypeError = throwsA(TypeMatcher<TypeError>());

/// A badly behaved stream which throws if it's ever listened to.
///
/// Can be used to test cases where a stream should not be used.
class UnusableStream<T> extends Stream<T> {
  @override
  StreamSubscription<T> listen(void Function(T event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    throw UnimplementedError('Gotcha!');
  }
}

/// A dummy [StreamSink] for testing the routing of the [done] and [close]
/// futures.
///
/// The [completer] field allows the user to control the future returned by
/// [done] and [close].
class CompleterStreamSink<T> implements StreamSink<T> {
  final completer = Completer();

  @override
  Future get done => completer.future;

  @override
  void add(T event) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<T> stream) async {}
  @override
  Future close() => completer.future;
}

/// A [StreamSink] that collects all events added to it as results.
///
/// This is used for testing code that interacts with sinks.
class TestSink<T> implements StreamSink<T> {
  /// The results corresponding to events that have been added to the sink.
  final results = <Result<T>>[];

  /// Whether [close] has been called.
  bool get isClosed => _isClosed;
  var _isClosed = false;

  @override
  Future get done => _doneCompleter.future;
  final _doneCompleter = Completer();

  final void Function() _onDone;

  /// Creates a new sink.
  ///
  /// If [onDone] is passed, it's called when the user calls [close]. Its result
  /// is piped to the [done] future.
  TestSink({void Function()? onDone}) : _onDone = onDone ?? (() {});

  @override
  void add(T event) {
    results.add(Result<T>.value(event));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    results.add(Result<T>.error(error, stackTrace));
  }

  @override
  Future addStream(Stream<T> stream) {
    var completer = Completer.sync();
    stream.listen(add, onError: addError, onDone: completer.complete);
    return completer.future;
  }

  @override
  Future close() {
    _isClosed = true;
    _doneCompleter.complete(Future.microtask(_onDone));
    return done;
  }
}
