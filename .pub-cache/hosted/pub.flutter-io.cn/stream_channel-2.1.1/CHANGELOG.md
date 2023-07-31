## 2.1.1

* Require Dart 2.14
* Populate the pubspec `repository` field.
* Handle multichannel messages where the ID element is a `double` at runtime
  instead of an `int`. When reading an array with `dart2wasm` numbers within the
  array are parsed as `double`.

## 2.1.0

* Stable release for null safety.

## 2.0.0

**Breaking changes**

* `IsolateChannel` requires a separate import
  `package:stram_channel/isolate_channel.dart`.
  `package:stream_channel/stream_channel.dart` will now not trigger any platform
  concerns due to importing `dart:isolate`.
* Remove `JsonDocumentTransformer` class. The `jsonDocument` top level is still
  available.
* Remove `StreamChannelTransformer.typed`. Use `.cast` on the transformed
  channel instead.
* Change `Future<dynamic>` returns to `Future<void>`.

## 1.7.0

* Make `IsolateChannel` available through
  `package:stream_channel/isolate_channel.dart`. This will be the required
  import in the next release.
* Require `2.0.0` or newer SDK.
* Internal style changes.

## 1.6.8

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 1.6.7+1

* Fix Dart 2 runtime types in `IsolateChannel`.

## 1.6.7

* Update SDK version to 2.0.0-dev.17.0.
* Add a type argument to `MultiChannel`.

## 1.6.6

* Fix a Dart 2 issue with inner stream transformation in `GuaranteeChannel`.

* Fix a Dart 2 issue with `StreamChannelTransformer.fromCodec()`.

## 1.6.5

* Fix an issue with `JsonDocumentTransformer.bind` where it created an internal
  stream channel which didn't get a properly inferred type for its `sink`.

## 1.6.4

* Fix a race condition in `MultiChannel` where messages from a remote virtual
  channel could get dropped if the corresponding local channel wasn't registered
  quickly enough.

## 1.6.3

* Use `pumpEventQueue()` from test.

## 1.6.2

* Declare support for `async` 2.0.0.

## 1.6.1

* Fix the type of `StreamChannel.transform()`. This previously inverted the
  generic parameters, so it only really worked with transformers where both
  generic types were identical.

## 1.6.0

* `Disconnector.disconnect()` now returns a future that completes when all the
  inner `StreamSink.close()` futures have completed.

## 1.5.0

* Add `new StreamChannel.withCloseGuarantee()` to provide the specific guarantee
  that closing the sink causes the stream to close before it emits any more
  events. This is the only guarantee that isn't automatically preserved when
  transforming a channel.

* `StreamChannelTransformer`s provided by the `stream_channel` package now
  properly provide the guarantee that closing the sink causes the stream to
  close before it emits any more events

## 1.4.0

* Add `StreamChannel.cast()`, which soundly coerces the generic type of a
  channel.

* Add `StreamChannelTransformer.typed()`, which soundly coerces the generic type
  of a transformer.

## 1.3.2

* Fix all strong-mode errors and warnings.

## 1.3.1

* Make `IsolateChannel` slightly more efficient.

* Make `MultiChannel` follow the stream channel rules.

## 1.3.0

* Add `Disconnector`, a transformer that allows the caller to disconnect the
  transformed channel.

## 1.2.0

* Add `new StreamChannel.withGuarantees()`, which creates a channel with extra
  wrapping to ensure that it obeys the stream channel guarantees.

* Add `StreamChannelController`, which can be used to create custom
  `StreamChannel` objects.

## 1.1.1

* Fix the type annotation for `StreamChannel.transform()`'s parameter.

## 1.1.0

* Add `StreamChannel.transformStream()`, `StreamChannel.transformSink()`,
  `StreamChannel.changeStream()`, and `StreamChannel.changeSink()` to support
  changing only the stream or only the sink of a channel.

* Be more explicit about `JsonDocumentTransformer`'s error-handling behavior.

## 1.0.1

* Fix `MultiChannel`'s constructor to take a `StreamChannel`. This is
  technically a breaking change, but since 1.0.0 was only released an hour ago,
  we're treating it as a bug fix.

## 1.0.0

* Initial version
