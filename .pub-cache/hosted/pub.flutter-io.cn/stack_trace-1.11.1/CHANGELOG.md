## 1.11.1

* Make use of `@pragma('vm:awaiter-link')` to make package work better with
  Dart VM's builtin awaiter stack unwinding. No other changes.

## 1.11.0

* Added the parameter `zoneValues` to `Chain.capture` to be able to use custom
  zone values with the `runZoned` internal calls.
* Populate the pubspec `repository` field.
* Require Dart 2.18 or greater

## 1.10.0

* Stable release for null safety.
* Fix broken test, `test/chain/vm_test.dart`, which incorrectly handles
  asynchronous suspension gap markers at the end of stack traces.

## 1.10.0-nullsafety.6

* Fix bug parsing asynchronous suspension gap markers at the end of stack
  traces, when parsing with `Trace.parse` and `Chain.parse`.
* Update SDK constraints to `>=2.12.0-0 <3.0.0` based on beta release
  guidelines.

## 1.10.0-nullsafety.5

* Allow prerelease versions of the 2.12 sdk.

## 1.10.0-nullsafety.4

* Allow the `2.10.0` stable and dev SDKs.

## 1.10.0-nullsafety.3

* Fix bug parsing asynchronous suspension gap markers at the end of stack
  traces.

## 1.10.0-nullsafety.2

* Forward fix for a change in SDK type promotion behavior.

## 1.10.0-nullsafety.1

* Allow 2.10 stable and 2.11.0 dev SDK versions.

## 1.10.0-nullsafety

* Opt in to null safety.

## 1.9.6 (backpublish)

* Fix bug parsing asynchronous suspension gap markers at the end of stack
  traces. (Also fixed separately in 1.10.0-nullsafety.3)
* Fix bug parsing asynchronous suspension gap markers at the end of stack
  traces, when parsing with `Trace.parse` and `Chain.parse`. (Also fixed
  separately in 1.10.0-nullsafety.6)

## 1.9.5

* Parse the format for `data:` URIs that the Dart VM has used since `2.2.0`.

## 1.9.4

* Add support for firefox anonymous stack traces.
* Add support for chrome eval stack traces without a column.
* Change the argument type to `Chain.capture` from `Function(dynamic, Chain)` to
  `Function(Object, Chain)`. Existing functions which take `dynamic` are still
  fine, but new uses can have a safer type.

## 1.9.3

* Set max SDK version to `<3.0.0`.

## 1.9.2

* Fix Dart 2.0 runtime cast failure in test.

## 1.9.1

* Preserve the original chain for a trace to handle cases where an
  error is rethrown.

## 1.9.0

* Add an `errorZone` parameter to `Chain.capture()` that makes it avoid creating
  an error zone.

## 1.8.3

* `Chain.forTrace()` now returns a full stack chain for *all* `StackTrace`s
  within `Chain.capture()`, even those that haven't been processed by
  `dart:async` yet.

* `Chain.forTrace()` now uses the Dart VM's stack chain information when called
  synchronously within `Chain.capture()`. This matches the existing behavior
  outside `Chain.capture()`.

* `Chain.forTrace()` now trims the VM's stack chains for the innermost stack
  trace within `Chain.capture()` (unless it's called synchronously, as above).
  This avoids duplicated frames and makes the format of the innermost traces
  consistent with the other traces in the chain.

## 1.8.2

* Update to use strong-mode clean Zone API.

## 1.8.1

* Use official generic function syntax.

* Updated minimum SDK to 1.23.0.

## 1.8.0

* Add a `Trace.original` field to provide access to the original `StackTrace`s
  from which the `Trace` was created, and a matching constructor parameter to
  `new Trace()`.

## 1.7.4

* Always run `onError` callbacks for `Chain.capture()` in the parent zone.

## 1.7.3

* Fix broken links in the README.

## 1.7.2

* `Trace.foldFrames()` and `Chain.foldFrames()` now remove the outermost folded
  frame. This matches the behavior of `.terse` with core frames.

* Fix bug parsing a friendly frame with spaces in the member name.

* Fix bug parsing a friendly frame where the location is a data url.

## 1.7.1

* Make `Trace.parse()`, `Chain.parse()`, treat the VM's new causal asynchronous
  stack traces as chains. Outside of a `Chain.capture()` block, `new
  Chain.current()` will return a stack chain constructed from the asynchronous
  stack traces.

## 1.7.0

* Add a `Chain.disable()` function that disables stack-chain tracking.

* Fix a bug where `Chain.capture(..., when: false)` would throw if an error was
  emitted without a stack trace.

## 1.6.8

* Add a note to the documentation of `Chain.terse` and `Trace.terse`.

## 1.6.7

* Fix a bug where `new Frame.caller()` returned the wrong depth of frame on
  Dartium.

## 1.6.6

* `new Trace.current()` and `new Chain.current()` now skip an extra frame when
  run in a JS context. This makes their return values match the VM context.

## 1.6.5

* Really fix strong mode warnings.

## 1.6.4

* Fix a syntax error introduced in 1.6.3.

## 1.6.3

* Make `Chain.capture()` generic. Its signature is now `T Chain.capture<T>(T
  callback(), ...)`.

## 1.6.2

* Fix all strong mode warnings.

## 1.6.1

* Use `StackTrace.current` in Dart SDK 1.14 to get the current stack trace.

## 1.6.0

* Add a `when` parameter to `Chain.capture()`. This allows capturing to be
  easily enabled and disabled based on whether the application is running in
  debug/development mode or not.

* Deprecate the `ChainHandler` typedef. This didn't provide any value over
  directly annotating the function argument, and it made the documentation less
  clear.

## 1.5.1

* Fix a crash in `Chain.foldFrames()` and `Chain.terse` when one of the chain's
  traces has no frames.

## 1.5.0

* `new Chain.parse()` now parses all the stack trace formats supported by `new
  Trace.parse()`. Formats other than that emitted by `Chain.toString()` will
  produce single-element chains.

* `new Trace.parse()` now parses the output of `Chain.toString()`. It produces
  the same result as `Chain.parse().toTrace()`.

## 1.4.2

* Improve the display of `data:` URIs in stack traces.

## 1.4.1

* Fix a crashing bug in `UnparsedFrame.toString()`.

## 1.4.0

* `new Trace.parse()` and related constructors will no longer throw an exception
  if they encounter an unparseable stack frame. Instead, they will generate an
  `UnparsedFrame`, which exposes no metadata but preserves the frame's original
  text.

* Properly parse native-code V8 frames.

## 1.3.5

* Properly shorten library names for pathnames of folded frames on Windows.

## 1.3.4

* No longer say that stack chains aren't supported on dart2js now that
  [sdk#15171][] is fixed. Note that this fix only applies to Dart 1.12.

[sdk#15171]: https://github.com/dart-lang/sdk/issues/15171

## 1.3.3

* When a `null` stack trace is passed to a completer or stream controller in
  nested `Chain.capture()` blocks, substitute the inner block's chain rather
  than the outer block's.

* Add support for empty chains and chains of empty traces to `Chain.parse()`.

* Don't crash when parsing stack traces from Dart VM stack overflows.

## 1.3.2

* Don't crash when running `Trace.terse` on empty stack traces.

## 1.3.1

* Support more types of JavaScriptCore stack frames.

## 1.3.0

* Support stack traces generated by JavaScriptCore. They can be explicitly
  parsed via `new Trace.parseJSCore` and `new Frame.parseJSCore`.

## 1.2.4

* Fix a type annotation in `LazyTrace`.

## 1.2.3

* Fix a crash in `Chain.parse`.

## 1.2.2

* Don't print the first folded frame of terse stack traces. This frame
  is always just an internal isolate message handler anyway. This
  improves the readability of stack traces, especially in stack chains.

* Remove the line numbers and specific files in all terse folded frames, not
  just those from core libraries.

* Make padding consistent across all stack traces for `Chain.toString()`.

## 1.2.1

* Add `terse` to `LazyTrace.foldFrames()`.

* Further improve stack chains when using the VM's async/await implementation.

## 1.2.0

* Add a `terse` argument to `Trace.foldFrames()` and `Chain.foldFrames()`. This
  allows them to inherit the behavior of `Trace.terse` and `Chain.terse` without
  having to duplicate the logic.

## 1.1.3

* Produce nicer-looking stack chains when using the VM's async/await
  implementation.

## 1.1.2

* Support VM frames without line *or* column numbers, which async/await programs
  occasionally generate.

* Replace `<<anonymous closure>_async_body>` in VM frames' members with the
  terser `<async>`.

## 1.1.1

* Widen the SDK constraint to include 1.7.0-dev.4.0.

## 1.1.0

* Unify the parsing of Safari and Firefox stack traces. This fixes an error in
  Firefox trace parsing.

* Deprecate `Trace.parseSafari6_0`, `Trace.parseSafari6_1`,
  `Frame.parseSafari6_0`, and `Frame.parseSafari6_1`.

* Add `Frame.parseSafari`.

## 1.0.3

* Use `Zone.errorCallback` to attach stack chains to all errors without the need
  for `Chain.track`, which is now deprecated.

## 1.0.2

* Remove a workaround for [issue 17083][].

[issue 17083]: https://github.com/dart-lang/sdk/issues/17083

## 1.0.1

* Synchronous errors in the [Chain.capture] callback are now handled correctly.

## 1.0.0

* No API changes, just declared stable.

## 0.9.3+2

* Update the dependency on path.

* Improve the formatting of library URIs in stack traces.

## 0.9.3+1

* If an error is thrown in `Chain.capture`'s `onError` handler, that error is
  handled by the parent zone. This matches the behavior of `runZoned` in
  `dart:async`.

## 0.9.3

* Add a `Chain.foldFrames` method that parallels `Trace.foldFrames`.

* Record anonymous method frames in IE10 as "<fn>".
