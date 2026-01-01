// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:async library.

import 'dart:_async_status_codes' as async_status_codes;
import 'dart:_js_helper' show notNull, ReifyFunctionTypes;
import 'dart:_internal' show patch, unsafeCast;
import 'dart:_isolate_helper' show TimerImpl;
import 'dart:_foreign_helper'
    show JS, JS_RAW_EXCEPTION, JSExportName, RAW_DART_FUNCTION_REF;
import 'dart:_runtime' as dart;

@patch
void _trySetStackTrace(Object error, StackTrace stackTrace) {
  if (error is Error) {
    dart.trySetStackTrace(error, stackTrace);
  }
}

/// This function adapts ES6 generators to implement Dart's async/await.
///
/// It's designed to interact with Dart's Future and follow Dart async/await
/// semantics.
///
/// See https://github.com/dart-lang/sdk/issues/27315 for ideas on reconciling
/// Dart's Future and ES6 Promise. At that point we should use native JS
/// async/await.
///
/// Inspired by `co`: https://github.com/tj/co/blob/master/index.js, which is a
/// stepping stone for ES async/await.
@JSExportName('async')
_async<T>(Function() initGenerator) {
  var iter;
  late Object? Function(Object?) onValue;
  late Object Function(Object, StackTrace?) onError;

  onAwait(Object? value) {
    _Future<Object?> f;
    if (value is _Future) {
      f = value;
    } else if (value is Future) {
      f = _Future();
      f._chainForeignFuture(value);
    } else {
      f = _Future.value(value);
    }
    f = JS('', '#', f._thenAwait(onValue, onError));
    return f;
  }

  onValue = (value) {
    var iteratorResult = JS('', '#.next(#)', iter, value);
    value = JS('', '#.value', iteratorResult);
    return JS<bool>('!', '#.done', iteratorResult) ? value : onAwait(value);
  };

  // If the awaited Future throws, we want to convert this to an exception
  // thrown from the `yield` point, as if it was thrown there.
  //
  // If the exception is not caught inside `gen`, it will emerge here, which
  // will send it to anyone listening on this async function's Future<T>.
  //
  // In essence, we are giving the code inside the generator a chance to
  // use try-catch-finally.
  onError = (value, stackTrace) {
    var iteratorResult = JS(
      '',
      '#.throw(#)',
      iter,
      dart.createErrorWithStack(value, stackTrace),
    );
    value = JS('', '#.value', iteratorResult);
    return JS<bool>('!', '#.done', iteratorResult) ? value : onAwait(value);
  };

  var zone = Zone.current;
  if (!identical(zone, _rootZone)) {
    onValue = zone.registerUnaryCallback(onValue);
    onError = zone.registerBinaryCallback(onError);
  }

  var asyncFuture = _Future<T>();

  // This will be set to true once we've yielded to the event loop.
  //
  // Before we've done that, we need to complete the future asynchronously to
  // match dart2js/VM. See https://github.com/dart-lang/sdk/issues/33330
  //
  // Once we've yielded to the event loop we can complete synchronously.
  // Other implementations call this `isSync` to indicate that.
  bool isRunningAsEvent = false;
  runBody() {
    try {
      iter = JS('', '#[Symbol.iterator]()', initGenerator());
      var iteratorValue = JS('', '#.next(null)', iter);
      var value = JS('', '#.value', iteratorValue);
      if (JS<bool>('!', '#.done', iteratorValue)) {
        // TODO(jmesserly): this is a workaround for ignored cast failures.
        // Remove it once we've fixed those. We should be able to call:
        //
        //     if (isRunningAsEvent) {
        //       asyncFuture._complete(value);
        //     } else {
        //       asyncFuture._asyncComplete(value);
        //     }
        //
        // But if the user code returns `Future<dynamic>` instead of
        // `Future<T>`, that function won't recognize it as a future and will
        // instead treat it as a completed value.
        if (value is Future) {
          if (value is _Future) {
            _Future._chainCoreFuture(value, asyncFuture, isRunningAsEvent);
          } else {
            asyncFuture._chainForeignFuture(value);
          }
        } else if (isRunningAsEvent) {
          asyncFuture._completeWithValue(JS('', '#', value));
        } else {
          asyncFuture._asyncComplete(JS('', '#', value));
        }
      } else {
        _Future._chainCoreFuture(onAwait(value), asyncFuture, true);
      }
    } catch (e, s) {
      if (isRunningAsEvent) {
        _completeWithErrorCallback(asyncFuture, e, s);
      } else {
        asyncFuture._asyncCompleteErrorObject(_interceptCaughtError(e, s));
      }
    }
  }

  if (dart.startAsyncSynchronously) {
    runBody();
    isRunningAsEvent = true;
  } else {
    isRunningAsEvent = true;
    scheduleMicrotask(runBody);
  }
  return asyncFuture;
}

/// Checks that the value being awaited is a Future of the expected type and
/// if not the value is wrapped in a new Future.
///
/// Calls to the method are generated from the compiler when it detects a type
/// check is required on the expression in an await.
///
/// Closes a soundness hole where null could leak from an awaited Future.
@JSExportName('awaitWithTypeCheck')
_awaitWithTypeCheck<T>(Object? value) =>
    value is T ? value : _Future.value(value);

@patch
class _AsyncRun {
  @patch
  static void _scheduleImmediate(void Function() callback) {
    _scheduleImmediateClosure(callback);
  }

  // Lazily initialized.
  static final _scheduleImmediateClosure = _initializeScheduleImmediate();

  static void Function(void Function()) _initializeScheduleImmediate() {
    // d8 support, see preambles/d8.js for the definition of `scheduleImmediate`.
    //
    // TODO(jmesserly): do we need this? It's only for our d8 stack trace test.
    if (JS('', '#.scheduleImmediate', dart.global_) != null) {
      return _scheduleImmediateJSOverride;
    }
    return _scheduleImmediateWithPromise;
  }

  @ReifyFunctionTypes(false)
  static void _scheduleImmediateJSOverride(void Function() callback) {
    final createdGeneration = dart.hotRestartGeneration();
    JS('void', '#.scheduleImmediate(#)', dart.global_, () {
      if (createdGeneration == dart.hotRestartGeneration()) callback();
    });
  }

  @ReifyFunctionTypes(false)
  static void _scheduleImmediateWithPromise(void Function() callback) {
    final createdGeneration = dart.hotRestartGeneration();
    JS('', '#.Promise.resolve(null).then(#)', dart.global_, () {
      if (createdGeneration == dart.hotRestartGeneration()) callback();
    });
  }
}

@patch
class Timer {
  @patch
  static Timer _createTimer(Duration duration, void Function() callback) {
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return TimerImpl(milliseconds, callback);
  }

  @patch
  static Timer _createPeriodicTimer(
    Duration duration,
    void callback(Timer timer),
  ) {
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return TimerImpl.periodic(milliseconds, callback);
  }
}

/// Used by the compiler to implement `async*` functions.
///
/// This is inspired by _AsyncStarStreamController in dart-lang/sdk's
/// runtime/lib/core_patch.dart
///
/// Given input like:
///
///     foo() async* {
///       yield 1;
///       yield* bar();
///       print(await baz());
///     }
///
/// This compiles to:
///
///     function foo() {
///       return new (AsyncStarImplOfT()).new(function*(stream) {
///         if (stream.add(1)) return;
///         yield;
///         if (stream.addStream(bar()) return;
///         yield;
///         print(yield baz());
///      });
///     }
///
class _AsyncStarImpl<T> {
  late StreamController<T> controller;
  Object Function(_AsyncStarImpl<T>) initGenerator;
  @notNull
  bool isSuspendedAtYieldStar = false;
  @notNull
  bool onListenReceived = false;
  @notNull
  bool isScheduled = false;
  @notNull
  bool isSuspendedAtYield = false;

  /// Whether we're suspended at an `await`.
  @notNull
  bool isSuspendedAtAwait = false;

  Completer? cancellationCompleter;
  late Object jsIterator;

  Null Function(Object, StackTrace)? _handleErrorCallback;
  void Function([Object?])? _runBodyCallback;

  _AsyncStarImpl(this.initGenerator) {
    controller = StreamController(
      onListen: JS('!', 'this.onListen.bind(this)'),
      onResume: JS('!', 'this.onResume.bind(this)'),
      onCancel: JS('!', 'this.onCancel.bind(this)'),
    );
    jsIterator = JS('!', '#[Symbol.iterator]()', initGenerator(this));
  }

  /// The stream produced by this `async*` function.
  Stream<T> get stream => controller.stream;

  /// Returns the callback used for error handling.
  ///
  /// This callback throws the error back into the user code, at the appropriate
  /// location (e.g. `await` `yield` or `yield*`). This gives user code a chance
  /// to handle it try-catch. If they do not handle, the error gets routed to
  /// the [stream] as an error via [addError].
  ///
  /// As a performance optimization, this callback is only bound once to the
  /// current [Zone]. This works because a single subscription stream should
  /// always be running in its original zone. An `async*` method will always
  /// save/restore the zone that was active when `listen()` was first called,
  /// similar to a stream. This follows from section 16.14 of the Dart 4th
  /// edition spec:
  ///
  /// > If `f` is marked `async*` (9), then a fresh instance `s` implementing
  /// > the built-in class `Stream` is associated with the invocation and
  /// > immediately returned. When `s` is listened to, execution of the body of
  /// > `f` will begin.
  ///
  Null Function(Object, StackTrace) get handleError {
    if (_handleErrorCallback == null) {
      _handleErrorCallback = (error, StackTrace stackTrace) {
        try {
          JS(
            '',
            '#.throw(#)',
            jsIterator,
            dart.createErrorWithStack(error, stackTrace),
          );
        } catch (e, newStack) {
          // The generator didn't catch the error, or it threw a new one.
          // Make sure to propagate the new error.
          addError(e, newStack);
        }
      };
      var zone = Zone.current;
      if (!identical(zone, Zone.root)) {
        _handleErrorCallback = zone.bindBinaryCallback(_handleErrorCallback!);
      }
    }
    return _handleErrorCallback!;
  }

  void scheduleGenerator() {
    // TODO(jmesserly): is this isPaused check in the right place? Assuming the
    // async* Stream yields, then is paused (by other code), the body will
    // already be scheduled. This will cause at least one more iteration to
    // run (adding another data item to the Stream) before actually pausing.
    // It could be fixed by moving the `isPaused` check inside `runBody`.
    if (isScheduled || controller.isPaused || isSuspendedAtYieldStar) {
      return;
    }
    isScheduled = true;
    // Capture the current zone. See comment on [handleError] for more
    // information about this optimization.
    var zone = Zone.current;
    if (_runBodyCallback == null) {
      _runBodyCallback = JS('!', '#.bind(this)', runBody);
      if (!identical(zone, Zone.root)) {
        var registered = zone.registerUnaryCallback(_runBodyCallback!);
        _runBodyCallback = ([arg]) => zone.runUnaryGuarded(registered, arg);
      }
    }
    zone.scheduleMicrotask(_runBodyCallback!);
  }

  void runBody(awaitValue) {
    isScheduled = false;
    isSuspendedAtYield = false;
    isSuspendedAtAwait = false;

    Object iterResult;
    try {
      iterResult = JS('', '#.next(#)', jsIterator, awaitValue);
    } catch (e, s) {
      addError(e, s);
      return;
    }

    if (JS('!', '#.done', iterResult)) {
      close();
      return;
    }

    // If we're suspended at a yield/yield*, we're done for now.
    if (isSuspendedAtYield || isSuspendedAtYieldStar) return;

    // Handle `await`: if we get a value passed to `yield` it means we are
    // waiting on this Future. Make sure to prevent scheduling, and pass the
    // value back as the result of the `yield`.
    //
    // TODO(jmesserly): is the timing here correct? The assumption here is
    // that we should schedule `await` in `async*` the same as in `async`.
    isSuspendedAtAwait = true;
    FutureOr<Object?> value = JS('', '#.value', iterResult);

    // TODO(jmesserly): this logic was copied from `async` function impl.
    _Future<Object?> f;
    if (value is _Future) {
      f = value;
    } else if (value is Future) {
      f = _Future();
      f._chainForeignFuture(value);
    } else {
      f = _Future.value(value);
    }
    f._thenAwait(_runBodyCallback!, handleError);
  }

  /// Adds element to [stream] and returns true if the caller should terminate
  /// execution of the generator.
  ///
  /// This is called from generated code like this:
  ///
  ///     if (controller.add(1)) return;
  ///     yield;
  //
  // TODO(hausner): Per spec, the generator should be suspended before exiting
  // when the stream is closed. We could add a getter like this:
  //
  //     get isCancelled => controller.hasListener;
  //
  // The generator would translate a 'yield e' statement to
  //
  //     controller.add(1);
  //     suspend; // this is `yield` in JS.
  //     if (controller.isCancelled) return;
  bool add(T event) {
    if (!onListenReceived) _fatal("yield before stream is listened to");
    if (isSuspendedAtYield) _fatal("unexpected yield");
    // If stream is cancelled, tell caller to exit the async generator.
    if (!controller.hasListener) {
      return true;
    }
    controller.add(event);
    scheduleGenerator();
    isSuspendedAtYield = true;
    return false;
  }

  /// Adds the elements of [stream] into this [controller]'s stream, and returns
  /// true if the caller should terminate execution of the generator.
  ///
  /// The generator will be scheduled again when all of the elements of the
  /// added stream have been consumed.
  bool addStream(Stream<T> stream) {
    if (!onListenReceived) _fatal("yield* before stream is listened to");
    // If stream is cancelled, tell caller to exit the async generator.
    if (!controller.hasListener) return true;
    isSuspendedAtYieldStar = true;
    var whenDoneAdding = controller.addStream(stream, cancelOnError: false);
    whenDoneAdding.then((_) {
      isSuspendedAtYieldStar = false;
      scheduleGenerator();
      if (!isScheduled) isSuspendedAtYield = true;
    }, onError: handleError);
    return false;
  }

  void addError(Object error, StackTrace stackTrace) {
    ArgumentError.checkNotNull(error, "error");
    var completer = cancellationCompleter;
    if (completer != null && !completer.isCompleted) {
      // If the stream has been cancelled, complete the cancellation future
      // with the error.
      completer.completeError(error, stackTrace);
    } else if (controller.hasListener) {
      controller.addError(error, stackTrace);
    }
    // No need to schedule the generator body here. This code is only
    // called from the catch clause of the implicit try-catch-finally
    // around the generator body. That is, we are on the error path out
    // of the generator and do not need to run the generator again.
    close();
  }

  void close() {
    var completer = cancellationCompleter;
    if (completer != null && !completer.isCompleted) {
      // If the stream has been cancelled, complete the cancellation future
      // with the error.
      completer.complete();
    }
    controller.close();
  }

  onListen() {
    assert(!onListenReceived);
    onListenReceived = true;
    scheduleGenerator();
  }

  onResume() {
    if (isSuspendedAtYield) {
      scheduleGenerator();
    }
  }

  onCancel() {
    if (controller.isClosed) {
      return null;
    }
    if (cancellationCompleter == null) {
      cancellationCompleter = Completer();
      // Only resume the generator if it is suspended at a yield.
      // Cancellation does not affect an async generator that is
      // suspended at an await.
      if (isSuspendedAtYield) {
        scheduleGenerator();
      }
    }
    return cancellationCompleter!.future;
  }

  _fatal(String message) => throw StateError(message);
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
/// Used as part of the runtime support for the async/await transformation. All
/// calls to this method are generated by the compiler.
Completer<T> _makeAsyncAwaitCompleter<T>() {
  return _AsyncAwaitCompleter<T>();
}

/// Initiates the computation of an `async` function and starts the body
/// synchronously.
///
/// Used as part of the runtime support for the async/await transformation. All
/// calls to this method are generated by the compiler.
///
/// This function sets up the first call into the transformed [bodyFunction].
/// Independently, it takes the [completer] and returns the future of the
/// completer for convenience of the transformed code.
Future _asyncStartSync(
  _WrappedAsyncBody bodyFunction,
  _AsyncAwaitCompleter completer,
) {
  bodyFunction(async_status_codes.SUCCESS, null);
  completer.isSync = true;
  return completer.future;
}

/// Performs the `await` operation of an `async` function.
///
/// Used as part of the runtime support for the async/await transformation. All
/// calls to this method are generated by the compiler.
///
/// Arranges for [bodyFunction] to be called when the future or value [object]
/// is completed with a code [async_status_codes.SUCCESS] or
/// [async_status_codes.ERROR] depending on the success of the future.
void _asyncAwait(
  Object? object,
  _WrappedAsyncBody bodyFunction,
  _AsyncAwaitCompleter completer,
) {
  _awaitOnObject(object, bodyFunction);
}

/// Completes the future of an `async` function.
///
/// Used as part of the runtime support for the async/await transformation. All
/// calls to this method are generated by the compiler.
///
/// This function is used when the `async` function returns (explicitly or
/// implicitly).
void _asyncReturn(Object? object, _AsyncAwaitCompleter completer) {
  completer.complete(object);
}

/// Completes the future of an `async` function with an error.
///
/// Used as part of the runtime support for the async/await transformation. All
/// calls to this method are generated by the compiler.
///
/// This function is used when the `async` function re-throws an exception.
void _asyncRethrow(Object? object, _AsyncAwaitCompleter completer) {
  // The error is a js-error.
  completer.completeError(dart.getThrown(object)!, dart.stackTrace(object));
}

/// Awaits on the given [object].
///
/// If the [object] is a Future, registers on it, otherwise wraps it into a
/// future first.
///
/// The [bodyFunction] argument is the continuation that should be invoked
/// when the future completes.
void _awaitOnObject(Object? object, _WrappedAsyncBody bodyFunction) {
  FutureOr<dynamic> Function(dynamic) thenCallback = (result) =>
      bodyFunction(async_status_codes.SUCCESS, result);

  Function errorCallback = (dynamic error, StackTrace stackTrace) {
    final wrappedException = dart.createErrorWithStack(error, stackTrace);
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

typedef _WrappedAsyncBody = void Function(int errorCode, Object? result);

/// Wraps a JS function generated by the compiler with boiler plate to handle
/// errors and re-entry logic.
///
/// Used as part of the runtime support for the async/await transformation. All
/// calls to this method are generated by the compiler.
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
    async_status_codes.ERROR,
  );

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
/// [bodyFunctionOrErrorCode] == [async_status_codes.SUCCESS], the
/// asyncStarHelper takes this as signal to close the stream.
///
/// When the async* function wants to signal that an uncaught error was thrown,
/// it calls this function with
/// [bodyFunctionOrErrorCode] == [async_status_codes.ERROR], the streamHelper
/// takes this as signal to addError [object] to the [controller] and close it.
///
/// If the async* function wants to do a yield or yield*, it calls this function
/// with [object] being an [_IterationMarker].
///
/// In the case of a yield or yield*, if the stream subscription has been
/// canceled, schedules [bodyFunctionOrErrorCode] to be called with
/// [async_status_codes.STREAM_WAS_CANCELED].
///
/// If [object] is a single-yield [_IterationMarker], adds the value of the
/// [_IterationMarker] to the stream. If the stream subscription has been
/// paused, return early. Otherwise schedule the helper function to be
/// executed again.
///
/// If [object] is a yield-star [_IterationMarker], starts listening to the
/// yielded stream, and adds all events and errors to our own controller (taking
/// care if the subscription has been paused or canceled) - when the sub-stream
/// is done, schedules [bodyFunctionOrErrorCode] again.
///
/// If the async* function wants to do an await it calls this function with
/// [object] not an [_IterationMarker].
///
/// If [object] is not a [Future], it is wrapped in a `Future.value`.
/// The [bodyFunctionOrErrorCode] is called on completion of the future
/// (see [_awaitOnObject]).
///
/// All calls to this method are generated by the compiler.
void _asyncStarHelper(
  Object? object,
  dynamic /* int | _WrappedAsyncBody */ bodyFunctionOrErrorCode,
  _AsyncStarStreamController controller,
) {
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
        dart.getThrown(object)!,
        dart.stackTrace(object),
      );
    } else {
      controller.addError(dart.getThrown(object)!, dart.stackTrace(object));
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
          null,
        );
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

/// Gets the stream out of an async controller.
///
/// Used as part of the runtime support for the async/await transformation. All
/// calls to this method are generated by the compiler.
Stream _streamOfController(_AsyncStarStreamController controller) {
  return controller.stream;
}

/// A wrapper around a [StreamController] that keeps track of the state of
/// the execution of an async* function.
///
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
  ///
  /// When true execution will only resume after a `onResume` or `onCancel`
  /// event.
  bool isSuspended = false;

  bool get isPaused => controller.isPaused;

  _Future? cancelationFuture = null;

  /// True after the StreamSubscription has been cancelled.
  ///
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

    controller = StreamController<T>(
      onListen: () {
        _resumeBody();
      },
      onResume: () {
        // Only schedule again if the async* function actually is suspended.
        // Resume directly instead of scheduling, so that the sequence
        // `pause-resume-pause` will result in one extra event produced.
        if (isSuspended) {
          isSuspended = false;
          _resumeBody();
        }
      },
      onCancel: () {
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
      },
    );
  }
}

/// Creates a stream controller for an `async*` function.
///
/// Used as part of the runtime support for the async/await transformation.
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

  static yieldStar(Object /* Iterable or Stream */ values) {
    return _IterationMarker._(YIELD_STAR, values);
  }

  static endOfIteration() {
    return const _IterationMarker._(ITERATION_ENDED, null);
  }

  static yieldSingle(Object value) {
    return _IterationMarker._(YIELD_SINGLE, value);
  }

  static uncaughtError(Object error) {
    return _IterationMarker._(UNCAUGHT_ERROR, error);
  }

  toString() => "IterationMarker($state, $value)";
}

/// _SyncStarIterator handles stepping a sync* generator body state machine.
///
/// It also handles the stepping over 'nested' iterators to flatten yield*
/// statements. For non-sync* iterators, [_nestedIterator] contains the
/// iterator. We delegate to [_nestedIterator] when it is not `null`.
///
/// For nested sync* iterators, this [Iterator] acts on behalf of the innermost
/// nested sync* iterator. The current state machine is suspended on a stack
/// until the inner state machine ends.
class _SyncStarIterator<T> implements Iterator<T> {
  /// The state machine for the innermost _SyncStarIterator.
  Object? _body;

  /// The current value, unless iterating a non-sync* nested iterator.
  T? _current = null;

  /// Value passed back from state machine for uncaught exceptions.
  Object? _datum;

  /// This is the nested iterator when iterating a yield* of a non-sync iterator.
  Iterator<T>? _nestedIterator = null;

  /// Stack of suspended state machines when iterating a yield* of a sync*
  /// iterator.
  List? _suspendedBodies = null;

  _SyncStarIterator(this._body);

  T get current {
    return _current as T;
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
          errorValue = error;
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
  }

  static _terminatedBody(_1, _2, _3) => async_status_codes.SYNC_STAR_DONE;

  // Called from generated code.
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
}

/// Creates an Iterable for a `sync*` function.
///
/// Used as part of the runtime support for the async/await transformation.
_SyncStarIterable<T> _makeSyncStarIterable<T>(body) {
  return _SyncStarIterable<T>(body);
}

/// An Iterable corresponding to a sync* method.
///
/// Each invocation of a sync* method will return a new instance of this class.
class _SyncStarIterable<T> extends Iterable<T> {
  /// This is a function that will return a helper function that does the
  /// iteration of the sync*.
  ///
  /// Each invocation should give a body with fresh state.
  final dynamic /* js function */ _outerHelper;

  _SyncStarIterable(this._outerHelper);

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
Future<T> _wrapAwaitedExpression<T>(Object? e) =>
    e is Future<T> ? e : _Future<T>.value(unsafeCast<T>(e));
