// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:async" which contains all the imports used
/// by patches of that library. We plan to change this when we have a shared
/// front end and simply use parts.

import "dart:_internal" show VMLibraryHooks, patch, unsafeCast;

/// These are the additional parts of this patch library:
part "schedule_microtask_patch.dart";
part "timer_patch.dart";

// Equivalent of calling FATAL from C++ code.
@pragma("vm:external-name", "DartAsync_fatal")
external _fatal(msg);

// This function is used when lowering `await for` statements.
void _asyncStarMoveNextHelper(var stream) {
  if (stream is! _StreamImpl) {
    return;
  }
  // stream is a _StreamImpl.
  final generator = stream._generator;
  if (generator == null) {
    // No generator registered, this isn't an async* Stream.
    return;
  }
  _moveNextDebuggerStepCheck(generator);
}

// _AsyncStarStreamController is used by the compiler to implement
// async* generator functions.
@pragma("vm:entry-point")
class _AsyncStarStreamController<T> {
  @pragma("vm:entry-point")
  StreamController<T> controller;
  @pragma("vm:entry-point")
  void Function(Object?)? asyncStarBody;
  bool isAdding = false;
  bool onListenReceived = false;
  bool isScheduled = false;
  bool isSuspendedAtYield = false;
  _Future? cancellationFuture = null;

  Stream<T> get stream {
    final Stream<T> local = controller.stream;
    if (local is _StreamImpl<T>) {
      local._generator = asyncStarBody!;
    }
    return local;
  }

  void runBody() {
    isScheduled = false;
    isSuspendedAtYield = false;
    asyncStarBody!(!controller.hasListener);
  }

  void scheduleGenerator() {
    if (isScheduled || controller.isPaused || isAdding) {
      return;
    }
    isScheduled = true;
    scheduleMicrotask(runBody);
  }

  // Adds element to stream.
  // Returns true if the caller should terminate execution of the generator.
  @pragma("vm:entry-point", "call")
  bool add(T event) {
    if (!onListenReceived) _fatal("yield before stream is listened to");
    if (isSuspendedAtYield) _fatal("unexpected yield");
    controller.add(event);
    if (!controller.hasListener) {
      return true;
    }

    scheduleGenerator();
    isSuspendedAtYield = true;
    return false;
  }

  // Adds the elements of stream into this controller's stream.
  // The generator will be scheduled again when all of the
  // elements of the added stream have been consumed.
  // Returns true if the caller should terminate execution of the generator.
  @pragma("vm:entry-point", "call")
  bool addStream(Stream<T> stream) {
    if (!onListenReceived) _fatal("yield before stream is listened to");
    if (!controller.hasListener) {
      return true;
    }

    isAdding = true;
    final whenDoneAdding = controller.addStream(stream, cancelOnError: false);
    @pragma('vm:awaiter-link')
    final self = this;
    whenDoneAdding.then((_) {
      self.isAdding = false;
      self.scheduleGenerator();
      if (!self.isScheduled) self.isSuspendedAtYield = true;
    });

    return false;
  }

  void addError(Object error, StackTrace stackTrace) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(error, "error");
    final future = cancellationFuture;
    if ((future != null) && future._mayComplete) {
      // If the stream has been cancelled, complete the cancellation future
      // with the error.
      future._completeError(error, stackTrace);
      return;
    }
    // If stream is cancelled, tell caller to exit the async generator.
    if (!controller.hasListener) return;
    controller.addError(error, stackTrace);
    // No need to schedule the generator body here. This code is only
    // called from the catch clause of the implicit try-catch-finally
    // around the generator body. That is, we are on the error path out
    // of the generator and do not need to run the generator again.
  }

  close() {
    final future = cancellationFuture;
    if ((future != null) && future._mayComplete) {
      // If the stream has been cancelled, complete the cancellation future
      // with the error.
      future._completeWithValue(null);
    }
    controller.close();
  }

  _AsyncStarStreamController() : controller = new StreamController(sync: true) {
    controller.onListen = this.onListen;
    controller.onResume = this.onResume;
    controller.onCancel = this.onCancel;
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
    if (cancellationFuture == null) {
      cancellationFuture = new _Future();
      // Only resume the generator if it is suspended at a yield.
      // Cancellation does not affect an async generator that is
      // suspended at an await.
      if (isSuspendedAtYield) {
        scheduleGenerator();
      }
    }
    return cancellationFuture;
  }
}

@patch
class _StreamImpl<T> {
  /// The closure implementing the async-generator body that is creating events
  /// for this stream.
  Function? _generator;
}

@pragma("vm:external-name", "AsyncStarMoveNext_debuggerStepCheck")
external void _moveNextDebuggerStepCheck(Function async_op);

@pragma("vm:entry-point")
class _SuspendState {
  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  static Object? _initAsync<T>() {
    return _Future<T>();
  }

  @pragma("vm:invisible")
  void _createAsyncCallbacks() {
    @pragma('vm:awaiter-link')
    final suspendState = this;

    @pragma("vm:invisible")
    thenCallback(value) {
      suspendState._resume(value, null, null);
    }

    @pragma("vm:invisible")
    errorCallback(Object exception, StackTrace stackTrace) {
      suspendState._resume(null, exception, stackTrace);
    }

    final currentZone = Zone._current;
    if (identical(currentZone, _rootZone) ||
        identical(currentZone._registerUnaryCallback,
            _rootZone._registerUnaryCallback)) {
      _thenCallback = thenCallback;
    } else {
      _thenCallback =
          currentZone.registerUnaryCallback<dynamic, dynamic>(thenCallback);
    }
    if (identical(currentZone, _rootZone) ||
        identical(currentZone._registerBinaryCallback,
            _rootZone._registerBinaryCallback)) {
      _errorCallback = errorCallback;
    } else {
      _errorCallback = currentZone
          .registerBinaryCallback<dynamic, Object, StackTrace>(errorCallback);
    }
  }

  @pragma("vm:invisible")
  @pragma("vm:prefer-inline")
  void _awaitCompletedFuture(_Future future) {
    assert(future._isComplete);
    final zone = Zone._current;
    if (future._hasError) {
      @pragma("vm:invisible")
      void run() {
        final AsyncError asyncError =
            unsafeCast<AsyncError>(future._resultOrListeners);
        if (!future._zone.inSameErrorZone(zone)) {
          // Don't cross zone boundaries with errors.
          future._zone
              .handleUncaughtError(asyncError.error, asyncError.stackTrace);
        } else {
          zone.runBinary(
              unsafeCast<dynamic Function(Object, StackTrace)>(_errorCallback),
              asyncError.error,
              asyncError.stackTrace);
        }
      }

      future._zone.scheduleMicrotask(run);
    } else {
      @pragma("vm:invisible")
      void run() {
        zone.runUnary(unsafeCast<dynamic Function(dynamic)>(_thenCallback),
            future._resultOrListeners);
      }

      future._zone.scheduleMicrotask(run);
    }
  }

  @pragma("vm:invisible")
  @pragma("vm:prefer-inline")
  void _awaitNotFuture(Object? object) {
    final zone = Zone._current;
    @pragma("vm:invisible")
    void run() {
      zone.runUnary(
          unsafeCast<dynamic Function(dynamic)>(_thenCallback), object);
    }

    zone.scheduleMicrotask(run);
  }

  @pragma("vm:invisible")
  @pragma("vm:prefer-inline")
  void _awaitUserDefinedFuture(Future future) {
    // Create a generic callback closure and instantiate it
    // using the type argument of Future.
    // This is needed to avoid unsoundness which may happen if user-defined
    // Future.then casts callback to Function(dynamic) passes a value of
    // incorrect type.
    @pragma("vm:invisible")
    dynamic typedCallback<T>(T value) {
      return unsafeCast<dynamic Function(dynamic)>(_thenCallback)(value);
    }

    future.then(
        unsafeCast<dynamic Function(dynamic)>(
            _instantiateClosureWithFutureTypeArgument(typedCallback, future)),
        onError:
            unsafeCast<dynamic Function(Object, StackTrace)>(_errorCallback));
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  Object? _await(Object? object) {
    if (_thenCallback == null) {
      _createAsyncCallbacks();
    }
    if (object is _Future) {
      if (object._isComplete) {
        _awaitCompletedFuture(object);
      } else {
        object._thenAwait<dynamic>(
            unsafeCast<dynamic Function(dynamic)>(_thenCallback),
            unsafeCast<dynamic Function(Object, StackTrace)>(_errorCallback));
      }
    } else if (object is! Future) {
      _awaitNotFuture(object);
    } else {
      _awaitUserDefinedFuture(object);
    }
    return _functionData;
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  Object? _awaitWithTypeCheck<T>(Object? object) {
    if (_thenCallback == null) {
      _createAsyncCallbacks();
    }
    // Declare a new variable to avoid type promotion of 'object' to
    // 'Future<T>', as it would disable further type promotion to '_Future'.
    final obj = object;
    if (obj is Future<T>) {
      if (object is _Future) {
        if (object._isComplete) {
          _awaitCompletedFuture(object);
        } else {
          object._thenAwait<dynamic>(
              unsafeCast<dynamic Function(dynamic)>(_thenCallback),
              unsafeCast<dynamic Function(Object, StackTrace)>(_errorCallback));
        }
      } else {
        _awaitUserDefinedFuture(obj);
      }
    } else {
      _awaitNotFuture(object);
    }
    return _functionData;
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  static Future _returnAsync(Object suspendState, Object? returnValue) {
    _Future future;
    if (suspendState is _SuspendState) {
      future = unsafeCast<_Future>(suspendState._functionData);
    } else {
      future = unsafeCast<_Future>(suspendState);
    }
    if (returnValue is Future) {
      future._asyncCompleteUnchecked(returnValue);
    } else {
      future._completeWithValue(returnValue);
    }
    return future;
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  static Future _returnAsyncNotFuture(
      Object suspendState, Object? returnValue) {
    _Future future;
    if (suspendState is _SuspendState) {
      future = unsafeCast<_Future>(suspendState._functionData);
    } else {
      future = unsafeCast<_Future>(suspendState);
    }
    future._completeWithValue(returnValue);
    return future;
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  static Object? _initAsyncStar<T>() {
    return _AsyncStarStreamController<T>();
  }

  @pragma("vm:invisible")
  _createAsyncStarCallback(_AsyncStarStreamController controller) {
    @pragma('vm:awaiter-link')
    final suspendState = this;

    controller.asyncStarBody = (value) {
      suspendState._resume(value, null, null);
    };
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  Object? _yieldAsyncStar(Object? object) {
    final controller = unsafeCast<_AsyncStarStreamController>(_functionData);
    if (controller.asyncStarBody == null) {
      _createAsyncStarCallback(controller);
      return controller.stream;
    }
    return null;
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  static void _returnAsyncStar(Object suspendState, Object? returnValue) {
    final controller = unsafeCast<_AsyncStarStreamController>(
        unsafeCast<_SuspendState>(suspendState)._functionData);
    controller.close();
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  static Object? _handleException(
      Object suspendState, Object exception, StackTrace stackTrace) {
    Object? functionData;
    bool isSync = true;
    if (suspendState is _SuspendState) {
      functionData = suspendState._functionData;
    } else {
      functionData = suspendState;
      isSync = false;
    }
    if (functionData is _Future) {
      // async function.
      if (!isSync) {
        functionData._asyncCompleteError(exception, stackTrace);
      } else {
        functionData._completeError(exception, stackTrace);
      }
    } else if (functionData is _AsyncStarStreamController) {
      // async* function.
      functionData.addError(exception, stackTrace);
      functionData.close();
    } else {
      throw 'Unexpected function data ${functionData.runtimeType} $functionData';
    }
    return functionData;
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  static Object? _initSyncStar<T>() {
    return _SyncStarIterable<T>();
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  Object? _suspendSyncStarAtStart(Object? object) {
    final data = _functionData;
    unsafeCast<_SyncStarIterable>(data)._stateAtStart = this;
    return data;
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external set _functionData(Object value);

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external Object get _functionData;

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external set _thenCallback(void Function(dynamic)? value);

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external void Function(dynamic)? get _thenCallback;

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external set _errorCallback(dynamic Function(Object, StackTrace)? value);

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external dynamic Function(Object, StackTrace)? get _errorCallback;

  @pragma("vm:recognized", "other")
  @pragma("vm:never-inline")
  external Object? _resume(
      Object? value, Object? exception, StackTrace? stackTrace);

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external _SuspendState _clone();

  @pragma("vm:external-name",
      "SuspendState_instantiateClosureWithFutureTypeArgument")
  external static Function _instantiateClosureWithFutureTypeArgument(
      dynamic Function<T>(T) closure, Future future);
}

class _SyncStarIterable<T> extends Iterable<T> {
  _SuspendState? _stateAtStart;

  _SyncStarIterable();

  Iterator<T> get iterator {
    return _SyncStarIterator<T>(_stateAtStart!._clone());
  }
}

class _SyncStarIterator<T> implements Iterator<T> {
  _SuspendState? _state;
  Iterator<T>? _yieldStarIterator;

  // Stack of suspended sync* methods.
  List<_SuspendState>? _stack;

  // sync* method sets either _yieldStarIterable
  // or _current before suspending.
  @pragma("vm:entry-point")
  T? _current;
  @pragma("vm:entry-point")
  Iterable<T>? _yieldStarIterable;

  @override
  T get current => _current as T;

  _SyncStarIterator(_SuspendState state) : _state = state {
    state._functionData = this;
  }

  @pragma('vm:prefer-inline')
  bool _handleSyncStarMethodCompletion() {
    _current = null;
    _state = null;
    final stack = _stack;
    if (stack != null && stack.isNotEmpty) {
      _state = stack.removeLast();
      return true;
    }
    return false;
  }

  @override
  bool moveNext() {
    if (_state == null) {
      return false;
    }

    Object? pendingException;
    StackTrace? pendingStackTrace;
    while (true) {
      // First delegate to an active nested iterator (if any).
      final iterator = _yieldStarIterator;
      if (iterator != null) {
        try {
          if (iterator.moveNext()) {
            _current = iterator.current;
            return true;
          }
        } catch (exception, stackTrace) {
          pendingException = exception;
          pendingStackTrace = stackTrace;
        }
        _yieldStarIterator = null;
      }

      try {
        // Resume current sync* method in order to move to the next value.
        final bool hasMore = unsafeCast<bool>(unsafeCast<_SuspendState>(_state)
            ._resume(null, pendingException, pendingStackTrace));
        pendingException = null;
        pendingStackTrace = null;
        if (!hasMore) {
          if (_handleSyncStarMethodCompletion()) {
            continue;
          }
          return false;
        }
      } catch (exception, stackTrace) {
        pendingException = exception;
        pendingStackTrace = stackTrace;
        if (_handleSyncStarMethodCompletion()) {
          continue;
        }
        rethrow;
      }

      // Case: yield* some_iterator.
      final iterable = _yieldStarIterable;
      if (iterable != null) {
        _yieldStarIterable = null;
        _current = null;
        if (iterable is _SyncStarIterable) {
          // We got a recursive yield* of sync* function. Instead of creating
          // a new iterator we replace our current _state (remembering the
          // current _state for later resumption).
          final stack = (_stack ??= []);
          stack.add(_state!);
          final nestedState =
              unsafeCast<_SyncStarIterable>(iterable)._stateAtStart!._clone();
          nestedState._functionData = this;
          _state = nestedState;
        } else {
          try {
            _yieldStarIterator = iterable.iterator;
          } catch (exception, stackTrace) {
            pendingException = exception;
            pendingStackTrace = stackTrace;
          }
        }
        // Fetch the next item or continue with exception.
        continue;
      }

      return true;
    }
  }
}
