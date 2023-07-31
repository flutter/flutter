[![Dart CI](https://github.com/dart-lang/async/actions/workflows/test-package.yml/badge.svg)](https://github.com/dart-lang/async/actions/workflows/test-package.yml)
[![pub package](https://img.shields.io/pub/v/async.svg)](https://pub.dev/packages/async)
[![package publisher](https://img.shields.io/pub/publisher/async.svg)](https://pub.dev/packages/async/publisher)

Contains utility classes in the style of `dart:async` to work with asynchronous
computations.

## Package API

* The [`AsyncCache`][AsyncCache] class allows expensive asynchronous
  computations values to be cached for a period of time.

* The [`AsyncMemoizer`][AsyncMemoizer] class makes it easy to only run an
  asynchronous operation once on demand.

* The [`CancelableOperation`][CancelableOperation] class defines an operation
  that can be canceled by its consumer. The producer can then listen for this
  cancellation and stop producing the future when it's received. It can be
  created using a [`CancelableCompleter`][CancelableCompleter].

* The delegating wrapper classes allow users to easily add functionality on top
  of existing instances of core types from `dart:async`. These include
  [`DelegatingFuture`][DelegatingFuture],
  [`DelegatingStream`][DelegatingStream],
  [`DelegatingStreamSubscription`][DelegatingStreamSubscription],
  [`DelegatingStreamConsumer`][DelegatingStreamConsumer],
  [`DelegatingSink`][DelegatingSink],
  [`DelegatingEventSink`][DelegatingEventSink], and
  [`DelegatingStreamSink`][DelegatingStreamSink].

* The [`FutureGroup`][FutureGroup] class makes it easy to wait until a group of
  futures that may change over time completes.

* The [`LazyStream`][LazyStream] class allows a stream to be initialized lazily
  when `.listen()` is first called.

* The [`NullStreamSink`][NullStreamSink] class is an implementation of
  `StreamSink` that discards all events.

* The [`RestartableTimer`][RestartableTimer] class extends `Timer` with a
  `reset()` method.

* The [`Result`][Result] class that can hold either a value or an error. It
  provides various utilities for converting to and from `Future`s and `Stream`s.

* The [`StreamGroup`][StreamGroup] class merges a collection of streams into a
  single output stream.

* The [`StreamQueue`][StreamQueue] class allows a stream to be consumed
  event-by-event rather than being pushed whichever events as soon as they
  arrive.

* The [`StreamSplitter`][StreamSplitter] class allows a stream to be duplicated
  into multiple identical streams.

* The [`StreamZip`][StreamZip] class combines multiple streams into a single
  stream of lists of events.

* This package contains a number of [`StreamTransformer`][StreamTransformer]s.
  [`SingleSubscriptionTransformer`][SingleSubscriptionTransformer] converts a
  broadcast stream to a single-subscription stream, and
  [`typedStreamTransformer`][typedStreamTransformer] casts the type of a
  `Stream`. It also defines a transformer type for [`StreamSink`][StreamSink]s,
  [`StreamSinkTransformer`][StreamSinkTransformer].

* The [`SubscriptionStream`][SubscriptionStream] class wraps a
  `StreamSubscription` so it can be re-used as a `Stream`.

[AsyncCache]: https://pub.dev/documentation/async/latest/async/AsyncCache-class.html
[AsyncMemoizer]: https://pub.dev/documentation/async/latest/async/AsyncMemoizer-class.html
[CancelableCompleter]: https://pub.dev/documentation/async/latest/async/CancelableCompleter-class.html
[CancelableOperation]: https://pub.dev/documentation/async/latest/async/CancelableOperation-class.html
[DelegatingEventSink]: https://pub.dev/documentation/async/latest/async/DelegatingEventSink-class.html
[DelegatingFuture]: https://pub.dev/documentation/async/latest/async/DelegatingFuture-class.html
[DelegatingSink]: https://pub.dev/documentation/async/latest/async/DelegatingSink-class.html
[DelegatingStreamConsumer]: https://pub.dev/documentation/async/latest/async/DelegatingStreamConsumer-class.html
[DelegatingStreamSink]: https://pub.dev/documentation/async/latest/async/DelegatingStreamSink-class.html
[DelegatingStreamSubscription]: https://pub.dev/documentation/async/latest/async/DelegatingStreamSubscription-class.html
[DelegatingStream]: https://pub.dev/documentation/async/latest/async/DelegatingStream-class.html
[FutureGroup]: https://pub.dev/documentation/async/latest/async/FutureGroup-class.html
[LazyStream]: https://pub.dev/documentation/async/latest/async/LazyStream-class.html
[NullStreamSink]: https://pub.dev/documentation/async/latest/async/NullStreamSink-class.html
[RestartableTimer]: https://pub.dev/documentation/async/latest/async/RestartableTimer-class.html
[Result]: https://pub.dev/documentation/async/latest/async/Result-class.html
[SingleSubscriptionTransformer]: https://pub.dev/documentation/async/latest/async/SingleSubscriptionTransformer-class.html
[StreamGroup]: https://pub.dev/documentation/async/latest/async/StreamGroup-class.html
[StreamQueue]: https://pub.dev/documentation/async/latest/async/StreamQueue-class.html
[StreamSinkTransformer]: https://pub.dev/documentation/async/latest/async/StreamSinkTransformer-class.html
[StreamSink]: https://api.dart.dev/stable/dart-async/StreamSink-class.html
[StreamSplitter]: https://pub.dev/documentation/async/latest/async/StreamSplitter-class.html
[StreamTransformer]: https://api.dart.dev/stable/dart-async/StreamTransformer-class.html
[StreamZip]: https://pub.dev/documentation/async/latest/async/StreamZip-class.html
[SubscriptionStream]: https://pub.dev/documentation/async/latest/async/SubscriptionStream-class.html
[typedStreamTransformer]: https://pub.dev/documentation/async/latest/async/typedStreamTransformer.html

## Publishing automation

For information about our publishing automation and release process, see
https://github.com/dart-lang/ecosystem/wiki/Publishing-automation.
