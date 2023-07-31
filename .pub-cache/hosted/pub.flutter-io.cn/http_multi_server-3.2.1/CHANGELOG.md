## 3.2.1

* Populate the pubspec `repository` field.

## 3.2.0

* Honor the `preserveHeaderCase` argument to `MultiHeaders.set` and `.add`.

## 3.1.0

* Add `HttpMultiServer.bindSecure` to match `HttpMultiServer.bind`.

## 3.0.1

* Fix an issue where `bind` would bind to the `anyIPv6` address in unsupported
  environments.

## 3.0.0

* Migrate to null safety.

## 2.2.0

* Preparation for [HttpHeaders change]. Update signature of `MultiHeaders.add()`
  and `MultiHeaders.set()` to match new signature of `HttpHeaders`. The
  parameter is not yet forwarded and will not behave as expected.

  [HttpHeaders change]: https://github.com/dart-lang/sdk/issues/39657

## 2.1.0

* Add `HttpMultiServer.bind` static which centralizes logic around common local
  serving scenarios - handling a more flexible 'localhost' and listening on
  'any' hostname.
* Update SDK constraints to `>=2.1.0 <3.0.0`.

## 2.0.6

* If there is a problem starting a loopback Ipv6 server, don't keep the Ipv4
  server open when throwing the exception.

## 2.0.5

* Update SDK constraints to `>=2.0.0-dev <3.0.0`.

## 2.0.4

* Declare support for `async` 2.0.0.

## 2.0.3

* Fix `HttpMultiServer.loopback()` and `.loopbackSecure()` for environments that
  don't support IPv4.

## 2.0.2

* Fix a dependency that was incorrectly marked as dev-only.

## 2.0.1

* Fix most strong mode errors and warnings.

## 2.0.0

* **Breaking:** Change the signature of `HttpMultiServer.loopbackSecure()` to
  match the new Dart 1.13 `HttpServer.bindSecure()` signature. This removes the
  `certificateName` named parameter and adds the required `context` parameter
  and the named `v6Only` and `shared` parameters.

* Added `v6Only` and `shared` parameters to `HttpMultiServer.loopback()` to
  match `HttpServer.bind()`.

## 1.3.2

* Eventually stop retrying port allocation if it fails repeatedly.

* Properly detect socket errors caused by already-in-use addresses.

## 1.3.1

* `loopback()` and `loopbackSecure()` recover gracefully if an ephemeral port is
  requested and the located port isn't available on both IPv4 and IPv6.

## 1.3.0

* Add support for `HttpServer.autoCompress`.

## 1.2.0

* Add support for `HttpServer.defaultResponseHeaders.clear`.

* Fix `HttpServer.defaultResponseHeaders.remove` and `.removeAll`.

## 1.1.0

* Add support for `HttpServer.defaultResponseHeaders`.

## 1.0.2

* Remove the workaround for [issue 19815][].

## 1.0.1

* Ignore errors from one of the servers if others are still bound. In
  particular, this works around [issue 19815][] on some Windows machines where
  IPv6 failure isn't discovered until we try to connect to the socket.

[issue 19815]: https://code.google.com/p/dart/issues/detail?id=19815
