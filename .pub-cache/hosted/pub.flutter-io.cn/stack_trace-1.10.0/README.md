This library provides the ability to parse, inspect, and manipulate stack traces
produced by the underlying Dart implementation. It also provides functions to
produce string representations of stack traces in a more readable format than
the native [StackTrace] implementation.

`Trace`s can be parsed from native [StackTrace]s using `Trace.from`, or captured
using `Trace.current`. Native [StackTrace]s can also be directly converted to
human-readable strings using `Trace.format`.

[StackTrace]: https://api.dart.dev/stable/dart-core/StackTrace-class.html

Here's an example native stack trace from debugging this library:

    #0      Object.noSuchMethod (dart:core-patch:1884:25)
    #1      Trace.terse.<anonymous closure> (file:///usr/local/google-old/home/goog/dart/dart/pkg/stack_trace/lib/src/trace.dart:47:21)
    #2      IterableMixinWorkaround.reduce (dart:collection:29:29)
    #3      List.reduce (dart:core-patch:1247:42)
    #4      Trace.terse (file:///usr/local/google-old/home/goog/dart/dart/pkg/stack_trace/lib/src/trace.dart:40:35)
    #5      format (file:///usr/local/google-old/home/goog/dart/dart/pkg/stack_trace/lib/stack_trace.dart:24:28)
    #6      main.<anonymous closure> (file:///usr/local/google-old/home/goog/dart/dart/test.dart:21:29)
    #7      _CatchErrorFuture._sendError (dart:async:525:24)
    #8      _FutureImpl._setErrorWithoutAsyncTrace (dart:async:393:26)
    #9      _FutureImpl._setError (dart:async:378:31)
    #10     _ThenFuture._sendValue (dart:async:490:16)
    #11     _FutureImpl._handleValue.<anonymous closure> (dart:async:349:28)
    #12     Timer.run.<anonymous closure> (dart:async:2402:21)
    #13     Timer.Timer.<anonymous closure> (dart:async-patch:15:15)

and its human-readable representation:

    dart:core-patch 1884:25                     Object.noSuchMethod
    pkg/stack_trace/lib/src/trace.dart 47:21    Trace.terse.<fn>
    dart:collection 29:29                       IterableMixinWorkaround.reduce
    dart:core-patch 1247:42                     List.reduce
    pkg/stack_trace/lib/src/trace.dart 40:35    Trace.terse
    pkg/stack_trace/lib/stack_trace.dart 24:28  format
    test.dart 21:29                             main.<fn>
    dart:async 525:24                           _CatchErrorFuture._sendError
    dart:async 393:26                           _FutureImpl._setErrorWithoutAsyncTrace
    dart:async 378:31                           _FutureImpl._setError
    dart:async 490:16                           _ThenFuture._sendValue
    dart:async 349:28                           _FutureImpl._handleValue.<fn>
    dart:async 2402:21                          Timer.run.<fn>
    dart:async-patch 15:15                      Timer.Timer.<fn>

You can further clean up the stack trace using `Trace.terse`. This folds
together multiple stack frames from the Dart core libraries, so that only the
core library method that was directly called from user code is visible. For
example:

    dart:core                                   Object.noSuchMethod
    pkg/stack_trace/lib/src/trace.dart 47:21    Trace.terse.<fn>
    dart:core                                   List.reduce
    pkg/stack_trace/lib/src/trace.dart 40:35    Trace.terse
    pkg/stack_trace/lib/stack_trace.dart 24:28  format
    test.dart 21:29                             main.<fn>

## Stack Chains

This library also provides the ability to capture "stack chains" with the
`Chain` class. When writing asynchronous code, a single stack trace isn't very
useful, since the call stack is unwound every time something async happens. A
stack chain tracks stack traces through asynchronous calls, so that you can see
the full path from `main` down to the error.

To use stack chains, just wrap the code that you want to track in
`Chain.capture`. This will create a new [Zone][] in which stack traces are
recorded and woven into chains every time an asynchronous call occurs. Zones are
sticky, too, so any asynchronous operations started in the `Chain.capture`
callback will have their chains tracked, as will asynchronous operations they
start and so on.

Here's an example of some code that doesn't capture its stack chains:

```dart
import 'dart:async';

void main() {
  scheduleAsync();
}

void scheduleAsync() {
  return new Future.delayed(new Duration(seconds: 1))
      .then((_) => runAsync());
}

void runAsync() {
  throw 'oh no!';
}
```

If we run this, it prints the following:

    Uncaught Error: oh no!
    Stack Trace: 
    #0      runAsync (file:///usr/local/google-old/home/goog/dart/dart/test.dart:13:3)
    #1      scheduleAsync.<anonymous closure> (file:///usr/local/google-old/home/goog/dart/dart/test.dart:9:28)
    #2      _rootRunUnary (dart:async/zone.dart:717)
    #3      _RootZone.runUnary (dart:async/zone.dart:854)
    #4      _Future._propagateToListeners.handleValueCallback (dart:async/future_impl.dart:488)
    #5      _Future._propagateToListeners (dart:async/future_impl.dart:571)
    #6      _Future._complete (dart:async/future_impl.dart:317)
    #7      _SyncCompleter.complete (dart:async/future_impl.dart:44)
    #8      Future.Future.delayed.<anonymous closure> (dart:async/future.dart:219)
    #9      _createTimer.<anonymous closure> (dart:async-patch/timer_patch.dart:11)
    #10     _handleTimeout (dart:io/timer_impl.dart:292)
    #11     _RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:115)

Notice how there's no mention of `main` in that stack trace. All we know is that
the error was in `runAsync`; we don't know why `runAsync` was called.

Now let's look at the same code with stack chains captured:

```dart
import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

void main() {
  Chain.capture(() {
    scheduleAsync();
  });
}

void scheduleAsync() {
  new Future.delayed(new Duration(seconds: 1))
      .then((_) => runAsync());
}

void runAsync() {
  throw 'oh no!';
}
```

Now if we run it, it prints this:

    Uncaught Error: oh no!
    Stack Trace: 
    test.dart 17:3                                                runAsync
    test.dart 13:28                                               scheduleAsync.<fn>
    package:stack_trace/src/stack_zone_specification.dart 129:26  registerUnaryCallback.<fn>.<fn>
    package:stack_trace/src/stack_zone_specification.dart 174:15  StackZoneSpecification._run
    package:stack_trace/src/stack_zone_specification.dart 177:7   StackZoneSpecification._run
    package:stack_trace/src/stack_zone_specification.dart 175:7   StackZoneSpecification._run
    package:stack_trace/src/stack_zone_specification.dart 129:18  registerUnaryCallback.<fn>
    dart:async/zone.dart 717                                      _rootRunUnary
    dart:async/zone.dart 449                                      _ZoneDelegate.runUnary
    dart:async/zone.dart 654                                      _CustomizedZone.runUnary
    dart:async/future_impl.dart 488                               _Future._propagateToListeners.handleValueCallback
    dart:async/future_impl.dart 571                               _Future._propagateToListeners
    dart:async/future_impl.dart 317                               _Future._complete
    dart:async/future_impl.dart 44                                _SyncCompleter.complete
    dart:async/future.dart 219                                    Future.Future.delayed.<fn>
    package:stack_trace/src/stack_zone_specification.dart 174:15  StackZoneSpecification._run
    package:stack_trace/src/stack_zone_specification.dart 119:52  registerCallback.<fn>
    dart:async/zone.dart 706                                      _rootRun
    dart:async/zone.dart 440                                      _ZoneDelegate.run
    dart:async/zone.dart 650                                      _CustomizedZone.run
    dart:async/zone.dart 561                                      _BaseZone.runGuarded
    dart:async/zone.dart 586                                      _BaseZone.bindCallback.<fn>
    package:stack_trace/src/stack_zone_specification.dart 174:15  StackZoneSpecification._run
    package:stack_trace/src/stack_zone_specification.dart 119:52  registerCallback.<fn>
    dart:async/zone.dart 710                                      _rootRun
    dart:async/zone.dart 440                                      _ZoneDelegate.run
    dart:async/zone.dart 650                                      _CustomizedZone.run
    dart:async/zone.dart 561                                      _BaseZone.runGuarded
    dart:async/zone.dart 586                                      _BaseZone.bindCallback.<fn>
    dart:async-patch/timer_patch.dart 11                          _createTimer.<fn>
    dart:io/timer_impl.dart 292                                   _handleTimeout
    dart:isolate-patch/isolate_patch.dart 115                     _RawReceivePortImpl._handleMessage
    ===== asynchronous gap ===========================
    dart:async/zone.dart 476                                      _ZoneDelegate.registerUnaryCallback
    dart:async/zone.dart 666                                      _CustomizedZone.registerUnaryCallback
    dart:async/future_impl.dart 164                               _Future._Future._then
    dart:async/future_impl.dart 187                               _Future.then
    test.dart 13:12                                               scheduleAsync
    test.dart 7:18                                                main.<fn>
    dart:async/zone.dart 710                                      _rootRun
    dart:async/zone.dart 440                                      _ZoneDelegate.run
    dart:async/zone.dart 650                                      _CustomizedZone.run
    dart:async/zone.dart 944                                      runZoned
    package:stack_trace/src/chain.dart 93:20                      Chain.capture
    test.dart 6:16                                                main
    dart:isolate-patch/isolate_patch.dart 216                     _startIsolate.isolateStartHandler
    dart:isolate-patch/isolate_patch.dart 115                     _RawReceivePortImpl._handleMessage

That's a lot of text! If you look closely, though, you can see that `main` is
listed in the first trace in the chain.

Thankfully, you can call `Chain.terse` just like `Trace.terse` to get rid of all
the frames you don't care about. The terse version of the stack chain above is
this:

    test.dart 17:3       runAsync
    test.dart 13:28      scheduleAsync.<fn>
    ===== asynchronous gap ===========================
    dart:async           _Future.then
    test.dart 13:12      scheduleAsync
    test.dart 7:18       main.<fn>
    package:stack_trace  Chain.capture
    test.dart 6:16       main

That's a lot easier to understand!

[Zone]: https://api.dart.dev/stable/dart-async/Zone-class.html
