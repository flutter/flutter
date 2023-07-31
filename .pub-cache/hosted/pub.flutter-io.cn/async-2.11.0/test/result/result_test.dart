// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:async/async.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

void main() {
  var stack = Trace.current();

  test('create result value', () {
    var result = Result<int>.value(42);
    expect(result.isValue, isTrue);
    expect(result.isError, isFalse);
    ValueResult value = result.asValue!;
    expect(value.value, equals(42));
  });

  test('create result value 2', () {
    Result<int> result = ValueResult<int>(42);
    expect(result.isValue, isTrue);
    expect(result.isError, isFalse);
    var value = result.asValue!;
    expect(value.value, equals(42));
  });

  test('create result error', () {
    var result = Result<bool>.error('BAD', stack);
    expect(result.isValue, isFalse);
    expect(result.isError, isTrue);
    var error = result.asError!;
    expect(error.error, equals('BAD'));
    expect(error.stackTrace, same(stack));
  });

  test('create result error 2', () {
    var result = ErrorResult('BAD', stack);
    expect(result.isValue, isFalse);
    expect(result.isError, isTrue);
    var error = result.asError;
    expect(error.error, equals('BAD'));
    expect(error.stackTrace, same(stack));
  });

  test('create result error no stack', () {
    var result = Result<bool>.error('BAD');
    expect(result.isValue, isFalse);
    expect(result.isError, isTrue);
    var error = result.asError!;
    expect(error.error, equals('BAD'));
    // A default stack trace is created
    expect(error.stackTrace, isNotNull);
  });

  test('complete with value', () {
    Result<int> result = ValueResult<int>(42);
    var c = Completer<int>();
    c.future.then(expectAsync1((int v) {
      expect(v, equals(42));
    }), onError: (e, s) {
      fail('Unexpected error');
    });
    result.complete(c);
  });

  test('complete with error', () {
    Result<bool> result = ErrorResult('BAD', stack);
    var c = Completer<bool>();
    c.future.then((bool v) {
      fail('Unexpected value $v');
    }).then<void>((_) {}, onError: expectAsync2((e, s) {
      expect(e, equals('BAD'));
      expect(s, same(stack));
    }));
    result.complete(c);
  });

  test('add sink value', () {
    var result = ValueResult<int>(42);
    EventSink<int> sink = TestSink(onData: expectAsync1((v) {
      expect(v, equals(42));
    }));
    result.addTo(sink);
  });

  test('add sink error', () {
    Result<bool> result = ErrorResult('BAD', stack);
    EventSink<bool> sink = TestSink(onError: expectAsync2((e, s) {
      expect(e, equals('BAD'));
      expect(s, same(stack));
    }));
    result.addTo(sink);
  });

  test('value as future', () {
    Result<int> result = ValueResult<int>(42);
    result.asFuture.then(expectAsync1((int v) {
      expect(v, equals(42));
    }), onError: (e, s) {
      fail('Unexpected error');
    });
  });

  test('error as future', () {
    Result<bool> result = ErrorResult('BAD', stack);
    result.asFuture.then((bool v) {
      fail('Unexpected value $v');
    }).then<void>((_) {}, onError: expectAsync2((e, s) {
      expect(e, equals('BAD'));
      expect(s, same(stack));
    }));
  });

  test('capture future value', () {
    var value = Future<int>.value(42);
    Result.capture(value).then(expectAsync1((Result result) {
      expect(result.isValue, isTrue);
      expect(result.isError, isFalse);
      var value = result.asValue!;
      expect(value.value, equals(42));
    }), onError: (e, s) {
      fail('Unexpected error: $e');
    });
  });

  test('capture future error', () {
    var value = Future<bool>.error('BAD', stack);
    Result.capture(value).then(expectAsync1((Result result) {
      expect(result.isValue, isFalse);
      expect(result.isError, isTrue);
      var error = result.asError!;
      expect(error.error, equals('BAD'));
      expect(error.stackTrace, same(stack));
    }), onError: (e, s) {
      fail('Unexpected error: $e');
    });
  });

  test('release future value', () {
    var future = Future<Result<int>>.value(Result<int>.value(42));
    Result.release(future).then(expectAsync1((v) {
      expect(v, equals(42));
    }), onError: (e, s) {
      fail('Unexpected error: $e');
    });
  });

  test('release future error', () {
    // An error in the result is unwrapped and reified by release.
    var future = Future<Result<bool>>.value(Result<bool>.error('BAD', stack));
    Result.release(future).then((v) {
      fail('Unexpected value: $v');
    }).then<void>((_) {}, onError: expectAsync2((e, s) {
      expect(e, equals('BAD'));
      expect(s, same(stack));
    }));
  });

  test('release future real error', () {
    // An error in the error lane is passed through by release.
    var future = Future<Result<bool>>.error('BAD', stack);
    Result.release(future).then((v) {
      fail('Unexpected value: $v');
    }).then<void>((_) {}, onError: expectAsync2((e, s) {
      expect(e, equals('BAD'));
      expect(s, same(stack));
    }));
  });

  test('capture stream', () {
    var c = StreamController<int>();
    var stream = Result.captureStream(c.stream);
    var expectedList = Queue.of(
        [Result.value(42), Result.error('BAD', stack), Result.value(37)]);
    void listener(Result actual) {
      expect(expectedList.isEmpty, isFalse);
      expectResult(actual, expectedList.removeFirst());
    }

    stream.listen(expectAsync1(listener, count: 3),
        onDone: expectAsync0(() {}), cancelOnError: true);
    c.add(42);
    c.addError('BAD', stack);
    c.add(37);
    c.close();
  });

  test('release stream', () {
    var c = StreamController<Result<int>>();
    var stream = Result.releaseStream(c.stream);
    var events = [
      Result<int>.value(42),
      Result<int>.error('BAD', stack),
      Result<int>.value(37)
    ];
    // Expect the data events, and an extra error event.
    var expectedList = Queue.of(events)..add(Result.error('BAD2', stack));

    void dataListener(int v) {
      expect(expectedList.isEmpty, isFalse);
      Result expected = expectedList.removeFirst();
      expect(expected.isValue, isTrue);
      expect(v, equals(expected.asValue!.value));
    }

    void errorListener(error, StackTrace stackTrace) {
      expect(expectedList.isEmpty, isFalse);
      Result expected = expectedList.removeFirst();
      expect(expected.isError, isTrue);
      expect(error, equals(expected.asError!.error));
      expect(stackTrace, same(expected.asError!.stackTrace));
    }

    stream.listen(expectAsync1(dataListener, count: 2),
        onError: expectAsync2(errorListener, count: 2),
        onDone: expectAsync0(() {}));
    for (var result in events) {
      c.add(result); // Result value or error in data line.
    }
    c.addError('BAD2', stack); // Error in error line.
    c.close();
  });

  test('release stream cancel on error', () {
    var c = StreamController<Result<int>>();
    var stream = Result.releaseStream(c.stream);
    stream.listen(expectAsync1((v) {
      expect(v, equals(42));
    }), onError: expectAsync2((e, s) {
      expect(e, equals('BAD'));
      expect(s, same(stack));
    }), onDone: () {
      fail('Unexpected done event');
    }, cancelOnError: true);
    c.add(Result.value(42));
    c.add(Result.error('BAD', stack));
    c.add(Result.value(37));
    c.close();
  });

  test('flatten error 1', () {
    var error = Result<int>.error('BAD', stack);
    var flattened = Result.flatten(Result<Result<int>>.error('BAD', stack));
    expectResult(flattened, error);
  });

  test('flatten error 2', () {
    var error = Result<int>.error('BAD', stack);
    var result = Result<Result<int>>.value(error);
    var flattened = Result.flatten(result);
    expectResult(flattened, error);
  });

  test('flatten value', () {
    var result = Result<Result<int>>.value(Result<int>.value(42));
    expectResult(Result.flatten(result), Result<int>.value(42));
  });

  test('handle unary', () {
    var result = ErrorResult('error', stack);
    var called = false;
    result.handle((error) {
      called = true;
      expect(error, 'error');
    });
    expect(called, isTrue);
  });

  test('handle binary', () {
    var result = ErrorResult('error', stack);
    var called = false;
    result.handle((error, stackTrace) {
      called = true;
      expect(error, 'error');
      expect(stackTrace, same(stack));
    });
    expect(called, isTrue);
  });

  test('handle unary and binary', () {
    var result = ErrorResult('error', stack);
    var called = false;
    result.handle((error, [stackTrace]) {
      called = true;
      expect(error, 'error');
      expect(stackTrace, same(stack));
    });
    expect(called, isTrue);
  });

  test('handle neither unary nor binary', () {
    var result = ErrorResult('error', stack);
    expect(() => result.handle(() => fail('unreachable')), throwsA(anything));
    expect(() => result.handle((a, b, c) => fail('unreachable')),
        throwsA(anything));
    expect(() => result.handle((a, b, {c}) => fail('unreachable')),
        throwsA(anything));
    expect(() => result.handle((a, {b}) => fail('unreachable')),
        throwsA(anything));
    expect(() => result.handle(({a, b}) => fail('unreachable')),
        throwsA(anything));
    expect(
        () => result.handle(({a}) => fail('unreachable')), throwsA(anything));
  });
}

void expectResult(Result actual, Result expected) {
  expect(actual.isValue, equals(expected.isValue));
  expect(actual.isError, equals(expected.isError));
  if (actual.isValue) {
    expect(actual.asValue!.value, equals(expected.asValue!.value));
  } else {
    expect(actual.asError!.error, equals(expected.asError!.error));
    expect(actual.asError!.stackTrace, same(expected.asError!.stackTrace));
  }
}

class TestSink<T> implements EventSink<T> {
  final void Function(T) onData;
  final void Function(dynamic, StackTrace) onError;
  final void Function() onDone;

  TestSink(
      {this.onData = _nullData,
      this.onError = _nullError,
      this.onDone = _nullDone});

  @override
  void add(T value) {
    onData(value);
  }

  @override
  void addError(Object error, [StackTrace? stack]) {
    onError(error, stack ?? StackTrace.fromString(''));
  }

  @override
  void close() {
    onDone();
  }

  static void _nullData(value) {
    fail('Unexpected sink add: $value');
  }

  static void _nullError(e, StackTrace s) {
    fail('Unexpected sink addError: $e');
  }

  static void _nullDone() {
    fail('Unepxected sink close');
  }
}
