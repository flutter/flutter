## 1.4.0

* Add Response.unauthorized() constructor
* Add `poweredByHeader` argument to `serve`, `serveRequests`, and
  `handleRequest`.
* Require Dart >= 2.17

## 1.3.2

* `shelf_io.dart`
    * Started setting `X-Powered-By` response header
      to `Dart with package:shelf`.
    * Stopped setting `Server` header (with value `dart:io with Shelf`).

## 1.3.1

* Update the pubspec `repository` field.

## 1.3.0

* Add Response.badRequest() constructor
* Deprecate `ServerHandler`.
* Require Dart >= 2.16

## 1.2.0

* Added `MiddlewareExtensions` which provides `addMiddleware` and `addHandler`
  to `Middleware` instances. Provides easier access to the composition
  capabilities offered by `Pipeline`.

## 1.1.4

* Documentation improvements.

## 1.1.3

* Automatically remove `content-length` header from a `Response.notModified`.
  Restores some of the safety around malformed requests that was removed in
  `1.1.2` where we started allowing `content-length` for some responses without
  bodies.
* Documentation cleanup.

## 1.1.2

* Allow an explicit non-zero content-length header if the body is empty.
  (Needed to correctly support HEAD requests).

## 1.1.1

* Avoid wrapping response bodies that already contained `List<int>` or
  `Stream<List<int>>` in a `CastList`/`CastStream` to improve
  performance.

## 1.1.0

* Change `Request.hijack` return type from `void` to `Never`. This may cause
  analysis hints in packages using this method, but is not actually breaking
  for apps.

## 1.0.0

* Stable null safety release.

## 1.0.0-nullsafety.0

* Update to support Dart null-safety.
* Updated the `change` function on `Request` and `Response` to clear existing
  values in `context` if the provided `context` value has `null` values.

## 0.7.9

* Allow a `handlerPath` to lead up to a double `//` in a URI.

## 0.7.8

* Handle malformed URLs (400 instead of 500).

## 0.7.7

* Fix internal error in `Request` when `.change()` matches the full path.

## 0.7.6

*   Supports multiple header values in `Request` and `Response`:
    *   `headersAll` field contains all the header values
    *   `headers` field contains the same values as previously (appending values
        with `,`)
    *   `headers` parameter in the constructor and in the `.change()` method
        accepts both `String` and `List<String>` values.

## 0.7.5

* Return the correct HTTP status code for badly formatted requests.

## 0.7.4+1

* Allow `stream_channel` version 2.x

## 0.7.4

* Allow passing `shared` parameter to underlying `HttpServer.bind` calls via
  `shelf_io.serve`.
* Correctly pass `encoding` in `Response` constructors `forbidden`, `notFound`,
  and `internalServerError`.
* Update `README.md` to point to latest docs.

## 0.7.3+3

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 0.7.3+2

* Fix constant evaluation analyzer error in `shelf_unmodifiable_map.dart`.

* Update usage of HTTP constants from the Dart SDK. Now require 2.0.0-dev.61.

## 0.7.3+1

* Updated SDK version to 2.0.0-dev.55.0.

## 0.7.3

* Fix some Dart 2 runtime errors.

## 0.7.2

* Update `createMiddleware` arguments to use `FutureOr`.

  * Note: this change is not breaking for the runtime behavior, but it might
    cause new errors during static analysis due the the type changes.

* Updated minimum Dart SDK to `1.24.0`, which added `FutureOr`.

* Improved formatting of the `logRequests` default logger.

## 0.7.1

* The `shelf_io` server now adds a `shelf.io.connection_info` field to
  `Request.context`, which provides access to the underlying
  `HttpConnectionInfo` object.

## 0.7.0

* Give a return type to the `Handler` typedef. This may cause static warnings
  where there previously were none, but all handlers should have already been
  returning a `Response` or `Future<Response>`.

* Remove `HijackCallback` and `OnHijackCallback` typedefs.

* **Breaking**: Change type of `onHijack` in the `Request` constructor to take
  an argument of `StreamChannel`.

## 0.6.8

* Add a `securityContext` parameter to `self_io.serve()`.

## 0.6.7+2

* Go back to auto-generating a `Content-Length` header when the length is known
  ahead-of-time *and* the user hasn't explicitly specified a `Transfer-Encoding:
  chunked`.

* Clarify adapter requirements around transfer codings.

* Make `shelf_io` consistent with the clarified adapter requirements. In
  particular, it removes the `Transfer-Encoding` header from chunked requests,
  and it doesn't apply additional chunking to responses that already declare
  `Transfer-Encoding: chunked`.

## 0.6.7+1

* Never auto-generate a `Content-Length` header.

## 0.6.7

* Add `Request.isEmpty` and `Response.isEmpty` getters which indicate whether a
  message has an empty body.

* Don't automatically generate `Content-Length` headers on messages where they
  may not be allowed.

* User-specified `Content-Length` headers now always take precedence over
  automatically-generated headers.

## 0.6.6

* Allow `List<int>`s to be passed as request or response bodies.

* Requests and responses now automatically set `Content-Length` headers when the
  body length is known ahead of time.

* Work around [sdk#27660][] by manually setting
  `HttpResponse.chunkedTransferEncoding` to `false` for requests known to have
  no content.

[sdk#27660]: https://github.com/dart-lang/sdk/issues/27660

## 0.6.5+3

* Improve the documentation of `logRequests()`.

## 0.6.5+2

* Support `http_parser` 3.0.0.

## 0.6.5+1

* Fix all strong-mode warnings and errors.

## 0.6.5

* `Request.hijack()` now takes a callback that accepts a single `StreamChannel`
  argument rather than separate `Stream` and `StreamSink` arguments. The old
  callback signature is still supported, but should be considered deprecated.

* The `HijackCallback` and `OnHijackCallback` typedefs are deprecated.

## 0.6.4+3

* Support `http_parser` 2.0.0.

## 0.6.4+2

* Fix a bug where the `Content-Type` header didn't interact properly with the
  `encoding` parameter for `new Request()` and `new Response()` if it wasn't
  lowercase.

## 0.6.4+1

* When the `shelf_io` adapter detects an error, print the request context as
  well as the error itself.

## 0.6.4

* Add a `Server` interface representing an adapter that knows its own URL.

* Add a `ServerHandler` class that exposes a `Server` backed by a `Handler`.

* Add an `IOServer` class that implements `Server` in terms of `dart:io`'s
  `HttpServer`.

## 0.6.3+1

* Cleaned up handling of certain `Map` instances and related dependencies.

## 0.6.3

* Messages returned by `Request.change()` and `Response.change()` are marked
  read whenever the original message is read, and vice-versa. This means that
  it's possible to read a message on which `change()` has been called and to
  call `change()` on a message more than once, as long as `read()` is called on
  only one of those messages.

## 0.6.2+1

* Support `http_parser` 1.0.0.

## 0.6.2

* Added a `body` named argument to `change` method on `Request` and `Response`.

## 0.6.1+3

* Updated minimum SDK to `1.9.0`.

* Allow an empty `url` parameter to be passed in to `new Request()`. This fits
  the stated semantics of the class, and should not have been forbidden.

## 0.6.1+2

* `logRequests` outputs a better message a request has a query string.

## 0.6.1+1

* Don't throw a bogus exception for `null` responses.

## 0.6.1

* `shelf_io` now takes a `"shelf.io.buffer_output"` `Response.context` parameter
  that controls `HttpResponse.bufferOutput`.

* Fixed spelling errors in README and code comments.

## 0.6.0

**Breaking change:** The semantics of `Request.scriptName` and
[`Request.url`][url] have been overhauled, and the former has been renamed to
[`Request.handlerPath`][handlerPath]. `handlerPath` is now the root-relative URL
path to the current handler, while `url`'s path is the relative path from the
current handler to the requested. The new semantics are easier to describe and
to understand.

[url]: https://pub.dev/documentation/shelf/latest/shelf/Request/url.html
[handlerPath]: https://pub.dev/documentation/shelf/latest/shelf/Request/handlerPath.html

Practically speaking, the main difference is that the `/` at the beginning of
`url`'s path has been moved to the end of `handlerPath`. This makes `url`'s path
easier to parse using the `path` package.

[`Request.change`][change]'s handling of `handlerPath` and `url` has also
changed. Instead of taking both parameters separately and requiring that the
user manually maintain all the associated guarantees, it now takes a single
`path` parameter. This parameter is the relative path from the current
`handlerPath` to the next one, and sets both `handlerPath` and `url` on the new
`Request` accordingly.

[change]: https://pub.dev/documentation/shelf/latest/shelf/Request/change.html

## 0.5.7

* Updated `Request` to support the `body` model from `Response`.

## 0.5.6

* Fixed `createMiddleware` to only catch errors if `errorHandler` is provided.

* Updated `handleRequest` in `shelf_io` to more gracefully handle errors when
  parsing `HttpRequest`.

## 0.5.5+1

* Updated `Request.change` to include the original `onHijack` callback if one
  exists.

## 0.5.5

* Added default body text for `Response.forbidden` and `Response.notFound` if
  null is provided.

* Clarified documentation on a number of `Response` constructors.

* Updated `README` links to point to latest docs.

## 0.5.4+3

* Widen the version constraint on the `collection` package.

## 0.5.4+2

* Updated headers map to use a more efficient case-insensitive backing store.

## 0.5.4+1

* Widen the version constraint for `stack_trace`.

## 0.5.4

* The `shelf_io` adapter now sends the `Date` HTTP header by default.

* Fixed logic for setting Server header in `shelf_io`.

## 0.5.3

* Add new named parameters to `Request.change`: `scriptName` and `url`.

## 0.5.2

* Add a `Cascade` helper that runs handlers in sequence until one returns a
  response that's neither a 404 nor a 405.

* Add a `Request.change` method that copies a request with new header values.

* Add a `Request.hijack` method that allows handlers to gain access to the
  underlying HTTP socket.

## 0.5.1+1

* Capture all asynchronous errors thrown by handlers if they would otherwise be
  top-leveled.

* Add more detail to the README about handlers, middleware, and the rules for
  implementing an adapter.

## 0.5.1

* Add a `context` map to `Request` and `Response` for passing data among
  handlers and middleware.

## 0.5.0+1

* Allow `scheduled_test` development dependency up to v0.12.0

## 0.5.0

* Renamed `Stack` to `Pipeline`.

## 0.4.0

* Access to headers for `Request` and `Response` is now case-insensitive.

* The constructor for `Request` has been simplified.

* `Request` now exposes `url` which replaces `pathInfo`, `queryString`, and
  `pathSegments`.

## 0.3.0+9

* Removed old testing infrastructure.

* Updated documentation address.

## 0.3.0+8

* Added a dependency on the `http_parser` package.

## 0.3.0+7

* Removed unused dependency on the `mime` package.

## 0.3.0+6

* Added a dependency on the `string_scanner` package.

## 0.3.0+5

* Updated `pubspec` details for move to Dart SDK.

## 0.3.0 2014-03-25

* `Response`
    * **NEW!** `int get contentLength`
    * **NEW!** `DateTime get expires`
    * **NEW!** `DateTime get lastModified`
* `Request`
    * **BREAKING** `contentLength` is now read from `headers`. The constructor
      argument has been removed.
    * **NEW!** supports an optional `Stream<List<int>> body` constructor argument.
    * **NEW!** `Stream<List<int>> read()` and
      `Future<String> readAsString([Encoding encoding])`
    * **NEW!** `DateTime get ifModifiedSince`
    * **NEW!** `String get mimeType`
    * **NEW!** `Encoding get encoding`

## 0.2.0 2014-03-06

* **BREAKING** Removed `Shelf` prefix from all classes.
* **BREAKING** `Response` has drastically different constructors.
* *NEW!* `Response` now accepts a body of either `String` or
  `Stream<List<int>>`.
* *NEW!* `Response` now exposes `encoding` and `mimeType`.

## 0.1.0 2014-03-02

* First reviewed release
