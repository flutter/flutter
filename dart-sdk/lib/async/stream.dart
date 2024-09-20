// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

// -------------------------------------------------------------------
// Core Stream types
// -------------------------------------------------------------------

typedef void _TimerCallback();

/// A source of asynchronous data events.
///
/// A Stream provides a way to receive a sequence of events.
/// Each event is either a data event, also called an *element* of the stream,
/// or an error event, which is a notification that something has failed.
/// When a stream has emitted all its events,
/// a single "done" event notifies the listener that the end has been reached.
///
/// You produce a stream by calling an `async*` function, which then returns
/// a stream. Consuming that stream will lead the function to emit events
/// until it ends, and the stream closes.
/// You consume a stream either using an `await for` loop, which is available
/// inside an `async` or `async*` function, or by forwarding its events directly
/// using `yield*` inside an `async*` function.
/// Example:
/// ```dart
/// Stream<T> optionalMap<T>(
///     Stream<T> source , [T Function(T)? convert]) async* {
///   if (convert == null) {
///     yield* source;
///   } else {
///     await for (var event in source) {
///       yield convert(event);
///     }
///   }
/// }
/// ```
/// When this function is called, it immediately returns a `Stream<T>` object.
/// Then nothing further happens until someone tries to consume that stream.
/// At that point, the body of the `async*` function starts running.
/// If the `convert` function was omitted, the `yield*` will listen to the
/// `source` stream and forward all events, date and errors, to the returned
/// stream. When the `source` stream closes, the `yield*` is done,
/// and the `optionalMap` function body ends too. This closes the returned
/// stream.
/// If a `convert` *is* supplied, the function instead listens on the source
/// stream and enters an `await for` loop which
/// repeatedly waits for the next data event.
/// On a data event, it calls `convert` with the value and emits the result
/// on the returned stream.
/// If no error events are emitted by the `source` stream,
/// the loop ends when the `source` stream does,
/// then the `optionalMap` function body completes,
/// which closes the returned stream.
/// On an error event from the `source` stream,
/// the `await for` re-throws that error, which breaks the loop.
/// The error then reaches the end of the `optionalMap` function body,
/// since it's not caught.
/// That makes the error be emitted on the returned stream, which then closes.
///
/// The `Stream` class also provides functionality which allows you to
/// manually listen for events from a stream, or to convert a stream
/// into another stream or into a future.
///
/// The [forEach] function corresponds to the `await for` loop,
/// just as [Iterable.forEach] corresponds to a normal `for`/`in` loop.
/// Like the loop, it will call a function for each data event and break on an
/// error.
///
/// The more low-level [listen] method is what every other method is based on.
/// You call `listen` on a stream to tell it that you want to receive
/// events, and to register the callbacks which will receive those events.
/// When you call `listen`, you receive a [StreamSubscription] object
/// which is the active object providing the events,
/// and which can be used to stop listening again,
/// or to temporarily pause events from the subscription.
///
/// There are two kinds of streams: "Single-subscription" streams and
/// "broadcast" streams.
///
/// *A single-subscription stream* allows only a single listener during the whole
/// lifetime of the stream.
/// It doesn't start generating events until it has a listener,
/// and it stops sending events when the listener is unsubscribed,
/// even if the source of events could still provide more.
/// The stream created by an `async*` function is a single-subscription stream,
/// but each call to the function creates a new such stream.
///
/// Listening twice on a single-subscription stream is not allowed, even after
/// the first subscription has been canceled.
///
/// Single-subscription streams are generally used for streaming chunks of
/// larger contiguous data, like file I/O.
///
/// *A broadcast stream* allows any number of listeners, and it fires
/// its events when they are ready, whether there are listeners or not.
///
/// Broadcast streams are used for independent events/observers.
///
/// If several listeners want to listen to a single-subscription stream,
/// use [asBroadcastStream] to create a broadcast stream on top of the
/// non-broadcast stream.
///
/// On either kind of stream, stream transformations, such as [where] and
/// [skip], return the same type of stream as the one the method was called on,
/// unless otherwise noted.
///
/// When an event is fired, the listener(s) at that time will receive the event.
/// If a listener is added to a broadcast stream while an event is being fired,
/// that listener will not receive the event currently being fired.
/// If a listener is canceled, it immediately stops receiving events.
/// Listening on a broadcast stream can be treated as listening on a new stream
/// containing only the events that have not yet been emitted when the [listen]
/// call occurs.
/// For example the [first] getter listens to the stream, then returns the first
/// event that listener receives.
/// This is not necessarily the first even emitted by the stream, but the first
/// of the *remaining* events of the broadcast stream.
///
/// When the "done" event is fired, subscribers are unsubscribed before
/// receiving the event. After the event has been sent, the stream has no
/// subscribers. Adding new subscribers to a broadcast stream after this point
/// is allowed, but they will just receive a new "done" event as soon
/// as possible.
///
/// Stream subscriptions always respect "pause" requests. If necessary they need
/// to buffer their input, but often, and preferably they can simply request
/// their input to pause too.
///
/// The default implementation of [isBroadcast] returns false.
/// A broadcast stream inheriting from [Stream] must override [isBroadcast]
/// to return `true` if it wants to signal that it behaves like a broadcast
/// stream.
@vmIsolateUnsendable
abstract mixin class Stream<T> {
  const Stream();

  /// Creates an empty broadcast stream.
  ///
  /// This is a stream which does nothing except sending a done event
  /// when it's listened to.
  ///
  /// Example:
  /// ```dart
  /// const stream = Stream.empty();
  /// stream.listen(
  ///   (value) {
  ///     throw "Unreachable";
  ///   },
  ///   onDone: () {
  ///     print('Done');
  ///   },
  /// );
  /// ```
  ///
  /// The stream defaults to being a broadcast stream,
  /// as reported by [isBroadcast].
  /// This value can be changed by passing `false` as
  /// the [broadcast] parameter, which defaults to `true`.
  ///
  /// The stream can be listened to more than once,
  /// whether it reports itself as broadcast or not.
  const factory Stream.empty({@Since("3.2") bool broadcast}) = _EmptyStream<T>;

  /// Creates a stream which emits a single data event before closing.
  ///
  /// This stream emits a single data event of [value]
  /// and then closes with a done event.
  ///
  /// Example:
  /// ```dart
  /// Future<void> printThings(Stream<String> data) async {
  ///   await for (var x in data) {
  ///     print(x);
  ///   }
  /// }
  /// printThings(Stream<String>.value('ok')); // prints "ok".
  /// ```
  ///
  /// The returned stream is effectively equivalent to one created by
  /// `(() async* { yield value; } ())` or `Future<T>.value(value).asStream()`.
  @Since("2.5")
  factory Stream.value(T value) =>
      (_AsyncStreamController<T>(null, null, null, null)
            .._add(value)
            .._closeUnchecked())
          .stream;

  /// Creates a stream which emits a single error event before completing.
  ///
  /// This stream emits a single error event of [error] and [stackTrace]
  /// and then completes with a done event.
  ///
  /// Example:
  /// ```dart
  /// Future<void> tryThings(Stream<int> data) async {
  ///   try {
  ///     await for (var x in data) {
  ///       print('Data: $x');
  ///     }
  ///   } catch (e) {
  ///     print(e);
  ///   }
  /// }
  /// tryThings(Stream<int>.error('Error')); // prints "Error".
  /// ```
  /// The returned stream is effectively equivalent to one created by
  /// `Future<T>.error(error, stackTrace).asStream()`, by or
  /// `(() async* { throw error; } ())`, except that you can control the
  /// stack trace as well.
  @Since("2.5")
  factory Stream.error(Object error, [StackTrace? stackTrace]) {
    // TODO(40614): Remove once non-nullability is sound.
    checkNotNullable(error, "error");
    return (_AsyncStreamController<T>(null, null, null, null)
          .._addError(error, stackTrace ?? AsyncError.defaultStackTrace(error))
          .._closeUnchecked())
        .stream;
  }

  /// Creates a new single-subscription stream from the future.
  ///
  /// When the future completes, the stream will fire one event, either
  /// data or error, and then close with a done-event.
  ///
  /// Example:
  /// ```dart
  /// Future<String> futureTask() async {
  ///   await Future.delayed(const Duration(seconds: 5));
  ///   return 'Future complete';
  /// }
  ///
  /// final stream = Stream<String>.fromFuture(futureTask());
  /// stream.listen(print,
  ///     onDone: () => print('Done'), onError: print);
  ///
  /// // Outputs:
  /// // "Future complete" after 'futureTask' finished.
  /// // "Done" when stream completed.
  /// ```
  factory Stream.fromFuture(Future<T> future) {
    // Use the controller's buffering to fill in the value even before
    // the stream has a listener. For a single value, it's not worth it
    // to wait for a listener before doing the `then` on the future.
    _StreamController<T> controller =
        new _SyncStreamController<T>(null, null, null, null);
    future.then((value) {
      controller._add(value);
      controller._closeUnchecked();
    }, onError: (error, stackTrace) {
      controller._addError(error, stackTrace);
      controller._closeUnchecked();
    });
    return controller.stream;
  }

  /// Create a single-subscription stream from a group of futures.
  ///
  /// The stream reports the results of the futures on the stream in the order
  /// in which the futures complete.
  /// Each future provides either a data event or an error event,
  /// depending on how the future completes.
  ///
  /// If some futures have already completed when `Stream.fromFutures` is called,
  /// their results will be emitted in some unspecified order.
  ///
  /// When all futures have completed, the stream is closed.
  ///
  /// If [futures] is empty, the stream closes as soon as possible.
  ///
  /// Example:
  /// ```dart
  /// Future<int> waitTask() async {
  ///   await Future.delayed(const Duration(seconds: 2));
  ///   return 10;
  /// }
  ///
  /// Future<String> doneTask() async {
  ///   await Future.delayed(const Duration(seconds: 5));
  ///   return 'Future complete';
  /// }
  ///
  /// final stream = Stream<Object>.fromFutures([doneTask(), waitTask()]);
  /// stream.listen(print, onDone: () => print('Done'), onError: print);
  ///
  /// // Outputs:
  /// // 10 after 'waitTask' finished.
  /// // "Future complete" after 'doneTask' finished.
  /// // "Done" when stream completed.
  /// ```
  factory Stream.fromFutures(Iterable<Future<T>> futures) {
    _StreamController<T> controller =
        new _SyncStreamController<T>(null, null, null, null);
    int count = 0;
    // Declare these as variables holding closures instead of as
    // function declarations.
    // This avoids creating a new closure from the functions for each future.
    void onValue(T value) {
      if (!controller.isClosed) {
        controller._add(value);
        if (--count == 0) controller._closeUnchecked();
      }
    }

    void onError(Object error, StackTrace stack) {
      if (!controller.isClosed) {
        controller._addError(error, stack);
        if (--count == 0) controller._closeUnchecked();
      }
    }

    // The futures are already running, so start listening to them immediately
    // (instead of waiting for the stream to be listened on).
    // If we wait, we might not catch errors in the futures in time.
    for (var future in futures) {
      count++;
      future.then(onValue, onError: onError);
    }
    // Use schedule microtask since controller is sync.
    if (count == 0) scheduleMicrotask(controller.close);
    return controller.stream;
  }

  /// Creates a stream that gets its data from [elements].
  ///
  /// The iterable is iterated when the stream receives a listener, and stops
  /// iterating if the listener cancels the subscription, or if the
  /// [Iterator.moveNext] method returns `false` or throws.
  /// Iteration is suspended while the stream subscription is paused.
  ///
  /// If calling [Iterator.moveNext] on `elements.iterator` throws,
  /// the stream emits that error and then it closes.
  /// If reading [Iterator.current] on `elements.iterator` throws,
  /// the stream emits that error, but keeps iterating.
  ///
  /// Can be listened to more than once. Each listener iterates [elements]
  /// independently.
  ///
  /// Example:
  /// ```dart
  /// final numbers = [1, 2, 3, 5, 6, 7];
  /// final stream = Stream.fromIterable(numbers);
  /// ```
  factory Stream.fromIterable(Iterable<T> elements) =>
      Stream<T>.multi((controller) {
        Iterator<T> iterator;
        try {
          iterator = elements.iterator;
        } catch (e, s) {
          controller.addError(e, s);
          controller.close();
          return;
        }
        var zone = Zone.current;
        var isScheduled = true;

        void next() {
          if (!controller.hasListener || controller.isPaused) {
            // Cancelled or paused since scheduled.
            isScheduled = false;
            return;
          }
          bool hasNext;
          try {
            hasNext = iterator.moveNext();
          } catch (e, s) {
            controller.addErrorSync(e, s);
            controller.closeSync();
            return;
          }
          if (hasNext) {
            try {
              controller.addSync(iterator.current);
            } catch (e, s) {
              controller.addErrorSync(e, s);
            }
            if (controller.hasListener && !controller.isPaused) {
              zone.scheduleMicrotask(next);
            } else {
              isScheduled = false;
            }
          } else {
            controller.closeSync();
          }
        }

        controller.onResume = () {
          if (!isScheduled) {
            isScheduled = true;
            zone.scheduleMicrotask(next);
          }
        };

        zone.scheduleMicrotask(next);
      });

  /// Creates a multi-subscription stream.
  ///
  /// Each time the created stream is listened to,
  /// the [onListen] callback is invoked with a new [MultiStreamController],
  /// which forwards events to the [StreamSubscription]
  /// returned by that [listen] call.
  ///
  /// This allows each listener to be treated as an individual stream.
  ///
  /// The [MultiStreamController] does not support reading its
  /// [StreamController.stream]. Setting its [StreamController.onListen]
  /// has no effect since the [onListen] callback is called instead,
  /// and the [StreamController.onListen] won't be called later.
  /// The controller acts like an asynchronous controller,
  /// but provides extra methods for delivering events synchronously.
  ///
  /// If [isBroadcast] is set to `true`, the returned stream's
  /// [Stream.isBroadcast] will be `true`.
  /// This has no effect on the stream behavior,
  /// it is up to the [onListen] function
  /// to act like a broadcast stream if it claims to be one.
  ///
  /// A multi-subscription stream can behave like any other stream.
  /// If the [onListen] callback throws on every call after the first,
  /// the stream behaves like a single-subscription stream.
  /// If the stream emits the same events to all current listeners,
  /// it behaves like a broadcast stream.
  ///
  /// It can also choose to emit different events to different listeners.
  /// For example, a stream which repeats the most recent
  /// non-`null` event to new listeners, could be implemented as this example:
  /// ```dart
  /// extension StreamRepeatLatestExtension<T extends Object> on Stream<T> {
  ///   Stream<T> repeatLatest() {
  ///     var done = false;
  ///     T? latest = null;
  ///     var currentListeners = <MultiStreamController<T>>{};
  ///     this.listen((event) {
  ///       latest = event;
  ///       for (var listener in [...currentListeners]) listener.addSync(event);
  ///     }, onError: (Object error, StackTrace stack) {
  ///       for (var listener in [...currentListeners]) listener.addErrorSync(error, stack);
  ///     }, onDone: () {
  ///       done = true;
  ///       latest = null;
  ///       for (var listener in currentListeners) listener.closeSync();
  ///       currentListeners.clear();
  ///     });
  ///     return Stream.multi((controller) {
  ///       if (done) {
  ///         controller.close();
  ///         return;
  ///       }
  ///       currentListeners.add(controller);
  ///       var latestValue = latest;
  ///       if (latestValue != null) controller.add(latestValue);
  ///       controller.onCancel = () {
  ///         currentListeners.remove(controller);
  ///       };
  ///     });
  ///   }
  /// }
  /// ```
  @Since("2.9")
  factory Stream.multi(void Function(MultiStreamController<T>) onListen,
      {bool isBroadcast = false}) {
    return _MultiStream<T>(onListen, isBroadcast);
  }

  /// Creates a stream that repeatedly emits events at [period] intervals.
  ///
  /// The event values are computed by invoking [computation]. The argument to
  /// this callback is an integer that starts with 0 and is incremented for
  /// every event.
  ///
  /// The [period] must be a non-negative [Duration].
  ///
  /// If [computation] is omitted, the event values will all be `null`.
  ///
  /// The [computation] must not be omitted if the event type [T] does not
  /// allow `null` as a value.
  ///
  /// Example:
  /// ```dart
  /// final stream =
  ///     Stream<int>.periodic(const Duration(
  ///         seconds: 1), (count) => count * count).take(5);
  ///
  /// stream.forEach(print); // Outputs event values 0,1,4,9,16.
  /// ```
  factory Stream.periodic(Duration period,
      [T computation(int computationCount)?]) {
    if (computation == null && !typeAcceptsNull<T>()) {
      throw ArgumentError.value(null, "computation",
          "Must not be omitted when the event type is non-nullable");
    }
    var controller = _SyncStreamController<T>(null, null, null, null);
    // Counts the time that the Stream was running (and not paused).
    Stopwatch watch = new Stopwatch();
    controller.onListen = () {
      int computationCount = 0;
      void sendEvent(_) {
        watch.reset();
        if (computation != null) {
          T event;
          try {
            event = computation(computationCount++);
          } catch (e, s) {
            controller.addError(e, s);
            return;
          }
          controller.add(event);
        } else {
          controller.add(null as T); // We have checked that null is T.
        }
      }

      Timer timer = Timer.periodic(period, sendEvent);
      controller
        ..onCancel = () {
          timer.cancel();
          return Future._nullFuture;
        }
        ..onPause = () {
          watch.stop();
          timer.cancel();
        }
        ..onResume = () {
          Duration elapsed = watch.elapsed;
          watch.start();
          timer = new Timer(period - elapsed, () {
            timer = Timer.periodic(period, sendEvent);
            sendEvent(null);
          });
        };
    };
    return controller.stream;
  }

  /// Creates a stream where all events of an existing stream are piped through
  /// a sink-transformation.
  ///
  /// The given [mapSink] closure is invoked when the returned stream is
  /// listened to. All events from the [source] are added into the event sink
  /// that is returned from the invocation. The transformation puts all
  /// transformed events into the sink the [mapSink] closure received during
  /// its invocation. Conceptually the [mapSink] creates a transformation pipe
  /// with the input sink being the returned [EventSink] and the output sink
  /// being the sink it received.
  ///
  /// This constructor is frequently used to build transformers.
  ///
  /// Example use for a duplicating transformer:
  /// ```dart
  /// class DuplicationSink implements EventSink<String> {
  ///   final EventSink<String> _outputSink;
  ///   DuplicationSink(this._outputSink);
  ///
  ///   void add(String data) {
  ///     _outputSink.add(data);
  ///     _outputSink.add(data);
  ///   }
  ///
  ///   void addError(e, [st]) { _outputSink.addError(e, st); }
  ///   void close() { _outputSink.close(); }
  /// }
  ///
  /// class DuplicationTransformer extends StreamTransformerBase<String, String> {
  ///   // Some generic types omitted for brevity.
  ///   Stream bind(Stream stream) => Stream<String>.eventTransformed(
  ///       stream,
  ///       (EventSink sink) => DuplicationSink(sink));
  /// }
  ///
  /// stringStream.transform(DuplicationTransformer());
  /// ```
  /// The resulting stream is a broadcast stream if [source] is.
  factory Stream.eventTransformed(
      Stream<dynamic> source, EventSink<dynamic> mapSink(EventSink<T> sink)) {
    return new _BoundSinkStream(source, mapSink);
  }

  /// Adapts [source] to be a `Stream<T>`.
  ///
  /// This allows [source] to be used at the new type, but at run-time it
  /// must satisfy the requirements of both the new type and its original type.
  ///
  /// Data events created by the source stream must also be instances of [T].
  static Stream<T> castFrom<S, T>(Stream<S> source) =>
      new CastStream<S, T>(source);

  /// Whether this stream is a broadcast stream.
  bool get isBroadcast => false;

  /// Returns a multi-subscription stream that produces the same events as this.
  ///
  /// The returned stream will subscribe to this stream when its first
  /// subscriber is added, and will stay subscribed until this stream ends,
  /// or a callback cancels the subscription.
  ///
  /// If [onListen] is provided, it is called with a subscription-like object
  /// that represents the underlying subscription to this stream. It is
  /// possible to pause, resume or cancel the subscription during the call
  /// to [onListen]. It is not possible to change the event handlers, including
  /// using [StreamSubscription.asFuture].
  ///
  /// If [onCancel] is provided, it is called in a similar way to [onListen]
  /// when the returned stream stops having listeners. If it later gets
  /// a new listener, the [onListen] function is called again.
  ///
  /// Use the callbacks, for example, for pausing the underlying subscription
  /// while having no subscribers to prevent losing events, or canceling the
  /// subscription when there are no listeners.
  ///
  /// Cancelling is intended to be used when there are no current subscribers.
  /// If the subscription passed to `onListen` or `onCancel` is cancelled,
  /// then no further events are ever emitted by current subscriptions on
  /// the returned broadcast stream, not even a done event.
  ///
  /// Example:
  /// ```dart
  /// final stream =
  ///     Stream<int>.periodic(const Duration(seconds: 1), (count) => count)
  ///         .take(10);
  ///
  /// final broadcastStream = stream.asBroadcastStream(
  ///   onCancel: (controller) {
  ///     print('Stream paused');
  ///     controller.pause();
  ///   },
  ///   onListen: (controller) async {
  ///     if (controller.isPaused) {
  ///       print('Stream resumed');
  ///       controller.resume();
  ///     }
  ///   },
  /// );
  ///
  /// final oddNumberStream = broadcastStream.where((event) => event.isOdd);
  /// final oddNumberListener = oddNumberStream.listen(
  ///       (event) {
  ///     print('Odd: $event');
  ///   },
  ///   onDone: () => print('Done'),
  /// );
  ///
  /// final evenNumberStream = broadcastStream.where((event) => event.isEven);
  /// final evenNumberListener = evenNumberStream.listen((event) {
  ///   print('Even: $event');
  /// }, onDone: () => print('Done'));
  ///
  /// await Future.delayed(const Duration(milliseconds: 3500)); // 3.5 second
  /// // Outputs:
  /// // Even: 0
  /// // Odd: 1
  /// // Even: 2
  /// oddNumberListener.cancel(); // Nothing printed.
  /// evenNumberListener.cancel(); // "Stream paused"
  /// await Future.delayed(const Duration(seconds: 2));
  /// print(await broadcastStream.first); // "Stream resumed"
  /// // Outputs:
  /// // 3
  /// ```
  Stream<T> asBroadcastStream(
      {void onListen(StreamSubscription<T> subscription)?,
      void onCancel(StreamSubscription<T> subscription)?}) {
    return new _AsBroadcastStream<T>(this, onListen, onCancel);
  }

  /// Adds a subscription to this stream.
  ///
  /// Returns a [StreamSubscription] which handles events from this stream using
  /// the provided [onData], [onError] and [onDone] handlers.
  /// The handlers can be changed on the subscription, but they start out
  /// as the provided functions.
  ///
  /// On each data event from this stream, the subscriber's [onData] handler
  /// is called. If [onData] is `null`, nothing happens.
  ///
  /// On errors from this stream, the [onError] handler is called with the
  /// error object and possibly a stack trace.
  ///
  /// The [onError] callback must be of type `void Function(Object error)` or
  /// `void Function(Object error, StackTrace)`.
  /// The function type determines whether [onError] is invoked with a stack
  /// trace argument.
  /// The stack trace argument may be [StackTrace.empty] if this stream received
  /// an error without a stack trace.
  ///
  /// Otherwise it is called with just the error object.
  /// If [onError] is omitted, any errors on this stream are considered unhandled,
  /// and will be passed to the current [Zone]'s error handler.
  /// By default unhandled async errors are treated
  /// as if they were uncaught top-level errors.
  ///
  /// If this stream closes and sends a done event, the [onDone] handler is
  /// called. If [onDone] is `null`, nothing happens.
  ///
  /// If [cancelOnError] is `true`, the subscription is automatically canceled
  /// when the first error event is delivered. The default is `false`.
  ///
  /// While a subscription is paused, or when it has been canceled,
  /// the subscription doesn't receive events and none of the
  /// event handler functions are called.
  StreamSubscription<T> listen(void onData(T event)?,
      {Function? onError, void onDone()?, bool? cancelOnError});

  /// Creates a new stream from this stream that discards some elements.
  ///
  /// The new stream sends the same error and done events as this stream,
  /// but it only sends the data events that satisfy the [test].
  ///
  /// If the [test] function throws, the data event is dropped and the
  /// error is emitted on the returned stream instead.
  ///
  /// The returned stream is a broadcast stream if this stream is.
  /// If a broadcast stream is listened to more than once, each subscription
  /// will individually perform the `test`.
  ///
  /// Example:
  /// ```dart
  /// final stream =
  ///     Stream<int>.periodic(const Duration(seconds: 1), (count) => count)
  ///         .take(10);
  ///
  /// final customStream = stream.where((event) => event > 3 && event <= 6);
  /// customStream.listen(print); // Outputs event values: 4,5,6.
  /// ```
  Stream<T> where(bool test(T event)) {
    return new _WhereStream<T>(this, test);
  }

  /// Transforms each element of this stream into a new stream event.
  ///
  /// Creates a new stream that converts each element of this stream
  /// to a new value using the [convert] function, and emits the result.
  ///
  /// For each data event, `o`, in this stream, the returned stream
  /// provides a data event with the value `convert(o)`.
  /// If [convert] throws, the returned stream reports it as an error
  /// event instead.
  ///
  /// Error and done events are passed through unchanged to the returned stream.
  ///
  /// The returned stream is a broadcast stream if this stream is.
  /// The [convert] function is called once per data event per listener.
  /// If a broadcast stream is listened to more than once, each subscription
  /// will individually call [convert] on each data event.
  ///
  /// Unlike [transform], this method does not treat the stream as
  /// chunks of a single value. Instead each event is converted independently
  /// of the previous and following events, which may not always be correct.
  /// For example, UTF-8 encoding, or decoding, will give wrong results
  /// if a surrogate pair, or a multibyte UTF-8 encoding, is split into
  /// separate events, and those events are attempted encoded or decoded
  /// independently.
  ///
  /// Example:
  /// ```dart
  /// final stream =
  ///     Stream<int>.periodic(const Duration(seconds: 1), (count) => count)
  ///         .take(5);
  ///
  /// final calculationStream =
  ///     stream.map<String>((event) => 'Square: ${event * event}');
  /// calculationStream.forEach(print);
  /// // Square: 0
  /// // Square: 1
  /// // Square: 4
  /// // Square: 9
  /// // Square: 16
  /// ```
  Stream<S> map<S>(S convert(T event)) {
    return new _MapStream<T, S>(this, convert);
  }

  /// Creates a new stream with each data event of this stream asynchronously
  /// mapped to a new event.
  ///
  /// This acts like [map], in that [convert] function is called once per
  /// data event, but here [convert] may be asynchronous and return a [Future].
  /// If that happens, this stream waits for that future to complete before
  /// continuing with further events.
  ///
  /// The returned stream is a broadcast stream if this stream is.
  Stream<E> asyncMap<E>(FutureOr<E> convert(T event)) {
    _StreamControllerBase<E> controller;
    if (isBroadcast) {
      controller = _SyncBroadcastStreamController<E>(null, null);
    } else {
      controller = _SyncStreamController<E>(null, null, null, null);
    }

    controller.onListen = () {
      StreamSubscription<T> subscription = this.listen(null,
          onError: controller._addError, // Avoid Zone error replacement.
          onDone: controller.close);
      FutureOr<Null> add(E value) {
        controller.add(value);
      }

      final addError = controller._addError;
      final resume = subscription.resume;
      subscription.onData((T event) {
        FutureOr<E> newValue;
        try {
          newValue = convert(event);
        } catch (e, s) {
          controller.addError(e, s);
          return;
        }
        if (newValue is Future<E>) {
          subscription.pause();
          newValue.then(add, onError: addError).whenComplete(resume);
        } else {
          controller.add(newValue);
        }
      });
      controller.onCancel = subscription.cancel;
      if (!isBroadcast) {
        controller
          ..onPause = subscription.pause
          ..onResume = resume;
      }
    };
    return controller.stream;
  }

  /// Transforms each element into a sequence of asynchronous events.
  ///
  /// Returns a new stream and for each event of this stream, do the following:
  ///
  /// * If the event is an error event or a done event, it is emitted directly
  /// by the returned stream.
  /// * Otherwise it is an element. Then the [convert] function is called
  /// with the element as argument to produce a convert-stream for the element.
  /// * If that call throws, the error is emitted on the returned stream.
  /// * If the call returns `null`, no further action is taken for the elements.
  /// * Otherwise, this stream is paused and convert-stream is listened to.
  /// Every data and error event of the convert-stream is emitted on the returned
  /// stream in the order it is produced.
  /// When the convert-stream ends, this stream is resumed.
  ///
  /// The returned stream is a broadcast stream if this stream is.
  Stream<E> asyncExpand<E>(Stream<E>? convert(T event)) {
    _StreamControllerBase<E> controller;
    if (isBroadcast) {
      controller = _SyncBroadcastStreamController<E>(null, null);
    } else {
      controller = _SyncStreamController<E>(null, null, null, null);
    }

    controller.onListen = () {
      StreamSubscription<T> subscription = this.listen(null,
          onError: controller._addError, // Avoid Zone error replacement.
          onDone: controller.close);
      subscription.onData((T event) {
        Stream<E>? newStream;
        try {
          newStream = convert(event);
        } catch (e, s) {
          controller.addError(e, s);
          return;
        }
        if (newStream != null) {
          subscription.pause();
          controller.addStream(newStream).whenComplete(subscription.resume);
        }
      });
      controller.onCancel = subscription.cancel;
      if (!isBroadcast) {
        controller
          ..onPause = subscription.pause
          ..onResume = subscription.resume;
      }
    };
    return controller.stream;
  }

  /// Creates a wrapper Stream that intercepts some errors from this stream.
  ///
  /// If this stream sends an error that matches [test], then it is intercepted
  /// by the [onError] function.
  ///
  /// The [onError] callback must be of type `void Function(Object error)` or
  /// `void Function(Object error, StackTrace)`.
  /// The function type determines whether [onError] is invoked with a stack
  /// trace argument.
  /// The stack trace argument may be [StackTrace.empty] if this stream received
  /// an error without a stack trace.
  ///
  /// An asynchronous error `error` is matched by a test function if
  /// `test(error)` returns true. If [test] is omitted, every error is
  /// considered matching.
  ///
  /// If the error is intercepted, the [onError] function can decide what to do
  /// with it. It can throw if it wants to raise a new (or the same) error,
  /// or simply return to make this stream forget the error.
  /// If the received `error` value is thrown again by the [onError] function,
  /// it acts like a `rethrow` and it is emitted along with its original
  /// stack trace, not the stack trace of the `throw` inside [onError].
  ///
  /// If you need to transform an error into a data event, use the more generic
  /// [Stream.transform] to handle the event by writing a data event to
  /// the output sink.
  ///
  /// The returned stream is a broadcast stream if this stream is.
  /// If a broadcast stream is listened to more than once, each subscription
  /// will individually perform the `test` and handle the error.
  ///
  /// Example:
  /// ```dart
  /// Stream.periodic(const Duration(seconds: 1), (count) {
  ///   if (count == 2) {
  ///     throw Exception('Exceptional event');
  ///   }
  ///   return count;
  /// }).take(4).handleError(print).forEach(print);
  ///
  /// // Outputs:
  /// // 0
  /// // 1
  /// // Exception: Exceptional event
  /// // 3
  /// // 4
  /// ```
  Stream<T> handleError(Function onError, {bool test(error)?}) {
    final void Function(Object, StackTrace) callback;
    if (onError is void Function(Object, StackTrace)) {
      callback = onError;
    } else if (onError is void Function(Object)) {
      callback = (Object error, StackTrace _) {
        onError(error);
      };
    } else {
      throw ArgumentError.value(
          onError,
          "onError",
          "Error handler must accept one Object or one Object and a StackTrace"
              " as arguments.");
    }
    return new _HandleErrorStream<T>(this, callback, test);
  }

  /// Transforms each element of this stream into a sequence of elements.
  ///
  /// Returns a new stream where each element of this stream is replaced
  /// by zero or more data events.
  /// The event values are provided as an [Iterable] by a call to [convert]
  /// with the element as argument, and the elements of that iterable is
  /// emitted in iteration order.
  /// If calling [convert] throws, or if the iteration of the returned values
  /// throws, the error is emitted on the returned stream and iteration ends
  /// for that element of this stream.
  ///
  /// Error events and the done event of this stream are forwarded directly
  /// to the returned stream.
  ///
  /// The returned stream is a broadcast stream if this stream is.
  /// If a broadcast stream is listened to more than once, each subscription
  /// will individually call `convert` and expand the events.
  Stream<S> expand<S>(Iterable<S> convert(T element)) {
    return new _ExpandStream<T, S>(this, convert);
  }

  /// Pipes the events of this stream into [streamConsumer].
  ///
  /// All events of this stream are added to `streamConsumer` using
  /// [StreamConsumer.addStream].
  /// The `streamConsumer` is closed when this stream has been successfully added
  /// to it - when the future returned by `addStream` completes without an error.
  ///
  /// Returns a future which completes when this stream has been consumed
  /// and the consumer has been closed.
  ///
  /// The returned future completes with the same result as the future returned
  /// by [StreamConsumer.close].
  /// If the call to [StreamConsumer.addStream] fails in some way, this
  /// method fails in the same way.
  Future pipe(StreamConsumer<T> streamConsumer) {
    return streamConsumer.addStream(this).then((_) => streamConsumer.close());
  }

  /// Applies [streamTransformer] to this stream.
  ///
  /// Returns the transformed stream,
  /// that is, the result of `streamTransformer.bind(this)`.
  /// This method simply allows writing the call to `streamTransformer.bind`
  /// in a chained fashion, like
  /// ```dart
  /// stream.map(mapping).transform(transformation).toList()
  /// ```
  /// which can be more convenient than calling `bind` directly.
  ///
  /// The [streamTransformer] can return any stream.
  /// Whether the returned stream is a broadcast stream or not,
  /// and which elements it will contain,
  /// is entirely up to the transformation.
  ///
  /// This method should always be used for transformations which treat
  /// the entire stream as representing a single value
  /// which has perhaps been split into several parts for transport,
  /// like a file being read from disk or being fetched over a network.
  /// The transformation will then produce a new stream which
  /// transforms the stream's value incrementally (perhaps using
  /// [Converter.startChunkedConversion]). The resulting stream
  /// may again be chunks of the result, but does not have to
  /// correspond to specific events from the source string.
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) {
    return streamTransformer.bind(this);
  }

  /// Combines a sequence of values by repeatedly applying [combine].
  ///
  /// Similar to [Iterable.reduce], this function maintains a value,
  /// starting with the first element of this stream
  /// and updated for each further element of this stream.
  /// For each element after the first,
  /// the value is updated to the result of calling [combine]
  /// with the previous value and the element.
  ///
  /// When this stream is done, the returned future is completed with
  /// the value at that time.
  ///
  /// If this stream is empty, the returned future is completed with
  /// an error.
  /// If this stream emits an error, or the call to [combine] throws,
  /// the returned future is completed with that error,
  /// and processing is stopped.
  ///
  /// Example:
  /// ```dart
  /// final result = await Stream.fromIterable([2, 6, 10, 8, 2])
  ///     .reduce((previous, element) => previous + element);
  /// print(result); // 28
  /// ```
  Future<T> reduce(T combine(T previous, T element)) {
    _Future<T> result = new _Future<T>();
    bool seenFirst = false;
    late T value;
    StreamSubscription<T> subscription =
        this.listen(null, onError: result._completeError, onDone: () {
      if (!seenFirst) {
        try {
          // Throw and recatch, instead of just doing
          //  _completeWithErrorCallback, e, theError, StackTrace.current),
          // to ensure that the stackTrace is set on the error.
          throw IterableElementError.noElement();
        } catch (e, s) {
          _completeWithErrorCallback(result, e, s);
        }
      } else {
        result._complete(value);
      }
    }, cancelOnError: true);
    subscription.onData((T element) {
      if (seenFirst) {
        _runUserCode(() => combine(value, element), (T newValue) {
          value = newValue;
        }, _cancelAndErrorClosure(subscription, result));
      } else {
        value = element;
        seenFirst = true;
      }
    });
    return result;
  }

  /// Combines a sequence of values by repeatedly applying [combine].
  ///
  /// Similar to [Iterable.fold], this function maintains a value,
  /// starting with [initialValue] and updated for each element of
  /// this stream.
  /// For each element, the value is updated to the result of calling
  /// [combine] with the previous value and the element.
  ///
  /// When this stream is done, the returned future is completed with
  /// the value at that time.
  /// For an empty stream, the future is completed with [initialValue].
  ///
  /// If this stream emits an error, or the call to [combine] throws,
  /// the returned future is completed with that error,
  /// and processing is stopped.
  ///
  /// Example:
  /// ```dart
  /// final result = await Stream.fromIterable([2, 6, 10, 8, 2])
  ///     .fold<int>(10, (previous, element) => previous + element);
  /// print(result); // 38
  /// ```
  Future<S> fold<S>(S initialValue, S combine(S previous, T element)) {
    _Future<S> result = new _Future<S>();
    S value = initialValue;
    StreamSubscription<T> subscription =
        this.listen(null, onError: result._completeError, onDone: () {
      result._complete(value);
    }, cancelOnError: true);
    subscription.onData((T element) {
      _runUserCode(() => combine(value, element), (S newValue) {
        value = newValue;
      }, _cancelAndErrorClosure(subscription, result));
    });
    return result;
  }

  /// Combines the string representation of elements into a single string.
  ///
  /// Each element is converted to a string using its [Object.toString] method.
  /// If [separator] is provided, it is inserted between element string
  /// representations.
  ///
  /// The returned future is completed with the combined string when this stream
  /// is done.
  ///
  /// If this stream emits an error, or the call to [Object.toString] throws,
  /// the returned future is completed with that error,
  /// and processing stops.
  ///
  /// Example:
  /// ```dart
  /// final result = await Stream.fromIterable(['Mars', 'Venus', 'Earth'])
  ///     .join('--');
  /// print(result); // 'Mars--Venus--Earth'
  /// ```
  Future<String> join([String separator = ""]) {
    _Future<String> result = new _Future<String>();
    StringBuffer buffer = new StringBuffer();
    bool first = true;
    StreamSubscription<T> subscription =
        this.listen(null, onError: result._completeError, onDone: () {
      result._complete(buffer.toString());
    }, cancelOnError: true);
    subscription.onData(separator.isEmpty
        ? (T element) {
            try {
              buffer.write(element);
            } catch (e, s) {
              _cancelAndErrorWithReplacement(subscription, result, e, s);
            }
          }
        : (T element) {
            if (!first) {
              buffer.write(separator);
            }
            first = false;
            try {
              buffer.write(element);
            } catch (e, s) {
              _cancelAndErrorWithReplacement(subscription, result, e, s);
            }
          });
    return result;
  }

  /// Returns whether [needle] occurs in the elements provided by this stream.
  ///
  /// Compares each element of this stream to [needle] using [Object.==].
  /// If an equal element is found, the returned future is completed with `true`.
  /// If this stream ends without finding a match, the future is completed with
  /// `false`.
  ///
  /// If this stream emits an error, or the call to [Object.==] throws,
  /// the returned future is completed with that error,
  /// and processing stops.
  ///
  /// Example:
  /// ```dart
  /// final result = await Stream.fromIterable(['Year', 2021, 12, 24, 'Dart'])
  ///     .contains('Dart');
  /// print(result); // true
  /// ```
  Future<bool> contains(Object? needle) {
    _Future<bool> future = new _Future<bool>();
    StreamSubscription<T> subscription =
        this.listen(null, onError: future._completeError, onDone: () {
      future._complete(false);
    }, cancelOnError: true);
    subscription.onData((T element) {
      _runUserCode(() => (element == needle), (bool isMatch) {
        if (isMatch) {
          _cancelAndValue(subscription, future, true);
        }
      }, _cancelAndErrorClosure(subscription, future));
    });
    return future;
  }

  /// Executes [action] on each element of this stream.
  ///
  /// Completes the returned [Future] when all elements of this stream
  /// have been processed.
  ///
  /// If this stream emits an error, or if the call to [action] throws,
  /// the returned future completes with that error,
  /// and processing stops.
  Future<void> forEach(void action(T element)) {
    _Future future = new _Future();
    StreamSubscription<T> subscription =
        this.listen(null, onError: future._completeError, onDone: () {
      future._complete(null);
    }, cancelOnError: true);
    subscription.onData((T element) {
      _runUserCode<void>(() => action(element), (_) {},
          _cancelAndErrorClosure(subscription, future));
    });
    return future;
  }

  /// Checks whether [test] accepts all elements provided by this stream.
  ///
  /// Calls [test] on each element of this stream.
  /// If the call returns `false`, the returned future is completed with `false`
  /// and processing stops.
  ///
  /// If this stream ends without finding an element that [test] rejects,
  /// the returned future is completed with `true`.
  ///
  /// If this stream emits an error, or if the call to [test] throws,
  /// the returned future is completed with that error,
  /// and processing stops.
  ///
  /// Example:
  /// ```dart
  /// final result =
  ///     await Stream.periodic(const Duration(seconds: 1), (count) => count)
  ///         .take(15)
  ///         .every((x) => x <= 5);
  /// print(result); // false
  /// ```
  Future<bool> every(bool test(T element)) {
    _Future<bool> future = new _Future<bool>();
    StreamSubscription<T> subscription =
        this.listen(null, onError: future._completeError, onDone: () {
      future._complete(true);
    }, cancelOnError: true);
    subscription.onData((T element) {
      _runUserCode(() => test(element), (bool isMatch) {
        if (!isMatch) {
          _cancelAndValue(subscription, future, false);
        }
      }, _cancelAndErrorClosure(subscription, future));
    });
    return future;
  }

  /// Checks whether [test] accepts any element provided by this stream.
  ///
  /// Calls [test] on each element of this stream.
  /// If the call returns `true`, the returned future is completed with `true`
  /// and processing stops.
  ///
  /// If this stream ends without finding an element that [test] accepts,
  /// the returned future is completed with `false`.
  ///
  /// If this stream emits an error, or if the call to [test] throws,
  /// the returned future is completed with that error,
  /// and processing stops.
  ///
  /// Example:
  /// ```dart
  /// final result =
  ///     await Stream.periodic(const Duration(seconds: 1), (count) => count)
  ///         .take(15)
  ///         .any((element) => element >= 5);
  ///
  /// print(result); // true
  /// ```
  Future<bool> any(bool test(T element)) {
    _Future<bool> future = new _Future<bool>();
    StreamSubscription<T> subscription =
        this.listen(null, onError: future._completeError, onDone: () {
      future._complete(false);
    }, cancelOnError: true);
    subscription.onData((T element) {
      _runUserCode(() => test(element), (bool isMatch) {
        if (isMatch) {
          _cancelAndValue(subscription, future, true);
        }
      }, _cancelAndErrorClosure(subscription, future));
    });
    return future;
  }

  /// The number of elements in this stream.
  ///
  /// Waits for all elements of this stream. When this stream ends,
  /// the returned future is completed with the number of elements.
  ///
  /// If this stream emits an error,
  /// the returned future is completed with that error,
  /// and processing stops.
  ///
  /// This operation listens to this stream, and a non-broadcast stream cannot
  /// be reused after finding its length.
  Future<int> get length {
    _Future<int> future = new _Future<int>();
    int count = 0;
    this.listen(
        (_) {
          count++;
        },
        onError: future._completeError,
        onDone: () {
          future._complete(count);
        },
        cancelOnError: true);
    return future;
  }

  /// Whether this stream contains any elements.
  ///
  /// Waits for the first element of this stream, then completes the returned
  /// future with `false`.
  /// If this stream ends without emitting any elements, the returned future is
  /// completed with `true`.
  ///
  /// If the first event is an error, the returned future is completed with that
  /// error.
  ///
  /// This operation listens to this stream, and a non-broadcast stream cannot
  /// be reused after checking whether it is empty.
  Future<bool> get isEmpty {
    _Future<bool> future = new _Future<bool>();
    StreamSubscription<T> subscription =
        this.listen(null, onError: future._completeError, onDone: () {
      future._complete(true);
    }, cancelOnError: true);
    subscription.onData((_) {
      _cancelAndValue(subscription, future, false);
    });
    return future;
  }

  /// Adapt this stream to be a `Stream<R>`.
  ///
  /// This stream is wrapped as a `Stream<R>` which checks at run-time that
  /// each data event emitted by this stream is also an instance of [R].
  Stream<R> cast<R>() => Stream.castFrom<T, R>(this);

  /// Collects all elements of this stream in a [List].
  ///
  /// Creates a `List<T>` and adds all elements of this stream to the list
  /// in the order they arrive.
  /// When this stream ends, the returned future is completed with that list.
  ///
  /// If this stream emits an error,
  /// the returned future is completed with that error,
  /// and processing stops.
  Future<List<T>> toList() {
    List<T> result = <T>[];
    _Future<List<T>> future = new _Future<List<T>>();
    this.listen(
        (T data) {
          result.add(data);
        },
        onError: future._completeError,
        onDone: () {
          future._complete(result);
        },
        cancelOnError: true);
    return future;
  }

  /// Collects the data of this stream in a [Set].
  ///
  /// Creates a `Set<T>` and adds all elements of this stream to the set.
  /// in the order they arrive.
  /// When this stream ends, the returned future is completed with that set.
  ///
  /// The returned set is the same type as created by `<T>{}`.
  /// If another type of set is needed, either use [forEach] to add each
  /// element to the set, or use
  /// `toList().then((list) => new SomeOtherSet.from(list))`
  /// to create the set.
  ///
  /// If this stream emits an error,
  /// the returned future is completed with that error,
  /// and processing stops.
  Future<Set<T>> toSet() {
    Set<T> result = new Set<T>();
    _Future<Set<T>> future = new _Future<Set<T>>();
    this.listen(
        (T data) {
          result.add(data);
        },
        onError: future._completeError,
        onDone: () {
          future._complete(result);
        },
        cancelOnError: true);
    return future;
  }

  /// Discards all data on this stream, but signals when it is done or an error
  /// occurred.
  ///
  /// When subscribing using [drain], cancelOnError will be true. This means
  /// that the future will complete with the first error on this stream and then
  /// cancel the subscription.
  ///
  /// If this stream emits an error, the returned future is completed with
  /// that error, and processing is stopped.
  ///
  /// In case of a `done` event the future completes with the given
  /// [futureValue].
  ///
  /// The [futureValue] must not be omitted if `null` is not assignable to [E].
  ///
  /// Example:
  /// ```dart
  /// final result = await Stream.fromIterable([1, 2, 3]).drain(100);
  /// print(result); // Outputs: 100.
  /// ```
  Future<E> drain<E>([E? futureValue]) {
    if (futureValue == null) {
      futureValue = futureValue as E;
    }
    return listen(null, cancelOnError: true).asFuture<E>(futureValue);
  }

  /// Provides at most the first [count] data events of this stream.
  ///
  /// Returns a stream that emits the same events that this stream would
  /// if listened to at the same time,
  /// until either this stream ends or it has emitted [count] data events,
  /// at which point the returned stream is done.
  ///
  /// If this stream produces fewer than [count] data events before it's done,
  /// so will the returned stream.
  ///
  /// Starts listening to this stream when the returned stream is listened to
  /// and stops listening when the first [count] data events have been received.
  ///
  /// This means that if this is a single-subscription (non-broadcast) streams
  /// it cannot be reused after the returned stream has been listened to.
  ///
  /// If this is a broadcast stream, the returned stream is a broadcast stream.
  /// In that case, the events are only counted from the time
  /// the returned stream is listened to.
  ///
  /// Example:
  /// ```dart
  /// final stream =
  ///     Stream<int>.periodic(const Duration(seconds: 1), (i) => i)
  ///         .take(60);
  /// stream.forEach(print); // Outputs events: 0, ... 59.
  /// ```
  Stream<T> take(int count) {
    return new _TakeStream<T>(this, count);
  }

  /// Forwards data events while [test] is successful.
  ///
  /// Returns a stream that provides the same events as this stream
  /// until [test] fails for a data event.
  /// The returned stream is done when either this stream is done,
  /// or when this stream first emits a data event that fails [test].
  ///
  /// The `test` call is considered failing if it returns a non-`true` value
  /// or if it throws. If the `test` call throws, the error is emitted as the
  /// last event on the returned streams.
  ///
  /// Stops listening to this stream after the accepted elements.
  ///
  /// Internally the method cancels its subscription after these elements. This
  /// means that single-subscription (non-broadcast) streams are closed and
  /// cannot be reused after a call to this method.
  ///
  /// The returned stream is a broadcast stream if this stream is.
  /// For a broadcast stream, the events are only tested from the time
  /// the returned stream is listened to.
  ///
  /// Example:
  /// ```dart
  /// final stream = Stream<int>.periodic(const Duration(seconds: 1), (i) => i)
  ///     .takeWhile((event) => event < 6);
  /// stream.forEach(print); // Outputs events: 0, ..., 5.
  /// ```
  Stream<T> takeWhile(bool test(T element)) {
    return new _TakeWhileStream<T>(this, test);
  }

  /// Skips the first [count] data events from this stream.
  ///
  /// Returns a stream that emits the same events as this stream would
  /// if listened to at the same time, except that the first [count]
  /// data events are not emitted.
  /// The returned stream is done when this stream is.
  ///
  /// If this stream emits fewer than [count] data events
  /// before being done, the returned stream emits no data events.
  ///
  /// The returned stream is a broadcast stream if this stream is.
  /// For a broadcast stream, the events are only counted from the time
  /// the returned stream is listened to.
  ///
  /// Example:
  /// ```dart
  /// final stream =
  ///     Stream<int>.periodic(const Duration(seconds: 1), (i) => i).skip(7);
  /// stream.forEach(print); // Skips events 0, ..., 6. Outputs events: 7, ...
  /// ```
  Stream<T> skip(int count) {
    return new _SkipStream<T>(this, count);
  }

  /// Skip data events from this stream while they are matched by [test].
  ///
  /// Returns a stream that emits the same events as this stream,
  /// except that data events are not emitted until a data event fails `test`.
  /// The test fails when called with a data event
  /// if it returns a non-`true` value or if the call to `test` throws.
  /// If the call throws, the error is emitted as an error event
  /// on the returned stream instead of the data event,
  /// otherwise the event that made `test` return non-true is emitted as the
  /// first data event.
  ///
  /// Error and done events are provided by the returned stream unmodified.
  ///
  /// The returned stream is a broadcast stream if this stream is.
  /// For a broadcast stream, the events are only tested from the time
  /// the returned stream is listened to.
  ///
  /// Example:
  /// ```dart
  /// final stream = Stream<int>.periodic(const Duration(seconds: 1), (i) => i)
  ///     .take(10)
  ///     .skipWhile((x) => x < 5);
  /// stream.forEach(print); // Outputs events: 5, ..., 9.
  /// ```
  Stream<T> skipWhile(bool test(T element)) {
    return new _SkipWhileStream<T>(this, test);
  }

  /// Skips data events if they are equal to the previous data event.
  ///
  /// The returned stream provides the same events as this stream, except
  /// that it never provides two consecutive data events that are equal.
  /// That is, errors are passed through to the returned stream, and
  /// data events are passed through if they are distinct from the most
  /// recently emitted data event.
  ///
  /// Equality is determined by the provided [equals] method. If that is
  /// omitted, the '==' operator on the last provided data element is used.
  ///
  /// If [equals] throws, the data event is replaced by an error event
  /// containing the thrown error. The behavior is equivalent to the
  /// original stream emitting the error event, and it doesn't change
  /// the what the most recently emitted data event is.
  ///
  /// The returned stream is a broadcast stream if this stream is.
  /// If a broadcast stream is listened to more than once, each subscription
  /// will individually perform the `equals` test.
  ///
  /// Example:
  /// ```dart
  /// final stream = Stream.fromIterable([2, 6, 6, 8, 12, 8, 8, 2]).distinct();
  /// stream.forEach(print); // Outputs events: 2,6,8,12,8,2.
  /// ```
  Stream<T> distinct([bool equals(T previous, T next)?]) {
    return new _DistinctStream<T>(this, equals);
  }

  /// The first element of this stream.
  ///
  /// Stops listening to this stream after the first element has been received.
  ///
  /// Internally the method cancels its subscription after the first element.
  /// This means that single-subscription (non-broadcast) streams are closed
  /// and cannot be reused after a call to this getter.
  ///
  /// If an error event occurs before the first data event, the returned future
  /// is completed with that error.
  ///
  /// If this stream is empty (a done event occurs before the first data event),
  /// the returned future completes with an error.
  ///
  /// Except for the type of the error, this method is equivalent to
  /// `this.elementAt(0)`.
  Future<T> get first {
    _Future<T> future = new _Future<T>();
    StreamSubscription<T> subscription =
        this.listen(null, onError: future._completeError, onDone: () {
      try {
        throw IterableElementError.noElement();
      } catch (e, s) {
        _completeWithErrorCallback(future, e, s);
      }
    }, cancelOnError: true);
    subscription.onData((T value) {
      _cancelAndValue(subscription, future, value);
    });
    return future;
  }

  /// The last element of this stream.
  ///
  /// If this stream emits an error event,
  /// the returned future is completed with that error
  /// and processing stops.
  ///
  /// If this stream is empty (the done event is the first event),
  /// the returned future completes with an error.
  Future<T> get last {
    _Future<T> future = new _Future<T>();
    late T result;
    bool foundResult = false;
    listen(
        (T value) {
          foundResult = true;
          result = value;
        },
        onError: future._completeError,
        onDone: () {
          if (foundResult) {
            future._complete(result);
            return;
          }
          try {
            throw IterableElementError.noElement();
          } catch (e, s) {
            _completeWithErrorCallback(future, e, s);
          }
        },
        cancelOnError: true);
    return future;
  }

  /// The single element of this stream.
  ///
  /// If this stream emits an error event,
  /// the returned future is completed with that error
  /// and processing stops.
  ///
  /// If this [Stream] is empty or has more than one element,
  /// the returned future completes with an error.
  Future<T> get single {
    _Future<T> future = new _Future<T>();
    late T result;
    bool foundResult = false;
    StreamSubscription<T> subscription =
        this.listen(null, onError: future._completeError, onDone: () {
      if (foundResult) {
        future._complete(result);
        return;
      }
      try {
        throw IterableElementError.noElement();
      } catch (e, s) {
        _completeWithErrorCallback(future, e, s);
      }
    }, cancelOnError: true);
    subscription.onData((T value) {
      if (foundResult) {
        // This is the second element we get.
        try {
          throw IterableElementError.tooMany();
        } catch (e, s) {
          _cancelAndErrorWithReplacement(subscription, future, e, s);
        }
        return;
      }
      foundResult = true;
      result = value;
    });
    return future;
  }

  /// Finds the first element of this stream matching [test].
  ///
  /// Returns a future that is completed with the first element of this stream
  /// for which [test] returns `true`.
  ///
  /// {@template stream_where_or_else}
  /// If no such element is found before this stream is done, and an
  /// [orElse] function is provided, the result of calling [orElse]
  /// becomes the value of the future. If [orElse] throws, the returned
  /// future is completed with that error.
  /// {@endtemplate}
  ///
  /// If this stream emits an error before the first matching element,
  /// the returned future is completed with that error, and processing stops.
  ///
  /// Stops listening to this stream after the first matching element or error
  /// has been received.
  ///
  /// Internally the method cancels its subscription after the first element that
  /// matches the predicate. This means that single-subscription (non-broadcast)
  /// streams are closed and cannot be reused after a call to this method.
  ///
  /// If an error occurs, or if this stream ends without finding a match and
  /// with no [orElse] function provided,
  /// the returned future is completed with an error.
  ///
  /// Example:
  /// ```dart
  /// var result = await Stream.fromIterable([1, 3, 4, 9, 12])
  ///     .firstWhere((element) => element % 6 == 0, orElse: () => -1);
  /// print(result); // 12
  ///
  /// result = await Stream.fromIterable([1, 2, 3, 4, 5])
  ///     .firstWhere((element) => element % 6 == 0, orElse: () => -1);
  /// print(result); // -1
  /// ```
  Future<T> firstWhere(bool test(T element), {T orElse()?}) {
    _Future<T> future = new _Future();
    StreamSubscription<T> subscription =
        this.listen(null, onError: future._completeError, onDone: () {
      if (orElse != null) {
        _runUserCode(orElse, future._complete, future._completeError);
        return;
      }
      try {
        // Sets stackTrace on error.
        throw IterableElementError.noElement();
      } catch (e, s) {
        _completeWithErrorCallback(future, e, s);
      }
    }, cancelOnError: true);

    subscription.onData((T value) {
      _runUserCode(() => test(value), (bool isMatch) {
        if (isMatch) {
          _cancelAndValue(subscription, future, value);
        }
      }, _cancelAndErrorClosure(subscription, future));
    });
    return future;
  }

  /// Finds the last element in this stream matching [test].
  ///
  /// Returns a future that is completed with the last element of this stream
  /// for which [test] returns `true`.
  ///
  /// {@macro stream_where_or_else}
  ///
  /// If this stream emits an error at any point, the returned future is
  /// completed with that error, and the subscription is canceled.
  ///
  /// A non-error result cannot be provided before this stream is done.
  ///
  /// Similar too [firstWhere], except that the last matching element is found
  /// instead of the first.
  ///
  /// Example:
  /// ```dart
  /// var result = await Stream.fromIterable([1, 3, 4, 7, 12, 24, 32])
  ///     .lastWhere((element) => element % 6 == 0, orElse: () => -1);
  /// print(result); // 24
  ///
  /// result = await Stream.fromIterable([1, 3, 4, 7, 12, 24, 32])
  ///     .lastWhere((element) => element % 10 == 0, orElse: () => -1);
  /// print(result); // -1
  /// ```
  Future<T> lastWhere(bool test(T element), {T orElse()?}) {
    _Future<T> future = new _Future();
    late T result;
    bool foundResult = false;
    StreamSubscription<T> subscription =
        this.listen(null, onError: future._completeError, onDone: () {
      if (foundResult) {
        future._complete(result);
        return;
      }
      if (orElse != null) {
        _runUserCode(orElse, future._complete, future._completeError);
        return;
      }
      try {
        throw IterableElementError.noElement();
      } catch (e, s) {
        _completeWithErrorCallback(future, e, s);
      }
    }, cancelOnError: true);

    subscription.onData((T value) {
      _runUserCode(() => test(value), (bool isMatch) {
        if (isMatch) {
          foundResult = true;
          result = value;
        }
      }, _cancelAndErrorClosure(subscription, future));
    });
    return future;
  }

  /// Finds the single element in this stream matching [test].
  ///
  /// Returns a future that is completed with the single element of this stream
  /// for which [test] returns `true`.
  ///
  /// {@macro stream_where_or_else}
  ///
  /// Only one element may match. If more than one matching element is found an
  /// error is thrown, regardless of whether [orElse] was passed.
  ///
  /// If this stream emits an error at any point, the returned future is
  /// completed with that error, and the subscription is canceled.
  ///
  /// A non-error result cannot be provided before this stream is done.
  ///
  /// Similar to [lastWhere], except that it is an error if more than one
  /// matching element occurs in this stream.
  ///
  /// Example:
  /// ```dart
  /// var result = await Stream.fromIterable([1, 2, 3, 6, 9, 12])
  ///     .singleWhere((element) => element % 4 == 0, orElse: () => -1);
  /// print(result); // 12
  ///
  /// result = await Stream.fromIterable([2, 6, 8, 12, 24, 32])
  ///     .singleWhere((element) => element % 9 == 0, orElse: () => -1);
  /// print(result); // -1
  ///
  /// result = await Stream.fromIterable([2, 6, 8, 12, 24, 32])
  ///     .singleWhere((element) => element % 6 == 0, orElse: () => -1);
  /// // Throws.
  /// ```
  Future<T> singleWhere(bool test(T element), {T orElse()?}) {
    _Future<T> future = new _Future<T>();
    late T result;
    bool foundResult = false;
    StreamSubscription<T> subscription =
        this.listen(null, onError: future._completeError, onDone: () {
      if (foundResult) {
        future._complete(result);
        return;
      }
      if (orElse != null) {
        _runUserCode(orElse, future._complete, future._completeError);
        return;
      }
      try {
        throw IterableElementError.noElement();
      } catch (e, s) {
        _completeWithErrorCallback(future, e, s);
      }
    }, cancelOnError: true);

    subscription.onData((T value) {
      _runUserCode(() => test(value), (bool isMatch) {
        if (isMatch) {
          if (foundResult) {
            try {
              throw IterableElementError.tooMany();
            } catch (e, s) {
              _cancelAndErrorWithReplacement(subscription, future, e, s);
            }
            return;
          }
          foundResult = true;
          result = value;
        }
      }, _cancelAndErrorClosure(subscription, future));
    });
    return future;
  }

  /// Returns the value of the [index]th data event of this stream.
  ///
  /// Stops listening to this stream after the [index]th data event has been
  /// received.
  ///
  /// Internally the method cancels its subscription after these elements. This
  /// means that single-subscription (non-broadcast) streams are closed and
  /// cannot be reused after a call to this method.
  ///
  /// If an error event occurs before the value is found, the future completes
  /// with this error.
  ///
  /// If a done event occurs before the value is found, the future completes
  /// with a [RangeError].
  Future<T> elementAt(int index) {
    RangeError.checkNotNegative(index, "index");
    _Future<T> result = new _Future<T>();
    int elementIndex = 0;
    StreamSubscription<T> subscription;
    subscription =
        this.listen(null, onError: result._completeError, onDone: () {
      result._completeError(
          new IndexError.withLength(index, elementIndex,
              indexable: this, name: "index"),
          StackTrace.empty);
    }, cancelOnError: true);
    subscription.onData((T value) {
      if (index == elementIndex) {
        _cancelAndValue(subscription, result, value);
        return;
      }
      elementIndex += 1;
    });

    return result;
  }

  /// Creates a new stream with the same events as this stream.
  ///
  /// When someone is listening on the returned stream and more than
  /// [timeLimit] passes without any event being emitted by this stream,
  /// the [onTimeout] function is called, which can then emit further events on
  /// the returned stream.
  ///
  /// The countdown starts when the returned stream is listened to,
  /// and is restarted when an event from this stream is emitted,
  /// or when listening on the returned stream is paused and resumed.
  /// The countdown is stopped when listening on the returned stream is
  /// paused or cancelled.
  /// No new countdown is started when a countdown completes
  /// and the [onTimeout] function is called, even if events are emitted.
  /// If the delay between events of this stream is multiple times
  /// [timeLimit], at most one timeout will happen between events.
  ///
  /// The [onTimeout] function is called with one argument: an
  /// [EventSink] that allows putting events into the returned stream.
  /// This `EventSink` is only valid during the call to [onTimeout].
  /// Calling [EventSink.close] on the sink passed to [onTimeout] closes the
  /// returned stream, and no further events are processed.
  ///
  /// If [onTimeout] is omitted, a timeout will emit a [TimeoutException]
  /// into the error channel of the returned stream.
  /// If the call to [onTimeout] throws, the error is emitted as an error
  /// on the returned stream.
  ///
  /// The returned stream is a broadcast stream if this stream is.
  /// If a broadcast stream is listened to more than once, each subscription
  /// will have its individually timer that starts counting on listen,
  /// and the subscriptions' timers can be paused individually.
  ///
  /// Example:
  /// ```dart
  /// Future<String> waitTask() async {
  ///   return await Future.delayed(
  ///       const Duration(seconds: 4), () => 'Complete');
  /// }
  /// final stream = Stream<String>.fromFuture(waitTask())
  ///     .timeout(const Duration(seconds: 2), onTimeout: (controller) {
  ///   print('TimeOut occurred');
  ///   controller.close();
  /// });
  ///
  /// stream.listen(print, onDone: () => print('Done'));
  ///
  /// // Outputs:
  /// // TimeOut occurred
  /// // Done
  /// ```
  Stream<T> timeout(Duration timeLimit, {void onTimeout(EventSink<T> sink)?}) {
    _StreamControllerBase<T> controller;
    if (isBroadcast) {
      controller = new _SyncBroadcastStreamController<T>(null, null);
    } else {
      controller = new _SyncStreamController<T>(null, null, null, null);
    }

    Zone zone = Zone.current;
    // Register callback immediately.
    _TimerCallback timeoutCallback;
    if (onTimeout == null) {
      timeoutCallback = () {
        controller.addError(
            new TimeoutException("No stream event", timeLimit), null);
      };
    } else {
      var registeredOnTimeout =
          zone.registerUnaryCallback<void, EventSink<T>>(onTimeout);
      var wrapper = new _ControllerEventSinkWrapper<T>(null);
      timeoutCallback = () {
        wrapper._sink = controller; // Only valid during call.
        zone.runUnaryGuarded(registeredOnTimeout, wrapper);
        wrapper._sink = null;
      };
    }

    // All further setup happens inside `onListen`.
    controller.onListen = () {
      Timer timer = zone.createTimer(timeLimit, timeoutCallback);
      var subscription = this.listen(null);
      // Set up event forwarding. Each data or error event resets the timer
      subscription
        ..onData((T event) {
          timer.cancel();
          timer = zone.createTimer(timeLimit, timeoutCallback);
          // Controller is synchronous, and the call might close the stream
          // and cancel the timer,
          // so create the Timer before calling into add();
          // issue: https://github.com/dart-lang/sdk/issues/37565
          controller.add(event);
        })
        ..onError((Object error, StackTrace stackTrace) {
          timer.cancel();
          timer = zone.createTimer(timeLimit, timeoutCallback);
          controller._addError(
              error, stackTrace); // Avoid Zone error replacement.
        })
        ..onDone(() {
          timer.cancel();
          controller.close();
        });
      // Set up further controller callbacks.
      controller.onCancel = () {
        timer.cancel();
        return subscription.cancel();
      };
      if (!isBroadcast) {
        controller
          ..onPause = () {
            timer.cancel();
            subscription.pause();
          }
          ..onResume = () {
            subscription.resume();
            timer = zone.createTimer(timeLimit, timeoutCallback);
          };
      }
    };

    return controller.stream;
  }
}

/// A subscription on events from a [Stream].
///
/// When you listen on a [Stream] using [Stream.listen],
/// a [StreamSubscription] object is returned.
///
/// The subscription provides events to the listener,
/// and holds the callbacks used to handle the events.
/// The subscription can also be used to unsubscribe from the events,
/// or to temporarily pause the events from the stream.
///
/// Example:
/// ```dart
/// final stream = Stream.periodic(const Duration(seconds: 1), (i) => i * i)
///     .take(10);
///
/// final subscription = stream.listen(print); // A StreamSubscription<int>.
/// ```
/// To pause the subscription, use [pause].
/// ```dart continued
/// // Do some work.
/// subscription.pause();
/// print(subscription.isPaused); // true
/// ```
/// To resume after the pause, use [resume].
/// ```dart continued
/// // Do some work.
/// subscription.resume();
/// print(subscription.isPaused); // false
/// ```
/// To cancel the subscription, use [cancel].
/// ```dart continued
/// // Do some work.
/// subscription.cancel();
/// ```
abstract interface class StreamSubscription<T> {
  /// Cancels this subscription.
  ///
  /// After this call, the subscription no longer receives events.
  ///
  /// The stream may need to shut down the source of events and clean up after
  /// the subscription is canceled.
  ///
  /// Returns a future that is completed once the stream has finished
  /// its cleanup.
  ///
  /// Typically, cleanup happens when the stream needs to release resources.
  /// For example, a stream might need to close an open file (as an asynchronous
  /// operation). If the listener wants to delete the file after having
  /// canceled the subscription, it must wait for the cleanup future to complete.
  ///
  /// If the cleanup throws, which it really shouldn't, the returned future
  /// completes with that error.
  Future<void> cancel();

  /// Replaces the data event handler of this subscription.
  ///
  /// The [handleData] function is called for each data event of the stream
  /// after this function is called.
  /// If [handleData] is `null`, data events are ignored.
  ///
  /// This method replaces the current handler set by the invocation of
  /// [Stream.listen] or by a previous call to [onData].
  void onData(void handleData(T data)?);

  /// Replaces the error event handler of this subscription.
  ///
  /// The [handleError] function must be able to be called with either
  /// one positional argument, or with two positional arguments
  /// where the seconds is always a [StackTrace].
  ///
  /// The [handleError] argument may be `null`, in which case further
  /// error events are considered *unhandled*, and will be reported to
  /// [Zone.handleUncaughtError].
  ///
  /// The provided function is called for all error events from the
  /// stream subscription.
  ///
  /// This method replaces the current handler set by the invocation of
  /// [Stream.listen], by calling [asFuture], or by a previous call to [onError].
  void onError(Function? handleError);

  /// Replaces the done event handler of this subscription.
  ///
  /// The [handleDone] function is called when the stream closes.
  /// The value may be `null`, in which case no function is called.
  ///
  /// This method replaces the current handler set by the invocation of
  /// [Stream.listen], by calling [asFuture], or by a previous call to [onDone].
  void onDone(void handleDone()?);

  /// Requests that the stream pauses events until further notice.
  ///
  /// While paused, the subscription will not fire any events.
  /// If it receives events from its source, they will be buffered until
  /// the subscription is resumed.
  /// For non-broadcast streams, the underlying source is usually informed
  /// about the pause,
  /// so it can stop generating events until the subscription is resumed.
  ///
  /// To avoid buffering events on a broadcast stream, it is better to
  /// cancel this subscription, and start to listen again when events
  /// are needed, if the intermediate events are not important.
  ///
  /// If [resumeSignal] is provided, the stream subscription will undo the pause
  /// when the future completes, as if by a call to [resume].
  /// If the future completes with an error,
  /// the stream will still resume, but the error will be considered unhandled
  /// and is passed to [Zone.handleUncaughtError].
  ///
  /// A call to [resume] will also undo a pause.
  ///
  /// If the subscription is paused more than once, an equal number
  /// of resumes must be performed to resume the stream.
  /// Calls to [resume] and the completion of a [resumeSignal] are
  /// interchangeable - the [pause] which was passed a [resumeSignal] may be
  /// ended by a call to [resume], and completing the [resumeSignal] may end a
  /// different [pause].
  ///
  /// It is safe to [resume] or complete a [resumeSignal] even when the
  /// subscription is not paused, and the resume will have no effect.
  void pause([Future<void>? resumeSignal]);

  /// Resumes after a pause.
  ///
  /// This undoes one previous call to [pause].
  /// When all previously calls to [pause] have been matched by a calls to
  /// [resume], possibly through a `resumeSignal` passed to [pause],
  /// the stream subscription may emit events again.
  ///
  /// It is safe to [resume] even when the subscription is not paused, and the
  /// resume will have no effect.
  void resume();

  /// Whether the [StreamSubscription] is currently paused.
  ///
  /// If there have been more calls to [pause] than to [resume] on this
  /// stream subscription, the subscription is paused, and this getter
  /// returns `true`.
  ///
  /// Returns `false` if the stream can currently emit events, or if
  /// the subscription has completed or been cancelled.
  bool get isPaused;

  /// Returns a future that handles the [onDone] and [onError] callbacks.
  ///
  /// This method *overwrites* the existing [onDone] and [onError] callbacks
  /// with new ones that complete the returned future.
  ///
  /// In case of an error the subscription will automatically cancel (even
  /// when it was listening with `cancelOnError` set to `false`).
  ///
  /// In case of a `done` event the future completes with the given
  /// [futureValue].
  ///
  /// If [futureValue] is omitted, the value `null as E` is used as a default.
  /// If `E` is not nullable, this will throw immediately when [asFuture]
  /// is called.
  Future<E> asFuture<E>([E? futureValue]);
}

/// A [Sink] that supports adding errors.
///
/// This makes it suitable for capturing the results of asynchronous
/// computations, which can complete with a value or an error.
///
/// The [EventSink] has been designed to handle asynchronous events from
/// [Stream]s. See, for example, [Stream.eventTransformed] which uses
/// `EventSink`s to transform events.
abstract interface class EventSink<T> implements Sink<T> {
  /// Adds a data [event] to the sink.
  ///
  /// Must not be called on a closed sink.
  void add(T event);

  /// Adds an [error] to the sink.
  ///
  /// Must not be called on a closed sink.
  void addError(Object error, [StackTrace? stackTrace]);

  /// Closes the sink.
  ///
  /// Calling this method more than once is allowed, but does nothing.
  ///
  /// Neither [add] nor [addError] must be called after this method.
  void close();
}

/// [Stream] wrapper that only exposes the [Stream] interface.
class StreamView<T> extends Stream<T> {
  final Stream<T> _stream;

  const StreamView(Stream<T> stream) : _stream = stream;

  bool get isBroadcast => _stream.isBroadcast;

  Stream<T> asBroadcastStream(
          {void onListen(StreamSubscription<T> subscription)?,
          void onCancel(StreamSubscription<T> subscription)?}) =>
      _stream.asBroadcastStream(onListen: onListen, onCancel: onCancel);

  StreamSubscription<T> listen(void onData(T value)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

/// Abstract interface for a "sink" accepting multiple entire streams.
///
/// A consumer can accept a number of consecutive streams using [addStream],
/// and when no further data need to be added, the [close] method tells the
/// consumer to complete its work and shut down.
///
/// The [Stream.pipe] accepts a `StreamConsumer` and will pass the stream
/// to the consumer's [addStream] method. When that completes, it will
/// call [close] and then complete its own returned future.
abstract interface class StreamConsumer<S> {
  /// Consumes the elements of [stream].
  ///
  /// Listens on [stream] and does something for each event.
  ///
  /// Returns a future which is completed when the stream is done being added,
  /// and the consumer is ready to accept a new stream.
  /// No further calls to [addStream] or [close] should happen before the
  /// returned future has completed.
  ///
  /// The consumer may stop listening to the stream after an error,
  /// it may consume all the errors and only stop at a done event,
  /// or it may be canceled early if the receiver don't want any further events.
  ///
  /// If the consumer stops listening because of some error preventing it
  /// from continuing, it may report this error in the returned future,
  /// otherwise it will just complete the future with `null`.
  Future addStream(Stream<S> stream);

  /// Tells the consumer that no further streams will be added.
  ///
  /// This allows the consumer to complete any remaining work and release
  /// resources that are no longer needed
  ///
  /// Returns a future which is completed when the consumer has shut down.
  /// If cleaning up can fail, the error may be reported in the returned future,
  /// otherwise it completes with `null`.
  Future close();
}

/// A object that accepts stream events both synchronously and asynchronously.
///
/// A [StreamSink] combines the methods from [StreamConsumer] and [EventSink].
///
/// The [EventSink] methods can't be used while the [addStream] is called.
/// As soon as the [addStream]'s [Future] completes with a value, the
/// [EventSink] methods can be used again.
///
/// If [addStream] is called after any of the [EventSink] methods, it'll
/// be delayed until the underlying system has consumed the data added by the
/// [EventSink] methods.
///
/// When [EventSink] methods are used, the [done] [Future] can be used to
/// catch any errors.
///
/// When [close] is called, it will return the [done] [Future].
abstract interface class StreamSink<S>
    implements EventSink<S>, StreamConsumer<S> {
  /// Tells the stream sink that no further streams will be added.
  ///
  /// This allows the stream sink to complete any remaining work and release
  /// resources that are no longer needed
  ///
  /// Returns a future which is completed when the stream sink has shut down.
  /// If cleaning up can fail, the error may be reported in the returned future,
  /// otherwise it completes with `null`.
  ///
  /// Returns the same future as [done].
  ///
  /// The stream sink may close before the [close] method is called, either due
  /// to an error or because it is itself providing events to someone who has
  /// stopped listening. In that case, the [done] future is completed first,
  /// and the `close` method will return the `done` future when called.
  ///
  /// Unifies [StreamConsumer.close] and [EventSink.close] which both mark their
  /// object as not expecting any further events.
  Future close();

  /// Return a future which is completed when the [StreamSink] is finished.
  ///
  /// If the `StreamSink` fails with an error,
  /// perhaps in response to adding events using [add], [addError] or [close],
  /// the [done] future will complete with that error.
  ///
  /// Otherwise, the returned future will complete when either:
  ///
  /// * all events have been processed and the sink has been closed, or
  /// * the sink has otherwise been stopped from handling more events
  ///   (for example by canceling a stream subscription).
  Future get done;
}

/// Transforms a Stream.
///
/// When a stream's [Stream.transform] method is invoked with a
/// [StreamTransformer], the stream calls the [bind] method on the provided
/// transformer. The resulting stream is then returned from the
/// [Stream.transform] method.
///
/// Conceptually, a transformer is simply a function from [Stream] to [Stream]
/// that is encapsulated into a class.
///
/// It is good practice to write transformers that can be used multiple times.
///
/// All other transforming methods on [Stream], such as [Stream.map],
/// [Stream.where] or [Stream.expand] can be implemented using
/// [Stream.transform]. A [StreamTransformer] is thus very powerful but often
/// also a bit more complicated to use.
///
/// The [StreamTransformer.fromHandlers] constructor allows passing separate
/// callbacks to react to events, errors, and the end of the stream.
/// The [StreamTransformer.fromBind] constructor creates a `StreamTransformer`
/// whose [bind] method is implemented by calling the function passed to the
/// constructor.
abstract interface class StreamTransformer<S, T> {
  /// Creates a [StreamTransformer] based on the given [onListen] callback.
  ///
  /// The returned stream transformer uses the provided [onListen] callback
  /// when a transformed stream is listened to. At that time, the callback
  /// receives the input stream (the one passed to [bind]) and a
  /// boolean flag `cancelOnError` to create a [StreamSubscription].
  ///
  /// If the transformed stream is a broadcast stream, so is the stream
  /// returned by the [StreamTransformer.bind] method by this transformer.
  ///
  /// If the transformed stream is listened to multiple times, the [onListen]
  /// callback is called again for each new [Stream.listen] call.
  /// This happens whether the stream is a broadcast stream or not,
  /// but the call will usually fail for non-broadcast streams.
  ///
  /// The [onListen] callback does *not* receive the handlers that were passed
  /// to [Stream.listen]. These are automatically set after the call to the
  /// [onListen] callback (using [StreamSubscription.onData],
  /// [StreamSubscription.onError] and [StreamSubscription.onDone]).
  ///
  /// Most commonly, an [onListen] callback will first call [Stream.listen] on
  /// the provided stream (with the corresponding `cancelOnError` flag), and then
  /// return a new [StreamSubscription].
  ///
  /// There are two common ways to create a StreamSubscription:
  ///
  /// 1. by allocating a [StreamController] and to return the result of
  ///    listening to its stream. It's important to forward pause, resume and
  ///    cancel events (unless the transformer intentionally wants to change
  ///    this behavior).
  /// 2. by creating a new class that implements [StreamSubscription].
  ///    Note that the subscription should run callbacks in the [Zone] the
  ///    stream was listened to (see [Zone] and [Zone.bindCallback]).
  ///
  /// Example:
  ///
  /// ```dart
  /// /// Starts listening to [input] and duplicates all non-error events.
  /// StreamSubscription<int> _onListen(Stream<int> input, bool cancelOnError) {
  ///   // Create the result controller.
  ///   // Using `sync` is correct here, since only async events are forwarded.
  ///   var controller = StreamController<int>(sync: true);
  ///   controller.onListen = () {
  ///     var subscription = input.listen((data) {
  ///       // Duplicate the data.
  ///       controller.add(data);
  ///       controller.add(data);
  ///     },
  ///         onError: controller.addError,
  ///         onDone: controller.close,
  ///         cancelOnError: cancelOnError);
  ///     // Controller forwards pause, resume and cancel events.
  ///     controller
  ///       ..onPause = subscription.pause
  ///       ..onResume = subscription.resume
  ///       ..onCancel = subscription.cancel;
  ///   };
  ///   // Return a new [StreamSubscription] by listening to the controller's
  ///   // stream.
  ///   return controller.stream.listen(null);
  /// }
  ///
  /// // Instantiate a transformer:
  /// var duplicator = const StreamTransformer<int, int>(_onListen);
  ///
  /// // Use as follows:
  /// intStream.transform(duplicator);
  /// ```
  const factory StreamTransformer(
          StreamSubscription<T> onListen(
              Stream<S> stream, bool cancelOnError)) =
      _StreamSubscriptionTransformer<S, T>;

  /// Creates a [StreamTransformer] that delegates events to the given functions.
  ///
  /// Example use of a duplicating transformer:
  ///
  /// ```dart
  /// stringStream.transform(StreamTransformer<String, String>.fromHandlers(
  ///     handleData: (String value, EventSink<String> sink) {
  ///       sink.add(value);
  ///       sink.add(value);  // Duplicate the incoming events.
  ///     }));
  /// ```
  ///
  /// When a transformed stream returned from a call to [bind] is listened to,
  /// the source stream is listened to, and a handler function is called for
  /// each event of the source stream.
  ///
  /// The handlers are invoked with the event data and with a sink that can be
  /// used to emit events on the transformed stream.
  ///
  /// The [handleData] handler is invoked for data events on the source stream.
  /// If [handleData] was omitted, data events are added directly to the created
  /// stream, as if calling [EventSink.add] on the sink with the event value.
  /// If [handleData] is omitted the source stream event type, [S], must be a
  /// subtype of the transformed stream event type [T].
  ///
  /// The [handleError] handler is invoked for each error of the source stream.
  /// If [handleError] is omitted, errors are forwarded directly to the
  /// transformed stream, as if calling [EventSink.addError] with the error and
  /// stack trace.
  ///
  /// The [handleDone] handler is invoked when the source stream closes, as
  /// signaled by sending a done event. The done handler takes no event value,
  /// but can still send other events before calling [EventSink.close]. If
  /// [handleDone] is omitted, a done event on the source stream closes the
  /// transformed stream.
  ///
  /// If any handler calls [EventSink.close] on the provided sink,
  /// the transformed sink closes and the source stream subscription
  /// is cancelled. No further events can be added to the sink by
  /// that handler, and no further source stream events will occur.
  ///
  /// The sink provided to the event handlers must only be used during
  /// the call to that handler. It must not be stored and used at a later
  /// time.
  ///
  /// Transformers created this way should be *stateless*.
  /// They should not retain state between invocations of handlers,
  /// because the same transformer, and therefore the same handlers,
  /// may be used on multiple streams, or on streams which can be listened
  /// to more than once.
  /// _To create per-stream handlers, [StreamTransformer.fromBind]
  /// could be used to create a new [StreamTransformer.fromHandlers] per
  /// stream to transform._
  ///
  /// ```dart
  /// var controller = StreamController<String>.broadcast();
  /// controller.onListen = () {
  ///   scheduleMicrotask(() {
  ///     controller.addError("Bad");
  ///     controller.addError("Worse");
  ///     controller.addError("Worst");
  ///   });
  /// };
  /// var sharedState = 0;
  /// var transformedStream = controller.stream.transform(
  ///     StreamTransformer<String>.fromHandlers(
  ///         handleError: (error, stackTrace, sink) {
  ///   sharedState++; // Increment shared error-counter.
  ///   sink.add("Error $sharedState: $error");
  /// }));
  ///
  /// transformedStream.listen(print);
  /// transformedStream.listen(print); // Listen twice.
  /// // Listening twice to the same stream makes the transformer share the same
  /// // state. Instead of having "Error 1: Bad", "Error 2: Worse",
  /// // "Error 3: Worst" as output (each twice for the separate subscriptions),
  /// // this program emits:
  /// // Error 1: Bad
  /// // Error 2: Bad
  /// // Error 3: Worse
  /// // Error 4: Worse
  /// // Error 5: Worst
  /// // Error 6: Worst
  /// ```
  factory StreamTransformer.fromHandlers(
      {void handleData(S data, EventSink<T> sink)?,
      void handleError(Object error, StackTrace stackTrace, EventSink<T> sink)?,
      void handleDone(EventSink<T> sink)?}) = _StreamHandlerTransformer<S, T>;

  /// Creates a [StreamTransformer] based on a [bind] callback.
  ///
  /// The returned stream transformer uses the [bind] argument to implement the
  /// [StreamTransformer.bind] API and can be used when the transformation is
  /// available as a stream-to-stream function.
  ///
  /// ```dart import:convert
  /// final splitDecoded = StreamTransformer<List<int>, String>.fromBind(
  ///     (stream) => stream.transform(utf8.decoder).transform(LineSplitter()));
  /// ```
  @Since("2.1")
  factory StreamTransformer.fromBind(Stream<T> Function(Stream<S>) bind) =
      _StreamBindTransformer<S, T>;

  /// Adapts [source] to be a `StreamTransformer<TS, TT>`.
  ///
  /// This allows [source] to be used at the new type, but at run-time it
  /// must satisfy the requirements of both the new type and its original type.
  ///
  /// Data events passed into the returned transformer must also be instances
  /// of [SS], and data events produced by [source] for those events must
  /// also be instances of [TT].
  static StreamTransformer<TS, TT> castFrom<SS, ST, TS, TT>(
      StreamTransformer<SS, ST> source) {
    return new CastStreamTransformer<SS, ST, TS, TT>(source);
  }

  /// Transforms the provided [stream].
  ///
  /// Returns a new stream with events that are computed from events of the
  /// provided [stream].
  ///
  /// The [StreamTransformer] interface is completely generic,
  /// so it cannot say what subclasses do.
  /// Each [StreamTransformer] should document clearly how it transforms the
  /// stream (on the class or variable used to access the transformer),
  /// as well as any differences from the following typical behavior:
  ///
  /// * When the returned stream is listened to, it starts listening to the
  ///   input [stream].
  /// * Subscriptions of the returned stream forward (in a reasonable time)
  ///   a [StreamSubscription.pause] call to the subscription of the input
  ///   [stream].
  /// * Similarly, canceling a subscription of the returned stream eventually
  ///   (in reasonable time) cancels the subscription of the input [stream].
  ///
  /// "Reasonable time" depends on the transformer and stream. Some transformers,
  /// like a "timeout" transformer, might make these operations depend on a
  /// duration. Others might not delay them at all, or just by a microtask.
  ///
  /// Transformers are free to handle errors in any way.
  /// A transformer implementation may choose to propagate errors,
  /// or convert them to other events, or ignore them completely,
  /// but if errors are ignored, it should be documented explicitly.
  Stream<T> bind(Stream<S> stream);

  /// Provides a `StreamTransformer<RS, RT>` view of this stream transformer.
  ///
  /// The resulting transformer will check at run-time that all data events
  /// of the stream it transforms are actually instances of [S],
  /// and it will check that all data events produced by this transformer
  /// are actually instances of [RT].
  StreamTransformer<RS, RT> cast<RS, RT>();
}

/// Base class for implementing [StreamTransformer].
///
/// Contains default implementations of every method except [bind].
abstract class StreamTransformerBase<S, T> implements StreamTransformer<S, T> {
  const StreamTransformerBase();

  StreamTransformer<RS, RT> cast<RS, RT>() =>
      StreamTransformer.castFrom<S, T, RS, RT>(this);
}

/// An [Iterator]-like interface for the values of a [Stream].
///
/// This wraps a [Stream] and a subscription on the stream. It listens
/// on the stream, and completes the future returned by [moveNext] when the
/// next value becomes available.
///
/// The stream may be paused between calls to [moveNext].
///
/// The [current] value must only be used after a future returned by [moveNext]
/// has completed with `true`, and only until [moveNext] is called again.
abstract interface class StreamIterator<T> {
  /// Create a [StreamIterator] on [stream].
  factory StreamIterator(Stream<T> stream) =>
      // TODO(lrn): use redirecting factory constructor when type
      // arguments are supported.
      new _StreamIterator<T>(stream);

  /// Wait for the next stream value to be available.
  ///
  /// Returns a future which will complete with either `true` or `false`.
  /// Completing with `true` means that another event has been received and
  /// can be read as [current].
  /// Completing with `false` means that the stream iteration is done and
  /// no further events will ever be available.
  /// The future may complete with an error, if the stream produces an error,
  /// which also ends iteration.
  ///
  /// The function must not be called again until the future returned by a
  /// previous call is completed.
  Future<bool> moveNext();

  /// The current value of the stream.
  ///
  /// When a [moveNext] call completes with `true`, the [current] field holds
  /// the most recent event of the stream, and it stays like that until the next
  /// call to [moveNext]. This value must only be read after a call to [moveNext]
  /// has completed with `true`, and only until the [moveNext] is called again.
  ///
  /// If the StreamIterator has not yet been moved to the first element
  /// ([moveNext] has not been called and completed yet), or if the
  /// StreamIterator has been moved past the last element ([moveNext] has
  /// returned `false`), then [current] is unspecified. A [StreamIterator] may
  /// either throw or return an iterator-specific default value in that case.
  T get current;

  /// Cancels the stream iterator (and the underlying stream subscription) early.
  ///
  /// The stream iterator is automatically canceled if the [moveNext] future
  /// completes with either `false` or an error.
  ///
  /// If you need to stop listening for values before the stream iterator is
  /// automatically closed, you must call [cancel] to ensure that the stream
  /// is properly closed.
  ///
  /// If [moveNext] has been called when the iterator is canceled,
  /// its returned future will complete with `false` as value,
  /// as will all further calls to [moveNext].
  ///
  /// Returns a future which completes when the cancellation is complete.
  /// This can be an already completed future if the cancellation happens
  /// synchronously.
  Future cancel();
}

/// Wraps an [_EventSink] so it exposes only the [EventSink] interface.
class _ControllerEventSinkWrapper<T> implements EventSink<T> {
  EventSink? _sink;
  _ControllerEventSinkWrapper(this._sink);

  EventSink _ensureSink() {
    var sink = _sink;
    if (sink == null) throw StateError("Sink not available");
    return sink;
  }

  void add(T data) {
    _ensureSink().add(data);
  }

  void addError(error, [StackTrace? stackTrace]) {
    _ensureSink().addError(error, stackTrace);
  }

  void close() {
    _ensureSink().close();
  }
}

/// An enhanced stream controller provided by [Stream.multi].
///
/// Acts like a normal asynchronous controller, but also allows
/// adding events synchronously.
/// As with any synchronous event delivery, the sender should be very careful
/// to not deliver events at times when a new listener might not
/// be ready to receive them.
/// That usually means only delivering events synchronously in response to other
/// asynchronous events, because that is a time when an asynchronous event could
/// happen.
@Since("2.9")
abstract interface class MultiStreamController<T>
    implements StreamController<T> {
  /// Adds and delivers an event.
  ///
  /// Adds an event like [add] and attempts to deliver it immediately.
  /// Delivery can be delayed if other previously added events are
  /// still pending delivery, if the subscription is paused,
  /// or if the subscription isn't listening yet.
  void addSync(T value);

  /// Adds and delivers an error event.
  ///
  /// Adds an error like [addError] and attempts to deliver it immediately.
  /// Delivery can be delayed if other previously added events are
  /// still pending delivery, if the subscription is paused,
  /// or if the subscription isn't listening yet.
  void addErrorSync(Object error, [StackTrace? stackTrace]);

  /// Closes the controller and delivers a done event.
  ///
  /// Closes the controller like [close] and attempts to deliver a "done"
  /// event immediately.
  /// Delivery can be delayed if other previously added events are
  /// still pending delivery, if the subscription is paused,
  /// or if the subscription isn't listening yet.
  /// If it's necessary to know whether the "done" event has been delivered,
  /// [done] future will complete when that has happened.
  void closeSync();
}
