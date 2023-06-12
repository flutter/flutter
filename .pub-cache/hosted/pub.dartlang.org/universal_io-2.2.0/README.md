[![Pub Package](https://img.shields.io/pub/v/universal_io.svg)](https://pub.dartlang.org/packages/universal_io)
[![package publisher](https://img.shields.io/pub/publisher/universal_io.svg)](https://pub.dev/packages/universal_io/publisher)
[![Github Actions CI](https://github.com/dint-dev/universal_io/workflows/Dart%20CI/badge.svg)](https://github.com/dint-dev/universal_io/actions)

# Overview
A cross-platform [dart:io](https://api.dart.dev/stable/2.19.2/dart-io/dart-io-library.html) that
works on all platforms, including browsers.

You can simply replace _dart:io_ imports with _package:universal_io/io.dart_.

Licensed under the [Apache License 2.0](LICENSE).
Some of the source code was derived [from Dart SDK](https://github.com/dart-lang/sdk/tree/master/sdk/lib/io),
which was obtained under the BSD-style license of Dart SDK. See LICENSE file for details.

## APIs added on top of "dart:io"
* [newUniversalHttpClient](https://pub.dev/documentation/universal_io/latest/universal_io/newUniversalHttpClient.html)
  * Returns BrowserHttpClient on browsers and the normal "dart:io" HttpClient on other platforms.
* [BrowserHttpClient](https://pub.dev/documentation/universal_io/latest/universal_io/BrowserHttpClient-class.html)
  * A subclass of "dart:io" [HttpClient](https://api.dart.dev/stable/2.19.2/dart-io/HttpClient-class.html)
    that works on browsers.
* [BrowserHttpClientRequest](https://pub.dev/documentation/universal_io/latest/universal_io/BrowserHttpClientRequest-class.html)
  * A subclass of "dart:io" [HttpClientRequest](https://api.dart.dev/stable/2.19.2/dart-io/HttpClientRequest-class.html)
    that works on browsers.
* [BrowserHttpClientResponse](https://pub.dev/documentation/universal_io/latest/universal_io/BrowserHttpClientResponse-class.html)
  * A subclass of "dart:io" [HttpClientResponse](https://api.dart.dev/stable/2.19.2/dart-io/HttpClientResponse-class.html)
    that works on browsers.
* [BrowserHttpClientException](https://pub.dev/documentation/universal_io/latest/universal_io/BrowserHttpClientException-class.html)
  * An exception that helps you understand why a HTTP request on a browser may have failed
    (see explanation below).

## Other features
The following features may be deprecated in the future versions (3.x) of the package:
* [HttpClient](https://pub.dev/documentation/universal_io/latest/universal_io/HttpClient-class.html)
    * `HttpClient()` factory is changed so that it returns BrowserHttpClient on browsers.
* [Platform](https://pub.dev/documentation/universal_io/latest/universal_io/Platform-class.html)
    * The package makes methods like `Platform.isAndroid` and `Platform.isMacOS` work in the
      browsers too.
* [InternetAddress](https://pub.dev/documentation/universal_io/latest/universal_io/InternetAddress-class.html)
    * The package makes it works in the browsers too.
* [BytesBuilder](https://pub.dev/documentation/universal_io/latest/universal_io/BytesBuilder-class.html)
    * The package makes it works in the browsers too.

## Links
  * [API reference](https://pub.dev/documentation/universal_io/latest/)
  * [Github project](https://github.com/dint-dev/universal_io)
    * We appreciate feedback, issue reports, and pull requests.

## Similar packages
  * [universal_html](https://pub.dev/packages/universal_html) (cross-platform _dart:html_)


# Getting started
## 1.Add dependency
In pubspec.yaml:
```yaml
dependencies:
  universal_io: ^2.2.0
```

## 2.Use HTTP client
```dart
import 'package:universal_io/io.dart';

Future<void> main() async {
  // HttpClient can be used in browser too!
  HttpClient httpClient = newUniversalHttpClient(); // Recommended way of creating HttpClient.
  final request = await httpClient.getUrl(Uri.parse("https://dart.dev/"));
  final response = await request.close();
}
```

# HTTP client behavior
HTTP client is implemented with [XMLHttpRequest (XHR)](https://developer.mozilla.org/en/docs/Web/API/XMLHttpRequest)
API on browsers.

XHR causes the following differences with _dart:io_:
  * HTTP connection is created only after `request.close()` has been called.
  * Same-origin policy limitations. For making cross-origin requests, see documentation below.

## Helpful error messages
When requests fail and assertions are enabled, error messages contains descriptions how to fix
possible issues such as missing cross-origin headers.

The error messages look like the following:
```text
XMLHttpRequest error.
-------------------------------------------------------------------------------
HTTP method:             PUT
HTTP URL:                http://destination.com/example
Origin:                  http://source.com
Cross-origin:            true
browserCredentialsMode:  false
browserResponseType:     arraybuffer

THE REASON FOR THE XHR ERROR IS UNKNOWN.
(For security reasons, browsers do not explain XHR errors.)

Is the server down? Did the server have an internal error?

Enabling credentials mode would enable use of some HTTP headers in both the
request and the response. For example, credentials mode is required for
sending/receiving cookies. If you think you need to enable 'credentials mode',
do the following:

    final httpClientRequest = ...;
    if (httpClientRequest is BrowserHttpClientRequest) {
      httpClientRequest.browserCredentialsMode = true;
    }

Did the server respond to a cross-origin "preflight" (OPTIONS) request?

Did the server send the following headers?
  * Access-Control-Allow-Origin: http://source.com
    * You can also use wildcard ("*").
    * Always required for cross-origin requests!
  * Access-Control-Allow-Methods: PUT
    * You can also use wildcard ("*").
```

Sometimes when you do cross-origin requests in browsers, you want to use
[CORS "credentials mode"](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS). This can be
achieved with the following pattern:
```dart
Future<void> main() async {
    final client = HttpClient();
    final request = client.getUrl(Url.parse('http://example/url'));

    // Enable credentials mode
    if (request is BrowserHttpClientRequest) {
      request.browserCredentialsMode = true;
    }

    // Close request
    final response = await request.close();
    // ...
}
```

## Streaming text responses
The underlying XMLHttpRequest (XHR) API supports response streaming only when _responseType_ is
"text".

This package automatically uses _responseType_ "text" based on value of the
HTTP request header "Accept". These media types are defined
[BrowserHttpClient.defaultTextMimes](https://pub.dev/documentation/universal_io/latest/universal_io/BrowserHttpClient/defaultTextMimes.html):
  * "text/*" (any text media type)
  * "application/grpc-web"
  * "application/grpc-web+proto"

If you want to disable streaming, use the following pattern:
```dart
Future<void> main() async {
    final client = newUniversalHttpClient();
    if (client is BrowserHttpClient) {
      client.textMimes = const {};
    }
    // ...
}
```