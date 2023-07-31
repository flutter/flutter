[![Dart CI](https://github.com/google/sync_http.dart/actions/workflows/test-package.yml/badge.svg)](https://github.com/google/sync_http.dart/actions/workflows/test-package.yml)
[![pub package](https://img.shields.io/pub/v/sync_http.svg)](https://pub.dev/packages/sync_http)
[![package publisher](https://img.shields.io/pub/publisher/sync_http.svg)](https://pub.dev/packages/sync_http/publisher)

A Dart HTTP client implemented using RawSynchronousSockets to allow for
synchronous HTTP requests.

## Using this package

**Note**: this package is only intended for very specialized use cases. For
general HTTP usage, please see instead
[package:http](https://pub.dev/packages/http).

This library should probably only be used to connect to HTTP servers that are
hosted on 'localhost'. The operations in this library will block the calling
thread to wait for a response from the HTTP server. The thread can process no
other events while waiting for the server to respond. As such, this synchronous
HTTP client library is not suitable for applications that require high
performance. Instead, such applications should use libraries built on
asynchronous I/O, including
[dart:io](https://api.dart.dev/stable/dart-io/dart-io-library.html)
and [package:http](https://pub.dev/packages/http), for the best 
performance.
