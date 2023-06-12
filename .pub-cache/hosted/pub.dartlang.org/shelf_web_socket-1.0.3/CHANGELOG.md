## 1.0.3

* Require Dart `2.17`.
* Fix checking for binary callbacks with strong null safety.

## 1.0.2

* Require Dart `2.14`.
* Update the pubspec `repository` field.

## 1.0.1

* Require the latest shelf, remove dead code.

## 1.0.0

* Migrate to null safety.

## 0.2.4+1

* Support the latest `package:web_socket_channel`.

## 0.2.4

* Support the latest shelf release (`1.x.x`).
* Require at least Dart 2.1
* Allow omitting `protocols` argument even if the `onConnection` callback takes a second argument.

## 0.2.3

* Add `pingInterval` argument to `webSocketHandler`, to be passed through to the created channel.

## 0.2.2+5

* Allow `stream_channel` version 2.x

## 0.2.2+4

* Fix the check for `onConnection` to check the number of arguments and not that the arguments are `dynamic`.

## 0.2.2+3

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 0.2.2+2

* Stopped using deprected `HTML_ESCAPE` constant name.

## 0.2.2+1

* Update SDK version to 2.0.0-dev.17.0.

## 0.2.2

* Stop using comment-based generic syntax.

## 0.2.1

* Fix all strong-mode warnings.

## 0.2.0

* **Breaking change**: `webSocketHandler()` now uses the
  [`WebSocketChannel`][WebSocketChannel] class defined in the
  `web_socket_channel` package, rather than the deprecated class defined in
  `http_parser`.

[WebSocketChannel]: https://pub.dev/documentation/web_socket_channel/latest/web_socket_channel/WebSocketChannel-class.html

## 0.1.0

* **Breaking change**: `webSocketHandler()` now passes a `WebSocketChannel` to the `onConnection()` callback, rather
  than a deprecated `CompatibleWebSocket`.

## 0.0.1+5

* Support `http_parser` 2.0.0.

## 0.0.1+4

* Fix a link to `shelf` in the README.

## 0.0.1+3

* Support `http_parser` 1.0.0.

## 0.0.1+2

* Mark as compatible with version `0.6.0` of `shelf`.

## 0.0.1+1

* Properly parse the `Connection` header. This fixes an issue where Firefox was unable to connect.
