# RxDart

[![Build Status](https://github.com/ReactiveX/rxdart/workflows/Dart%20CI/badge.svg)](https://github.com/ReactiveX/rxdart/actions)
[![codecov](https://codecov.io/gh/ReactiveX/rxdart/branch/master/graph/badge.svg)](https://codecov.io/gh/ReactiveX/rxdart)
[![Pub](https://img.shields.io/pub/v/rxdart.svg)](https://pub.dartlang.org/packages/rxdart)
[![Gitter](https://img.shields.io/gitter/room/ReactiveX/rxdart.svg)](https://gitter.im/ReactiveX/rxdart)
[![Build Flutter example](https://github.com/ReactiveX/rxdart/actions/workflows/flutter-example.yml/badge.svg)](https://github.com/ReactiveX/rxdart/actions/workflows/flutter-example.yml)

## About

RxDart extends the capabilities of Dart
[Streams](https://api.dart.dev/stable/dart-async/Stream-class.html) and
[StreamControllers](https://api.dart.dev/stable/dart-async/StreamController-class.html).

Dart comes with a very decent
[Streams](https://api.dart.dev/stable/dart-async/Stream-class.html) API
out-of-the-box; rather than attempting to provide an alternative to this API,
RxDart adds functionality from the reactive extensions specification on top of
it. 

RxDart does not provide its Observable class as a replacement for Dart 
Streams. Instead, it offers several additional Stream classes, operators 
(extension methods on the Stream class), and Subjects. 

If you are familiar with Observables from other languages, please see [the Rx
Observables vs. Dart Streams comparison chart](#rx-observables-vs-dart-streams)
for notable distinctions between the two.

## Upgrading from RxDart 0.22.x to 0.23.x

RxDart 0.23.x moves away from the Observable class, utilizing Dart 2.6's new
extension methods instead. This requires several small refactors that can be
easily automated -- which is just what we've done!

Please follow the instructions on the
[rxdart_codemod](https://pub.dev/packages/rxdart_codemod) package to 
automatically upgrade your code to support RxDart 0.23.x.

## How To Use RxDart

### For Example: Reading the Konami Code 

```dart
import 'package:rxdart/rxdart.dart';

void main() {
  const konamiKeyCodes = <int>[
    KeyCode.UP,
    KeyCode.UP,
    KeyCode.DOWN,
    KeyCode.DOWN,
    KeyCode.LEFT,
    KeyCode.RIGHT,
    KeyCode.LEFT,
    KeyCode.RIGHT,
    KeyCode.B,
    KeyCode.A,
  ];

  final result = querySelector('#result')!;

  document.onKeyUp
      .map((event) => event.keyCode)
      .bufferCount(10, 1) // An extension method provided by rxdart
      .where((lastTenKeyCodes) => const IterableEquality<int>().equals(lastTenKeyCodes, konamiKeyCodes))
      .listen((_) => result.innerHtml = 'KONAMI!');
}
```

## API Overview

RxDart adds functionality to Dart Streams in three ways:

  * [Stream Classes](#stream-classes) - create Streams with specific capabilities, such as combining or merging many Streams.
  * [Extension Methods](#extension-methods) - transform a source Stream into a new Stream with different capabilities, such as throttling or buffering events.
  * [Subjects](#subjects) - StreamControllers with additional powers 

### Stream Classes

The Stream class provides different ways to create a Stream: `Stream.fromIterable` or `Stream.periodic`. RxDart provides additional Stream classes for a variety of tasks, such as combining or merging Streams!

You can construct the Streams provided by RxDart in two ways. The following examples are equivalent in terms of functionality:
 
  - Instantiating the Stream class directly. 
    - Example: `final mergedStream = MergeStream([myFirstStream, mySecondStream]);`
  - Using static factories from the Rx class, which are useful for discovering which types of Streams are provided by RxDart. Under the hood, these factories call the corresponding Stream constructor.  
    - Example: `final mergedStream = Rx.merge([myFirstStream, mySecondStream]);`

#### List of Classes / Static Factories

- [CombineLatestStream](https://pub.dev/documentation/rxdart/latest/rx/CombineLatestStream-class.html) (combine2, combine3... combine9) / [Rx.combineLatest2](https://pub.dev/documentation/rxdart/latest/rx/Rx/combineLatest2.html)...[Rx.combineLatest9](https://pub.dev/documentation/rxdart/latest/rx/Rx/combineLatest9.html)
- [ConcatStream](https://pub.dev/documentation/rxdart/latest/rx/ConcatStream-class.html) / [Rx.concat](https://pub.dev/documentation/rxdart/latest/rx/Rx/concat.html)
- [ConcatEagerStream](https://pub.dev/documentation/rxdart/latest/rx/ConcatEagerStream-class.html) / [Rx.concatEager](https://pub.dev/documentation/rxdart/latest/rx/Rx/concatEager.html)
- [DeferStream](https://pub.dev/documentation/rxdart/latest/rx/DeferStream-class.html) / [Rx.defer](https://pub.dev/documentation/rxdart/latest/rx/Rx/defer.html)
- [ForkJoinStream](https://pub.dev/documentation/rxdart/latest/rx/ForkJoinStream-class.html) (join2, join3... join9) / [Rx.forkJoin2](https://pub.dev/documentation/rxdart/latest/rx/Rx/forkJoin2.html)...[Rx.forkJoin9](https://pub.dev/documentation/rxdart/latest/rx/Rx/forkJoin9.html)
- [FromCallableStream](https://pub.dev/documentation/rxdart/latest/rx/FromCallableStream-class.html) / [Rx.fromCallable](https://pub.dev/documentation/rxdart/latest/rx/Rx/fromCallable.html)
- [MergeStream](https://pub.dev/documentation/rxdart/latest/rx/MergeStream-class.html) / [Rx.merge](https://pub.dev/documentation/rxdart/latest/rx/Rx/merge.html)
- [NeverStream](https://pub.dev/documentation/rxdart/latest/rx/NeverStream-class.html) / [Rx.never](https://pub.dev/documentation/rxdart/latest/rx/Rx/never.html)
- [RaceStream](https://pub.dev/documentation/rxdart/latest/rx/RaceStream-class.html) / [Rx.race](https://pub.dev/documentation/rxdart/latest/rx/Rx/race.html)
- [RangeStream](https://pub.dev/documentation/rxdart/latest/rx/RangeStream-class.html) / [Rx.range](https://pub.dev/documentation/rxdart/latest/rx/Rx/range.html)
- [RepeatStream](https://pub.dev/documentation/rxdart/latest/rx/RepeatStream-class.html) / [Rx.repeat](https://pub.dev/documentation/rxdart/latest/rx/Rx/repeat.html)
- [RetryStream](https://pub.dev/documentation/rxdart/latest/rx/RetryStream-class.html) / [Rx.retry](https://pub.dev/documentation/rxdart/latest/rx/Rx/retry.html)
- [RetryWhenStream](https://pub.dev/documentation/rxdart/latest/rx/RetryWhenStream-class.html) / [Rx.retryWhen](https://pub.dev/documentation/rxdart/latest/rx/Rx/retryWhen.html)
- [SequenceEqualStream](https://pub.dev/documentation/rxdart/latest/rx/SequenceEqualStream-class.html) / [Rx.sequenceEqual](https://pub.dev/documentation/rxdart/latest/rx/Rx/sequenceEqual.html)
- [SwitchLatestStream](https://pub.dev/documentation/rxdart/latest/rx/SwitchLatestStream-class.html) / [Rx.switchLatest](https://pub.dev/documentation/rxdart/latest/rx/Rx/switchLatest.html)
- [TimerStream](https://pub.dev/documentation/rxdart/latest/rx/TimerStream-class.html) / [Rx.timer](https://pub.dev/documentation/rxdart/latest/rx/Rx/timer.html)
- [UsingStream](https://pub.dev/documentation/rxdart/latest/rx/UsingStream-class.html) / [Rx.using](https://pub.dev/documentation/rxdart/latest/rx/Rx/using.html)
- [ZipStream](https://pub.dev/documentation/rxdart/latest/rx/ZipStream-class.html) (zip2, zip3, zip4, ..., zip9) / [Rx.zip](https://pub.dev/documentation/rxdart/latest/rx/Rx/zip2.html)...[Rx.zip9](https://pub.dev/documentation/rxdart/latest/rx/Rx/zip9.html)
- If you're looking for an [Interval](https://reactivex.io/documentation/operators/interval.html) equivalent, check out Dart's [Stream.periodic](https://api.dart.dev/stable/2.7.2/dart-async/Stream/Stream.periodic.html) for similar behavior.

### Extension Methods

The extension methods provided by RxDart can be used on any `Stream`. They convert a source Stream into a new Stream with additional capabilities, such as buffering or throttling events.

#### Example

```dart
Stream.fromIterable([1, 2, 3])
  .throttleTime(Duration(seconds: 1))
  .listen(print); // prints 3
``` 

#### List of Extension Methods

- [buffer](https://pub.dev/documentation/rxdart/latest/rx/BufferExtensions/buffer.html)
- [bufferCount](https://pub.dev/documentation/rxdart/latest/rx/BufferExtensions/bufferCount.html)
- [bufferTest](https://pub.dev/documentation/rxdart/latest/rx/BufferExtensions/bufferTest.html)
- [bufferTime](https://pub.dev/documentation/rxdart/latest/rx/BufferExtensions/bufferTime.html)
- [concatWith](https://pub.dev/documentation/rxdart/latest/rx/ConcatExtensions/concatWith.html)
- [debounce](https://pub.dev/documentation/rxdart/latest/rx/DebounceExtensions/debounce.html)
- [debounceTime](https://pub.dev/documentation/rxdart/latest/rx/DebounceExtensions/debounceTime.html)
- [defaultIfEmpty](https://pub.dev/documentation/rxdart/latest/rx/DefaultIfEmptyExtension/defaultIfEmpty.html)
- [delay](https://pub.dev/documentation/rxdart/latest/rx/DelayExtension/delay.html)
- [delayWhen](https://pub.dev/documentation/rxdart/latest/rx/DelayWhenExtension/delayWhen.html)
- [dematerialize](https://pub.dev/documentation/rxdart/latest/rx/DematerializeExtension/dematerialize.html)
- [distinctUnique](https://pub.dev/documentation/rxdart/latest/rx/DistinctUniqueExtension/distinctUnique.html)
- [doOnCancel](https://pub.dev/documentation/rxdart/latest/rx/DoExtensions/doOnCancel.html)
- [doOnData](https://pub.dev/documentation/rxdart/latest/rx/DoExtensions/doOnData.html)
- [doOnDone](https://pub.dev/documentation/rxdart/latest/rx/DoExtensions/doOnDone.html)
- [doOnEach](https://pub.dev/documentation/rxdart/latest/rx/DoExtensions/doOnEach.html)
- [doOnError](https://pub.dev/documentation/rxdart/latest/rx/DoExtensions/doOnError.html)
- [doOnListen](https://pub.dev/documentation/rxdart/latest/rx/DoExtensions/doOnListen.html)
- [doOnPause](https://pub.dev/documentation/rxdart/latest/rx/DoExtensions/doOnPause.html)
- [doOnResume](https://pub.dev/documentation/rxdart/latest/rx/DoExtensions/doOnResume.html)
- [endWith](https://pub.dev/documentation/rxdart/latest/rx/EndWithExtension/endWith.html)
- [endWithMany](https://pub.dev/documentation/rxdart/latest/rx/EndWithManyExtension/endWithMany.html) 
- [exhaustMap](https://pub.dev/documentation/rxdart/latest/rx/ExhaustMapExtension/exhaustMap.html)
- [flatMap](https://pub.dev/documentation/rxdart/latest/rx/FlatMapExtension/flatMap.html)
- [flatMapIterable](https://pub.dev/documentation/rxdart/latest/rx/FlatMapExtension/flatMapIterable.html)
- [groupBy](https://pub.dev/documentation/rxdart/latest/rx/GroupByExtension/groupBy.html)
- [interval](https://pub.dev/documentation/rxdart/latest/rx/IntervalExtension/interval.html)
- [mapNotNull](https://pub.dev/documentation/rxdart/latest/rx/MapNotNullExtension/mapNotNull.html)
- [mapTo](https://pub.dev/documentation/rxdart/latest/rx/MapToExtension/mapTo.html)
- [materialize](https://pub.dev/documentation/rxdart/latest/rx/MaterializeExtension/materialize.html)
- [max](https://pub.dev/documentation/rxdart/latest/rx/MaxExtension/max.html)
- [mergeWith](https://pub.dev/documentation/rxdart/latest/rx/MergeExtension/mergeWith.html)
- [min](https://pub.dev/documentation/rxdart/latest/rx/MinExtension/min.html)
- [onErrorResume](https://pub.dev/documentation/rxdart/latest/rx/OnErrorExtensions/onErrorResume.html)
- [onErrorResumeNext](https://pub.dev/documentation/rxdart/latest/rx/OnErrorExtensions/onErrorResumeNext.html)
- [onErrorReturn](https://pub.dev/documentation/rxdart/latest/rx/OnErrorExtensions/onErrorReturn.html)
- [onErrorReturnWith](https://pub.dev/documentation/rxdart/latest/rx/OnErrorExtensions/onErrorReturnWith.html)
- [pairwise](https://pub.dev/documentation/rxdart/latest/rx/PairwiseExtension/pairwise.html)
- [sample](https://pub.dev/documentation/rxdart/latest/rx/SampleExtensions/sample.html)
- [sampleTime](https://pub.dev/documentation/rxdart/latest/rx/SampleExtensions/sampleTime.html)
- [scan](https://pub.dev/documentation/rxdart/latest/rx/ScanExtension/scan.html)
- [skipLast](https://pub.dev/documentation/rxdart/latest/rx/SkipLastExtension/skipLast.html)
- [skipUntil](https://pub.dev/documentation/rxdart/latest/rx/SkipUntilExtension/skipUntil.html)
- [startWith](https://pub.dev/documentation/rxdart/latest/rx/StartWithExtension/startWith.html)
- [startWithMany](https://pub.dev/documentation/rxdart/latest/rx/StartWithManyExtension/startWithMany.html) 
- [switchIfEmpty](https://pub.dev/documentation/rxdart/latest/rx/SwitchIfEmptyExtension/switchIfEmpty.html)
- [switchMap](https://pub.dev/documentation/rxdart/latest/rx/SwitchMapExtension/switchMap.html)
- [takeLast](https://pub.dev/documentation/rxdart/latest/rx/TakeLastExtension/takeLast.html)
- [takeUntil](https://pub.dev/documentation/rxdart/latest/rx/TakeUntilExtension/takeUntil.html)
- [takeWhileInclusive](https://pub.dev/documentation/rxdart/latest/rx/TakeWhileInclusiveExtension/takeWhileInclusive.html)
- [throttle](https://pub.dev/documentation/rxdart/latest/rx/ThrottleExtensions/throttle.html)
- [throttleTime](https://pub.dev/documentation/rxdart/latest/rx/ThrottleExtensions/throttleTime.html)
- [timeInterval](https://pub.dev/documentation/rxdart/latest/rx/TimeIntervalExtension/timeInterval.html)
- [timestamp](https://pub.dev/documentation/rxdart/latest/rx/TimeStampExtension/timestamp.html)
- [whereNotNull](https://pub.dev/documentation/rxdart/latest/rx/WhereNotNullExtension/whereNotNull.html)
- [whereType](https://pub.dev/documentation/rxdart/latest/rx/WhereTypeExtension/whereType.html)
- [window](https://pub.dev/documentation/rxdart/latest/rx/WindowExtensions/window.html)
- [windowCount](https://pub.dev/documentation/rxdart/latest/rx/WindowExtensions/windowCount.html)
- [windowTest](https://pub.dev/documentation/rxdart/latest/rx/WindowExtensions/windowTest.html)
- [windowTime](https://pub.dev/documentation/rxdart/latest/rx/WindowExtensions/windowTime.html)
- [withLatestFrom](https://pub.dev/documentation/rxdart/latest/rx/WithLatestFromExtensions.html)
- [zipWith](https://pub.dev/documentation/rxdart/latest/rx/ZipWithExtension/zipWith.html)

### Subjects

Dart provides the [StreamController](https://api.dart.dev/stable/dart-async/StreamController-class.html) class to create and manage a Stream. RxDart offers two additional StreamControllers with additional capabilities, known as Subjects:
 
- [BehaviorSubject](https://pub.dev/documentation/rxdart/latest/rx/BehaviorSubject-class.html) - A broadcast StreamController that caches the latest added value or error. When a new listener subscribes to the Stream, the latest value or error will be emitted to the listener. Furthermore, you can synchronously read the last emitted value. 
- [ReplaySubject](https://pub.dev/documentation/rxdart/latest/rx/ReplaySubject-class.html) - A broadcast StreamController that caches the added values. When a new listener subscribes to the Stream, the cached values will be emitted to the listener.

## Rx Observables vs Dart Streams

In many situations, Streams and Observables work the same way. However, if you're used to standard Rx Observables, some features of the Stream API may surprise you. We've included a table below to help folks understand the differences. 

Additional information about the following situations can be found by reading the [Rx class documentation](https://pub.dev/documentation/rxdart/latest/rx/Rx-class.html).

| Situation | Rx Observables  | Dart Streams |
| ------------- |------------- | ------------- |
| An error is raised | Observable Terminates with Error  | Error is emitted and Stream continues |
| Cold Observables  | Multiple subscribers can listen to the same cold Observable, and each subscription will receive a unique Stream of data | Single subscriber only | 
| Hot Observables  | Yes | Yes, known as Broadcast Streams | 
| Is {Publish, Behavior, Replay}Subject hot? | Yes | Yes |
| Single/Maybe/Completable ? | Yes | Yes, uses [rxdart_ext Single](https://pub.dev/documentation/rxdart_ext/latest/single/Single-class.html) (`Completable = Single<void>, Maybe<T> = Single<T?>`) |
| Support back pressure| Yes | Yes |
| Can emit null? | Yes, except RxJava | Yes |
| Sync by default | Yes | No |
| Can pause/resume a subscription*? | No | Yes |

## Examples

Web and command-line examples can be found in the `example` folder.

### Web Examples
 
In order to run the web examples, please follow these steps:

  1. Clone this repo and enter the directory
  2. Run `dart pub get`
  3. Run `dart pub run build_runner serve example`
  4. Navigate to [http://localhost:8080/web/index.html](http://localhost:8080/web/index.html) in your browser

### Command Line Examples

In order to run the command line example, please follow these steps:

  1. Clone this repo and enter the directory
  2. Run `pub get`
  3. Run `dart example/example.dart 10`
  
### Flutter Example
  
#### Install Flutter

To run the flutter example, you must have Flutter installed. For installation instructions, view the online
[documentation](https://flutter.io/).

#### Run the app

  1. Open up an Android Emulator, the iOS Simulator, or connect an appropriate mobile device for debugging.
  2. Open up a terminal
  3. `cd` into the `example/flutter/github_search` directory
  4. Run `flutter doctor` to ensure you have all Flutter dependencies working.
  5. Run `flutter packages get`
  6. Run `flutter run`

## Notable References

- [Documentation on the Dart Stream class](https://api.dart.dev/stable/dart-async/Stream-class.html)
- [Tutorial on working with Streams in Dart](https://www.dartlang.org/tutorials/language/streams)
- [ReactiveX (Rx)](https://reactivex.io/)

## Changelog

Refer to the [Changelog](https://github.com/ReactiveX/rxdart/blob/master/CHANGELOG.md) to get all release notes.
