## 2.1.0

- Add `whereNotNull`.

## 2.0.1

- Require Dart 2.14 or greater.
- Wait for the future returned from `StreamSubscription.cancel()` before
  listening to the subsequent stream in `switchLatest` and `switchMap`.

## 2.0.0

- Migrate to null safety.
- Improve tests of `switchMap` and improve documentation with links and
  clarification.
- Add `trailing` argument to `throttle`.

## 1.2.0

-  Add support for emitting the "leading" event in `debounce`.

## 1.1.1

-   Fix a bug in `asyncMapSample`, `buffer`, `combineLatest`,
    `combineLatestAll`, `merge`, and `mergeAll` which would cause an exception
    when cancelling a subscription after using the transformer if the original
    stream(s) returned `null` from cancelling their subscriptions.

## 1.1.0

-   Add `concurrentAsyncExpand` to interleave events emitted by multiple sub
    streams created by a callback.

## 1.0.0

-   Remove the top level methods and retain the extensions only.

## 0.0.20

-   Add extension methods for most transformers. These should be used in place
    of the current methods. All current implementations are deprecated and will
    be removed in the next major version bump.
    -   Migrating typical use: Instead of
        `stream.transform(debounce(Duration(seconds: 1)))` use
        `stream.debounce(Duration(seconds: 1))`.
    -   To migrate a usage where a `StreamTransformer` instance is stored or
        passed see "Getting a StreamTransformer instance" on the README.
-   The `map` and `chainTransformers` utilities are no longer useful with the
    new patterns so they are deprecated without a replacement. If you still have
    a need for them they can be replicated with `StreamTransformer.fromBind`:

    ```
    // Replace `map(convert)`
    StreamTransformer.fromBind((s) => s.map(convert));

    // Replace `chainTransformers(first, second)`
    StreamTransformer.fromBind((s) => s.transform(first).transform(second));
    ```

## 0.0.19

- Add `asyncMapSample` transform.

## 0.0.18

- Internal cleanup. Passed "trigger" streams or futures now allow `<void>`
  generic type rather than an implicit `dynamic>`

## 0.0.17

- Add concrete types to the `onError` callback in `tap`.

## 0.0.16+1

- Remove usage of Set literal which is not available before Dart 2.2.0

## 0.0.16

- Allow a `combine` callback to return a `FutureOr<T>` in `scan`. There are no
  behavior changes for synchronous callbacks. **Potential breaking change** In
  the unlikely situation where `scan` was used to produce a `Stream<Future>`
  inference may now fail and require explicit generic type arguments.
- Add `combineLatest`.
- Add `combineLatestAll`.

## 0.0.15

- Add `whereType`.

## 0.0.14+1

- Allow using non-dev Dart 2 SDK.

## 0.0.14

- `asyncWhere` will now forward exceptions thrown by the callback through the
  result Stream.
- Added `concurrentAsyncMap`.

## 0.0.13

- `mergeAll` now accepts an `Iterable<Stream>` instead of only `List<Stream>`.

## 0.0.12

- Add `chainTransformers` and `map` for use cases where `StreamTransformer`
  instances are stored as variables or passed to methods other than `transform`.

## 0.0.11

- Renamed `concat` as `followedBy` to match the naming of `Iterable.followedBy`.
  `concat` is now deprecated.

## 0.0.10

- Updates to support Dart 2.0 core library changes (wave
  2.2). See [issue 31847][sdk#31847] for details.

  [sdk#31847]: https://github.com/dart-lang/sdk/issues/31847

## 0.0.9

- Add `asyncMapBuffer`.

## 0.0.8

- Add `takeUntil`.

## 0.0.7

- Bug Fix: Streams produced with `scan` and `switchMap` now correctly report
  `isBroadcast`.
- Add `startWith`, `startWithMany`, and `startWithStream`.

## 0.0.6

- Bug Fix: Some transformers did not correctly add data to all listeners on
  broadcast streams. Fixed for `throttle`, `debounce`, `asyncWhere` and `audit`.
- Bug Fix: Only call the `tap` data callback once per event rather than once per
  listener.
- Bug Fix: Allow canceling and re-listening to broadcast streams after a
  `merge` transform.
- Bug Fix: Broadcast streams which are buffered using a single-subscription
  trigger can be canceled and re-listened.
- Bug Fix: Buffer outputs one more value if there is a pending trigger before
  the trigger closes.
- Bug Fix: Single-subscription streams concatted after broadcast streams are
  handled correctly.
- Use sync `StreamControllers` for forwarding where possible.

## 0.0.5

- Bug Fix: Allow compiling switchLatest with Dart2Js.
- Add `asyncWhere`: Like `where` but allows an asynchronous predicate.

## 0.0.4
- Add `scan`: fold which returns intermediate values
- Add `throttle`: block events for a duration after emitting a value
- Add `audit`: emits the last event received after a duration

## 0.0.3

- Add `tap`: React to values as they pass without being a subscriber on a stream
- Add `switchMap` and `switchLatest`: Flatten a Stream of Streams into a Stream
  which forwards values from the most recent Stream

## 0.0.2

- Add `concat`: Appends streams in series
- Add `merge` and `mergeAll`: Interleaves streams

## 0.0.1

- Initial release with the following utilities:
  - `buffer`: Collects events in a `List` until a `trigger` stream fires.
  - `debounce`, `debounceBuffer`: Collect or drop events which occur closer in
    time than a given duration.
