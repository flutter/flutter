// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/// Abstract and private interface for a place to put events.
abstract class _EventSink<T> {
  void _add(T data);
  void _addError(Object error, StackTrace stackTrace);
  void _close();
}

/// Abstract and private interface for a place to send events.
///
/// Used by event buffering to finally dispatch the pending event, where
/// [_EventSink] is where the event first enters the stream subscription,
/// and may yet be buffered.
abstract class _EventDispatch<T> {
  void _sendData(T data);
  void _sendError(Object error, StackTrace stackTrace);
  void _sendDone();
}

/// Default implementation of stream subscription of buffering events.
///
/// The only public methods are those of [StreamSubscription], so instances of
/// [_BufferingStreamSubscription] can be returned directly as a
/// [StreamSubscription] without exposing internal functionality.
///
/// The [StreamController] is a public facing version of [Stream] and this class,
/// with some methods made public.
///
/// The user interface of [_BufferingStreamSubscription] are the following
/// methods:
///
/// * [_add]: Add a data event to the stream.
/// * [_addError]: Add an error event to the stream.
/// * [_close]: Request to close the stream.
/// * [_onCancel]: Called when the subscription will provide no more events,
///     either due to being actively canceled, or after sending a done event.
/// * [_onPause]: Called when the subscription wants the event source to pause.
/// * [_onResume]: Called when allowing new events after a pause.
///
/// The user should not add new events when the subscription requests a paused,
/// but if it happens anyway, the subscription will enqueue the events just as
/// when new events arrive while still firing an old event.
class _BufferingStreamSubscription<T>
    implements StreamSubscription<T>, _EventSink<T>, _EventDispatch<T> {
  /// The `cancelOnError` flag from the `listen` call.
  static const int _STATE_CANCEL_ON_ERROR = 1 << 0;

  /// Whether the "done" event has been received.
  /// No further events are accepted after this.
  static const int _STATE_CLOSED = 1 << 1;

  /// Set if the input has been asked not to send events.
  ///
  /// This is not the same as being paused, since the input will remain paused
  /// after a call to [resume] if there are pending events.
  static const int _STATE_INPUT_PAUSED = 1 << 2;

  /// Whether the subscription has been canceled.
  ///
  /// Set by calling [cancel], or by handling a "done" event, or an "error" event
  /// when `cancelOnError` is true.
  static const int _STATE_CANCELED = 1 << 3;

  /// Set when either:
  ///
  ///   * an error is sent, and [cancelOnError] is true, or
  ///   * a done event is sent.
  ///
  /// If the subscription is canceled while _STATE_WAIT_FOR_CANCEL is set, the
  /// state is unset, and no further events must be delivered.
  static const int _STATE_WAIT_FOR_CANCEL = 1 << 4;

  /// Set when [_onError] is set to something other than [_nullErrorHandler].
  /// Is used by VM to decide whether subscription is going to handle an
  /// error or not.
  ///
  /// When changing this value make sure to update runtime/vm/stack_trace.cc
  static const int _STATE_HAS_ERROR_HANDLER = 1 << 5;

  /// Caveat: [_canFire] expects these bits to be at the top so that it
  /// can use a single `< _STATE_IN_CALLBACK` comparison to test for all
  /// of them.
  static const int _STATE_IN_CALLBACK = 1 << 6;
  static const int _STATE_HAS_PENDING = 1 << 7;
  static const int _STATE_PAUSE_COUNT = 1 << 8;

  /* Event handlers provided in constructor. */
  @pragma("vm:entry-point")
  void Function(T) _onData;

  @pragma("vm:entry-point")
  Function _onError;

  @pragma("vm:entry-point")
  void Function() _onDone;

  final Zone _zone;

  /// Bit vector based on state-constants above.
  ///
  /// Upper bits (starting at _STATE_PAUSE_COUNT) contain number of times
  /// this subscription was paused.
  @pragma("vm:entry-point")
  int _state;

  // TODO(floitsch): reuse another field
  /// The future [_onCancel] may return.
  Future? _cancelFuture;

  /// Queue of pending events.
  ///
  /// Is created when necessary, or set in constructor for preconfigured events.
  _PendingEvents<T>? _pending;

  _BufferingStreamSubscription(void onData(T data)?, Function? onError,
      void onDone()?, bool cancelOnError)
      : this.zoned(Zone.current, onData, onError, onDone, cancelOnError);

  _BufferingStreamSubscription.zoned(this._zone, void onData(T data)?,
      Function? onError, void onDone()?, bool cancelOnError)
      : _state = (cancelOnError ? _STATE_CANCEL_ON_ERROR : 0) |
            (onError != null ? _STATE_HAS_ERROR_HANDLER : 0),
        _onData = _registerDataHandler<T>(_zone, onData),
        _onError = _registerErrorHandler(_zone, onError),
        _onDone = _registerDoneHandler(_zone, onDone);

  /// Sets the subscription's pending events object.
  ///
  /// This can only be done once. The pending events object is used for the
  /// rest of the subscription's life cycle.
  void _setPendingEvents(_PendingEvents<T>? pendingEvents) {
    assert(_pending == null);
    if (pendingEvents == null) return;
    _pending = pendingEvents;
    if (!pendingEvents.isEmpty) {
      _state |= _STATE_HAS_PENDING;
      pendingEvents.schedule(this);
    }
  }

  // StreamSubscription interface.

  void onData(void handleData(T event)?) {
    _onData = _registerDataHandler<T>(_zone, handleData);
  }

  static void Function(T) _registerDataHandler<T>(
      Zone zone, void Function(T)? handleData) {
    return zone.registerUnaryCallback<void, T>(handleData ?? _nullDataHandler);
  }

  void onError(Function? handleError) {
    if (handleError == null) {
      _state &= ~_STATE_HAS_ERROR_HANDLER;
    } else {
      _state |= _STATE_HAS_ERROR_HANDLER;
    }
    _onError = _registerErrorHandler(_zone, handleError);
  }

  static Function _registerErrorHandler(Zone zone, Function? handleError) {
    // TODO(lrn): Consider whether we need to register the null handler.
    handleError ??= _nullErrorHandler;
    if (handleError is void Function(Object, StackTrace)) {
      return zone
          .registerBinaryCallback<dynamic, Object, StackTrace>(handleError);
    }
    if (handleError is void Function(Object)) {
      return zone.registerUnaryCallback<dynamic, Object>(handleError);
    }
    throw new ArgumentError("handleError callback must take either an Object "
        "(the error), or both an Object (the error) and a StackTrace.");
  }

  void onDone(void handleDone()?) {
    _onDone = _registerDoneHandler(_zone, handleDone);
  }

  static void Function() _registerDoneHandler(
      Zone zone, void Function()? handleDone) {
    return zone.registerCallback(handleDone ?? _nullDoneHandler);
  }

  void pause([Future<void>? resumeSignal]) {
    if (_isCanceled) return;
    bool wasPaused = _isPaused;
    bool wasInputPaused = _isInputPaused;
    // Increment pause count and mark input paused (if it isn't already).
    _state = (_state + _STATE_PAUSE_COUNT) | _STATE_INPUT_PAUSED;
    resumeSignal?.whenComplete(resume);
    if (!wasPaused) _pending?.cancelSchedule();
    if (!wasInputPaused && !_inCallback) _guardCallback(_onPause);
  }

  void resume() {
    if (_isCanceled) return;
    if (_isPaused) {
      _decrementPauseCount();
      if (!_isPaused) {
        if (_hasPending && !_pending!.isEmpty) {
          // Input is still paused.
          _pending!.schedule(this);
        } else {
          assert(_mayResumeInput);
          _state &= ~_STATE_INPUT_PAUSED;
          if (!_inCallback) _guardCallback(_onResume);
        }
      }
    }
  }

  Future cancel() {
    // The user doesn't want to receive any further events. If there is an
    // error or done event pending (waiting for the cancel to be done) discard
    // that event.
    _state &= ~_STATE_WAIT_FOR_CANCEL;
    if (!_isCanceled) {
      _cancel();
    }
    return _cancelFuture ?? Future._nullFuture;
  }

  Future<E> asFuture<E>([E? futureValue]) {
    E resultValue;
    if (futureValue == null) {
      if (!typeAcceptsNull<E>()) {
        throw ArgumentError.notNull("futureValue");
      }
      resultValue = futureValue as dynamic;
    } else {
      resultValue = futureValue;
    }
    // Overwrite the onDone and onError handlers.
    _Future<E> result = new _Future<E>();
    _onDone = () {
      result._complete(resultValue);
    };
    _state |= _STATE_HAS_ERROR_HANDLER;
    _onError = (Object error, StackTrace stackTrace) {
      Future cancelFuture = cancel();
      if (!identical(cancelFuture, Future._nullFuture)) {
        cancelFuture.whenComplete(() {
          result._completeError(error, stackTrace);
        });
      } else {
        result._completeError(error, stackTrace);
      }
    };
    return result;
  }

  // State management.

  bool get _isInputPaused => (_state & _STATE_INPUT_PAUSED) != 0;
  bool get _isClosed => (_state & _STATE_CLOSED) != 0;
  bool get _isCanceled => (_state & _STATE_CANCELED) != 0;
  bool get _waitsForCancel => (_state & _STATE_WAIT_FOR_CANCEL) != 0;
  bool get _inCallback => (_state & _STATE_IN_CALLBACK) != 0;
  bool get _hasPending => (_state & _STATE_HAS_PENDING) != 0;
  bool get _isPaused => _state >= _STATE_PAUSE_COUNT;
  bool get _canFire => _state < _STATE_IN_CALLBACK;
  bool get _mayResumeInput => !_isPaused && (_pending?.isEmpty ?? true);
  bool get _cancelOnError => (_state & _STATE_CANCEL_ON_ERROR) != 0;

  bool get isPaused => _isPaused;

  void _cancel() {
    _state |= _STATE_CANCELED;
    if (_hasPending) {
      _pending!.cancelSchedule();
    }
    if (!_inCallback) _pending = null;
    _cancelFuture = _onCancel();
  }

  /// Decrements the pause count.
  ///
  /// Does not automatically unpause the input (call [_onResume]) when
  /// the pause count reaches zero. This is handled elsewhere, and only
  /// if there are no pending events buffered.
  void _decrementPauseCount() {
    assert(_isPaused);
    _state -= _STATE_PAUSE_COUNT;
  }

  // _EventSink interface.

  void _add(T data) {
    assert(!_isClosed);
    if (_isCanceled) return;
    if (_canFire) {
      _sendData(data);
    } else {
      _addPending(new _DelayedData<T>(data));
    }
  }

  void _addError(Object error, StackTrace stackTrace) {
    if (_isCanceled) return;
    if (_canFire) {
      _sendError(error, stackTrace); // Reports cancel after sending.
    } else {
      _addPending(new _DelayedError(error, stackTrace));
    }
  }

  void _close() {
    assert(!_isClosed);
    if (_isCanceled) return;
    _state |= _STATE_CLOSED;
    if (_canFire) {
      _sendDone();
    } else {
      _addPending(const _DelayedDone());
    }
  }

  // Hooks called when the input is paused, unpaused or canceled.
  // These must not throw. If overwritten to call user code, include suitable
  // try/catch wrapping and send any errors to
  // [_Zone.current.handleUncaughtError].
  void _onPause() {
    assert(_isInputPaused);
  }

  void _onResume() {
    assert(!_isInputPaused);
  }

  Future<void>? _onCancel() {
    assert(_isCanceled);
    return null;
  }

  // Handle pending events.

  /// Add a pending event.
  ///
  /// If the subscription is not paused, this also schedules a firing
  /// of pending events later (if necessary).
  void _addPending(_DelayedEvent event) {
    var pending = _pending ??= _PendingEvents<T>();
    pending.add(event);
    if (!_hasPending) {
      _state |= _STATE_HAS_PENDING;
      if (!_isPaused) {
        pending.schedule(this);
      }
    }
  }

  /* _EventDispatch interface. */

  void _sendData(T data) {
    assert(!_isCanceled);
    assert(!_isPaused);
    assert(!_inCallback);
    bool wasInputPaused = _isInputPaused;
    _state |= _STATE_IN_CALLBACK;
    _zone.runUnaryGuarded(_onData, data);
    _state &= ~_STATE_IN_CALLBACK;
    _checkState(wasInputPaused);
  }

  void _sendError(Object error, StackTrace stackTrace) {
    assert(!_isCanceled);
    assert(!_isPaused);
    assert(!_inCallback);
    bool wasInputPaused = _isInputPaused;

    void sendError() {
      // If the subscription has been canceled while waiting for the cancel
      // future to finish we must not report the error.
      if (_isCanceled && !_waitsForCancel) return;
      _state |= _STATE_IN_CALLBACK;
      // TODO(floitsch): this dynamic should be 'void'.
      var onError = _onError;
      if (onError is void Function(Object, StackTrace)) {
        _zone.runBinaryGuarded<Object, StackTrace>(onError, error, stackTrace);
      } else {
        _zone.runUnaryGuarded<Object>(_onError as dynamic, error);
      }
      _state &= ~_STATE_IN_CALLBACK;
    }

    if (_cancelOnError) {
      _state |= _STATE_WAIT_FOR_CANCEL;
      _cancel();
      var cancelFuture = _cancelFuture;
      if (cancelFuture != null &&
          !identical(cancelFuture, Future._nullFuture)) {
        cancelFuture.whenComplete(sendError);
      } else {
        sendError();
      }
    } else {
      sendError();
      // Only check state if not cancelOnError.
      _checkState(wasInputPaused);
    }
  }

  void _sendDone() {
    assert(!_isCanceled);
    assert(!_isPaused);
    assert(!_inCallback);

    void sendDone() {
      // If the subscription has been canceled while waiting for the cancel
      // future to finish we must not report the done event.
      if (!_waitsForCancel) return;
      _state |= (_STATE_CANCELED | _STATE_CLOSED | _STATE_IN_CALLBACK);
      _zone.runGuarded(_onDone);
      _state &= ~_STATE_IN_CALLBACK;
    }

    _cancel();
    _state |= _STATE_WAIT_FOR_CANCEL;
    var cancelFuture = _cancelFuture;
    if (cancelFuture != null && !identical(cancelFuture, Future._nullFuture)) {
      cancelFuture.whenComplete(sendDone);
    } else {
      sendDone();
    }
  }

  /// Call a hook function.
  ///
  /// The call is properly wrapped in code to avoid other callbacks
  /// during the call, and it checks for state changes after the call
  /// that should cause further callbacks.
  void _guardCallback(void Function() callback) {
    assert(!_inCallback);
    bool wasInputPaused = _isInputPaused;
    _state |= _STATE_IN_CALLBACK;
    callback();
    _state &= ~_STATE_IN_CALLBACK;
    _checkState(wasInputPaused);
  }

  /// Check if the input needs to be informed of state changes.
  ///
  /// State changes are pausing, resuming and canceling.
  ///
  /// After canceling, no further callbacks will happen.
  ///
  /// The cancel callback is called after a user cancel, or after
  /// the final done event is sent.
  void _checkState(bool wasInputPaused) {
    assert(!_inCallback);
    if (_hasPending && _pending!.isEmpty) {
      _state &= ~_STATE_HAS_PENDING;
      if (_isInputPaused && _mayResumeInput) {
        _state &= ~_STATE_INPUT_PAUSED;
      }
    }
    // If the state changes during a callback, we immediately
    // make a new state-change callback. Loop until the state didn't change.
    while (true) {
      if (_isCanceled) {
        _pending = null;
        return;
      }
      bool isInputPaused = _isInputPaused;
      if (wasInputPaused == isInputPaused) break;
      _state ^= _STATE_IN_CALLBACK;
      if (isInputPaused) {
        _onPause();
      } else {
        _onResume();
      }
      _state &= ~_STATE_IN_CALLBACK;
      wasInputPaused = isInputPaused;
    }
    if (_hasPending && !_isPaused) {
      _pending!.schedule(this);
    }
  }
}

// -------------------------------------------------------------------
// Common base class for single and multi-subscription streams.
// -------------------------------------------------------------------
abstract class _StreamImpl<T> extends Stream<T> {
  // ------------------------------------------------------------------
  // Stream interface.

  StreamSubscription<T> listen(void onData(T data)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    cancelOnError ??= false;
    StreamSubscription<T> subscription =
        _createSubscription(onData, onError, onDone, cancelOnError);
    _onListen(subscription);
    return subscription;
  }

  // -------------------------------------------------------------------
  /// Create a subscription object. Called by [subscribe].
  StreamSubscription<T> _createSubscription(void onData(T data)?,
      Function? onError, void onDone()?, bool cancelOnError) {
    return new _BufferingStreamSubscription<T>(
        onData, onError, onDone, cancelOnError);
  }

  /// Hook called when the subscription has been created.
  void _onListen(StreamSubscription subscription) {}
}

// Internal helpers.

/// Default data handler, does nothing.
void _nullDataHandler(dynamic value) {}

/// Default error handler, reports the error to the current zone's handler.
void _nullErrorHandler(Object error, StackTrace stackTrace) {
  Zone.current.handleUncaughtError(error, stackTrace);
}

/// Default done handler, does nothing.
void _nullDoneHandler() {}

/// A delayed event on a buffering stream subscription.
abstract class _DelayedEvent<T> {
  /// Added as a linked list on the [StreamController].
  _DelayedEvent? next;

  /// Execute the delayed event on the [StreamController].
  void perform(_EventDispatch<T> dispatch);
}

/// A delayed data event.
class _DelayedData<T> extends _DelayedEvent<T> {
  final T value;
  _DelayedData(this.value);
  void perform(_EventDispatch<T> dispatch) {
    dispatch._sendData(value);
  }
}

/// A delayed error event.
class _DelayedError extends _DelayedEvent {
  final Object error;
  final StackTrace stackTrace;

  _DelayedError(this.error, this.stackTrace);
  void perform(_EventDispatch dispatch) {
    dispatch._sendError(error, stackTrace);
  }
}

/// A delayed done event.
class _DelayedDone implements _DelayedEvent {
  const _DelayedDone();
  void perform(_EventDispatch dispatch) {
    dispatch._sendDone();
  }

  _DelayedEvent? get next => null;

  void set next(_DelayedEvent? _) {
    throw new StateError("No events after a done.");
  }
}

/// Container and manager of pending events for a stream subscription.
class _PendingEvents<T> {
  // No async event has been scheduled.
  static const int stateUnscheduled = 0;
  // An async event has been scheduled to run a function.
  static const int stateScheduled = 1;
  // An async event has been scheduled, but it will do nothing when it runs.
  // Async events can't be preempted.
  static const int stateCanceled = 3;

  /// State of being scheduled.
  ///
  /// Set to [stateScheduled] when pending events are scheduled for
  /// async dispatch. Since we can't cancel a [scheduleMicrotask] call, if
  /// scheduling is "canceled", the _state is simply set to [stateCanceled]
  /// which will make the async code do nothing except resetting [_state].
  ///
  /// If events are scheduled while the state is [stateCanceled], it is
  /// merely switched back to [stateScheduled], but no new call to
  /// [scheduleMicrotask] is performed.
  int _state = stateUnscheduled;

  /// First element in the list of pending events, if any.
  _DelayedEvent? firstPendingEvent;

  /// Last element in the list of pending events. New events are added after it.
  _DelayedEvent? lastPendingEvent;

  bool get isScheduled => _state == stateScheduled;
  bool get _eventScheduled => _state >= stateScheduled;

  /// Schedule an event to run later.
  ///
  /// If called more than once, it should be called with the same dispatch as
  /// argument each time. It may reuse an earlier argument in some cases.
  void schedule(_EventDispatch<T> dispatch) {
    if (isScheduled) return;
    assert(!isEmpty);
    if (_eventScheduled) {
      assert(_state == stateCanceled);
      _state = stateScheduled;
      return;
    }
    scheduleMicrotask(() {
      int oldState = _state;
      _state = stateUnscheduled;
      if (oldState == stateCanceled) return;
      handleNext(dispatch);
    });
    _state = stateScheduled;
  }

  void cancelSchedule() {
    if (isScheduled) _state = stateCanceled;
  }

  bool get isEmpty => lastPendingEvent == null;

  void add(_DelayedEvent event) {
    var lastEvent = lastPendingEvent;
    if (lastEvent == null) {
      firstPendingEvent = lastPendingEvent = event;
    } else {
      lastPendingEvent = lastEvent.next = event;
    }
  }

  void handleNext(_EventDispatch<T> dispatch) {
    assert(!isScheduled);
    assert(!isEmpty);
    _DelayedEvent event = firstPendingEvent!;
    _DelayedEvent? nextEvent = event.next;
    firstPendingEvent = nextEvent;
    if (nextEvent == null) {
      lastPendingEvent = null;
    }
    event.perform(dispatch);
  }

  void clear() {
    if (isScheduled) cancelSchedule();
    firstPendingEvent = lastPendingEvent = null;
  }
}

typedef void _BroadcastCallback<T>(StreamSubscription<T> subscription);

/// Done subscription that will send one done event as soon as possible.
class _DoneStreamSubscription<T> implements StreamSubscription<T> {
  // States of the subscription.
  //
  // The subscription will try to send a done event.
  // When created, it schedules a microtask to emit the
  // event to the current [_onDone] callback.
  // If paused when the microtask happens, the subscription won't
  // send the done event. It will reschedule a new microtask when
  // the subscription is resumed.
  // If cancelled, the event will not be sent, and a new
  // microtask won't be scheduled, and further pauses
  // are ignored.

  /// Sending a done event is allowed.
  ///
  /// Not paused or cancelled, no microtask scheduled.
  static const int _stateReadyToSend = 0;

  /// Set when a microtask is scheduled, and not cancelled.
  static const int _stateScheduled = 1;

  /// State set when done event sent or subscription cancelled.
  ///
  /// Any negative value counts as done, so we can safely subtract
  /// [_stateScheduled] or [_statePausedOnce] without affecting
  /// being cancelled.
  ///
  /// Never considered paused in this state, may still be scheduled,
  /// and [_onDone] is always set to `null`.
  static const int _stateDone = -1;

  /// Added for each pause while not done or cancelled, subtracted on resume.
  ///
  /// Subscription is paused when state is at least `_statePausedOnce`.
  static const int _statePausedOnce = 2;

  int _state;
  final Zone _zone;
  void Function()? _onDone;

  _DoneStreamSubscription(void Function()? onDone)
      : _zone = Zone.current,
        _state = _stateScheduled {
    scheduleMicrotask(_onMicrotask);
    if (onDone != null) {
      _onDone = _zone.registerCallback(onDone);
    }
  }

  bool get isPaused => _state >= _statePausedOnce;

  /// True after being cancelled, or after delivering done event.
  static bool _isDone(int state) => state < 0;

  static int _incrementPauseCount(int state) => state + _statePausedOnce;
  static int _decrementPauseCount(int state) => state - _statePausedOnce;

  void onData(void handleData(T data)?) {}

  void onError(Function? handleError) {}

  void onDone(void handleDone()?) {
    if (!_isDone(_state)) {
      if (handleDone != null) handleDone = _zone.registerCallback(handleDone);
      _onDone = handleDone;
    }
  }

  void pause([Future<void>? resumeSignal]) {
    if (!_isDone(_state)) {
      _state = _incrementPauseCount(_state);
      if (resumeSignal != null) resumeSignal.whenComplete(resume);
    }
  }

  void resume() {
    var resumeState = _decrementPauseCount(_state);
    if (resumeState < 0) return; // Wasn't paused.
    if (resumeState == _stateReadyToSend) {
      // No longer paused, and not already scheduled.
      _state = _stateScheduled;
      scheduleMicrotask(_onMicrotask);
    } else {
      _state = resumeState;
    }
  }

  Future cancel() {
    _state = _stateDone;
    _onDone = null;
    return Future._nullFuture;
  }

  Future<E> asFuture<E>([E? futureValue]) {
    E resultValue;
    if (futureValue == null) {
      if (!typeAcceptsNull<E>()) {
        throw ArgumentError.notNull("futureValue");
      }
      resultValue = futureValue as dynamic;
    } else {
      resultValue = futureValue;
    }
    _Future<E> result = _Future<E>();
    if (!_isDone(_state)) {
      _onDone = _zone.registerCallback(() {
        result._completeWithValue(resultValue);
      });
    }
    return result;
  }

  void _onMicrotask() {
    var unscheduledState = _state - _stateScheduled;
    if (unscheduledState == _stateReadyToSend) {
      // Send the done event.
      _state = _stateDone;
      if (_onDone case var doneHandler?) {
        _onDone = null;
        _zone.runGuarded(doneHandler);
      }
    } else {
      // Paused or cancelled.
      _state = unscheduledState;
    }
  }
}

class _AsBroadcastStream<T> extends Stream<T> {
  final Stream<T> _source;
  final _BroadcastCallback<T>? _onListenHandler;
  final _BroadcastCallback<T>? _onCancelHandler;
  final Zone _zone;

  _AsBroadcastStreamController<T>? _controller;
  StreamSubscription<T>? _subscription;

  _AsBroadcastStream(
      this._source,
      void onListenHandler(StreamSubscription<T> subscription)?,
      void onCancelHandler(StreamSubscription<T> subscription)?)
      : _onListenHandler = onListenHandler == null
            ? null
            : Zone.current.registerUnaryCallback<void, StreamSubscription<T>>(
                onListenHandler),
        _onCancelHandler = onCancelHandler == null
            ? null
            : Zone.current.registerUnaryCallback<void, StreamSubscription<T>>(
                onCancelHandler),
        _zone = Zone.current {
    _controller = new _AsBroadcastStreamController<T>(_onListen, _onCancel);
  }

  bool get isBroadcast => true;

  StreamSubscription<T> listen(void onData(T data)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    var controller = _controller;
    if (controller == null || controller.isClosed) {
      // Return a dummy subscription backed by nothing, since
      // it will only ever send one done event.
      return new _DoneStreamSubscription<T>(onDone);
    }
    _subscription ??= _source.listen(controller.add,
        onError: controller.addError, onDone: controller.close);
    return controller._subscribe(
        onData, onError, onDone, cancelOnError ?? false);
  }

  void _onCancel() {
    var controller = _controller;
    bool shutdown = (controller == null) || controller.isClosed;
    var cancelHandler = _onCancelHandler;
    if (cancelHandler != null) {
      _zone.runUnary(cancelHandler, new _BroadcastSubscriptionWrapper<T>(this));
    }
    if (shutdown) {
      var subscription = _subscription;
      if (subscription != null) {
        subscription.cancel();
        _subscription = null;
      }
    }
  }

  void _onListen() {
    var listenHandler = _onListenHandler;
    if (listenHandler != null) {
      _zone.runUnary(listenHandler, new _BroadcastSubscriptionWrapper<T>(this));
    }
  }

  // Methods called from _BroadcastSubscriptionWrapper.
  void _cancelSubscription() {
    // Called by [_controller] when it has no subscribers left.
    var subscription = _subscription;
    if (subscription != null) {
      _subscription = null;
      _controller = null; // Marks the stream as no longer listenable.
      subscription.cancel();
    }
  }

  void _pauseSubscription(Future<void>? resumeSignal) {
    _subscription?.pause(resumeSignal);
  }

  void _resumeSubscription() {
    _subscription?.resume();
  }

  bool get _isSubscriptionPaused {
    return _subscription?.isPaused ?? false;
  }
}

/// Wrapper for subscription that disallows changing handlers.
class _BroadcastSubscriptionWrapper<T> implements StreamSubscription<T> {
  final _AsBroadcastStream _stream;

  _BroadcastSubscriptionWrapper(this._stream);

  void onData(void handleData(T data)?) {
    throw new UnsupportedError(
        "Cannot change handlers of asBroadcastStream source subscription.");
  }

  void onError(Function? handleError) {
    throw new UnsupportedError(
        "Cannot change handlers of asBroadcastStream source subscription.");
  }

  void onDone(void handleDone()?) {
    throw new UnsupportedError(
        "Cannot change handlers of asBroadcastStream source subscription.");
  }

  void pause([Future<void>? resumeSignal]) {
    _stream._pauseSubscription(resumeSignal);
  }

  void resume() {
    _stream._resumeSubscription();
  }

  Future cancel() {
    _stream._cancelSubscription();
    return Future._nullFuture;
  }

  bool get isPaused {
    return _stream._isSubscriptionPaused;
  }

  Future<E> asFuture<E>([E? futureValue]) {
    throw new UnsupportedError(
        "Cannot change handlers of asBroadcastStream source subscription.");
  }
}

/// Simple implementation of [StreamIterator].
///
/// Pauses the stream between calls to [moveNext].
class _StreamIterator<T> implements StreamIterator<T> {
  // The stream iterator is always in one of five states.
  // The value of the [_stateData] field depends on the state.
  //
  // When `_subscription == null`, `_stateData != null`, and not listened yet:
  // The stream iterator has been created, but [moveNext] has not been called
  // yet. The [_stateData] field contains the stream to listen to on the first
  // call to [moveNext] and [current] returns `null`.
  //
  // When `_subscription == null`, `_stateData != null`, during `listen` call.
  // The `listen` call has not returned a subscription yet.
  // The `_stateData` contains the future returned by the first [moveNext]
  // call. This state is only detected inside the stream event callbacks,
  // since it's the only case where they can get called while `_subscription`
  // is `null`. (A well-behaved stream should not be emitting events during
  // the `listen` call, but some do anyway). The [current] is `null`.
  //
  // When `_subscription != null` and `!_hasValue`:
  // The user has called [moveNext] and the iterator is waiting for the next
  // event. The [_stateData] field contains the [_Future] returned by the
  // [_moveNext] call and [current] returns `null.`
  //
  // When `_subscription != null` and `_hasValue`:
  // The most recent call to [moveNext] has completed with a `true` value
  // and [current] provides the value of the data event.
  // The [_stateData] field contains the [current] value.
  //
  // When `_subscription == null` and `_stateData == null`:
  // The stream has completed or been canceled using [cancel].
  // The stream completes on either a done event or an error event.
  // The last call to [moveNext] has completed with `false` and [current]
  // returns `null`.

  /// Subscription being listened to.
  ///
  /// Set to `null` when the stream subscription is done or canceled.
  StreamSubscription<T>? _subscription;

  /// Data value depending on the current state.
  ///
  /// Before first call to [moveNext]: The stream to listen to.
  ///
  /// After calling [moveNext] but before the returned future completes:
  /// The returned future.
  ///
  /// After calling [moveNext] and the returned future has completed
  /// with `true`: The value of [current].
  ///
  /// After calling [moveNext] and the returned future has completed
  /// with `false`, or after calling [cancel]: `null`.
  @pragma("vm:entry-point")
  Object? _stateData;

  /// Whether the iterator is between calls to `moveNext`.
  /// This will usually cause the [_subscription] to be paused, but as an
  /// optimization, we only pause after the [moveNext] future has been
  /// completed.
  @pragma("vm:entry-point")
  bool _hasValue = false;

  _StreamIterator(final Stream<T> stream)
      : _stateData = checkNotNullable(stream, "stream");

  T get current {
    if (_hasValue) return _stateData as dynamic;
    return null as dynamic;
  }

  Future<bool> moveNext() {
    var subscription = _subscription;
    if (subscription != null) {
      if (_hasValue) {
        var future = new _Future<bool>();
        _stateData = future;
        _hasValue = false;
        subscription.resume();
        return future;
      }
      throw new StateError("Already waiting for next.");
    }
    return _initializeOrDone();
  }

  /// Called if there is no active subscription when [moveNext] is called.
  ///
  /// Either starts listening on the stream if this is the first call to
  /// [moveNext], or returns a `false` future because the stream has already
  /// ended.
  Future<bool> _initializeOrDone() {
    assert(_subscription == null);
    var stateData = _stateData;
    if (stateData != null) {
      Stream<T> stream = stateData as dynamic;
      var future = new _Future<bool>();
      _stateData = future;
      // The `listen` call may invoke user code, and it might try to emit
      // events.
      // We ignore data events during `listen`, but error or done events
      // are used to asynchronously complete the future and set `_stateData`
      // to null.
      // This ensures that we do no other user-code callbacks during `listen`
      // than the `onListen` itself. If that code manages to call `moveNext`
      // again on this iterator, then we will get here and fail when the
      // `_stateData` is a future instead of a stream.
      var subscription = stream.listen(_onData,
          onError: _onError, onDone: _onDone, cancelOnError: true);
      if (_stateData != null) {
        _subscription = subscription;
      }
      return future;
    }
    return Future._falseFuture;
  }

  Future cancel() {
    var subscription = _subscription;
    var stateData = _stateData;
    _stateData = null;
    if (subscription != null) {
      _subscription = null;
      if (!_hasValue) {
        _Future<bool> future = stateData as dynamic;
        future._asyncComplete(false);
      } else {
        _hasValue = false;
      }
      return subscription.cancel();
    }
    return Future._nullFuture;
  }

  void _onData(T data) {
    // Ignore events sent during the `listen` call
    // (which can happen if misusing synchronous broadcast stream controllers),
    // or after `cancel` or `done` (for *really* misbehaving streams).
    if (_subscription == null) return;
    _Future<bool> moveNextFuture = _stateData as dynamic;
    _stateData = data;
    _hasValue = true;
    moveNextFuture._complete(true);
    if (_hasValue) _subscription?.pause();
  }

  void _onError(Object error, StackTrace stackTrace) {
    var subscription = _subscription;
    _Future<bool> moveNextFuture = _stateData as dynamic;
    _subscription = null;
    _stateData = null;
    if (subscription != null) {
      moveNextFuture._completeError(error, stackTrace);
    } else {
      // Event delivered during `listen` call.
      moveNextFuture._asyncCompleteError(error, stackTrace);
    }
  }

  void _onDone() {
    var subscription = _subscription;
    _Future<bool> moveNextFuture = _stateData as dynamic;
    _subscription = null;
    _stateData = null;
    if (subscription != null) {
      moveNextFuture._completeWithValue(false);
    } else {
      // Event delivered during `listen` call.
      moveNextFuture._asyncCompleteWithValue(false);
    }
  }
}

/// An empty broadcast stream, sending a done event as soon as possible.
class _EmptyStream<T> extends Stream<T> {
  const _EmptyStream({bool broadcast = true}) : isBroadcast = broadcast;
  final bool isBroadcast;
  StreamSubscription<T> listen(void Function(T data)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _DoneStreamSubscription<T>(onDone);
  }
}

/// A stream which creates a new controller for each listener.
class _MultiStream<T> extends Stream<T> {
  final bool isBroadcast;

  /// The callback called for each listen.
  final void Function(MultiStreamController<T>) _onListen;

  _MultiStream(this._onListen, this.isBroadcast);

  StreamSubscription<T> listen(void onData(T event)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    var controller = _MultiStreamController<T>();
    controller.onListen = () {
      _onListen(controller);
    };
    return controller._subscribe(
        onData, onError, onDone, cancelOnError ?? false);
  }
}

class _MultiStreamController<T> extends _AsyncStreamController<T>
    implements MultiStreamController<T> {
  _MultiStreamController() : super(null, null, null, null);

  void addSync(T data) {
    if (!_mayAddEvent) throw _badEventState();
    if (hasListener) _subscription._add(data);
  }

  void addErrorSync(Object error, [StackTrace? stackTrace]) {
    if (!_mayAddEvent) throw _badEventState();
    if (hasListener) {
      _subscription._addError(error, stackTrace ?? StackTrace.empty);
    }
  }

  void closeSync() {
    if (isClosed) return;
    if (!_mayAddEvent) throw _badEventState();
    _state |= _StreamController._STATE_CLOSED;
    if (hasListener) _subscription._close();
  }

  Stream<T> get stream {
    throw UnsupportedError("Not available");
  }
}
