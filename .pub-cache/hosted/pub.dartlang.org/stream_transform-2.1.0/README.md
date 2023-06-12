[![Build Status](https://travis-ci.org/dart-lang/stream_transform.svg?branch=master)](https://travis-ci.org/dart-lang/stream_transform)
[![Pub package](https://img.shields.io/pub/v/stream_transform.svg)](https://pub.dev/packages/stream_transform)
[![package publisher](https://img.shields.io/pub/publisher/stream_transform.svg)](https://pub.dev/packages/stream_transform/publisher)

Extension methods on `Stream` adding common transform operators.

## Operators

### asyncMapBuffer, asyncMapSample, concurrentAsyncMap

Alternatives to `asyncMap`. `asyncMapBuffer` prevents the callback from
overlapping execution and collects events while it is executing.
`asyncMapSample` prevents overlapping execution and discards events while it is
executing. `concurrentAsyncMap` allows overlap and removes ordering guarantees
for higher throughput.

Like `asyncMap` but events are buffered in a List until previous events have
been processed rather than being called for each element individually.

### asyncWhere

Like `where` but allows an asynchronous predicate.

### audit

Waits for a period of time after receiving a value and then only emits the most
recent value.

### buffer

Collects values from a source stream until a `trigger` stream fires and the
collected values are emitted.

### combineLatest, combineLatestAll

Combine the most recent event from multiple streams through a callback or into a
list.

### debounce, debounceBuffer

Prevents a source stream from emitting too frequently by dropping or collecting
values that occur within a given duration.

### followedBy

Appends the values of a stream after another stream finishes.

### merge, mergeAll, concurrentAsyncExpand

Interleaves events from multiple streams into a single stream.

### scan

Scan is like fold, but instead of producing a single value it yields each
intermediate accumulation.

### startWith, startWithMany, startWithStream

Prepend a value, an iterable, or a stream to the beginning of another stream.

### switchMap, switchLatest

Flatten a Stream of Streams into a Stream which forwards values from the most
recent Stream

### takeUntil

Let values through until a Future fires.

### tap

Taps into a single-subscriber stream to react to values as they pass, without
being a real subscriber.

### throttle

Blocks events for a duration after an event is successfully emitted.

### whereType

Like `Iterable.whereType` for a stream.

## Comparison to Rx Operators

The semantics and naming in this package have some overlap, and some conflict,
with the [ReactiveX](https://reactivex.io/) suite of libraries. Some of the
conflict is intentional - Dart `Stream` predates `Observable` and coherence with
the Dart ecosystem semantics and naming is a strictly higher priority than
consistency with ReactiveX.

Rx Operator Category      | variation                                              | `stream_transform`
------------------------- | ------------------------------------------------------ | ------------------
[`sample`][rx_sample]     | `sample/throttleLast(Duration)`                        | `sample(Stream.periodic(Duration), longPoll: false)`
&#x200B;                  | `throttleFirst(Duration)`                              | [`throttle`][throttle]
&#x200B;                  | `sample(Observable)`                                   | `sample(trigger, longPoll: false)`
[`debounce`][rx_debounce] | `debounce/throttleWithTimeout(Duration)`               | [`debounce`][debounce]
&#x200B;                  | `debounce(Observable)`                                 | No equivalent
[`buffer`][rx_buffer]     | `buffer(boundary)`, `bufferWithTime`,`bufferWithCount` | No equivalent
&#x200B;                  | `buffer(boundaryClosingSelector)`                      | `buffer(trigger, longPoll: false)`
RxJs extensions           | [`audit(callback)`][rxjs_audit]                        | No equivalent
&#x200B;                  | [`auditTime(Duration)`][rxjs_auditTime]                | [`audit`][audit]
&#x200B;                  | [`exhaustMap`][rxjs_exhaustMap]                        | No equivalent
&#x200B;                  | [`throttleTime(trailing: true)`][rxjs_throttleTime]    | `throttle(trailing: true)`
&#x200B;                  | `throttleTime(leading: false, trailing: true)`         | No equivalent
No equivalent?            |                                                        | [`asyncMapBuffer`][asyncMapBuffer]
&#x200B;                  |                                                        | [`asyncMapSample`][asyncMapSample]
&#x200B;                  |                                                        | [`buffer`][buffer]
&#x200B;                  |                                                        | [`sample`][sample]
&#x200B;                  |                                                        | [`debounceBuffer`][debounceBuffer]
&#x200B;                  |                                                        | `debounce(leading: true, trailing: false)`
&#x200B;                  |                                                        | `debounce(leading: true, trailing: true)`

[rx_sample]:https://reactivex.io/documentation/operators/sample.html
[rx_debounce]:https://reactivex.io/documentation/operators/debounce.html
[rx_buffer]:https://reactivex.io/documentation/operators/buffer.html
[rxjs_audit]:https://rxjs.dev/api/operators/audit
[rxjs_auditTime]:https://rxjs.dev/api/operators/auditTime
[rxjs_throttleTime]:https://rxjs.dev/api/operators/throttleTime
[rxjs_exhaustMap]:https://rxjs.dev/api/operators/exhaustMap
[asyncMapBuffer]:https://pub.dev/documentation/stream_transform/latest/stream_transform/AsyncMap/asyncMapBuffer.html
[asyncMapSample]:https://pub.dev/documentation/stream_transform/latest/stream_transform/AsyncMap/asyncMapSample.html
[audit]:https://pub.dev/documentation/stream_transform/latest/stream_transform/RateLimit/audit.html
[buffer]:https://pub.dev/documentation/stream_transform/latest/stream_transform/RateLimit/buffer.html
[sample]:https://pub.dev/documentation/stream_transform/latest/stream_transform/RateLimit/sample.html
[debounceBuffer]:https://pub.dev/documentation/stream_transform/latest/stream_transform/RateLimit/debounceBuffer.html
[debounce]:https://pub.dev/documentation/stream_transform/latest/stream_transform/RateLimit/debounce.html
[throttle]:https://pub.dev/documentation/stream_transform/latest/stream_transform/RateLimit/throttle.html

## Getting a `StreamTransformer` instance

It may be useful to pass an instance of `StreamTransformer` so that it can be
used with `stream.transform` calls rather than reference the specific operator
in place. Any operator on `Stream` that returns a `Stream` can be modeled as a
`StreamTransformer` using the [`fromBind` constructor][fromBind].

```dart
final debounce = StreamTransformer.fromBind(
    (s) => s.debounce(const Duration(milliseconds: 100)));
```

[fromBind]: https://api.dart.dev/stable/dart-async/StreamTransformer/StreamTransformer.fromBind.html
