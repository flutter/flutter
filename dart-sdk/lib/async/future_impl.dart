// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

abstract class _Completer<T> implements Completer<T> {
  @pragma("wasm:entry-point")
  @pragma("vm:entry-point")
  final _Future<T> future = new _Future<T>();

  // Overridden by either a synchronous or asynchronous implementation.
  void complete([FutureOr<T>? value]);

  @pragma("wasm:entry-point")
  void completeError(Object error, [StackTrace? stackTrace]) {
    // TODO(40614): Remove once non-nullability is sound.
    checkNotNullable(error, "error");
    if (!future._mayComplete) throw new StateError("Future already completed");
    AsyncError? replacement = Zone.current.errorCallback(error, stackTrace);
    if (replacement != null) {
      error = replacement.error;
      stackTrace = replacement.stackTrace;
    } else {
      stackTrace ??= AsyncError.defaultStackTrace(error);
    }
    _completeError(error, stackTrace);
  }

  // Overridden by either a synchronous or asynchronous implementation.
  void _completeError(Object error, StackTrace stackTrace);

  // The future's _isComplete doesn't take into account pending completions.
  // We therefore use _mayComplete.
  bool get isCompleted => !future._mayComplete;
}

/// Completer which completes future asynchronously.
@pragma("vm:entry-point")
class _AsyncCompleter<T> extends _Completer<T> {
  @pragma("wasm:entry-point")
  void complete([FutureOr<T>? value]) {
    if (!future._mayComplete) throw new StateError("Future already completed");
    future._asyncComplete(value == null ? value as dynamic : value);
  }

  void _completeError(Object error, StackTrace stackTrace) {
    future._asyncCompleteError(error, stackTrace);
  }
}

/// Completer which completes future synchronously.
///
/// Created by [Completer.sync]. Use with caution.
@pragma("vm:entry-point")
class _SyncCompleter<T> extends _Completer<T> {
  void complete([FutureOr<T>? value]) {
    if (!future._mayComplete) throw new StateError("Future already completed");
    future._complete(value == null ? value as dynamic : value);
  }

  void _completeError(Object error, StackTrace stackTrace) {
    future._completeError(error, stackTrace);
  }
}

class _FutureListener<S, T> {
  // Keep in sync with sdk/runtime/vm/stack_trace.cc.
  static const int maskValue = 1 << 0;
  static const int maskError = 1 << 1;
  static const int maskTestError = 1 << 2;
  static const int maskWhenComplete = 1 << 3;
  static const int maskAwait = 1 << 4;
  static const int stateChain = 0;
  // Handles values, passes errors on.
  static const int stateThen = maskValue;
  // Handles values and errors.
  static const int stateThenOnerror = maskValue | maskError;
  // Handles values and error. Created by the implementation of `await`.
  static const int stateThenAwait = stateThenOnerror | maskAwait;
  // Handles errors, has errorCallback.
  static const int stateCatchError = maskError;
  // Ignores both values and errors. Has no callback or errorCallback.
  // The [result] future is ignored, its always the same as the source.
  static const int stateCatchErrorTest = maskError | maskTestError;
  static const int stateWhenComplete = maskWhenComplete;
  static const int maskType =
      maskValue | maskError | maskTestError | maskWhenComplete;

  // Listeners on the same future are linked through this link.
  @pragma("vm:entry-point")
  _FutureListener? _nextListener;

  // The future to complete when this listener is activated.
  @pragma("vm:entry-point")
  final _Future<T> result;

  // Which fields means what.
  @pragma("vm:entry-point")
  final int state;

  // Used for then/whenDone callback and error test
  @pragma("vm:entry-point")
  final Function? callback;

  // Used for error callbacks.
  final Function? errorCallback;

  _FutureListener.then(
      this.result, FutureOr<T> Function(S) onValue, Function? errorCallback)
      : callback = onValue,
        errorCallback = errorCallback,
        state = (errorCallback == null) ? stateThen : stateThenOnerror;

  _FutureListener.thenAwait(
      this.result, FutureOr<T> Function(S) onValue, Function errorCallback)
      : callback = onValue,
        errorCallback = errorCallback,
        state = stateThenAwait;

  _FutureListener.catchError(this.result, this.errorCallback, this.callback)
      : state = (callback == null) ? stateCatchError : stateCatchErrorTest;

  _FutureListener.whenComplete(this.result, this.callback)
      : errorCallback = null,
        state = stateWhenComplete;

  _Zone get _zone => result._zone;

  bool get handlesValue => (state & maskValue != 0);
  bool get handlesError => (state & maskError != 0);
  bool get hasErrorTest => (state & maskType == stateCatchErrorTest);
  bool get handlesComplete => (state & maskType == stateWhenComplete);

  FutureOr<T> Function(S) get _onValue {
    assert(handlesValue);
    return unsafeCast<FutureOr<T> Function(S)>(callback);
  }

  Function? get _onError => errorCallback;

  bool Function(Object) get _errorTest {
    assert(hasErrorTest);
    return unsafeCast<bool Function(Object)>(callback);
  }

  dynamic Function() get _whenCompleteAction {
    assert(handlesComplete);
    return unsafeCast<dynamic Function()>(callback);
  }

  /// Whether this listener has an error callback.
  ///
  /// This function must only be called if the listener [handlesError].
  bool get hasErrorCallback {
    assert(handlesError);
    return _onError != null;
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:never-inline")
  FutureOr<T> handleValue(S sourceResult) {
    return _zone.runUnary<FutureOr<T>, S>(_onValue, sourceResult);
  }

  bool matchesErrorTest(AsyncError asyncError) {
    if (!hasErrorTest) return true;
    return _zone.runUnary<bool, Object>(_errorTest, asyncError.error);
  }

  FutureOr<T> handleError(AsyncError asyncError) {
    assert(handlesError && hasErrorCallback);
    var errorCallback = this.errorCallback; // To enable promotion.
    // If the errorCallback returns something which is not a FutureOr<T>,
    // this return statement throws, and the caller handles the error.
    dynamic result;
    if (errorCallback is dynamic Function(Object, StackTrace)) {
      result = _zone.runBinary<dynamic, Object, StackTrace>(
          errorCallback, asyncError.error, asyncError.stackTrace);
    } else {
      result = _zone.runUnary<dynamic, Object>(
          errorCallback as dynamic, asyncError.error);
    }
    // Give better error messages if the result is not a valid
    // FutureOr<T>.
    try {
      return result;
    } on TypeError {
      if (handlesValue) {
        // This is a `.then` callback with an `onError`.
        throw ArgumentError(
            "The error handler of Future.then"
                " must return a value of the returned future's type",
            "onError");
      }
      // This is a `catchError` callback.
      throw ArgumentError(
          "The error handler of "
              "Future.catchError must return a value of the future's type",
          "onError");
    }
  }

  dynamic handleWhenComplete() {
    assert(!handlesError);
    return _zone.run(_whenCompleteAction);
  }

  // Whether the [value] future should be awaited and the [future] completed
  // with its result, rather than just completing the [future] directly
  // with the [value].
  bool shouldChain(Future<dynamic> value) => value is Future<T> || value is! T;
}

@pragma("wasm:entry-point")
class _Future<T> implements Future<T> {
  /// Initial state, waiting for a result. In this state, the
  /// [_resultOrListeners] field holds a single-linked list of
  /// [_FutureListener] listeners.
  static const int _stateIncomplete = 0;

  /// Flag set when an error need not be handled.
  ///
  /// Set by the [FutureExtensions.ignore] method to avoid
  /// having to introduce an unnecessary listener.
  /// Only relevant until the future is completed.
  ///
  /// When changing update runtime/vm/stack_trace.cc
  static const int _stateIgnoreError = 1;

  /// Pending completion. Set when completed using [_asyncComplete] or
  /// [_asyncCompleteError]. It is an error to try to complete it again.
  /// [_resultOrListeners] holds listeners.
  static const int _statePendingComplete = 2;

  /// The future has been chained to another "source" [_Future].
  ///
  /// The result of that other future becomes the result of this future
  /// as well, when the other future completes.
  /// This future cannot be completed again.
  /// [_resultOrListeners] contains the source future.
  /// Listeners have been moved to the chained future.
  static const int _stateChained = 4;

  /// The future has been completed with a value result.
  ///
  /// [_resultOrListeners] contains the value.
  static const int _stateValue = 8;

  /// The future has been completed with an error result.
  ///
  /// [_resultOrListeners] contains an [AsyncError]
  /// holding the error and stack trace.
  static const int _stateError = 16;

  /// Mask for the states above except [_stateIgnoreError].
  static const int _completionStateMask = 30;

  /// Whether the future is complete, and as what.
  @pragma('vm:entry-point')
  int _state = _stateIncomplete;

  /// Zone that the future was completed from.
  /// This is the zone that an error result belongs to.
  ///
  /// Until the future is completed, the field may hold the zone that
  /// listener callbacks used to create this future should be run in.
  final _Zone _zone;

  /// Either the result, a list of listeners or another future.
  ///
  /// The result of the future is either a value or an error.
  /// A result is only stored when the future has completed.
  ///
  /// The listeners is an internally linked list of [_FutureListener]s.
  /// Listeners are only remembered while the future is not yet complete,
  /// and it is not chained to another future.
  ///
  /// The future is another future that this future is chained to. This future
  /// is waiting for the other future to complete, and when it does,
  /// this future will complete with the same result.
  /// All listeners are forwarded to the other future.
  @pragma("vm:entry-point")
  var _resultOrListeners;

  // This constructor is used by async/await.
  _Future() : _zone = Zone._current;

  // Constructor used by [Future.value].
  _Future.immediate(FutureOr<T> result) : _zone = Zone._current {
    _asyncComplete(result);
  }

  /// Creates a future with the value and the specified zone.
  _Future.zoneValue(T value, this._zone) {
    _setValue(value);
  }

  _Future.immediateError(var error, StackTrace stackTrace)
      : _zone = Zone._current {
    _asyncCompleteError(error, stackTrace);
  }

  /// Creates a future that is already completed with the value.
  _Future.value(T value) : this.zoneValue(value, Zone._current);

  bool get _mayComplete => (_state & _completionStateMask) == _stateIncomplete;
  bool get _isPendingComplete => (_state & _statePendingComplete) != 0;
  bool get _mayAddListener =>
      _state <= (_statePendingComplete | _stateIgnoreError);
  bool get _isChained => (_state & _stateChained) != 0;
  bool get _isComplete => (_state & (_stateValue | _stateError)) != 0;
  bool get _hasError => (_state & _stateError) != 0;
  bool get _ignoreError => (_state & _stateIgnoreError) != 0;

  void _setChained(_Future source) {
    assert(_mayAddListener);
    _state = _stateChained | (_state & _stateIgnoreError);
    _resultOrListeners = source;
  }

  Future<R> then<R>(FutureOr<R> f(T value), {Function? onError}) {
    Zone currentZone = Zone.current;
    if (identical(currentZone, _rootZone)) {
      if (onError != null &&
          onError is! Function(Object, StackTrace) &&
          onError is! Function(Object)) {
        throw ArgumentError.value(
            onError,
            "onError",
            "Error handler must accept one Object or one Object and a StackTrace"
                " as arguments, and return a value of the returned future's type");
      }
    } else {
      f = currentZone.registerUnaryCallback<FutureOr<R>, T>(f);
      if (onError != null) {
        // This call also checks that onError is assignable to one of:
        //   dynamic Function(Object)
        //   dynamic Function(Object, StackTrace)
        onError = _registerErrorHandler(onError, currentZone);
      }
    }
    _Future<R> result = new _Future<R>();
    _addListener(new _FutureListener<T, R>.then(result, f, onError));
    return result;
  }

  /// Registers a system created result and error continuation.
  ///
  /// Used by the implementation of `await` to listen to a future.
  /// The system created listeners are not registered in the zone.
  Future<E> _thenAwait<E>(FutureOr<E> f(T value), Function onError) {
    _Future<E> result = new _Future<E>();
    _addListener(new _FutureListener<T, E>.thenAwait(result, f, onError));
    return result;
  }

  void _ignore() {
    _Future<Object?> source = this;
    while (source._isChained) {
      source = source._chainSource;
    }
    source._state |= _stateIgnoreError;
  }

  Future<T> catchError(Function onError, {bool test(Object error)?}) {
    _Future<T> result = new _Future<T>();
    if (!identical(result._zone, _rootZone)) {
      onError = _registerErrorHandler(onError, result._zone);
      if (test != null) test = result._zone.registerUnaryCallback(test);
    }
    _addListener(new _FutureListener<T, T>.catchError(result, onError, test));
    return result;
  }

  // Used by extension method `onError` to up-cast the result to `R`.
  //
  // Not public because we cannot statically ensure that [R] is a supertype
  // of [T].
  //
  // Avoids needing to allocate an extra value handler to do the up cast,
  // which is needed if using `.then`.
  Future<R> _safeOnError<R>(FutureOr<R> Function(Object, StackTrace) onError) {
    assert(this is _Future<R>); // Is up-cast.
    _Future<R> result = _Future<R>();
    if (!identical(result._zone, _rootZone)) {
      onError = result._zone.registerBinaryCallback(onError);
    }
    _addListener(_FutureListener<T, R>.catchError(result, onError, null));
    return result;
  }

  Future<T> whenComplete(dynamic action()) {
    _Future<T> result = new _Future<T>();
    if (!identical(result._zone, _rootZone)) {
      action = result._zone.registerCallback<dynamic>(action);
    }
    _addListener(new _FutureListener<T, T>.whenComplete(result, action));
    return result;
  }

  Stream<T> asStream() => new Stream<T>.fromFuture(this);

  void _setPendingComplete() {
    assert(_mayComplete); // Aka. _stateIncomplete
    _state ^= _stateIncomplete ^ _statePendingComplete;
  }

  void _clearPendingComplete() {
    assert(_isPendingComplete);
    _state ^= _statePendingComplete ^ _stateIncomplete;
  }

  AsyncError get _error {
    assert(_hasError);
    return _resultOrListeners;
  }

  _Future get _chainSource {
    assert(_isChained);
    return _resultOrListeners;
  }

  // This method is used by async/await.
  void _setValue(T value) {
    assert(!_isComplete); // But may have a completion pending.
    _state = _stateValue;
    _resultOrListeners = value;
  }

  void _setErrorObject(AsyncError error) {
    assert(!_isComplete); // But may have a completion pending.
    _state = _stateError | (_state & _stateIgnoreError);
    _resultOrListeners = error;
  }

  void _setError(Object error, StackTrace stackTrace) {
    _setErrorObject(new AsyncError(error, stackTrace));
  }

  /// Copy the completion result of [source] into this future.
  ///
  /// Used when a chained future notices that its source is completed.
  void _cloneResult(_Future source) {
    assert(!_isComplete);
    assert(source._isComplete);
    _state =
        (source._state & _completionStateMask) | (_state & _stateIgnoreError);
    _resultOrListeners = source._resultOrListeners;
  }

  void _addListener(_FutureListener listener) {
    assert(listener._nextListener == null);
    if (_mayAddListener) {
      listener._nextListener = _resultOrListeners;
      _resultOrListeners = listener;
    } else {
      if (_isChained) {
        // Delegate listeners to chained source future.
        // If the source is complete, instead copy its values and
        // drop the chaining.
        _Future source = _chainSource;
        if (!source._isComplete) {
          source._addListener(listener);
          return;
        }
        _cloneResult(source);
      }
      assert(_isComplete);
      // Handle late listeners asynchronously.
      _zone.scheduleMicrotask(() {
        _propagateToListeners(this, listener);
      });
    }
  }

  void _prependListeners(_FutureListener? listeners) {
    if (listeners == null) return;
    if (_mayAddListener) {
      _FutureListener? existingListeners = _resultOrListeners;
      _resultOrListeners = listeners;
      if (existingListeners != null) {
        _FutureListener cursor = listeners;
        _FutureListener? next = cursor._nextListener;
        while (next != null) {
          cursor = next;
          next = cursor._nextListener;
        }
        cursor._nextListener = existingListeners;
      }
    } else {
      if (_isChained) {
        // Delegate listeners to chained source future.
        // If the source is complete, instead copy its values and
        // drop the chaining.
        _Future source = _chainSource;
        if (!source._isComplete) {
          source._prependListeners(listeners);
          return;
        }
        _cloneResult(source);
      }
      assert(_isComplete);
      listeners = _reverseListeners(listeners);
      _zone.scheduleMicrotask(() {
        _propagateToListeners(this, listeners);
      });
    }
  }

  _FutureListener? _removeListeners() {
    // Reverse listeners before returning them, so the resulting list is in
    // subscription order.
    assert(!_isComplete);
    _FutureListener? current = _resultOrListeners;
    _resultOrListeners = null;
    return _reverseListeners(current);
  }

  _FutureListener? _reverseListeners(_FutureListener? listeners) {
    _FutureListener? prev = null;
    _FutureListener? current = listeners;
    while (current != null) {
      _FutureListener? next = current._nextListener;
      current._nextListener = prev;
      prev = current;
      current = next;
    }
    return prev;
  }

  /// Completes this future with the result of [source].
  ///
  /// The [source] future should not be a [_Future], use
  /// [_chainCoreFutureSync] for those.
  ///
  /// Since [source] is an unknown [Future], it's interacted with
  /// through [Future.then], which is required to be asynchronous.
  void _chainForeignFuture(Future source) {
    assert(!_isComplete);
    assert(source is! _Future);

    // Mark the target as chained (and as such half-completed).
    _setPendingComplete();
    try {
      source.then((value) {
        assert(_isPendingComplete);
        _clearPendingComplete(); // Clear this first, it's set again.
        try {
          _completeWithValue(value as T);
        } catch (error, stackTrace) {
          _completeError(error, stackTrace);
        }
      }, onError: (Object error, StackTrace stackTrace) {
        assert(_isPendingComplete);
        _completeError(error, stackTrace);
      });
    } catch (e, s) {
      // This only happens if the `then` call threw synchronously when given
      // valid arguments.
      // That requires a non-conforming implementation of the Future interface,
      // which should, hopefully, never happen.
      scheduleMicrotask(() {
        _completeError(e, s);
      });
    }
  }

  /// Synchronously completes a target future with another, source, future.
  ///
  /// If the source future is already completed, its result is synchronously
  /// propagated to the target future's listeners.
  /// If the source future is not completed, the target future is made
  /// to listen for its completion.
  static void _chainCoreFutureSync(_Future source, _Future target) {
    assert(target._mayAddListener); // Not completed, not already chained.
    while (source._isChained) {
      source = source._chainSource;
    }
    if (identical(source, target)) {
      target._asyncCompleteError(
          ArgumentError.value(
              source, null, "Cannot complete a future with itself"),
          StackTrace.current);
      return;
    }
    source._state |= target._state & _stateIgnoreError;
    if (source._isComplete) {
      _FutureListener? listeners = target._removeListeners();
      target._cloneResult(source);
      _propagateToListeners(target, listeners);
    } else {
      _FutureListener? listeners = target._resultOrListeners;
      target._setChained(source);
      source._prependListeners(listeners);
    }
  }

  /// Asynchronously completes a [target] future with a [source] future.
  ///
  /// If the [source] future is already completed, its result is
  /// asynchronously propagated to the [target] future's listeners.
  /// If the [source] future is not completed, the [target] future is made
  /// to listen for its completion.
  static void _chainCoreFutureAsync(_Future source, _Future target) {
    assert(target._mayAddListener); // Not completed, not already chained.
    while (source._isChained) {
      source = source._chainSource;
    }
    if (identical(source, target)) {
      target._asyncCompleteError(
          ArgumentError.value(
              source, null, "Cannot complete a future with itself"),
          StackTrace.current);
      return;
    }
    if (!source._isComplete) {
      // Chain immediately if the source is not complete.
      // This won't call any listeners.
      _FutureListener? listeners = target._resultOrListeners;
      target._setChained(source);
      source._prependListeners(listeners);
      return;
    }

    // Complete a value synchronously, if no-one is listening.
    // This won't call any listeners.
    if (!source._hasError && target._resultOrListeners == null) {
      target._cloneResult(source);
      return;
    }

    // Otherwise delay the chaining to avoid any synchronous callbacks.
    target._setPendingComplete();
    target._zone.scheduleMicrotask(() {
      _chainCoreFutureSync(source, target);
    });
  }

  /// Synchronously completes this future with [value].
  ///
  /// If [value] is a value or an already completed [_Future],
  /// the result is immediately used to complete this future.
  /// If [value] is an incomplete future, this future will wait for
  /// it to complete, then use the result.
  void _complete(FutureOr<T> value) {
    assert(!_isComplete);
    if (value is Future<T>) {
      if (value is _Future<T>) {
        _chainCoreFutureSync(value, this);
      } else {
        _chainForeignFuture(value);
      }
    } else {
      _FutureListener? listeners = _removeListeners();
      _setValue(value);
      _propagateToListeners(this, listeners);
    }
  }

  void _completeWithValue(T value) {
    assert(!_isComplete);

    _FutureListener? listeners = _removeListeners();
    _setValue(value);
    _propagateToListeners(this, listeners);
  }

  void _completeError(Object error, StackTrace stackTrace) {
    assert(!_isComplete);

    _FutureListener? listeners = _removeListeners();
    _setError(error, stackTrace);
    _propagateToListeners(this, listeners);
  }

  // Completes future in a later microtask.
  void _asyncComplete(FutureOr<T> value) {
    assert(!_isComplete); // Allows both pending complete and incomplete.
    // Two corner cases if the value is a future:
    //   1. the future is already completed and an error.
    //   2. the future is not yet completed but might become an error.
    // The first case means that we must not immediately complete the Future,
    // as our code would immediately start propagating the error without
    // giving the time to install error-handlers.
    // However the second case requires us to deal with the value immediately.
    // Otherwise the value could complete with an error and report an
    // unhandled error, even though we know we are already going to listen to
    // it.

    if (value is Future<T>) {
      _chainFuture(value);
      return;
    }
    _asyncCompleteWithValue(value);
  }

  /// Internal helper function used by the implementation of `async` functions.
  ///
  /// Like [_asyncComplete], but avoids type checks that are guaranteed to
  /// succeed by the way the function is called.
  /// Should be used judiciously.
  void _asyncCompleteUnchecked(/*FutureOr<T>*/ dynamic value) {
    // Ensure [value] is FutureOr<T>, do so using an `as` check so it works
    // also correctly in non-sound null-safety mode.
    assert(identical(value as FutureOr<T>, value));
    final typedValue = unsafeCast<FutureOr<T>>(value);

    // Doing just "is Future" is not sufficient.
    // If `T` is Object` and `value` is `Future<Object?>.value(null)`,
    // then value is a `Future`, but not a `Future<T>`, and going through the
    // `_chainFuture` branch would end up assigning `null` to `Object`.
    if (typedValue is Future<T>) {
      _chainFuture(typedValue);
      return;
    }
    _asyncCompleteWithValue(unsafeCast<T>(typedValue));
  }

  /// Internal helper function used to implement `async` functions.
  ///
  /// Like [_asyncCompleteUnchecked], but avoids a `is Future<T>` check due to
  /// having a static guarantee on the callsite that the [value] cannot be a
  /// [Future].
  /// Should be used judiciously.
  void _asyncCompleteUncheckedNoFuture(/*T*/ dynamic value) {
    // Ensure [value] is T, do so using an `as` check so it works also correctly
    // in non-sound null-safety mode.
    assert(identical(value as T, value));
    _asyncCompleteWithValue(unsafeCast<T>(value));
  }

  void _asyncCompleteWithValue(T value) {
    _setPendingComplete();
    _zone.scheduleMicrotask(() {
      _completeWithValue(value);
    });
  }

  /// Asynchronously completes a future with another future.
  ///
  /// Even if [value] is already completed, it won't synchronously
  /// complete this completer's future.
  void _chainFuture(Future<T> value) {
    assert(_mayComplete);
    if (value is _Future<T>) {
      // Chain ensuring that we don't complete synchronously.
      _chainCoreFutureAsync(value, this);
      return;
    }
    // Just listen on the foreign future. This guarantees an async delay.
    _chainForeignFuture(value);
  }

  void _asyncCompleteError(Object error, StackTrace stackTrace) {
    assert(!_isComplete);

    _setPendingComplete();
    _zone.scheduleMicrotask(() {
      _completeError(error, stackTrace);
    });
  }

  /// Propagates the value/error of [source] to its [listeners], executing the
  /// listeners' callbacks.
  static void _propagateToListeners(
      _Future source, _FutureListener? listeners) {
    while (true) {
      assert(source._isComplete);
      bool hasError = source._hasError;
      if (listeners == null) {
        if (hasError && !source._ignoreError) {
          AsyncError asyncError = source._error;
          source._zone
              .handleUncaughtError(asyncError.error, asyncError.stackTrace);
        }
        return;
      }
      // Usually futures only have one listener. If they have several, we
      // call handle them separately in recursive calls, continuing
      // here only when there is only one listener left.
      _FutureListener listener = listeners;
      _FutureListener? nextListener = listener._nextListener;
      while (nextListener != null) {
        listener._nextListener = null;
        _propagateToListeners(source, listener);
        listener = nextListener;
        nextListener = listener._nextListener;
      }

      final dynamic sourceResult = source._resultOrListeners;
      // Do the actual propagation.
      // Set initial state of listenerHasError and listenerValueOrError. These
      // variables are updated with the outcome of potential callbacks.
      // Non-error results, including futures, are stored in
      // listenerValueOrError and listenerHasError is set to false. Errors
      // are stored in listenerValueOrError as an [AsyncError] and
      // listenerHasError is set to true.
      bool listenerHasError = hasError;
      var listenerValueOrError = sourceResult;

      // Only if we either have an error or callbacks, go into this, somewhat
      // expensive, branch. Here we'll enter/leave the zone. Many futures
      // don't have callbacks, so this is a significant optimization.
      if (hasError || listener.handlesValue || listener.handlesComplete) {
        _Zone zone = listener._zone;
        if (hasError && !source._zone.inSameErrorZone(zone)) {
          // Don't cross zone boundaries with errors.
          AsyncError asyncError = source._error;
          source._zone
              .handleUncaughtError(asyncError.error, asyncError.stackTrace);
          return;
        }

        _Zone? oldZone;
        if (!identical(Zone._current, zone)) {
          // Change zone if it's not current.
          oldZone = Zone._enter(zone);
        }

        // These callbacks are abstracted to isolate the try/catch blocks
        // from the rest of the code to work around a V8 glass jaw.
        void handleWhenCompleteCallback() {
          // The whenComplete-handler is not combined with normal value/error
          // handling. This means at most one handleX method is called per
          // listener.
          assert(!listener.handlesValue);
          assert(!listener.handlesError);
          var completeResult;
          try {
            completeResult = listener.handleWhenComplete();
          } catch (e, s) {
            if (hasError && identical(source._error.error, e)) {
              listenerValueOrError = source._error;
            } else {
              listenerValueOrError = new AsyncError(e, s);
            }
            listenerHasError = true;
            return;
          }
          if (completeResult is _Future && completeResult._isComplete) {
            if (completeResult._hasError) {
              listenerValueOrError = completeResult._error;
              listenerHasError = true;
            }
            // Otherwise use the existing result of source.
            return;
          }
          if (completeResult is Future) {
            // We have to wait for the completeResult future to complete
            // before knowing if it's an error or we should use the result
            // of source.
            var originalSource = source;
            listenerValueOrError = completeResult.then((_) => originalSource);
            listenerHasError = false;
          }
        }

        void handleValueCallback() {
          try {
            listenerValueOrError = listener.handleValue(sourceResult);
          } catch (e, s) {
            listenerValueOrError = new AsyncError(e, s);
            listenerHasError = true;
          }
        }

        void handleError() {
          try {
            AsyncError asyncError = source._error;
            if (listener.matchesErrorTest(asyncError) &&
                listener.hasErrorCallback) {
              listenerValueOrError = listener.handleError(asyncError);
              listenerHasError = false;
            }
          } catch (e, s) {
            if (identical(source._error.error, e)) {
              listenerValueOrError = source._error;
            } else {
              listenerValueOrError = new AsyncError(e, s);
            }
            listenerHasError = true;
          }
        }

        if (listener.handlesComplete) {
          handleWhenCompleteCallback();
        } else if (!hasError) {
          if (listener.handlesValue) {
            handleValueCallback();
          }
        } else {
          if (listener.handlesError) {
            handleError();
          }
        }

        // If we changed zone, oldZone will not be null.
        if (oldZone != null) Zone._leave(oldZone);

        // If the listener's value is a future we *might* need to chain it. Note that
        // this can only happen if there is a callback.
        if (listenerValueOrError is Future &&
            listener.shouldChain(listenerValueOrError)) {
          Future chainSource = listenerValueOrError;
          // Shortcut if the chain-source is already completed. Just continue
          // the loop.
          _Future result = listener.result;
          if (chainSource is _Future) {
            if (chainSource._isComplete) {
              listeners = result._removeListeners();
              result._cloneResult(chainSource);
              source = chainSource;
              continue;
            } else {
              _chainCoreFutureSync(chainSource, result);
            }
          } else {
            result._chainForeignFuture(chainSource);
          }
          return;
        }
      }

      _Future result = listener.result;
      listeners = result._removeListeners();
      if (!listenerHasError) {
        result._setValue(listenerValueOrError);
      } else {
        AsyncError asyncError = listenerValueOrError;
        result._setErrorObject(asyncError);
      }
      // Prepare for next round.
      source = result;
    }
  }

  @pragma("vm:entry-point")
  Future<T> timeout(Duration timeLimit, {FutureOr<T> onTimeout()?}) {
    if (_isComplete) return new _Future.immediate(this);
    @pragma('vm:awaiter-link')
    _Future<T> _future = new _Future<T>();
    Timer timer;
    if (onTimeout == null) {
      timer = new Timer(timeLimit, () {
        _future._completeError(
            new TimeoutException("Future not completed", timeLimit),
            StackTrace.empty);
      });
    } else {
      Zone zone = Zone.current;
      FutureOr<T> Function() onTimeoutHandler =
          zone.registerCallback(onTimeout);

      timer = new Timer(timeLimit, () {
        try {
          _future._complete(zone.run(onTimeoutHandler));
        } catch (e, s) {
          _future._completeError(e, s);
        }
      });
    }
    this.then((T v) {
      if (timer.isActive) {
        timer.cancel();
        _future._completeWithValue(v);
      }
    }, onError: (Object e, StackTrace s) {
      if (timer.isActive) {
        timer.cancel();
        _future._completeError(e, s);
      }
    });
    return _future;
  }
}

/// Registers errorHandler in zone if it has the correct type.
///
/// Checks that the function accepts either an [Object] and a [StackTrace]
/// or just one [Object]. Does not check the return type.
/// The actually returned value must be `FutureOr<R>` where `R` is the
/// value type of the future that the call will complete (either returned
/// by [Future.then] or [Future.catchError]). We check the returned value
/// dynamically because the functions are passed as arguments in positions
/// without inference, so a function expression won't infer the return type.
///
/// Throws if the type is not valid.
Function _registerErrorHandler(Function errorHandler, Zone zone) {
  if (errorHandler is dynamic Function(Object, StackTrace)) {
    return zone
        .registerBinaryCallback<dynamic, Object, StackTrace>(errorHandler);
  }
  if (errorHandler is dynamic Function(Object)) {
    return zone.registerUnaryCallback<dynamic, Object>(errorHandler);
  }
  throw ArgumentError.value(
      errorHandler,
      "onError",
      "Error handler must accept one Object or one Object and a StackTrace"
          " as arguments, and return a value of the returned future's type");
}
