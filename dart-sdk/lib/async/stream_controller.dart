// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

// -------------------------------------------------------------------
// Controller for creating and adding events to a stream.
// -------------------------------------------------------------------

/// Type of a stream controller's `onListen`, `onPause` and `onResume`
/// callbacks.
typedef ControllerCallback = void Function();

/// Type of stream controller `onCancel` callbacks.
typedef ControllerCancelCallback = FutureOr<void> Function();

/// A controller with the stream it controls.
///
/// This controller allows sending data, error and done events on
/// its [stream].
///
/// This class can be used to create a simple stream that others
/// can listen on, and to push events to that stream.
///
/// It's possible to check whether the stream is paused or not, and whether
/// it has subscribers or not, as well as getting a callback when either of
/// these change.
///
/// Example:
/// ```dart
/// final streamController = StreamController(
///   onPause: () => print('Paused'),
///   onResume: () => print('Resumed'),
///   onCancel: () => print('Cancelled'),
///   onListen: () => print('Listens'),
/// );
///
/// streamController.stream.listen(
///   (event) => print('Event: $event'),
///   onDone: () => print('Done'),
///   onError: (error) => print(error),
/// );
/// ```
/// To check whether there is a subscriber on the stream, use [hasListener].
/// ```dart continued
/// var hasListener = streamController.hasListener; // true
/// ```
/// To send data events to the stream, use [add] or [addStream].
/// ```dart continued
/// streamController.add(999);
/// final stream = Stream<int>.periodic(
///     const Duration(milliseconds: 200), (count) => count * count).take(4);
/// await streamController.addStream(stream);
/// ```
/// To send an error event to the stream, use [addError] or [addStream].
/// ```dart continued
/// streamController.addError(Exception('Issue 101'));
/// await streamController.addStream(Stream.error(Exception('Issue 404')));
/// ```
/// To check whether the stream is closed, use [isClosed].
/// ```dart continued
/// var isClosed = streamController.isClosed; // false
/// ```
/// To close the stream, use [close].
/// ```dart continued
/// await streamController.close();
/// isClosed = streamController.isClosed; // true
/// ```
abstract interface class StreamController<T> implements StreamSink<T> {
  /// The stream that this controller is controlling.
  Stream<T> get stream;

  /// A controller with a [stream] that supports only one single subscriber.
  ///
  /// If [sync] is true, the returned stream controller is a
  /// [SynchronousStreamController], and must be used with the care
  /// and attention necessary to not break the [Stream] contract. If in doubt,
  /// use the non-sync version.
  ///
  /// Using an asynchronous controller will never give the wrong
  /// behavior, but using a synchronous controller incorrectly can cause
  /// otherwise correct programs to break.
  ///
  /// A synchronous controller is only intended for optimizing event
  /// propagation when one asynchronous event immediately triggers another.
  /// It should not be used unless the calls to [add] or [addError]
  /// are guaranteed to occur in places where it won't break `Stream` invariants.
  ///
  /// Use synchronous controllers only to forward (potentially transformed)
  /// events from another stream or a future.
  ///
  /// A Stream should be inert until a subscriber starts listening on it (using
  /// the [onListen] callback to start producing events). Streams should not
  /// leak resources (like websockets) when no user ever listens on the stream.
  ///
  /// The controller buffers all incoming events until a subscriber is
  /// registered, but this feature should only be used in rare circumstances.
  ///
  /// The [onPause] function is called when the stream becomes
  /// paused. [onResume] is called when the stream resumed.
  ///
  /// The [onListen] callback is called when the stream
  /// receives its listener and [onCancel] when the listener ends
  /// its subscription. If [onCancel] needs to perform an asynchronous operation,
  /// [onCancel] should return a future that completes when the cancel operation
  /// is done.
  ///
  /// If the stream is canceled before the controller needs data the
  /// [onResume] call might not be executed.
  factory StreamController(
      {void onListen()?,
      void onPause()?,
      void onResume()?,
      FutureOr<void> onCancel()?,
      bool sync = false}) {
    return sync
        ? _SyncStreamController<T>(onListen, onPause, onResume, onCancel)
        : _AsyncStreamController<T>(onListen, onPause, onResume, onCancel);
  }

  /// A controller where [stream] can be listened to more than once.
  ///
  /// The [Stream] returned by [stream] is a broadcast stream.
  /// It can be listened to more than once.
  ///
  /// A Stream should be inert until a subscriber starts listening on it (using
  /// the [onListen] callback to start producing events). Streams should not
  /// leak resources (like websockets) when no user ever listens on the stream.
  ///
  /// Broadcast streams do not buffer events when there is no listener.
  ///
  /// The controller distributes any events to all currently subscribed
  /// listeners at the time when [add], [addError] or [close] is called.
  /// It is not allowed to call `add`, `addError`, or `close` before a previous
  /// call has returned. The controller does not have any internal queue of
  /// events, and if there are no listeners at the time the event or error is
  /// added, it will just be dropped.
  ///
  /// Each listener subscription is handled independently,
  /// and if one pauses, only the pausing listener is affected.
  /// A paused listener will buffer events internally until unpaused or canceled.
  ///
  /// If [sync] is true, events may be fired directly by the stream's
  /// subscriptions during an [add], [addError] or [close] call.
  /// The returned stream controller is a [SynchronousStreamController],
  /// and must be used with the care and attention necessary to not break
  /// the [Stream] contract.
  /// See [Completer.sync] for some explanations on when a synchronous
  /// dispatching can be used.
  /// If in doubt, keep the controller non-sync.
  ///
  /// If [sync] is false, the event will always be fired at a later time,
  /// after the code adding the event has completed.
  /// In that case, no guarantees are given with regard to when
  /// multiple listeners get the events, except that each listener will get
  /// all events in the correct order. Each subscription handles the events
  /// individually.
  /// If two events are sent on an async controller with two listeners,
  /// one of the listeners may get both events
  /// before the other listener gets any.
  /// A listener must be subscribed both when the event is initiated
  /// (that is, when [add] is called)
  /// and when the event is later delivered,
  /// in order to receive the event.
  ///
  /// The [onListen] callback is called when the first listener is subscribed,
  /// and the [onCancel] is called when there are no longer any active listeners.
  /// If a listener is added again later, after the [onCancel] was called,
  /// the [onListen] will be called again.
  factory StreamController.broadcast(
      {void onListen()?, void onCancel()?, bool sync = false}) {
    return sync
        ? _SyncBroadcastStreamController<T>(onListen, onCancel)
        : _AsyncBroadcastStreamController<T>(onListen, onCancel);
  }

  /// The callback which is called when the stream is listened to.
  ///
  /// May be set to `null`, in which case no callback will happen.
  abstract void Function()? onListen;

  /// The callback which is called when the stream is paused.
  ///
  /// May be set to `null`, in which case no callback will happen.
  ///
  /// Pause related callbacks are not supported on broadcast stream controllers.
  abstract void Function()? onPause;

  /// The callback which is called when the stream is resumed.
  ///
  /// May be set to `null`, in which case no callback will happen.
  ///
  /// Pause related callbacks are not supported on broadcast stream controllers.
  abstract void Function()? onResume;

  /// The callback which is called when the stream is canceled.
  ///
  /// May be set to `null`, in which case no callback will happen.
  abstract FutureOr<void> Function()? onCancel;

  /// Returns a view of this object that only exposes the [StreamSink] interface.
  StreamSink<T> get sink;

  /// Whether the stream controller is closed for adding more events.
  ///
  /// The controller becomes closed by calling the [close] method.
  /// New events cannot be added, by calling [add] or [addError],
  /// to a closed controller.
  ///
  /// If the controller is closed,
  /// the "done" event might not have been delivered yet,
  /// but it has been scheduled, and it is too late to add more events.
  bool get isClosed;

  /// Whether the subscription would need to buffer events.
  ///
  /// This is the case if the controller's stream has a listener and it is
  /// paused, or if it has not received a listener yet. In that case, the
  /// controller is considered paused as well.
  ///
  /// A broadcast stream controller is never considered paused. It always
  /// forwards its events to all uncanceled subscriptions, if any,
  /// and let the subscriptions handle their own pausing and buffering.
  bool get isPaused;

  /// Whether there is a subscriber on the [Stream].
  bool get hasListener;

  /// Sends a data [event].
  ///
  /// Listeners receive this event in a later microtask.
  ///
  /// Note that a synchronous controller (created by passing true to the `sync`
  /// parameter of the `StreamController` constructor) delivers events
  /// immediately. Since this behavior violates the contract mentioned here,
  /// synchronous controllers should only be used as described in the
  /// documentation to ensure that the delivered events always *appear* as if
  /// they were delivered in a separate microtask.
  void add(T event);

  /// Sends or enqueues an error event.
  ///
  /// Listeners receive this event at a later microtask. This behavior can be
  /// overridden by using `sync` controllers. Note, however, that sync
  /// controllers have to satisfy the preconditions mentioned in the
  /// documentation of the constructors.
  void addError(Object error, [StackTrace? stackTrace]);

  /// Closes the stream.
  ///
  /// No further events can be added to a closed stream.
  ///
  /// The returned future is the same future provided by [done].
  /// It is completed when the stream listeners is done sending events,
  /// This happens either when the done event has been sent,
  /// or when the subscriber on a single-subscription stream is canceled.
  ///
  /// A stream controller will not complete the returned future until all
  /// listeners present when the done event is sent have stopped listening.
  /// A listener will stop listening if it is cancelled, or if it has handled
  /// the done event.
  /// A paused listener will not process the done even until it is resumed, so
  /// completion of the returned Future will be delayed until all paused
  /// listeners have been resumed or cancelled.
  ///
  /// If no one listens to a non-broadcast stream,
  /// or the listener pauses and never resumes,
  /// the done event will not be sent and this future will never complete.
  Future close();

  /// A future which is completed when the stream controller is done
  /// sending events.
  ///
  /// This happens either when the done event has been sent, or if the
  /// subscriber on a single-subscription stream is canceled.
  ///
  /// A stream controller will not complete the returned future until all
  /// listeners present when the done event is sent have stopped listening.
  /// A listener will stop listening if it is cancelled, or if it has handled
  /// the done event.
  /// A paused listener will not process the done even until it is resumed, so
  /// completion of the returned Future will be delayed until all paused
  /// listeners have been resumed or cancelled.
  ///
  /// If there is no listener on a non-broadcast stream,
  /// or the listener pauses and never resumes,
  /// the done event will not be sent and this future will never complete.
  Future get done;

  /// Receives events from [source] and puts them into this controller's stream.
  ///
  /// Returns a future which completes when the source stream is done.
  ///
  /// Events must not be added directly to this controller using [add],
  /// [addError], [close] or [addStream], until the returned future
  /// is complete.
  ///
  /// Data and error events are forwarded to this controller's stream. A done
  /// event on the source will end the `addStream` operation and complete the
  /// returned future.
  ///
  /// If [cancelOnError] is `true`, only the first error on [source] is
  /// forwarded to the controller's stream, and the `addStream` ends
  /// after this. If [cancelOnError] is false, all errors are forwarded
  /// and only a done event will end the `addStream`.
  /// If [cancelOnError] is omitted or `null`, it defaults to `false`.
  Future addStream(Stream<T> source, {bool? cancelOnError});
}

/// A stream controller that delivers its events synchronously.
///
/// A synchronous stream controller is intended for cases where
/// an already asynchronous event triggers an event on a stream.
///
/// Instead of adding the event to the stream in a later microtask,
/// causing extra latency, the event is instead fired immediately by the
/// synchronous stream controller, as if the stream event was
/// the current event or microtask.
///
/// The synchronous stream controller can be used to break the contract
/// on [Stream], and it must be used carefully to avoid doing so.
///
/// The only advantage to using a [SynchronousStreamController] over a
/// normal [StreamController] is the improved latency.
/// Only use the synchronous version if the improvement is significant,
/// and if its use is safe. Otherwise just use a normal stream controller,
/// which will always have the correct behavior for a [Stream], and won't
/// accidentally break other code.
///
/// Adding events to a synchronous controller should only happen as the
/// very last part of the handling of the original event.
/// At that point, adding an event to the stream is equivalent to
/// returning to the event loop and adding the event in the next microtask.
///
/// Each listener callback will be run as if it was a top-level event
/// or microtask. This means that if it throws, the error will be reported as
/// uncaught as soon as possible.
/// This is one reason to add the event as the last thing in the original event
/// handler – any action done after adding the event will delay the report of
/// errors in the event listener callbacks.
///
/// If an event is added in a setting that isn't known to be another event,
/// it may cause the stream's listener to get that event before the listener
/// is ready to handle it. We promise that after calling [Stream.listen],
/// you won't get any events until the code doing the listen has completed.
/// Calling [add] in response to a function call of unknown origin may break
/// that promise.
///
/// An [onListen] callback from the controller is *not* an asynchronous event,
/// and adding events to the controller in the `onListen` callback is always
/// wrong. The events will be delivered before the listener has even received
/// the subscription yet.
///
/// The synchronous broadcast stream controller also has a restrictions that a
/// normal stream controller does not:
/// The [add], [addError], [close] and [addStream] methods *must not* be
/// called while an event is being delivered.
/// That is, if a callback on a subscription on the controller's stream causes
/// a call to any of the functions above, the call will fail.
/// A broadcast stream may have more than one listener, and if an
/// event is added synchronously while another is being also in the process
/// of being added, the latter event might reach some listeners before
/// the former. To prevent that, an event cannot be added while a previous
/// event is being fired.
/// This guarantees that an event is fully delivered when the
/// first [add], [addError] or [close] returns,
/// and further events will be delivered in the correct order.
///
/// This still only guarantees that the event is delivered to the subscription.
/// If the subscription is paused, the actual callback may still happen later,
/// and the event will instead be buffered by the subscription.
/// Barring pausing, and the following buffered events that haven't been
/// delivered yet, callbacks will be called synchronously when an event is added.
///
/// Adding an event to a synchronous non-broadcast stream controller while
/// another event is in progress may cause the second event to be delayed
/// and not be delivered synchronously, and until that event is delivered,
/// the controller will not act synchronously.
abstract interface class SynchronousStreamController<T>
    implements StreamController<T> {
  /// Adds event to the controller's stream.
  ///
  /// As [StreamController.add], but must not be called while an event is
  /// being added by [add], [addError] or [close].
  void add(T data);

  /// Adds error to the controller's stream.
  ///
  /// As [StreamController.addError], but must not be called while an event is
  /// being added by [add], [addError] or [close].
  void addError(Object error, [StackTrace? stackTrace]);

  /// Closes the controller's stream.
  ///
  /// As [StreamController.close], but must not be called while an event is
  /// being added by [add], [addError] or [close].
  Future close();
}

abstract class _StreamControllerLifecycle<T> {
  StreamSubscription<T> _subscribe(void onData(T data)?, Function? onError,
      void onDone()?, bool cancelOnError);
  void _recordPause(StreamSubscription<T> subscription) {}
  void _recordResume(StreamSubscription<T> subscription) {}
  Future<void>? _recordCancel(StreamSubscription<T> subscription) => null;
}

// Base type for implementations of stream controllers.
abstract class _StreamControllerBase<T>
    implements
        StreamController<T>,
        _StreamControllerLifecycle<T>,
        _EventSink<T>,
        _EventDispatch<T> {}

/// Default implementation of [StreamController].
///
/// Controls a stream that only supports a single controller.
abstract class _StreamController<T> implements _StreamControllerBase<T> {
  // The states are bit-flags. More than one can be set at a time.
  //
  // The "subscription state" goes through the states:
  //   initial -> subscribed -> canceled.
  // These are mutually exclusive.
  // The "closed" state records whether the [close] method has been called
  // on the controller. This can be done at any time. If done before
  // subscription, the done event is queued. If done after cancel, the done
  // event is ignored (just as any other event after a cancel).

  /// The controller is in its initial state with no subscription.
  static const int _STATE_INITIAL = 0;

  /// The controller has a subscription, but hasn't been closed or canceled.
  ///
  /// Keep in sync with
  /// runtime/vm/stack_trace.cc:kStreamController_StateSubscribed.
  static const int _STATE_SUBSCRIBED = 1;

  /// The subscription is canceled.
  static const int _STATE_CANCELED = 2;

  /// Mask for the subscription state.
  static const int _STATE_SUBSCRIPTION_MASK = 3;

  // The following state relate to the controller, not the subscription.
  // If closed, adding more events is not allowed.
  // If executing an [addStream], new events are not allowed either, but will
  // be added by the stream.

  /// The controller is closed due to calling [close].
  ///
  /// When the stream is closed, you can neither add new events nor add new
  /// listeners.
  static const int _STATE_CLOSED = 4;

  /// The controller is in the middle of an [addStream] operation.
  ///
  /// While adding events from a stream, no new events can be added directly
  /// on the controller.
  static const int _STATE_ADDSTREAM = 8;

  /// Field containing different data depending on the current subscription
  /// state.
  ///
  /// If [_state] is [_STATE_INITIAL], the field may contain a [_PendingEvents]
  /// for events added to the controller before a subscription.
  ///
  /// While [_state] is [_STATE_SUBSCRIBED], the field contains the subscription.
  ///
  /// When [_state] is [_STATE_CANCELED] the field is currently not used,
  /// and will contain `null`.
  @pragma("vm:entry-point")
  Object? _varData;

  /// Current state of the controller.
  @pragma("vm:entry-point")
  int _state = _STATE_INITIAL;

  /// Future completed when the stream sends its last event.
  ///
  /// This is also the future returned by [close].
  // TODO(lrn): Could this be stored in the varData field too, if it's not
  // accessed until the call to "close"? Then we need to special case if it's
  // accessed earlier, or if close is called before subscribing.
  _Future<void>? _doneFuture;

  void Function()? onListen;
  void Function()? onPause;
  void Function()? onResume;
  FutureOr<void> Function()? onCancel;

  _StreamController(this.onListen, this.onPause, this.onResume, this.onCancel);

  // Return a new stream every time. The streams are equal, but not identical.
  Stream<T> get stream => _ControllerStream<T>(this);

  /// Returns a view of this object that only exposes the [StreamSink] interface.
  StreamSink<T> get sink => _StreamSinkWrapper<T>(this);

  /// Whether a listener has existed and been canceled.
  ///
  /// After this, adding more events will be ignored.
  bool get _isCanceled => (_state & _STATE_CANCELED) != 0;

  /// Whether there is an active listener.
  bool get hasListener => (_state & _STATE_SUBSCRIBED) != 0;

  /// Whether there has not been a listener yet.
  bool get _isInitialState =>
      (_state & _STATE_SUBSCRIPTION_MASK) == _STATE_INITIAL;

  bool get isClosed => (_state & _STATE_CLOSED) != 0;

  bool get isPaused =>
      hasListener ? _subscription._isInputPaused : !_isCanceled;

  bool get _isAddingStream => (_state & _STATE_ADDSTREAM) != 0;

  /// New events may not be added after close, or during addStream.
  bool get _mayAddEvent => (_state < _STATE_CLOSED);

  // Returns the pending events.
  // Pending events are events added before a subscription exists.
  // They are added to the subscription when it is created.
  // Pending events, if any, are kept in the _varData field until the
  // stream is listened to.
  // While adding a stream, pending events are moved into the
  // state object to allow the state object to use the _varData field.
  _PendingEvents<T>? get _pendingEvents {
    assert(_isInitialState);
    if (!_isAddingStream) {
      return _varData as dynamic;
    }
    _StreamControllerAddStreamState<T> state = _varData as dynamic;
    return state._varData;
  }

  // Returns the pending events, and creates the object if necessary.
  _PendingEvents<T> _ensurePendingEvents() {
    assert(_isInitialState);
    if (!_isAddingStream) {
      Object? events = _varData;
      if (events == null) {
        _varData = events = _PendingEvents<T>();
      }
      return events as dynamic;
    }
    _StreamControllerAddStreamState<T> state = _varData as dynamic;
    Object? events = state._varData;
    if (events == null) {
      state._varData = events = _PendingEvents<T>();
    }
    return events as dynamic;
  }

  // Get the current subscription.
  // If we are adding a stream, the subscription is moved into the state
  // object to allow the state object to use the _varData field.
  _ControllerSubscription<T> get _subscription {
    assert(hasListener);
    Object? varData = _varData;
    if (_isAddingStream) {
      _StreamControllerAddStreamState<Object?> streamState = varData as dynamic;
      varData = streamState._varData;
    }
    return varData as dynamic;
  }

  /// Creates an error describing why an event cannot be added.
  ///
  /// The reason, and therefore the error message, depends on the current state.
  Error _badEventState() {
    if (isClosed) {
      return StateError("Cannot add event after closing");
    }
    assert(_isAddingStream);
    return StateError("Cannot add event while adding a stream");
  }

  // StreamSink interface.
  Future addStream(Stream<T> source, {bool? cancelOnError}) {
    if (!_mayAddEvent) throw _badEventState();
    if (_isCanceled) return _Future.immediate(null);
    _StreamControllerAddStreamState<T> addState =
        _StreamControllerAddStreamState<T>(
            this, _varData, source, cancelOnError ?? false);
    _varData = addState;
    _state |= _STATE_ADDSTREAM;
    return addState.addStreamFuture;
  }

  /// Returns a future that is completed when the stream is done
  /// processing events.
  ///
  /// This happens either when the done event has been sent, or if the
  /// subscriber of a single-subscription stream is cancelled.
  Future<void> get done => _ensureDoneFuture();

  Future<void> _ensureDoneFuture() =>
      _doneFuture ??= _isCanceled ? Future._nullFuture : _Future<void>();

  /// Send or enqueue a data event.
  void add(T value) {
    if (!_mayAddEvent) throw _badEventState();
    _add(value);
  }

  /// Send or enqueue an error event.
  void addError(Object error, [StackTrace? stackTrace]) {
    checkNotNullable(error, "error");
    if (!_mayAddEvent) throw _badEventState();
    AsyncError? replacement = Zone.current.errorCallback(error, stackTrace);
    if (replacement != null) {
      error = replacement.error;
      stackTrace = replacement.stackTrace;
    } else {
      stackTrace ??= AsyncError.defaultStackTrace(error);
    }
    _addError(error, stackTrace);
  }

  /// Closes this controller and sends a done event on the stream.
  ///
  /// The first time a controller is closed, a "done" event is added to its
  /// stream.
  ///
  /// You are allowed to close the controller more than once, but only the first
  /// call has any effect.
  ///
  /// After closing, no further events may be added using [add], [addError]
  /// or [addStream].
  ///
  /// The returned future is completed when the done event has been delivered.
  Future close() {
    if (isClosed) {
      return _ensureDoneFuture();
    }
    if (!_mayAddEvent) throw _badEventState();
    _closeUnchecked();
    return _ensureDoneFuture();
  }

  void _closeUnchecked() {
    _state |= _STATE_CLOSED;
    if (hasListener) {
      _sendDone();
    } else if (_isInitialState) {
      _ensurePendingEvents().add(const _DelayedDone());
    }
  }

  // EventSink interface. Used by the [addStream] events.

  // Add data event, used both by the [addStream] events and by [add].
  void _add(T value) {
    if (hasListener) {
      _sendData(value);
    } else if (_isInitialState) {
      _ensurePendingEvents().add(_DelayedData<T>(value));
    }
  }

  void _addError(Object error, StackTrace stackTrace) {
    if (hasListener) {
      _sendError(error, stackTrace);
    } else if (_isInitialState) {
      _ensurePendingEvents().add(_DelayedError(error, stackTrace));
    }
  }

  void _close() {
    // End of addStream stream.
    assert(_isAddingStream);
    _StreamControllerAddStreamState<T> addState = _varData as dynamic;
    _varData = addState._varData;
    _state &= ~_STATE_ADDSTREAM;
    addState.complete();
  }

  // _StreamControllerLifeCycle interface

  StreamSubscription<T> _subscribe(void onData(T data)?, Function? onError,
      void onDone()?, bool cancelOnError) {
    if (!_isInitialState) {
      throw StateError("Stream has already been listened to.");
    }
    _ControllerSubscription<T> subscription = _ControllerSubscription<T>(
        this, onData, onError, onDone, cancelOnError);

    _PendingEvents<T>? pendingEvents = _pendingEvents;
    _state |= _STATE_SUBSCRIBED;
    if (_isAddingStream) {
      _StreamControllerAddStreamState<T> addState = _varData as dynamic;
      addState._varData = subscription;
      addState.resume();
    } else {
      _varData = subscription;
    }
    subscription._setPendingEvents(pendingEvents);
    subscription._guardCallback(() {
      _runGuarded(onListen);
    });

    return subscription;
  }

  Future<void>? _recordCancel(StreamSubscription<T> subscription) {
    // When we cancel, we first cancel any stream being added,
    // Then we call `onCancel`, and finally the _doneFuture is completed.
    // If either of addStream's cancel or `onCancel` returns a future,
    // we wait for it before continuing.
    // Any error during this process ends up in the returned future.
    // If more errors happen, we act as if it happens inside nested try/finally
    // blocks or whenComplete calls, and only the last error ends up in the
    // returned future.
    Future<void>? result;
    if (_isAddingStream) {
      _StreamControllerAddStreamState<T> addState = _varData as dynamic;
      result = addState.cancel();
    }
    _varData = null;
    _state =
        (_state & ~(_STATE_SUBSCRIBED | _STATE_ADDSTREAM)) | _STATE_CANCELED;

    var onCancel = this.onCancel;
    if (onCancel != null) {
      if (result == null) {
        // Only introduce a future if one is needed.
        // If _onCancel returns null, no future is needed.
        try {
          var cancelResult = onCancel();
          if (cancelResult is Future<void>) {
            result = cancelResult;
          }
        } catch (e, s) {
          // Return the error in the returned future.
          // Complete it asynchronously, so there is time for a listener
          // to handle the error.
          result = _Future().._asyncCompleteError(e, s);
        }
      } else {
        // Simpler case when we already know that we will return a future.
        result = result.whenComplete(onCancel);
      }
    }

    void complete() {
      var doneFuture = _doneFuture;
      if (doneFuture != null && doneFuture._mayComplete) {
        doneFuture._asyncComplete(null);
      }
    }

    if (result != null) {
      result = result.whenComplete(complete);
    } else {
      complete();
    }

    return result;
  }

  void _recordPause(StreamSubscription<T> subscription) {
    if (_isAddingStream) {
      _StreamControllerAddStreamState<T> addState = _varData as dynamic;
      addState.pause();
    }
    _runGuarded(onPause);
  }

  void _recordResume(StreamSubscription<T> subscription) {
    if (_isAddingStream) {
      _StreamControllerAddStreamState<T> addState = _varData as dynamic;
      addState.resume();
    }
    _runGuarded(onResume);
  }
}

mixin _SyncStreamControllerDispatch<T>
    implements _StreamController<T>, SynchronousStreamController<T> {
  void _sendData(T data) {
    _subscription._add(data);
  }

  void _sendError(Object error, StackTrace stackTrace) {
    _subscription._addError(error, stackTrace);
  }

  void _sendDone() {
    _subscription._close();
  }
}

mixin _AsyncStreamControllerDispatch<T> implements _StreamController<T> {
  void _sendData(T data) {
    _subscription._addPending(_DelayedData<T>(data));
  }

  void _sendError(Object error, StackTrace stackTrace) {
    _subscription._addPending(_DelayedError(error, stackTrace));
  }

  void _sendDone() {
    _subscription._addPending(const _DelayedDone());
  }
}

// TODO(lrn): Use common superclass for callback-controllers when VM supports
// constructors in mixin superclasses.

@pragma("vm:entry-point")
class _AsyncStreamController<T> = _StreamController<T>
    with _AsyncStreamControllerDispatch<T>;

@pragma("vm:entry-point")
class _SyncStreamController<T> = _StreamController<T>
    with _SyncStreamControllerDispatch<T>;

void _runGuarded(void Function()? notificationHandler) {
  if (notificationHandler == null) return;
  try {
    notificationHandler();
  } catch (e, s) {
    Zone.current.handleUncaughtError(e, s);
  }
}

class _ControllerStream<T> extends _StreamImpl<T> {
  _StreamControllerLifecycle<T> _controller;

  _ControllerStream(this._controller);

  StreamSubscription<T> _createSubscription(void onData(T data)?,
          Function? onError, void onDone()?, bool cancelOnError) =>
      _controller._subscribe(onData, onError, onDone, cancelOnError);

  // Override == and hashCode so that new streams returned by the same
  // controller are considered equal. The controller returns a new stream
  // each time it's queried, but doesn't have to cache the result.

  int get hashCode => _controller.hashCode ^ 0x35323532;

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ControllerStream &&
        identical(other._controller, this._controller);
  }
}

class _ControllerSubscription<T> extends _BufferingStreamSubscription<T> {
  final _StreamControllerLifecycle<T> _controller;

  _ControllerSubscription(this._controller, void onData(T data)?,
      Function? onError, void onDone()?, bool cancelOnError)
      : super(onData, onError, onDone, cancelOnError);

  Future<void>? _onCancel() {
    return _controller._recordCancel(this);
  }

  void _onPause() {
    _controller._recordPause(this);
  }

  void _onResume() {
    _controller._recordResume(this);
  }
}

/// A class that exposes only the [StreamSink] interface of an object.
class _StreamSinkWrapper<T> implements StreamSink<T> {
  final StreamController _target;
  _StreamSinkWrapper(this._target);
  void add(T data) {
    _target.add(data);
  }

  void addError(Object error, [StackTrace? stackTrace]) {
    _target.addError(error, stackTrace);
  }

  Future close() => _target.close();

  Future addStream(Stream<T> source) => _target.addStream(source);

  Future get done => _target.done;
}

/// Object containing the state used to handle [StreamController.addStream].
class _AddStreamState<T> {
  // [_Future] returned by call to addStream.
  @pragma('vm:entry-point')
  final _Future addStreamFuture;

  // Subscription on stream argument to addStream.
  final StreamSubscription addSubscription;

  _AddStreamState(
      _EventSink<T> controller, Stream<T> source, bool cancelOnError)
      : addStreamFuture = _Future(),
        addSubscription = source.listen(controller._add,
            onError: cancelOnError
                ? makeErrorHandler(controller)
                : controller._addError,
            onDone: controller._close,
            cancelOnError: cancelOnError);

  static makeErrorHandler(_EventSink controller) => (Object e, StackTrace s) {
        controller._addError(e, s);
        controller._close();
      };

  void pause() {
    addSubscription.pause();
  }

  void resume() {
    addSubscription.resume();
  }

  /// Stop adding the stream.
  ///
  /// Complete the future returned by `StreamController.addStream` when
  /// the cancel is complete.
  ///
  /// Return a future if the cancel takes time, otherwise return `null`.
  Future<void> cancel() {
    var cancel = addSubscription.cancel();
    if (cancel == null) {
      addStreamFuture._asyncComplete(null);
      return Future._nullFuture;
    }
    return cancel.whenComplete(() {
      addStreamFuture._asyncComplete(null);
    });
  }

  void complete() {
    addStreamFuture._asyncComplete(null);
  }
}

class _StreamControllerAddStreamState<T> extends _AddStreamState<T> {
  // The subscription or pending data of a _StreamController.
  // Stored here because we reuse the `_varData` field  in the _StreamController
  // to store this state object.
  @pragma('vm:entry-point')
  var _varData;

  _StreamControllerAddStreamState(_StreamController<T> controller,
      this._varData, Stream<T> source, bool cancelOnError)
      : super(controller, source, cancelOnError) {
    if (controller.isPaused) {
      addSubscription.pause();
    }
  }
}
