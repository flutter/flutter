[![Dart CI](https://github.com/dart-lang/stack_trace/actions/workflows/test-package.yml/badge.svg)](https://github.com/dart-lang/stack_trace/actions/workflows/test-package.yml)
[![pub package](https://img.shields.io/pub/v/stack_trace.svg)](https://pub.dev/packages/stack_trace)
[![package publisher](https://img.shields.io/pub/publisher/stack_trace.svg)](https://pub.dev/packages/stack_trace/publisher)

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
  _scheduleAsync();
}

void _scheduleAsync() {
  Future.delayed(Duration(seconds: 1)).then((_) => _runAsync());
}

void _runAsync() {
  throw 'oh no!';
}
```

If we run this, it prints the following:

    Unhandled exception:
    oh no!
    #0      _runAsync (file:///Users/kevmoo/github/stack_trace/example/example.dart:12:3)
    #1      _scheduleAsync.<anonymous closure> (file:///Users/kevmoo/github/stack_trace/example/example.dart:8:52)
    <asynchronous suspension>

Notice how there's no mention of `main` in that stack trace. All we know is that
the error was in `runAsync`; we don't know why `runAsync` was called.

Now let's look at the same code with stack chains captured:

```dart
import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

void main() {
  Chain.capture(_scheduleAsync);
}

void _scheduleAsync() {
  Future.delayed(Duration(seconds: 1)).then((_) => _runAsync());
}

void _runAsync() {
  throw 'oh no!';
}
```

Now if we run it, it prints this:

    Unhandled exception:
    oh no!
    example/example.dart 14:3                                     _runAsync
    example/example.dart 10:52                                    _scheduleAsync.<fn>
    package:stack_trace/src/stack_zone_specification.dart 126:26  StackZoneSpecification._registerUnaryCallback.<fn>.<fn>
    package:stack_trace/src/stack_zone_specification.dart 208:15  StackZoneSpecification._run
    package:stack_trace/src/stack_zone_specification.dart 126:14  StackZoneSpecification._registerUnaryCallback.<fn>
    dart:async/zone.dart 1406:47                                  _rootRunUnary
    dart:async/zone.dart 1307:19                                  _CustomZone.runUnary
    ===== asynchronous gap ===========================
    dart:async/zone.dart 1328:19                                  _CustomZone.registerUnaryCallback
    dart:async/future_impl.dart 315:23                            Future.then
    example/example.dart 10:40                                    _scheduleAsync
    package:stack_trace/src/chain.dart 97:24                      Chain.capture.<fn>
    dart:async/zone.dart 1398:13                                  _rootRun
    dart:async/zone.dart 1300:19                                  _CustomZone.run
    dart:async/zone.dart 1803:10                                  _runZoned
    dart:async/zone.dart 1746:10                                  runZoned
    package:stack_trace/src/chain.dart 95:12                      Chain.capture
    example/example.dart 6:9                                      main
    dart:isolate-patch/isolate_patch.dart 297:19                  _delayEntrypointInvocation.<fn>
    dart:isolate-patch/isolate_patch.dart 192:12                  _RawReceivePortImpl._handleMessage

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
