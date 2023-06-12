[![Pub Package](https://img.shields.io/pub/v/universal_io.svg)](https://pub.dartlang.org/packages/universal_io)
[![Github Actions CI](https://github.com/dint-dev/universal_io/workflows/Dart%20CI/badge.svg)](https://github.com/dint-dev/universal_io/actions?query=workflow%3A%22Dart+CI%22)

# Overview
A cross-platform _dart:io_ that works in all platforms (browsers, mobile, desktop, and server-side).

The API is exactly the same API as _dart:io_. You can simply replace _dart:io_ imports with
_package:universal_io/io.dart_. Normal _dart:io_ will continue to be used when your application runs
in non-Javascript platforms.

Licensed under the [Apache License 2.0](LICENSE).
Much of the source code is derived [from Dart SDK](https://github.com/dart-lang/sdk/tree/master/sdk/lib/io),
which was obtained under the BSD-style license of Dart SDK. See LICENSE file for details.

## Links
  * [API reference](https://pub.dev/documentation/universal_io/latest/)
  * [Github project](https://github.com/dint-dev/universal_io)
    * We appreciate feedback, issue reports, and pull requests.

## Similar packages
  * [universal_html](https://pub.dev/packages/universal_html) (cross-platform _dart:html_)


# Getting started
## 1.Add dependency
```yaml
dependencies:
  universal_io: ^2.0.4
```

## 2.Use APIs

```dart
import 'package:universal_io/io.dart';

Future<void> main() async {
  // HttpClient can be used in browser too!
  final httpClient = HttpClient();
  final request = await httpClient.getUrl(Uri.parse("http://example/url"));
  final response = await request.close();
}
```

# Behavior in browsers
## Platform
The following [Platform](https://api.dart.dev/stable/2.12.2/dart-io/Platform-class.html) APIs work
in browsers:
  * Platform.locale
  * Platform.operatingSystem
  * Platform.operatingSystemVersion

## HTTP client
HTTP client is implemented with [XMLHttpRequest (XHR)](https://developer.mozilla.org/en/docs/Web/API/XMLHttpRequest)
(in _dart:html_, the class is [HttpRequest](https://api.dart.dev/stable/2.12.2/dart-html/HttpRequest-class.html)).

XHR causes the following differences with _dart:io_:
  * HTTP connection is created only after `request.close()` has been called.
  * Same-origin policy limitations. For making cross-origin requests, see documentation below.

### Helpful error messages
When requests fail and assertions are enabled, error messages contains descriptions how to fix
possible issues such as missing cross-origin headers.

The error messages look like the following:
```
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

See [source code](https://github.com/dint-dev/universal_io/blob/master/lib/src/browser/http_client_request.dart).

### Streaming text responses
The underlying XMLHttpRequest (XHR) API supports response streaming only when _responseType_ is
"text". This package automatically uses _responseType_ "text" in some cases based on value of the
HTTP request header "Accept".

If you want to always have arraybuffer / text responses, use:
```dart
Future<void> main() async {
    final client = HttpClient();
    final request = client.getUrl(Url.parse('http://example/url'));

    // The following causes XHR responseType 'text' to be used when request is closed.
    request.headers.set('Accept', 'text/plain');

    // Use XHR responseType 'arraybuffer'.
    if (request is BrowserHttpClientRequest) {
      request.browserResponseType = 'arrayBuffer';
    }

    // Close request
    final response = await request.close();
    // ...
}
```

See [source code](https://github.com/dint-dev/universal_io/blob/master/lib/src/browser/http_client_request.dart).