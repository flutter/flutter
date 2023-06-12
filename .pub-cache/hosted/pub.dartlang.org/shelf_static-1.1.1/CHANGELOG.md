## 1.1.1

* Require Dart `2.14`.
* Update the pubspec `repository` field.

## 1.1.0

* Correctly handle `HEAD` requests.
* Support HTTP range requests.

## 1.0.0

* Migrate to null safety.

## 0.2.9+2

* Change version constraint for the `shelf` dependency, so it accepts null-safe versions.

## 0.2.9+1

* Change version constraint for the `mime` dependency, so it accepts null-safe versions.

## 0.2.9

* Update SDK constraint to `>=2.3.0 <3.0.0`.
* Allow `3.x` versions of `package:convert`.
* Allow `4.x` versions of `package:http_parser`.
* Use file `modified` dates instead of `changed` for `304 Not Modified` checks as `changed` returns creation dates on
  Windows.

## 0.2.8

* Update SDK constraint to `>=2.0.0-dev.61 <3.0.0`.

* Directory listings are now sorted.

## 0.2.7+1

* Updated SDK version to 2.0.0-dev.17.0

## 0.2.7

* Require at least Dart SDK 1.24.0.
* Other internal changes e.g. removing dep on `scheduled_test`.

## 0.2.6

* Add a `createFileHandler()` function that serves a single static file.

## 0.2.5

* Add an optional `contentTypeResolver` argument to `createStaticHandler`.

## 0.2.4

* Add support for "sniffing" the content of the file for the content-type via an optional
  `useHeaderBytesForContentType` argument on `createStaticHandler`.

## 0.2.3+4

* Support `http_parser` 3.0.0.

## 0.2.3+3

* Support `shelf` 0.7.0.

## 0.2.3+2

* Support `http_parser` 2.0.0.

## 0.2.3+1

* Support `http_parser` 1.0.0.

## 0.2.3

* Added `listDirectories` argument to `createStaticHandler`.

## 0.2.2

* Bumped up minimum SDK to 1.7.0.

* Added support for `shelf` 0.6.0.

## 0.2.1

* Removed `Uri` format checks now that the core libraries is more strict.

## 0.2.0

* Removed deprecated `getHandler`.

* Send correct mime type for default document.

## 0.1.4+6

* Updated development dependencies.

## 0.1.4+5

* Handle differences in resolution between `DateTime` and HTTP date format.

## 0.1.4+4

* Using latest `shelf`. Cleaned up test code by using new features.

## 0.1.4

* Added named (optional) `defaultDocument` argument to `createStaticHandler`.

## 0.1.3

* `createStaticHandler` added `serveFilesOutsidePath` optional parameter.

## 0.1.2

* The preferred top-level method is now `createStaticHandler`. `getHandler` is deprecated.
* Set `content-type` header if the mime type of the requested file can be determined from the file extension.
* Respond with `304-Not modified` against `IF-MODIFIED-SINCE` request header.
* Better error when provided a non-existent `fileSystemPath`.
* Added `example/example_server.dart`.

## 0.1.1+1

* Removed work around for [issue](https://codereview.chromium.org/278783002/).

## 0.1.1

* Correctly handle requests when not hosted at the root of a site.
* Send `last-modified` header.
* Work around [known issue](https://codereview.chromium.org/278783002/) with HTTP date formatting.
