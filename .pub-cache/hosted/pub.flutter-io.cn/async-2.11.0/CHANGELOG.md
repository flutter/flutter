## 2.11.0

* Add `CancelableOperation.fromValue`.
* Add `StreamExtensions.listenAndBuffer`, which buffers events from a stream
  before it has a listener.

## 2.10.0

* Add `CancelableOperation.thenOperation` which gives more flexibility to
  complete the resulting operation.
* Add `CancelableCompleter.completeOperation`.
* Require Dart 2.18

## 2.9.0

* **Potentially Breaking** The default `propagateCancel` argument to
  `CancelableOperation.then` changed from `false` to `true`. In most usages this
  won't have a meaningful difference in behavior, but in usages where the
  behavior is important propagation is the more common need. If there are any
  `CancelableOperation` with multiple listeners where canceling subsequent
  computation using `.then` shouldn't also cancel the original operation, pass
  `propagateCancel: false`.
* Add `StreamExtensions.firstOrNull`.
* Add a `CancelableOperation.fromSubscription()` static factory.
* Add a `CancelableOperation.race()` static method.
* Update `StreamGroup` methods that return a `Future<dynamic>` today to return
  a `Future<void>` instead.
* Deprecated `AsyncCache.fetchStream`.
* Make `AsyncCache.ephemeral` invalidate itself immediately when the returned
  future completes, rather than wait for a later timer event.

## 2.8.2

* Deprecate `EventSinkBase`, `StreamSinkBase`, `IOSinkBase`.

## 2.8.1

* Don't ignore broadcast streams added to a `StreamGroup` that doesn't have an
  active listener but previously had listeners and contains a single
  subscription inner stream.

## 2.8.0

* Add `EventSinkBase`, `StreamSinkBase`, and `IOSinkBase` classes to make it
  easier to implement custom sinks.
* Improve performance for `ChunkedStreamReader` by creating fewer internal
  sublists and specializing to create views for `Uint8List` chunks.

## 2.7.0

* Add a `Stream.slices()` extension method.
* Fix a bug where `CancelableOperation.then` may invoke the `onValue` callback,
  even if it had been canceled before `CancelableOperation.value` completes.
* Fix a bug in `CancelableOperation.isComplete` where it may appear to be
  complete and no longer be cancelable when it in fact could still be canceled.

## 2.6.1

* When `StreamGroup.stream.listen()` is called, gracefully handle component
  streams throwing errors when their `Stream.listen()` methods are called.

## 2.6.0

* Add a `StreamCloser` class, which is a `StreamTransformer` that allows the
  caller to force the stream to emit a done event.
* Added `ChunkedStreamReader` for reading _chunked streams_ without managing
  buffers.
* Add extensions on `StreamSink`, including `StreamSink.transform()` for
  applying `StreamSinkTransformer`s and `StreamSink.rejectErrors()`.
* Add `StreamGroup.isIdle` and `StreamGroup.onIdle`.
* Add `StreamGroup.isClosed` and `FutureGroup.isClosed` getters.

## 2.5.0

* Stable release for null safety.

## 2.5.0-nullsafety.3

* Update SDK constraints to `>=2.12.0-0 <3.0.0` based on beta release
  guidelines.

## 2.5.0-nullsafety.2

* Remove the unusable setter `CancelableOperation.operation=`. This was
  mistakenly added to the public API but could never be called.
* Allow 2.12.0 dev SDK versions.

## 2.5.0-nullsafety.1

* Allow 2.10 stable and 2.11.0 dev SDK versions.

## 2.5.0-nullsafety

* Migrate this package to null safety.

## 2.4.2

* `StreamQueue` starts listening immediately to broadcast strings.

## 2.4.1

* Deprecate `DelegatingStream.typed`. Use `Stream.cast` instead.
* Deprecate `DelegatingStreamSubcription.typed` and
  `DelegatingStreamConsumer.typed`. For each of these the `Stream` should be
  cast to the correct type before being used.
* Deprecate `DelegatingStreamSink.typed`. `DelegatingSink.typed`,
  `DelegatingEventSink.typed`, `DelegatingStreamConsumer.typed`. For each of
  these a new `StreamController` can be constructed to forward to the sink.
  `StreamController<T>()..stream.cast<S>().pipe(sink)`
* Deprecate `typedStreamTransformer`. Cast after transforming instead.
* Deprecate `StreamSinkTransformer.typed` since there was no usage.
* Improve docs for `CancelablOperation.fromFuture`, indicate that `isCompleted`
  starts `true`.

## 2.4.0

* Add `StreamGroup.mergeBroadcast()` utility.

## 2.3.0

* Implement `RestartableTimer.tick`.

## 2.2.0

* Add `then` to `CancelableOperation`.

## 2.1.0

* Fix `CancelableOperation.valueOrCancellation`'s type signature
* Add `isCanceled` and `isCompleted` to `CancelableOperation`.

## 2.0.8

* Set max SDK version to `<3.0.0`.
* Deprecate `DelegatingFuture.typed`, it is not necessary in Dart 2.

## 2.0.7

* Fix Dart 2 runtime errors.
* Stop using deprecated constants from the SDK.

## 2.0.6

* Add further support for Dart 2.0 library changes to `Stream`.

## 2.0.5

* Fix Dart 2.0 [runtime cast errors][sdk#27223] in `StreamQueue`.

[sdk#27223]: https://github.com/dart-lang/sdk/issues/27223

## 2.0.4

* Add support for Dart 2.0 library changes to `Stream` and `StreamTransformer`.
  Changed classes that implement `StreamTransformer` to extend
  `StreamTransformerBase`, and changed signatures of `firstWhere`, `lastWhere`,
  and `singleWhere` on classes extending `Stream`.  See
  also [issue 31847][sdk#31847].

  [sdk#31847]: https://github.com/dart-lang/sdk/issues/31847

## 2.0.3

* Fix a bug in `StreamQueue.startTransaction()` and related methods when
  rejecting a transaction that isn't the oldest request in the queue.

## 2.0.2

* Add support for Dart 2.0 library changes to class `Timer`.

## 2.0.1

* Fix a fuzzy arrow type warning.

## 2.0.0
* Remove deprecated public `result.dart` and `stream_zip.dart` libraries and
  deprecated classes `ReleaseStreamTransformer` and `CaptureStreamTransformer`.

* Add `captureAll` and `flattenList` static methods to `Result`.

* Change `ErrorResult` to not be generic and always be a `Result<Null>`.
  That makes an error independent of the type of result it occurs instead of.

## 1.13.3

* Make `TypeSafeStream` extend `Stream` instead of implementing it. This ensures
  that new methods on `Stream` are automatically picked up, they will go through
  the `listen` method which type-checks every event.

## 1.13.2

* Fix a type-warning.

## 1.13.1

* Use `FutureOr` for various APIs that had previously used `dynamic`.

## 1.13.0

* Add `collectBytes` and `collectBytesCancelable` functions which collects
  list-of-byte events into a single byte list.

* Fix a bug where rejecting a `StreamQueueTransaction` would throw a
  `StateError` if `StreamQueue.rest` had been called on one of its child queues.

* `StreamQueue.withTransaction()` now properly returns whether or not the
  transaction was committed.

## 1.12.0

* Add an `AsyncCache` class that caches asynchronous operations for a period of
  time.

* Add `StreamQueue.peek` and `StreamQueue.lookAheead`.
  These allow users to look at events without consuming them.

* Add `StreamQueue.startTransaction()` and `StreamQueue.withTransaction()`.
  These allow users to conditionally consume events based on their values.

* Add `StreamQueue.cancelable()`, which allows users to easily make a
  `CancelableOperation` that can be canceled without affecting the queue.

* Add `StreamQueue.eventsDispatched` which counts the number of events that have
  been dispatched by a given queue.

* Add a `subscriptionTransformer()` function to create `StreamTransformer`s that
  modify the behavior of subscriptions to a stream.

## 1.11.3

* Fix strong-mode warning against the signature of Future.then

## 1.11.1

* Fix new strong-mode warnings introduced in Dart 1.17.0.

## 1.11.0

* Add a `typedStreamTransformer()` function. This wraps an untyped
  `StreamTransformer` with the correct type parameters, and asserts the types of
  events as they're emitted from the transformed stream.

* Add a `StreamSinkTransformer.typed()` static method. This wraps an untyped
  `StreamSinkTransformer` with the correct type parameters, and asserts the
  types of arguments passed in to the resulting sink.

## 1.10.0

* Add `DelegatingFuture.typed()`, `DelegatingStreamSubscription.typed()`,
  `DelegatingStreamConsumer.typed()`, `DelegatingSink.typed()`,
  `DelegatingEventSink.typed()`, and `DelegatingStreamSink.typed()` static
  methods. These wrap untyped instances of these classes with the correct type
  parameter, and assert the types of values as they're accessed.

* Add a `DelegatingStream` class. This is behaviorally identical to `StreamView`
  from `dart:async`, but it follows this package's naming conventions and
  provides a `DelegatingStream.typed()` static method.

* Fix all strong mode warnings and add generic method annotations.

* `new StreamQueue()`, `new SubscriptionStream()`, `new
  DelegatingStreamSubscription()`, `new DelegatingStreamConsumer()`, `new
  DelegatingSink()`, `new DelegatingEventSink()`, and `new
  DelegatingStreamSink()` now take arguments with generic type arguments (for
  example `Stream<T>`) rather than without (for example `Stream<dynamic>`).
  Passing a type that wasn't `is`-compatible with the fully-specified generic
  would already throw an error under some circumstances, so this is not
  considered a breaking change.

* `ErrorResult` now takes a type parameter.

* `Result.asError` now returns a `Result<T>`.

## 1.9.0

* Deprecate top-level libraries other than `package:async/async.dart`, which
  exports these libraries' interfaces.

* Add `Result.captureStreamTransformer`, `Result.releaseStreamTransformer`,
  `Result.captureSinkTransformer`, and `Result.releaseSinkTransformer`.

* Deprecate `CaptureStreamTransformer`, `ReleaseStreamTransformer`,
  `CaptureSink`, and `ReleaseSink`. `Result.captureStreamTransformer`,
  `Result.releaseStreamTransformer`, `Result.captureSinkTransformer`, and
  `Result.releaseSinkTransformer` should be used instead.

## 1.8.0

- Added `StreamSinkCompleter`, for creating a `StreamSink` now and providing its
  destination later as another sink.

- Added `StreamCompleter.setError`, a shortcut for emitting a single error event
  on the resulting stream.

- Added `NullStreamSink`, an implementation of `StreamSink` that discards all
  events.

## 1.7.0

- Added `SingleSubscriptionTransformer`, a `StreamTransformer` that converts a
  broadcast stream into a single-subscription stream.

## 1.6.0

- Added `CancelableOperation.valueOrCancellation()`, which allows users to be
  notified when an operation is canceled elsewhere.

- Added `StreamSinkTransformer` which transforms events before they're passed to
  a `StreamSink`, similarly to how `StreamTransformer` transforms events after
  they're emitted by a stream.

## 1.5.0

- Added `LazyStream`, which forwards to the return value of a callback that's
  only called when the stream is listened to.

## 1.4.0

- Added `AsyncMemoizer.future`, which allows the result to be accessed before
  `runOnce()` is called.

- Added `CancelableOperation`, an asynchronous operation that can be canceled.
  It can be created using a `CancelableCompleter`.

- Added `RestartableTimer`, a non-periodic timer that can be reset over and
  over.

## 1.3.0

- Added `StreamCompleter` class for creating a stream now and providing its
  events later as another stream.

- Added `StreamQueue` class which allows requesting events from a stream
  before they are avilable. It is like a `StreamIterator` that can queue
  requests.

- Added `SubscriptionStream` which creates a single-subscription stream
  from an existing stream subscription.

- Added a `ResultFuture` class for synchronously accessing the result of a
  wrapped future.

- Added `FutureGroup.onIdle` and `FutureGroup.isIdle`, which provide visibility
  into whether a group is actively waiting on any futures.

- Add an `AsyncMemoizer` class for running an asynchronous block of code exactly
  once.

- Added delegating wrapper classes for a number of core async types:
  `DelegatingFuture`, `DelegatingStreamConsumer`, `DelegatingStreamController`,
  `DelegatingSink`, `DelegatingEventSink`, `DelegatingStreamSink`, and
  `DelegatingStreamSubscription`. These are all simple wrappers that forward all
  calls to the wrapped objects. They can be used to expose only the desired
  interface for subclasses, or extended to add extra functionality.

## 1.2.0

- Added a `FutureGroup` class for waiting for a group of futures, potentially of
  unknown size, to complete.

- Added a `StreamGroup` class for merging the events of a group of streams,
  potentially of unknown size.

- Added a `StreamSplitter` class for splitting a stream into multiple new
  streams.

## 1.1.1

- Updated SDK version constraint to at least 1.9.0.

## 1.1.0

- ChangeLog starts here.
