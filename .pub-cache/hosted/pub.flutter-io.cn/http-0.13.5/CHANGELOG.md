## 0.13.5

* Allow async callbacks in RetryClient.
* In `MockHttpClient` use the callback returned `Response.request` instead of
  the argument value to give more control to the callback. This may be breaking
  for callbacks which return incomplete Responses and relied on the default.

## 0.13.4

* Throw a more useful error when a client is used after it has been closed.
* Require Dart 2.14.

## 0.13.3

* Validate that the `method` parameter of BaseRequest is a valid "token".

## 0.13.2

* Add `package:http/retry.dart` with `RetryClient`. This is the same
  implementation as `package:http_retry` which will be discontinued.

## 0.13.1

* Fix code samples in `README` to pass a `Uri` instance.

## 0.13.0

* Migrate to null safety.
* Add `const` constructor to `ByteStream`.
* Migrate `BrowserClient` from `blob` to `arraybuffer`.
* **Breaking** All APIs which previously allowed a `String` or `Uri` to be
  passed now require a `Uri`.
* **Breaking** Added a `body` and `encoding` argument to `Client.delete`. This
  is only breaking for implementations which override that method.

## 0.12.2

* Fix error handler callback type for response stream errors to avoid masking
  root causes.

## 0.12.1

* Add `IOStreamedResponse` which includes the ability to detach the socket.
  When sending a request with an `IOClient` the response will be an
  `IOStreamedResponse`.
* Remove dependency on `package:async`.

## 0.12.0+4

* Fix a bug setting the `'content-type'` header in `MultipartRequest`.

## 0.12.0+3

* Documentation fixes.

## 0.12.0+2

* Documentation fixes.

## 0.12.0

### New Features

* The regular `Client` factory constructor is now usable anywhere that `dart:io`
  or `dart:html` are available, and will give you an `IoClient` or
  `BrowserClient` respectively.
* The `package:http/http.dart` import is now safe to use on the web (or
  anywhere that either `dart:io` or `dart:html` are available).

### Breaking Changes

* In order to use or reference the `IoClient` directly, you will need to import
  the new `package:http/io_client.dart` import. This is typically only necessary
  if you are passing a custom `HttpClient` instance to the constructor, in which
  case you are already giving up support for web.

## 0.11.3+17

* Use new Dart 2 constant names. This branch is only for allowing existing
  code to keep running under Dart 2.

## 0.11.3+16

* Stop depending on the `stack_trace` package.

## 0.11.3+15

* Declare support for `async` 2.0.0.

## 0.11.3+14

* Remove single quote ("'" - ASCII 39) from boundary characters.
  Causes issues with Google Cloud Storage.

## 0.11.3+13

* remove boundary characters that package:http_parser cannot parse.

## 0.11.3+12

* Don't quote the boundary header for `MultipartRequest`. This is more
  compatible with server quirks.

## 0.11.3+11

* Fix the SDK constraint to only include SDK versions that support importing
  `dart:io` everywhere.

## 0.11.3+10

* Stop using `dart:mirrors`.

## 0.11.3+9

* Remove an extra newline in multipart chunks.

## 0.11.3+8

* Properly specify `Content-Transfer-Encoding` for multipart chunks.

## 0.11.3+7

* Declare compatibility with `http_parser` 3.0.0.

## 0.11.3+6

* Fix one more strong mode warning in `http/testing.dart`.

## 0.11.3+5

* Fix some lingering strong mode warnings.

## 0.11.3+4

* Fix all strong mode warnings.

## 0.11.3+3

* Support `http_parser` 2.0.0.

## 0.11.3+2

* Require Dart SDK >= 1.9.0

* Eliminate many uses of `Chain.track` from the `stack_trace` package.

## 0.11.3+1

* Support `http_parser` 1.0.0.

## 0.11.3

* Add a `Client.patch` shortcut method and a matching top-level `patch` method.

## 0.11.2

* Add a `BrowserClient.withCredentials` property.

## 0.11.1+3

* Properly namespace an internal library name.

## 0.11.1+2

* Widen the version constraint on `unittest`.

## 0.11.1+1

* Widen the version constraint for `stack_trace`.

## 0.11.1

* Expose the `IOClient` class which wraps a `dart:io` `HttpClient`.

## 0.11.0+1

* Fix a bug in handling errors in decoding XMLHttpRequest responses for
  `BrowserClient`.

## 0.11.0

* The package no longer depends on `dart:io`. The `BrowserClient` class in
  `package:http/browser_client.dart` can now be used to make requests on the
  browser.

* Change `MultipartFile.contentType` from `dart:io`'s `ContentType` type to
  `http_parser`'s `MediaType` type.

* Exceptions are now of type `ClientException` rather than `dart:io`'s
  `HttpException`.

## 0.10.0

* Make `BaseRequest.contentLength` and `BaseResponse.contentLength` use `null`
  to indicate an unknown content length rather than -1.

* The `contentLength` parameter to `new BaseResponse` is now named rather than
  positional.

* Make request headers case-insensitive.

* Make `MultipartRequest` more closely adhere to browsers' encoding conventions.
