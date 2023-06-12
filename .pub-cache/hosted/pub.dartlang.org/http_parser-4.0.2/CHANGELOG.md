## 4.0.2

* Remove `package:charcode` from dev_dependencies.

## 4.0.1

* Remove dependency on `package:charcode`.

## 4.0.0

* Stable null safety stable release.

## 4.0.0-nullsafety

* Migrate to null safety.

## 3.1.4

* Fixed lints affecting package health score.
* Added an example.

## 3.1.3

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 3.1.2

* Require Dart SDK 2.0.0-dev.17.0 or greater.

* A number of strong-mode fixes.

## 3.1.1

* Fix a logic bug in the `chunkedCoding` codec. It had been producing invalid
  output and rejecting valid input.

## 3.1.0

* Add `chunkedCoding`, a `Codec` that supports encoding and decoding the
  [chunked transfer coding][].

[chunked transfer coding]: https://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.6.1

## 3.0.2

* Support `string_scanner` 1.0.0.

## 3.0.1

* Remove unnecessary dependencies.

## 3.0.0

* All deprecated APIs have been removed. No new APIs have been added. Packages
  that would use 3.0.0 as a lower bound should use 2.2.0 instead—for example,
  `http_parser: ">=2.2.0 <4.0.0"`.

* Fix all strong-mode warnings.

## 2.2.1

* Add support for `crypto` 1.0.0.

## 2.2.0

* `WebSocketChannel` has been moved to
  [the `web_socket_channel` package][web_socket_channel]. The implementation
  here is now deprecated.

[web_socket_channel]: https://pub.dev/packages/web_socket_channel

## 2.1.0

* Added `WebSocketChannel`, an implementation of `StreamChannel` that's backed
  by a `WebSocket`.

* Deprecated `CompatibleWebSocket` in favor of `WebSocketChannel`.

## 2.0.0

* Removed the `DataUri` class. It's redundant with the `Uri.data` getter that's
  coming in Dart 1.14, and the `DataUri.data` field in particular was an invalid
  override of that field.

## 1.1.0

* The MIME spec says that media types and their parameter names are
  case-insensitive. Accordingly, `MediaType` now uses a case-insensitive map for
  its parameters and its `type` and `subtype` fields are now always lowercase.

## 1.0.0

This is 1.0.0 because the API is stable—there are no breaking changes.

* Added an `AuthenticationChallenge` class for parsing and representing the
  value of `WWW-Authenticate` and related headers.

* Added a `CaseInsensitiveMap` class for representing case-insensitive HTTP
  values.

## 0.0.2+8

* Bring in the latest `dart:io` WebSocket code.

## 0.0.2+7

* Add more detail to the readme.

## 0.0.2+6

* Updated homepage URL.

## 0.0.2+5

* Widen the version constraint on the `collection` package.

## 0.0.2+4

* Widen the `string_scanner` version constraint.

## 0.0.2+3

* Fix a library name conflict.

## 0.0.2+2

* Fixes for HTTP date formatting.

## 0.0.2+1

* Minor code refactoring.

## 0.0.2

* Added `CompatibleWebSocket`, for platform- and API-independent support for the
  WebSocket API.
