// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:async library.

import 'dart:_internal' show patch, unsafeCast;
import 'dart:_js_helper'
    show
        ExceptionAndStackTrace,
        convertDartClosureToJS,
        getTraceFromException,
        requiresPreamble,
        wrapException,
        unwrapException;

import 'dart:_foreign_helper'
    show JS, JS_FALSE, JS_RAW_EXCEPTION, RAW_DART_FUNCTION_REF;

import 'dart:_async_status_codes' as async_status_codes;

@patch
class _AsyncRun {
  @patch
  static void _scheduleImmediate(void callback()) {
    _scheduleImmediateClosure(callback);
  }

  // Lazily initialized.
  static final Function _scheduleImmediateClosure =
      _initializeScheduleImmediate();

  static Function _initializeScheduleImmediate() {
    requiresPreamble();
    if (JS('', 'self.scheduleImmediate') != null) {
      return _scheduleImmediateJsOverride;
    }
    if (JS('', 'self.MutationObserver') != null &&
        JS('', 'self.document') != null) {
      // Use mutationObservers.
      var div = JS('', 'self.document.createElement("div")');
      var span = JS('', 'self.document.createElement("span")');
      void Function()? storedCallback;

      internalCallback(_) {
        var f = storedCallback;
        storedCallback = null;
        f!();
      }

      var observer = JS('', 'new self.MutationObserver(#)',
          convertDartClosureToJS(internalCallback, 1));
      JS('', '#.observe(#, { childList: true })', observer, div);

      return (void callback()) {
        assert(storedCallback == null);
        storedCallback = callback;
        // Because of a broken shadow-dom polyfill we have to change the
        // children instead a cheap property.
        JS('', '#.firstChild ? #.removeChild(#): #.appendChild(#)', div, div,
            span, div, span);
      };
    } else if (JS('', 'self.setImmediate') != null) {
      return _scheduleImmediateWithSetImmediate;
    }
    // TODO(20055): We should use DOM promises when available.
    return _scheduleImmediateWithTimer;
  }

  static void _scheduleImmediateJsOverride(void callback()) {
    internalCallback() {
      callback();
    }

    JS('void', 'self.scheduleImmediate(#)',
        convertDartClosureToJS(internalCallback, 0));
  }

  static void _scheduleImmediateWithSetImmediate(void callback()) {
    internalCallback() {
      callback();
    }

    JS('void', 'self.setImmediate(#)',
        convertDartClosureToJS(internalCallback, 0));
  }

  static void _scheduleImmediateWithTimer(void callback()) {
    Timer._createTimer(Duration.zero, callback);
  }
}

@patch
class Timer {
  @patch
  static Timer _createTimer(Duration duration, void callback()) {
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return _TimerImpl(milliseconds, callback);
  }

  @patch
  static Timer _createPeriodicTimer(
      Duration duration, void callback(Timer timer)) {
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return _TimerImpl.periodic(milliseconds, callback);
  }
}

class _TimerImpl implements Timer {
  final bool _once;
  int? _handle;
  int _tick = 0;

  _TimerImpl(int milliseconds, void callback()) : _once = true {
    if (_hasTimer()) {
      void internalCallback() {
        _handle = null;
        this._tick = 1;
        callback();
      }

      _handle = JS('int', 'self.setTimeout(#, #)',
          convertDartClosureToJS(internalCallback, 0), milliseconds);
    } else {
      throw UnsupportedError('`setTimeout()` not found.');
    }
  }

  _TimerImpl.periodic(int milliseconds, void callback(Timer timer))
      : _once = false {
    if (_hasTimer()) {
      int start = JS('int', 'Date.now()');
      _handle = JS(
          'int',
          'self.setInterval(#, #)',
          convertDartClosureToJS(() {
            int tick = this._tick + 1;
            if (milliseconds > 0) {
              int end = JS('int', 'Date.now()');
              int duration = end - start;
              if (duration > (tick + 1) * milliseconds) {
                tick = duration ~/ milliseconds;
              }
            }
            this._tick = tick;
            callback(this);
          }, 0),
          milliseconds);
    } else {
      throw UnsupportedError('Periodic timer.');
    }
  }

  @override
  bool get isActive => _handle != null;

  @override
  int get tick => _tick;

  @override
  void cancel() {
    if (_hasTimer()) {
      if (_handle == null) return;
      if (_once) {
        JS('void', 'self.clearTimeout(#)', _handle);
      } else {
        JS('void', 'self.clearInterval(#)', _handle);
      }
      _handle = null;
    } else {
      throw UnsupportedError('Canceling a timer.');
    }
  }
}

bool _hasTimer() {
  requiresPreamble();
  return JS('', 'self.setTimeout') != null;
}

class _AsyncAwaitCompleter<T> implements Completer<T> {
  final _future = _Future<T>();
  bool isSync;

  _AsyncAwaitCompleter() : isSync = false;

  void complete([FutureOr<T>? value]) {
    // All paths require that if value is null, null as T succeeds.
    value = (value == null) ? value as T : value;
    if (!isSync) {
      _future._asyncComplete(value);
    } else if (value is Future<T>) {
      assert(!_future._isComplete);
      _future._chainFuture(value);
    } else {
      _future._completeWithValue(value);
    }
  }

  void completeError(Object e, [StackTrace? st]) {
    st ??= AsyncError.defaultStackTrace(e);
    if (isSync) {
      _future._completeError(e, st);
    } else {
      _future._asyncCompleteError(e, st);
    }
  }

  Future<T> get future => _future;
  bool get isCompleted => !_future._mayComplete;
}

/// Creates a Completer for an `async` function.
///
/// Used as part of the runtime support for the async/await transformation.
@pragma('dart2js:assumeDynamic') // Global type inference can't see call site.
Completer<T> _makeAsyncAwaitCompleter<T>() {
  return _AsyncAwaitCompleter<T>();
}

/// Initiates the computation of an `async` function and starts the body
/// synchronously.
///
/// Used as part of the runtime support for the async/await transformation.
///
/// This function sets up the first call into the transformed [bodyFunction].
/// Independently, it takes the [completer] and returns the future of the
/// completer for convenience of the transformed code.
dynamic _asyncStartSync(
    _WrappedAsyncBody bodyFunction, _AsyncAwaitCompleter completer) {
  bodyFunction(async_status_codes.SUCCESS, null);
  completer.isSync = true;
  return completer.future;
}

/// Performs the `await` operation of an `async` function.
///
/// Used as part of the runtime support for the async/await transformation.
///
/// Arranges for [bodyFunction] to be called when the future or value [object]
/// is completed with a code [async_status_codes.SUCCESS] or
/// [async_status_codes.ERROR] depending on the success of the future.
dynamic _asyncAwait(dynamic object, _WrappedAsyncBody bodyFunction) {
  _awaitOnObject(object, bodyFunction);
}

/// Completes the future of an `async` function.
///
/// Used as part of the runtime support for the async/await transformation.
///
/// This function is used when the `async` function returns (explicitly or
/// implicitly).
dynamic _asyncReturn(dynamic object, Completer completer) {
  completer.complete(object);
}

/// Completes the future of an `async` function with an error.
///
/// Used as part of the runtime support for the async/await transformation.
///
/// This function is used when the `async` function re-throws an exception.
dynamic _asyncRethrow(dynamic object, Completer completer) {
  // The error is a js-error.
  completer.completeError(
      unwrapException(object), getTraceFromException(object));
}

/// Awaits on the given [object].
///
/// If the [object] is a Future, registers on it, otherwise wraps it into a
/// future first.
///
/// The [bodyFunction] argument is the continuation that should be invoked
/// when the future completes.
void _awaitOnObject(object, _WrappedAsyncBody bodyFunction) {
  FutureOr<dynamic> Function(dynamic) thenCallback =
      (result) => bodyFunction(async_status_codes.SUCCESS, result);

  Function errorCallback = (dynamic error, StackTrace stackTrace) {
    ExceptionAndStackTrace wrappedException =
        ExceptionAndStackTrace(error, stackTrace);
    bodyFunction(async_status_codes.ERROR, wrappedException);
  };

  if (object is _Future) {
    // We can skip the zone registration, since the bodyFunction is already
    // registered (see [_wrapJsFunctionForAsync]).
    object._thenAwait(thenCallback, errorCallback);
  } else if (object is Future) {
    object.then(thenCallback, onError: errorCallback);
  } else {
    _Future future = _Future().._setValue(object);
    // We can skip the zone registration, since the bodyFunction is already
    // registered (see [_wrapJsFunctionForAsync]).
    future._thenAwait(thenCallback, errorCallback);
  }
}

typedef _WrappedAsyncBody = void Function(int errorCode, dynamic result);

_WrappedAsyncBody _wrapJsFunctionForAsync(dynamic /* js function */ function) {
  var protected = JS(
      '',
      """
        (function (fn, ERROR) {
          // Invokes [function] with [errorCode] and [result].
          //
          // If (and as long as) the invocation throws, calls [function] again,
          // with an error-code.
          return function(errorCode, result) {
            while (true) {
              try {
                fn(errorCode, result);
                break;
              } catch (error) {
                result = error;
                errorCode = ERROR;
              }
            }
          }
        })(#, #)""",
      function,
      async_status_codes.ERROR);

  return Zone.current.registerBinaryCallback((int errorCode, dynamic result) {
    JS('', '#(#, #)', protected, errorCode, result);
  });
}

/// Implements the runtime support for async* functions.
///
/// Called by the transformed function for each original return, await, yield,
/// yield* and before starting the function.
///
/// When the async* function wants to return it calls this function with
/// [asyncBody] == [async_status_codes.SUCCESS], the asyncStarHelper takes this
/// as signal to close the stream.
///
/// When the async* function wants to signal that an uncaught error was thrown,
/// it calls this function with [asyncBody] == [async_status_codes.ERROR],
/// the streamHelper takes this as signal to addError [object] to the
/// [controller] and close it.
///
/// If the async* function wants to do a yield or yield*, it calls this function
/// with [object] being an [IterationMarker].
///
/// In the case of a yield or yield*, if the stream subscription has been
/// canceled, schedules [asyncBody] to be called with
/// [async_status_codes.STREAM_WAS_CANCELED].
///
/// If [object] is a single-yield [IterationMarker], adds the value of the
/// [IterationMarker] to the stream. If the stream subscription has been
/// paused, return early. Otherwise schedule the helper function to be
/// executed again.
///
/// If [object] is a yield-star [IterationMarker], starts listening to the
/// yielded stream, and adds all events and errors to our own controller (taking
/// care if the subscription has been paused or canceled) - when the sub-stream
/// is done, schedules [asyncBody] again.
///
/// If the async* function wants to do an await it calls this function with
/// [object] not an [IterationMarker].
///
/// If [object] is not a [Future], it is wrapped in a `Future.value`.
/// The [asyncBody] is called on completion of the future (see [asyncHelper].
void _asyncStarHelper(
    dynamic object,
    dynamic /* int | _WrappedAsyncBody */ bodyFunctionOrErrorCode,
    _AsyncStarStreamController controller) {
  if (identical(bodyFunctionOrErrorCode, async_status_codes.SUCCESS)) {
    // This happens on return from the async* function.
    if (controller.isCanceled) {
      controller.cancelationFuture!._completeWithValue(null);
    } else {
      controller.close();
    }
    return;
  } else if (identical(bodyFunctionOrErrorCode, async_status_codes.ERROR)) {
    // The error is a js-error.
    if (controller.isCanceled) {
      controller.cancelationFuture!._completeError(
          unwrapException(object), getTraceFromException(object));
    } else {
      controller.addError(
          unwrapException(object), getTraceFromException(object));
      controller.close();
    }
    return;
  }

  _WrappedAsyncBody bodyFunction = bodyFunctionOrErrorCode;
  if (object is _IterationMarker) {
    if (controller.isCanceled) {
      bodyFunction(async_status_codes.STREAM_WAS_CANCELED, null);
      return;
    }
    if (object.state == _IterationMarker.YIELD_SINGLE) {
      controller.add(object.value);

      scheduleMicrotask(() {
        if (controller.isPaused) {
          // We only suspend the thread inside the microtask in order to allow
          // listeners on the output stream to pause in response to the just
          // output value, and have the stream immediately stop producing.
          controller.isSuspended = true;
          return;
        }
        bodyFunction(
            controller.isCanceled
                ? async_status_codes.STREAM_WAS_CANCELED
                : async_status_codes.SUCCESS,
            null);
      });
      return;
    } else if (object.state == _IterationMarker.YIELD_STAR) {
      Stream stream = object.value;
      // Errors of [stream] are passed though to the main stream. (see
      // [AsyncStreamController.addStream]).
      controller.addStream(stream).then((_) {
        // No need to check for pause because to get here the stream either
        // completed normally or was cancelled. The stream cannot be paused
        // after either of these states.
        int errorCode = controller.isCanceled
            ? async_status_codes.STREAM_WAS_CANCELED
            : async_status_codes.SUCCESS;
        bodyFunction(errorCode, null);
      });
      return;
    }
  }

  _awaitOnObject(object, bodyFunction);
}

Stream _streamOfController(_AsyncStarStreamController controller) {
  return controller.stream;
}

/// A wrapper around a [StreamController] that keeps track of the state of
/// the execution of an async* function.
/// It can be in 1 of 3 states:
///
/// - running/scheduled
/// - suspended
/// - canceled
///
/// If yielding while the subscription is paused it will become suspended. And
/// only resume after the subscription is resumed or canceled.
class _AsyncStarStreamController<T> {
  late StreamController<T> controller;
  Stream get stream => controller.stream;

  /// True when the async* function has yielded while being paused.
  /// When true execution will only resume after a `onResume` or `onCancel`
  /// event.
  bool isSuspended = false;

  bool get isPaused => controller.isPaused;

  _Future? cancelationFuture = null;

  /// True after the StreamSubscription has been cancelled.
  /// When this is true, errors thrown from the async* body should go to the
  /// [cancelationFuture] instead of adding them to [controller], and
  /// returning from the async function should complete [cancelationFuture].
  bool get isCanceled => cancelationFuture != null;

  add(event) => controller.add(event);

  Future addStream(Stream<T> stream) {
    return controller.addStream(stream, cancelOnError: false);
  }

  addError(error, stackTrace) => controller.addError(error, stackTrace);

  close() => controller.close();

  _AsyncStarStreamController(_WrappedAsyncBody body) {
    _resumeBody() {
      scheduleMicrotask(() {
        body(async_status_codes.SUCCESS, null);
      });
    }

    controller = StreamController<T>(onListen: () {
      _resumeBody();
    }, onResume: () {
      // Only schedule again if the async* function actually is suspended.
      // Resume directly instead of scheduling, so that the sequence
      // `pause-resume-pause` will result in one extra event produced.
      if (isSuspended) {
        isSuspended = false;
        _resumeBody();
      }
    }, onCancel: () {
      // If the async* is finished we ignore cancel events.
      if (!controller.isClosed) {
        cancelationFuture = _Future();
        if (isSuspended) {
          // Resume the suspended async* function to run finalizers.
          isSuspended = false;
          scheduleMicrotask(() {
            body(async_status_codes.STREAM_WAS_CANCELED, null);
          });
        }
        return cancelationFuture;
      }
    });
  }
}

/// Creates a stream controller for an `async*` function.
///
/// Used as part of the runtime support for the async/await transformation.
@pragma('dart2js:assumeDynamic') // Global type inference can't see call site.
_makeAsyncStarStreamController<T>(_WrappedAsyncBody body) {
  return _AsyncStarStreamController<T>(body);
}

class _IterationMarker {
  static const YIELD_SINGLE = 0;
  static const YIELD_STAR = 1;
  static const ITERATION_ENDED = 2;
  static const UNCAUGHT_ERROR = 3;

  final value;
  final int state;

  const _IterationMarker._(this.state, this.value);

  static yieldStar(dynamic /* Iterable or Stream */ values) {
    return _IterationMarker._(YIELD_STAR, values);
  }

  static endOfIteration() {
    return const _IterationMarker._(ITERATION_ENDED, null);
  }

  static yieldSingle(dynamic value) {
    return _IterationMarker._(YIELD_SINGLE, value);
  }

  static uncaughtError(dynamic error) {
    return _IterationMarker._(UNCAUGHT_ERROR, error);
  }

  toString() => "IterationMarker($state, $value)";
}

class _SyncStarIterator<T> implements Iterator<T> {
  // _SyncStarIterator handles stepping a sync* generator body state machine.
  //
  // It also handles the stepping over 'nested' iterators to flatten yield*
  // statements. For non-sync* iterators, [_nestedIterator] contains the
  // iterator. We delegate to [_nestedIterator] when it is not `null`.
  //
  // For nested sync* iterators, this [Iterator] acts on behalf of the innermost
  // nested sync* iterator. The current state machine is suspended on a stack
  // until the inner state machine ends.

  // The state machine for the innermost _SyncStarIterator.
  Object? _body;

  // The current value, unless iterating a non-sync* nested iterator.
  T? _current = null;

  // Value passed back from state machine for uncaught exceptions.
  Object? _datum;

  // This is the nested iterator when iterating a yield* of a non-sync iterator.
  Iterator<T>? _nestedIterator = null;

  // Stack of suspended state machines when iterating a yield* of a sync*
  // iterator.
  List? _suspendedBodies = null;

  _SyncStarIterator(this._body);

  T get current {
    return _current as dynamic; // implicit: as T;
  }

  _resumeBody(int errorCode, Object? errorValue) {
    final body = _body;
    while (true) {
      try {
        return JS('', '#(#, #, #)', body, this, errorCode, errorValue);
      } catch (error) {
        errorValue = JS_RAW_EXCEPTION();
        errorCode = async_status_codes.ERROR;
      }
    }
  }

  bool moveNext() {
    if (JS_FALSE()) _modelGeneratedCode();
    Object? errorValue;
    int errorCode = async_status_codes.SUCCESS;
    while (true) {
      final nestedIterator = _nestedIterator;
      if (nestedIterator != null) {
        try {
          if (nestedIterator.moveNext()) {
            _current = nestedIterator.current;
            return true;
          } else {
            _nestedIterator = null;
          }
        } catch (error) {
          errorValue = JS_RAW_EXCEPTION();
          errorCode = async_status_codes.ERROR;
          _nestedIterator = null;
        }
      }

      var value = _resumeBody(errorCode, errorValue);

      if (async_status_codes.SYNC_STAR_YIELD == value) {
        // The state-machine has assgned the value to _current.
        return true;
      }
      if (async_status_codes.SYNC_STAR_DONE == value) {
        _current = null;
        var suspendedBodies = _suspendedBodies;
        if (suspendedBodies == null || suspendedBodies.isEmpty) {
          // Overwrite the body with a stub for an empty iterable. If [moveNext]
          // is called 'too many' times, it continues to return `false`.
          _body = RAW_DART_FUNCTION_REF(_terminatedBody);
          return false;
        }
        // Resume the innermost suspended iterator.
        _body = suspendedBodies.removeLast();
        errorCode = async_status_codes.SUCCESS;
        errorValue = null;
        continue;
      }
      if (async_status_codes.SYNC_STAR_YIELD_STAR == value) {
        // The call to _yieldStar has modified the state.
        errorCode = async_status_codes.SUCCESS;
        errorValue = null;
        continue;
      }
      if (async_status_codes.SYNC_STAR_UNCAUGHT_EXCEPTION == value) {
        errorValue = _datum;
        _datum = null;
        var suspendedBodies = _suspendedBodies;
        if (suspendedBodies == null || suspendedBodies.isEmpty) {
          _current = null;
          // Overwrite the body with a stub for an empty iterable. If [moveNext]
          // is called after the exception propagates out of the `yield*` stack,
          // it will return `false`.
          _body = RAW_DART_FUNCTION_REF(_terminatedBody);

          // This is a wrapped exception, so we use JavaScript throw to throw
          // it.
          JS('', 'throw #', errorValue);
          // The above is not seen as terminating, so we need this return:
          return false; // unreachable
        }
        // Resume the innermost suspended iterator.
        _body = suspendedBodies.removeLast();
        errorCode = async_status_codes.ERROR;
        continue;
      }
      throw StateError('sync*');
    }
    // TODO(http://dartbug.com/52166): Fix type inference so that this return
    // statement is not needed.
    return false;
  }

  static _terminatedBody(_1, _2, _3) => async_status_codes.SYNC_STAR_DONE;

  // Called from generated code.
  @pragma('dart2js:parameter:trust')
  int _yieldStar(Iterable<T> iterable) {
    if (iterable is _SyncStarIterable) {
      // Promotion fails, so we need this zero-cost 'cast'.
      _SyncStarIterable<T> syncStarIterable = JS('', '#', iterable);
      _SyncStarIterator inner = syncStarIterable.iterator;
      // Suspend the current state machine and start acting on behalf of
      // the nested state machine.
      //
      // TODO(sra): Recognize "tail yield*" statements and avoid
      // suspending the current body when all it will do is step without
      // effect to ITERATION_ENDED.
      (_suspendedBodies ??= []).add(_body);
      _body = inner._body;
      return async_status_codes.SYNC_STAR_YIELD_STAR;
    } else {
      _nestedIterator = iterable.iterator;
      return async_status_codes.SYNC_STAR_YIELD_STAR;
    }
  }

  // This code is assumed present by global type inference and models the types
  // flowing to various fields and methods from code inserted by the
  // state-machine rewriter.
  _modelGeneratedCode() {
    _yieldStar(_confuse<Iterable<T>>(this));
    _current = _confuse<T?>(null);
    _datum = _confuse<Object>(this);
  }

  @pragma('dart2js:assumeDynamic')
  static T _confuse<T>(dynamic x) => x;
}

/// Creates an Iterable for a `sync*` function.
///
/// Used as part of the runtime support for the async/await transformation.
@pragma('dart2js:assumeDynamic') // Global type inference can't see call site.
_SyncStarIterable<T> _makeSyncStarIterable<T>(body) {
  return _SyncStarIterable<T>(body);
}

/// An Iterable corresponding to a sync* method.
///
/// Each invocation of a sync* method will return a new instance of this class.
class _SyncStarIterable<T> extends Iterable<T> {
  // This is a function that will return a helper function that does the
  // iteration of the sync*.
  //
  // Each invocation should give a body with fresh state.
  final dynamic /* js function */ _outerHelper;

  _SyncStarIterable(this._outerHelper);

  @pragma('dart2js:prefer-inline')
  _SyncStarIterator<T> get iterator =>
      _SyncStarIterator<T>(JS('', '#()', _outerHelper));
}

/// Wraps an `await`ed expression in [Future.value] if needed.
///
/// If an expression `e` has a static type of `S`, then `await e` must first
/// check if the runtime type of `e` is `Future<flatten(S)>`. If it is, `e` can
/// be `await`ed directly. Otherwise, we must `await Future.value(e)`. Here, [T]
/// is expected to be `flatten(S)`.
///
/// It suffices to use `_Future.value` rather than `Future.value` - see the
/// comments on https://github.com/dart-lang/sdk/issues/50601.
@pragma('dart2js:prefer-inline')
Future<T> _wrapAwaitedExpression<T>(Object? e) =>
    e is Future<T> ? e : _Future<T>.value(unsafeCast<T>(e));
