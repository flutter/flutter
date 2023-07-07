[![Build Status](https://travis-ci.org/dart-lang/stream_transform.svg?branch=master)](https://travis-ci.org/dart-lang/stream_transform)
[![Pub package](https://img.shields.io/pub/v/stream_transform.svg)](https://pub.dev/packages/stream_transform)

Extension methods on `Stream` adding common transform operators.

# Operators

## asyncMapBuffer, asyncMapSample, concurrentAsyncMap

Alternatives to `asyncMap`. `asyncMapBuffer` prevents the callback from
overlapping execution and collects events while it is executing.
`asyncMapSample` prevents overlapping execution and discards events while it is
executing. `concurrentAsyncMap` allows overlap and removes ordering guarantees
for higher throughput.

Like `asyncMap` but events are buffered in a List until previous events have
been processed rather than being called for each element individually.

## asyncWhere

Like `where` but allows an asynchronous predicate.

## audit

Waits for a period of time after receiving a value and then only emits the most
recent value.

## buffer

Collects values from a source stream until a `trigger` stream fires and the
collected values are emitted.

## combineLatest, combineLatestAll

Combine the most recent event from multiple streams through a callback or into a
list.

## debounce, debounceBuffer

Prevents a source stream from emitting too frequently by dropping or collecting
values that occur within a given duration.

## followedBy

Appends the values of a stream after another stream finishes.

## merge, mergeAll, concurrentAsyncExpand

Interleaves events from multiple streams into a single stream.

## scan

Scan is like fold, but instead of producing a single value it yields each
intermediate accumulation.

## startWith, startWithMany, startWithStream

Prepend a value, an iterable, or a stream to the beginning of another stream.

## switchMap, switchLatest

Flatten a Stream of Streams into a Stream which forwards values from the most
recent Stream

## takeUntil

Let values through until a Future fires.

## tap

Taps into a single-subscriber stream to react to values as they pass, without
being a real subscriber.

## throttle

Blocks events for a duration after an event is successfully emitted.

## whereType

Like `Iterable.whereType` for a stream.

# Getting a `StreamTransformer` instance

It may be useful to pass an instance of `StreamTransformer` so that it can be
used with `stream.transform` calls rather than reference the specific operator
in place. Any operator on `Stream` that returns a `Stream` can be modeled as a
`StreamTransformer` using the [`fromBind` constructor][fromBind].

```dart
final debounce = StreamTransformer.fromBind(
    (s) => s.debounce(const Duration(milliseconds: 100)));
```

[fromBind]: https://api.dart.dev/stable/dart-async/StreamTransformer/StreamTransformer.fromBind.html
