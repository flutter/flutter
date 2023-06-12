[![Build Status](https://github.com/dart-lang/http_parser/workflows/Dart%20CI/badge.svg)](https://github.com/dart-lang/http_parser/actions?query=workflow%3A"Dart+CI"+branch%3Amaster)
[![Pub Package](https://img.shields.io/pub/v/http_parser.svg)](https://pub.dartlang.org/packages/http_parser)
[![package publisher](https://img.shields.io/pub/publisher/http_parser.svg)](https://pub.dev/packages/http_parser/publisher)

`http_parser` is a platform-independent package for parsing and serializing
various HTTP-related formats. It's designed to be usable on both the browser and
the server, and thus avoids referencing any types from `dart:io` or `dart:html`.

## Features

* Support for parsing and formatting dates according to [HTTP/1.1][2616], the
  HTTP/1.1 standard.

* A `MediaType` class that represents an HTTP media type, as used in `Accept`
  and `Content-Type` headers. This class supports both parsing and formatting
  media types according to [HTTP/1.1][2616].

* A `WebSocketChannel` class that provides a `StreamChannel` interface for both
  the client and server sides of the [WebSocket protocol][6455] independently of
  any specific server implementation.

[2616]: https://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html
[6455]: https://tools.ietf.org/html/rfc6455
