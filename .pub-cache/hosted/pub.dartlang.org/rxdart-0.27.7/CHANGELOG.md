## 0.27.7 (2022-11-16)

### Fixed

* `Subject`
  * Only call `onAdd` and `onError` if the subject is not closed.
    This ensures `BehaviorSubject` and `ReplaySubject` do not update their values after they have been closed.

  * `Subject.stream` now returns a **read-only** `Stream`.
    Previously, `Subject.stream` was identical to the `Subject`, so we could add events to it, for example: `(subject.stream as Sink<T>).add(event)`.
    This behavior is now disallowed, and will throw a `TypeError` if attempted. Use `Subject.sink`/`Subject` itself for adding events.

  * Change return type of `ReplaySubject<T>.stream` to `ReplayStream<T>`.
  * Internal refactoring of `Subject.addStream`.

## 0.27.6 (2022-11-11)

* `Rx.using`/`UsingStream`: `resourceFactory` can now return a `Future`.
  This allows for asynchronous resource creation.

* `Rx.range`/`RangeStream`: ensure `RangeStream` is only listened to once.

## 0.27.5 (2022-07-16)

### Bug fixes

* Fix issue [#683](https://github.com/ReactiveX/rxdart/issues/683): Throws runtime type error when using extension
  methods on a `Stream<R>` but its type annotation is `Stream<T>`, `R` is a subtype of `T`
  (covariance issue with `StreamTransformer`).
  ```Dart
  Stream<num> s1 = Stream<int>.fromIterable([1, 2, 3]);
  // throws "type 'SwitchMapStreamTransformer<num, num>' is not a subtype of type 'StreamTransformer<int, num>' of 'streamTransformer'"
  s1.switchMap((v) => Stream.value(v));

  Stream<int?> s2 = Stream<int>.fromIterable([1, 2, 3]);
  // throws "type 'SwitchMapStreamTransformer<int?, int?>' is not a subtype of type 'StreamTransformer<int, int?>' of 'streamTransformer'"
  s2.switchMap((v) => Stream.value(v));
  ```
  Extension methods were previously implemented via `stream.transform(streamTransformer)`, now
  via `streamTransformer.bind(stream)` to avoid this issue.

* Fix `concatEager`: `activeSubscription` should be changed to next subscription.

### Code refactoring

* Change return type of `pairwise` to `Stream<List<T>>`.

## 0.27.4 (2022-05-29)

### Bug fixes

* `withLatestFrom` should iterate over `Iterable<Stream>` only once when the stream is listened to.
* Fix analyzer warnings when using `Dart 2.16.0`.

### Features

* Add `mapNotNull`/`MapNotNullStreamTransformer`.
* Add `whereNotNull`/`WhereNotNullStreamTransformer`.

### Documentation

* Fix grammar errors in code examples (thanks to [@fzyzcjy](https://github.com/fzyzcjy)).
* Update RxMarbles URL for `RaceStream` (thanks to [@Péter Ferenc Gyarmati](https://github.com/peter-gy)).

## 0.27.3 (2021-11-21)

### Bug fixes

* `flatMap` now creates inner `Stream`s lazily.
* `combineLatest`, `concat`, `concatEager`, `forkJoin`, `merge`, `race`, `zip` iterate over `Iterable<Stream>`s only once
  when the stream is listened to.
* Disallow mixing `autoConnect`, `connect` and `refCount` together, only one of them should be used.

### Features

* Introduce `AbstractConnectableStream`, base class for the `ConnectableStream` implementations.
* Improve `CompositeSubscription` (thanks to [@BreX900](https://github.com/BreX900))
  * CompositeSubscription's `dispose`, `clear`, and `remove` methods now return a completion future.
  * Fixed an issue where a stream not present in CompositeSubscription was canceled.
  * Added the ability not to cancel the stream when it is removed from CompositeSubscription.
  * CompositeSubscription implements `StreamSubscription`.
  * `CompositeSubscription.add` will throw a `StateError` instead of a `String` if this composite was disposed.

### Documentation

* Fix `Connectable` examples.
* Update Web example to null safety.
* Fix `Flutter` example: `SearchResultItem.fromJson` type error (thanks to [@WenYeh](https://github.com/wayne900204))

### Code refactoring

* Simplify `takeLast` implementation.
* Migrate from `pedantic` to `lints` and `flutter_lints`.
* Refactor `BehaviorSubject`, `ReplaySubject` implementations by using "`Sentinel object`"s instead of `ValueWrapper`s.

## 0.27.2 (2021-09-03)

### Bug fixes

* `onErrorReturnWith` now does not drop the remaining data events after the first error.
* Disallow changing handlers of `ConnectableStreamSubscription`.

### Features

* Add `delayWhen` operator.
* Add optional parameter `maxConcurrent` to `flatMap`.
* `groupBy`
  * Rename `GroupByStream` to `GroupedStream`.
  * Add optional parameter `durationSelector`, which used to determine how long each group should exist.
* `ignoreElements`
  * Remove `@deprecated` annotation (`ignoreElements` should not be marked as deprecated).
  * Change return type to `Stream<Never>`.

### Documentation

* Update to `PublishSubject`'s docs (thanks to [@AlexanderJohr](https://github.com/AlexanderJohr)).

### Code refactoring

* Refactoring Stream Transformers, using `Stream.multi` internally.

## 0.27.1

* Bugfix: `ForkJoinStream` throws `Null check operator used on a null value` when using nullable-type.
* Bugfix: `delay` operator
  *  Pause and resume properly.
  *  Cancel all timers after it has been cancelled.

## 0.27.0
  * **BREAKING: ValueStream**
    * Remove `ValueStreamExtensions`.
    * `ValueStream.valueWrapper` becomes
      - `value`.
      - `valueOrNull`.
      - `hasValue`.
    * `ValueStream.errorAndStackTrace` becomes
      - `error`.
      - `errorOrNull`.
      - `hasError`.
      - `stackTrace`.
  * Add `skipLast`/`SkipLastStreamTransformer` (thanks [@HannibalKcc](https://github.com/HannibalKcc)).
  * Update `scan`: change `seed` to required param.
  * Add `StackTrace` param to `recoveryFn` when using `OnErrorResumeStreamTransformer`/`onErrorResume`/`onErrorReturnWith`.
  * Internal refactoring `ConnectableStream`.

## 0.26.0
  * Stable, null-safe release.
  * Add `takeLast` (thanks [@ThomasKliszowski](https://github.com/ThomasKliszowski)).
  * Rework for `retry`/`retryWhen`:
    * Removed `RetryError`.
    * `retry`: emits all errors if retry fails.
    * `retryWhen`: emits original error, and error from factory if they are not identical.
    * `streamFactory` now accepts non-nullable `StackTrace` argument.
  * Update `ValueStream.requireValue` and `ValueStream.requireError`: throws actual error or a `StateError`,
    instead of throwing `"Null check operator used on a null value"` error.

## 0.26.0-nullsafety.1
  * Breaking change: `ValueStream`
    - Add `valueWrapper` to `ValueStream`.
    - Change `value`, `hasValue`, `error` and `hasError` to extension getters.
  * Fixed some API example documentation (thanks [@HannibalKcc](https://github.com/HannibalKcc)).
  * `throttle`/`throttleTime` have been optimised for performance.
  * Updated Flutter example to work with the latest Flutter stable.

## 0.26.0-nullsafety.0
  * Migrate this package to null safety.
  * Sdk constraints: `>=2.12.0-0 <3.0.0` based on beta release guidelines.
  
## 0.25.0
  * Sync behavior when using `publishValueSeeded`.
  * `ValueStream`, `ReplayStream`: exposes `stackTrace` along with the `error`:
    * Change `ValueStream.error` to `ValueStream.errorAndStackTrace`.
    * Change `ReplayStream.errors` to `ReplayStream.errorAndStackTraces`.
    * Merge `Notification.error` and `Notification.stackTrace` into `Notification.errorAndStackTrace`.
  * Bugfix: `debounce`/`debounceTime` unnecessarily kept too many elements in queue.

## 0.25.0-beta3
  * Bugfix: `switchMap` doesn't close after the last inner Stream closes.
  * Docs: updated URL for "Single-Subscription vs. Broadcast Streams" doc (thanks [Aman Gupta](https://github.com/Aman9026)).
  * Add `FromCallableStream`/`Rx.fromCallable`: allows you to create a `Stream` from a callable function.
  * Override `BehaviorSubject`'s built-in operators to correct replaying the latest value of `BehaviorSubject`.
  * Bugfix: Source `StreamSubscription` doesn't cancel when cancelling `refCount`, `zip`, `merge`, `concat` StreamSubscription.
  * Forward done event of upstream to `ConnectableStream`.

## 0.25.0-beta2
  * Internal refactoring Stream Transformers.
  * Fixed `RetryStream` example documentation.
  * Error thrown from `DeferStream` factory will now be caught and converted to `Stream.error`.
  * `doOnError` now have strong type signature: `Stream<T> doOnError(void Function(Object, StackTrace) onError)`.
  * Updated `ForkJoinStream`:
    * When any Stream emits an error, listening still continues unless `cancelOnError: true` on the downstream.
    * Pause and resume Streams properly.
  * Added `UsingStream`.
  * Updated `TimerStream`: Pause and resume Timer when pausing and resuming StreamSubscription.

## 0.25.0-beta
  * stream transformations on a ValueStream will also return a ValueStream, instead of 
    a standard broadcast Stream
  * throttle can now be both leading and trailing  
  * better handling of empty Lists when using operators that accept a List as input
  * error & hasError added to BehaviorSubject
  * various docs updates
  * note that this is a beta release, mainly because the behavior of transform has been adjusted (see first bullet)
    if all goes well, we'll release a proper 0.25.0 release soon

## 0.24.1
  * Fix for BehaviorSubject, no longer emits null when using addStream and expecting an Error as first event (thanks [yuvalr1](https://github.com/yuvalr1))
  * min/max have been optimised for performance
  * Further refactors on our Transformers

## 0.24.0
  * Fix throttle no longer outputting the current buffer onDone
  * Adds endWith and endWithMany
  * Fix when using pipe and an Error, Subjects would throw an Exception that couldn't be caught using onError
  * Updates links for docs (thanks [@renefloor](https://github.com/renefloor))
  * Fix links to correct marbles diagram for debounceTime (thanks [@wheater](https://github.com/Wheater))
  * Fix flakiness of withLatestFrom test Streams
  * Update to docs ([@wheater](https://github.com/Wheater))
  * Fix withLatestFrom not pause/resume/cancelling underlying Streams
  * Support sync behavior for Subjects
  * Add addTo extension for StreamSubscription, use it to easily add a subscription to a CompositeSubscription
  * Fix mergeWith and zipWith will return a broadcast Stream, if the source Stream is also broadcast
  * Fix concatWith will return a broadcast Stream, if the source Stream is also broadcast (thanks [@jarekb123](https://github.com/jarekb123))
  * Adds pauseAll, resumeAll, ... to CompositeSubscription
  * Additionally, fixes some issues introduced with 0.24.0-dev.1

## 0.24.0-dev.1
  * Breaking: as of this release, we've refactored the way Stream transformers are set up.
  Previous releases had some incorrect behavior when using certain operators, for example:
    - startWith (startWithMany, startWithError)
    would incorrectly replay the starting event(s) when using a
    broadcast Stream at subscription time.
    - doOnX was not always producing the expected results:
      * doOnData did not output correct sequences on streams that were transformed 
      multiple times in sequence.
      * doOnCancel now acts in the same manner onCancel works on 
      regular subscriptions, i.e. it will now be called when all
      active subscriptions on a Stream are cancelled.
      * doOnListen will now call the first time the Stream is
      subscribed to, and will only call again after all subscribers
      have cancelled, before a new subscription starts.
  
      To properly fix this up, a new way of transforming Streams was introduced.    
      Operators as of now use Stream.eventTransformed and we've refactored all
      operators to implement Sink instead.
  * Adds takeWileInclusive operator (thanks to [@hoc081098](https://github.com/hoc081098))
  
  We encourage everyone to give the dev release(s) a spin and report back if
  anything breaks. If needed, a guide will be written to help migrate from
  the old behavior to the new behavior in certain common use cases.
  
  Keep in mind that we tend to stick as close as we can to how normal
  Dart Streams work!

## 0.23.1

  * Fix API doc links in README

## 0.23.0

  * Extension Methods replace `Observable` class!
  * Please upgrade existing code by using the rxdart_codemod package
  * Remove the Observable class. With extensions, you no longer need to wrap Streams in a [Stream]!
    * Convert all factories to static constructors to aid in discoverability of Stream classes
    * Move all factories to an `Rx` class.
    * Remove `Observable.just`, use `Stream.value`
    * Remove `Observable.error`, use `Stream.error`
    * Remove all tests that check base Stream methods
    * Subjects and *Observable classes extend Stream instead of base Observable
    * Rename *Observable to *Stream to reflect the fact they're just Streams.
      * `ValueObservable` -> `ValueStream`
      * `ReplayObservable` -> `ReplayStream`
      * `ConnectableObservable` -> `ConnectableStream`
      * `ValueConnectableObservable` -> `ValueConnectableStream`
      * `ReplayConnectableObservable` -> `ReplayConnectableStream`
  * All transformation methods removed from Observable class
      * Transformation methods are now Extensions of the Stream class
      * Any Stream can make use of the transformation methods provided by RxDart
    * Observable class remains in place with factory methods to create different types of Streams
    * Removed deprecated `ofType` method, use `whereType` instead
    * Deprecated `concatMap`, use standard Stream `asyncExpand`.
    * Removed `AsObservableFuture`, `MinFuture`, `MaxFuture`, and `WrappedFuture`
      * This removes `asObservable` method in chains
      * Use default `asStream` method from the base `Future` class instead.
      * `min` and `max` now implemented directly on the Stream class

## 0.23.0-dev.3

  * Fix missing exports:
    - `ValueStream`
    - `ReplayStream`
    - `ConnectableStream`
    - `ValueConnectableStream`
    - `ReplayConnectableStream`

## 0.23.0-dev.2
  * Remove the Observable class. With extensions, you no longer need to wrap Streams in a [Stream]!
  * Convert all factories to static constructors to aid in discoverability of Stream classes
  * Move all factories to an `Rx` class.
  * Remove `Observable.just`, use `Stream.value`
  * Remove `Observable.error`, use `Stream.error`
  * Remove all tests that check base Stream methods
  * Subjects and *Observable classes extend Stream instead of base Observable
  * Rename *Observable to *Stream to reflect the fact they're just Streams.
    * `ValueObservable` -> `ValueStream`
    * `ReplayObservable` -> `ReplayStream`
    * `ConnectableObservable` -> `ConnectableStream`
    * `ValueConnectableObservable` -> `ValueConnectableStream`
    * `ReplayConnectableObservable` -> `ReplayConnectableStream`

## 0.23.0-dev.1
  * Feedback on this change appreciated as this is a dev release before 0.23.0 stable!
  * All transformation methods removed from Observable class
    * Transformation methods are now Extensions of the Stream class
    * Any Stream can make use of the transformation methods provided by RxDart
  * Observable class remains in place with factory methods to create different types of Streams
  * Removed deprecated `ofType` method, use `whereType` instead
  * Deprecated `concatMap`, use standard Stream `asyncExpand`.
  * Removed `AsObservableFuture`, `MinFuture`, `MaxFuture`, and `WrappedFuture`
    * This removes `asObservable` method in chains
    * Use default `asStream` method from the base `Future` class instead.
    * `min` and `max` now implemented directly on the Stream class
  
## 0.22.6
  * Bugfix: When listening multiple times to a`BehaviorSubject` that starts with an Error,
  it emits duplicate events.
  * Linter: public_member_api_docs is now used, we have added extra documentation
  where required.

## 0.22.5
  * Bugfix: DeferStream created Stream too early
  * Bugfix: TimerStream created Timer too early

## 0.22.4
  * Bugfix: switchMap controller no longer closes prematurely
  
## 0.22.3
  * Bugfix: whereType failing in Flutter production builds only

## 0.22.2
  * Bugfix: When using a seeded `BehaviorSubject` and adding an `Error`,
    upon listening, the `BehaviorSubject` emits `null` instead of the last `Error`.
  * Bugfix: calling cancel after a `switchMap` can cause a `NoSuchMethodError`.
  * Updated Flutter example to match the latest Flutter release
  * `Observable.withLatestFrom` is now expanded to accept 2 or more `Stream`s
    thanks to Petrus Nguyễn Thái Học (@hoc081098)!
  * Deprecates `ofType` in favor of `whereType`, drop `TypeToken`.

## 0.22.1
  Fixes following issues:
  * Erroneous behavior with scan and `BehaviorSubject`.
  * Bug where `flatMap` would cancel inner subscriptions in `pause`/`resume`.
  * Updates to make the current "pedantic" analyzer happy.

## 0.22.0
  This version includes refactoring for the backpressure operators:
  * Breaking Change: `debounce` is now split into `debounce` and `debounceTime`.
  * Breaking Change: `sample` is now split into `sample` and `sampleTime`.
  * Breaking Change: `throttle` is now split into `throttle` and `throttleTime`.

## 0.21.0
  * Breaking Change: `BehaviorSubject` now has a separate factory constructor `seeded()`
  This allows you to seed this Subject with a `null` value.
  * Breaking Change: `BehaviorSubject` will now emit an `Error`, if the last event was also an `Error`.
  Before, when an `Error` occurred before a `listen`, the subscriber would not be notified of that `Error`.
  To refactor, simply change all occurences of `BehaviorSubject(seedValue: value)` to `BehaviorSubject.seeded(value)`
  * Added the `groupBy` operator
  * Bugix: `doOnCancel`: will now await the cancel result, if it is a `Future`.
  * Removed: `bufferWithCount`, `windowWithCount`, `tween`
  Please use `bufferCount` and `windowCount`, `tween` is removed, because it never was an official Rx spec.
  * Updated Flutter example to work with the latest Flutter stable.

## 0.20.0
  * Breaking Change: bufferCount had buggy behavior when using `startBufferEvery` (was `skip` previously)
  If you were relying on bufferCount with `skip` greater than 1 before, then you may have noticed 
  erroneous behavior.
  * Breaking Change: `repeat` is no longer an operator which simply repeats the last emitted event n-times,
  instead this is now an Observable factory method which takes a StreamFactory and a count parameter.
  This will cause each repeat cycle to create a fresh Observable sequence.
  * `mapTo` is a new operator, which works just like `map`, but instead of taking a mapper Function, it takes
  a single value where each event is mapped to.
  * Bugfix: switchIfEmpty now correctly calls onDone
  * combineLatest and zip can now take any amount of Streams:
    * combineLatest2-9 & zip2-9 functionality unchanged, but now use a new path for construction.
    * adds combineLatest and zipLatest which allows you to pass through an Iterable<Stream<T>> and a combiner that takes a List<T> when any source emits a change.
    * adds combineLatestList / zipList which allows you to take in an Iterable<Stream<T>> and emit a Observable<List<T>> with the values. Just a convenience factory if all you want is the list!
    * Constructors are provided by the Stream implementation directly
  * Bugfix: Subjects that are transformed will now correctly return a new Observable where isBroadcast is true (was false before)  
  * Remove deprecated operators which were replaced long ago: `bufferWithCount`, `windowWithCount`, `amb`, `flatMapLatest`

## 0.19.0

  * Breaking Change: Subjects `onCancel` function now returns `void` instead of `Future` to properly comply with the `StreamController` signature.
  * Bugfix: FlatMap operator properly calls onDone for all cases
  * Connectable Observable: An observable that can be listened to multiple times, and does not begin emitting values until the `connect` method is called
  * ValueObservable: A new interface that allows you to get the latest value emitted by an Observable.
    * Implemented by BehaviorSubject
    * Convert normal observables into ValueObservables via `publishValue` or `shareValue`
  * ReplayObservable: A new interface that allows you to get the values emitted by an Observable.
      * Implemented by ReplaySubject
      * Convert normal observables into ReplayObservables via `publishReplay` or `shareReplay`  

## 0.18.1

* Add `retryWhen` operator. Thanks to Razvan Lung (@long1eu)! This can be used for custom retry logic.

## 0.18.0

* Breaking Change: remove `retype` method, deprecated as part of Dart 2.
* Add `flatMapIterable`

## 0.17.0

* Breaking Change: `stream` property on Observable is now private.
  * Avoids API confusion
  * Simplifies Subject implementation
  * Require folks who are overriding the `stream` property to use a `super` constructor instead 
* Adds proper onPause and onResume handling for `amb`/`race`, `combineLatest`, `concat`, `concat_eager`, `merge`  and `zip`
* Add `switchLatest` operator
* Add errors and stacktraces to RetryError class
* Add `onErrorResume` and `onErrorRetryWith` operators. These allow folks to return a specific stream or value depending on the error that occurred. 

## 0.16.7

* Fix new buffer and window implementation for Flutter + Dart 2
* Subject now implements the Observable interface

## 0.16.6

* Rework for `buffer` and `window`, allow to schedule using a sampler
* added `buffer`
* added `bufferFuture`
* added `bufferTest`
* added `bufferTime`
* added `bufferWhen`
* added `window`
* added `windowFuture`
* added `windowTest`
* added `windowTime`
* added `windowWhen`
* added `onCount` sampler for `buffer` and `window`
* added `onFuture` sampler for `buffer` and `window`
* added `onTest` sampler for `buffer` and `window`
* added `onTime` sampler for `buffer` and `window`
* added `onStream` sampler for `buffer` and `window`

## 0.16.5

* Renames `amb` to `race`
* Renames `flatMapLatest` to `switchMap`
* Renames `bufferWithCount` to `bufferCount`
* Renames `windowWithCount` to `windowCount`

## 0.16.4

* Adds `bufferTime` transformer.
* Adds `windowTime` transformer.

## 0.16.3

* Adds `delay` transformer.

## 0.16.2

* Fix added events to `sink` are not processed correctly by `Subjects`.

## 0.16.1

* Fix `dematerialize` method for Dart 2.

## 0.16.0+2

* Add `value` to `BehaviorSubject`. Allows you to get the latest value emitted by the subject if it exists.
* Add `values` to `ReplayrSubject`. Allows you to get the values stored by the subject if any exists.

## 0.16.0+1

* Update Changelog

## 0.16.0

* **breaks backwards compatibility**, this release only works with Dart SDK >=2.0.0.
* Removed old `cast` in favour of the now native Stream cast method.
* Override `retype` to return an `Observable`.

## 0.15.1

* Add `exhaustMap` map to inner observable, ignore other values until that observable completes.
* Improved code to be dartdevc compatible.
* Add upper SDK version limit in pubspec

## 0.15.0

* Change `debounce` to emit the last item of the source stream as soon as the source stream completes.
* Ensure `debounce` does not keep open any addition async timers after it has been cancelled.

## 0.14.0+1

* Change `DoStreamTransformer` to return a `Future` on cancel for api compatibility. 

## 0.14.0

* Add `PublishSubject` (thanks to @pauldemarco)
* Fix bug with `doOnX` operators where callbacks were fired too often

## 0.13.1

* Fix error with FlatMapLatest where it was not properly cancelled in some scenarios
* Remove additional async methods on Stream handlers unless they're shown to solve a problem

## 0.13.0

* Remove `call` operator / `StreamTransformer` entirely
* Important bug fix: Errors thrown within any Stream or Operator will now be properly sent to the `StreamSubscription`.
* Improve overall handling of errors throughout the library to ensure they're handled correctly

## 0.12.0

* Added doOn* operators in place of `call`.
* Added `DoStreamTransformer` as a replacement for `CallStreamTransformer`
* Deprecated `call` and `CallStreamTransformer`. Please use the appropriate `doOnX` operator / transformer.
* Added `distinctUnique`. Emits items if they've never been emitted before. Same as to Rx#distinct.

## 0.11.0

* !!!Breaking Api Change!!!
    * Observable.groupBy has been removed in order to be compatible with the next version of the `Stream` class in Dart 1.24.0, which includes this method

## 0.10.2

* BugFix: The new Subject implementation no longer causes infinite loops when used with ng2 async pipes.

## 0.10.1

* Documentation fixes

## 0.10.0

* Api Changes
  * Observable
    * Remove all deprecated methods, including:
      * `observable` factory -- replaced by the constructor `new Observable()`
      * `combineLatest` -- replaced by Strong-Mode versions `combineLatest2` - `combineLatest9`
      * `zip` -- replaced by Strong-Mode versions `zip2` - `zip9`
    * Support `asObservable` conversion from Future-returning methods. e.g. `new Observable.fromIterable([1, 2]).first.asObservable()`
    * Max and Min now return a Future of the Max or Min value, rather than a stream of increasing or decreasing values.
    * Add `cast` operator
    * Remove `ConcatMapStreamTransformer` -- functionality is already supported by `asyncExpand`. Keep the `concatMap` method as an alias.
  * Subjects
    * BehaviourSubject has been renamed to BehaviorSubject
    * The subjects have been rewritten and include far more testing
    * In keeping with the Rx idea of Subjects, they are broadcast-only
* Documentation -- extensive documentation has been added to the library with explanations and examples for each Future, Stream & Transformer.
  * Docs detailing the differences between RxDart and raw Observables.
  
## 0.9.0

* Api Changes:
  * Convert all StreamTransformer factories to proper classes
    * Ensure these classes can be re-used multiple times
  * Retry has moved from an operator to a constructor. This is to ensure the stream can be properly re-constructed every time in the correct way.
  * Streams now properly enforce the single-subscription contract
* Include example Flutter app. To run it, please follow the instructions in the README.

## 0.8.3+1
* rename examples map to example

## 0.8.3
* added concatWith, zipWith, mergeWith, skipUntil
* cleanup of the examples folder
* cleanup of examples code
* added fibonacci example
* added search GitHub example

## 0.8.2+1
* moved repo into ReactiveX
* update readme badges accordingly

## 0.8.2
* added materialize/dematerialize
* added range (factory)
* added timer (factory)
* added timestamp
* added concatMap

## 0.8.1
* added never constructor
* added error constructor
* moved code coverage to [codecov.io](https://codecov.io/gh/frankpepermans/rxdart)

## 0.8.0
* BREAKING: tap is replaced by call(onData)
* added call, which can take any combination of the following event methods: 
onCancel, onData, onDone, onError, onListen, onPause, onResume

## 0.7.1+1
* improved the README file

## 0.7.1
* added ignoreElements
* added onErrorResumeNext
* added onErrorReturn
* added switchIfEmpty
* added empty factory constructor

## 0.7.0
* BREAKING: rename combineXXXLatest and zipXXX to a numbered equivalent,
for example: combineThreeLatest becomes combineLatest3
* internal refactoring, expose streams/stream transformers as a separate library

## 0.6.3+4
* changed ofType to use TypeToken

## 0.6.3+3
* added ofType

## 0.6.3+2
* added defaultIfEmpty

## 0.6.3+1
* changed concat, old concat is now concatEager, new concat behaves as expected

## 0.6.3
* Added withLatestFrom 
* Added defer ctr
(both thanks to [brianegan](https://github.com/brianegan "GitHub link"))

## 0.6.2
* Added just (thanks to [brianegan](https://github.com/brianegan "GitHub link"))
* Added groupBy
* Added amb

## 0.6.1
* Added concat

## 0.6.0
* BREAKING: startWith now takes just one parameter instead of an Iterable. To add multiple starting events, please use startWithMany.
* Added BehaviourSubject and ReplaySubject. These implement StreamController.
* BehaviourSubject will notify the last added event upon listening.
* ReplaySubject will notify all past events upon listening.
* DEPRECATED: zip and combineLatest, use their strong-type-friendly alternatives instead (available as static methods on the Observable class, i.e. Observable.combineThreeLatest, Observable.zipFour, ...)

## 0.5.1

* Added documentation (thanks to [dustinlessard-wf](https://github.com/dustinlessard-wf "GitHub link"))
* Fix tests breaking due to deprecation of expectAsync
* Fix tests to satisfy strong mode requirements

## 0.5.0

* As of this version, rxdart depends on SDK v1.21.0, to support the newly added generic method type syntax

