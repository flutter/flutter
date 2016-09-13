// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'base_client.dart';
import 'base_request.dart';
import 'io.dart' as io;
import 'io_client.dart';
import 'response.dart';
import 'streamed_response.dart';

/// The interface for HTTP clients that take care of maintaining persistent
/// connections across multiple requests to the same server. If you only need to
/// send a single request, it's usually easier to use [head], [get], [post],
/// [put], [patch], or [delete] instead.
///
/// When creating an HTTP client class with additional functionality, you must
/// extend [BaseClient] rather than [Client]. In most cases, you can wrap
/// another instance of [Client] and add functionality on top of that. This
/// allows all classes implementing [Client] to be mutually composable.
abstract class Client {
  /// Creates a new client.
  ///
  /// Currently this will create an [IOClient] if `dart:io` is available and
  /// throw an [UnsupportedError] otherwise. In the future, it will create a
  /// [BrowserClient] if `dart:html` is available.
  factory Client() {
    io.assertSupported("IOClient");
    return new IOClient();
  }

  /// Sends an HTTP HEAD request with the given headers to the given URL, which
  /// can be a [Uri] or a [String].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> head(url, {Map<String, String> headers});

  /// Sends an HTTP GET request with the given headers to the given URL, which
  /// can be a [Uri] or a [String].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> get(url, {Map<String, String> headers});

  /// Sends an HTTP POST request with the given headers and body to the given
  /// URL, which can be a [Uri] or a [String].
  ///
  /// [body] sets the body of the request. It can be a [String], a [List<int>]
  /// or a [Map<String, String>]. If it's a String, it's encoded using
  /// [encoding] and used as the body of the request. The content-type of the
  /// request will default to "text/plain".
  ///
  /// If [body] is a List, it's used as a list of bytes for the body of the
  /// request.
  ///
  /// If [body] is a Map, it's encoded as form fields using [encoding]. The
  /// content-type of the request will be set to
  /// `"application/x-www-form-urlencoded"`; this cannot be overridden.
  ///
  /// [encoding] defaults to [UTF8].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> post(url, {Map<String, String> headers, body,
      Encoding encoding});

  /// Sends an HTTP PUT request with the given headers and body to the given
  /// URL, which can be a [Uri] or a [String].
  ///
  /// [body] sets the body of the request. It can be a [String], a [List<int>]
  /// or a [Map<String, String>]. If it's a String, it's encoded using
  /// [encoding] and used as the body of the request. The content-type of the
  /// request will default to "text/plain".
  ///
  /// If [body] is a List, it's used as a list of bytes for the body of the
  /// request.
  ///
  /// If [body] is a Map, it's encoded as form fields using [encoding]. The
  /// content-type of the request will be set to
  /// `"application/x-www-form-urlencoded"`; this cannot be overridden.
  ///
  /// [encoding] defaults to [UTF8].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> put(url, {Map<String, String> headers, body,
      Encoding encoding});

  /// Sends an HTTP PATCH request with the given headers and body to the given
  /// URL, which can be a [Uri] or a [String].
  ///
  /// [body] sets the body of the request. It can be a [String], a [List<int>]
  /// or a [Map<String, String>]. If it's a String, it's encoded using
  /// [encoding] and used as the body of the request. The content-type of the
  /// request will default to "text/plain".
  ///
  /// If [body] is a List, it's used as a list of bytes for the body of the
  /// request.
  ///
  /// If [body] is a Map, it's encoded as form fields using [encoding]. The
  /// content-type of the request will be set to
  /// `"application/x-www-form-urlencoded"`; this cannot be overridden.
  ///
  /// [encoding] defaults to [UTF8].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> patch(url, {Map<String, String> headers, body,
      Encoding encoding});

  /// Sends an HTTP DELETE request with the given headers to the given URL,
  /// which can be a [Uri] or a [String].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> delete(url, {Map<String, String> headers});

  /// Sends an HTTP GET request with the given headers to the given URL, which
  /// can be a [Uri] or a [String], and returns a Future that completes to the
  /// body of the response as a String.
  ///
  /// The Future will emit a [ClientException] if the response doesn't have a
  /// success status code.
  ///
  /// For more fine-grained control over the request and response, use [send] or
  /// [get] instead.
  Future<String> read(url, {Map<String, String> headers});

  /// Sends an HTTP GET request with the given headers to the given URL, which
  /// can be a [Uri] or a [String], and returns a Future that completes to the
  /// body of the response as a list of bytes.
  ///
  /// The Future will emit a [ClientException] if the response doesn't have a
  /// success status code.
  ///
  /// For more fine-grained control over the request and response, use [send] or
  /// [get] instead.
  Future<Uint8List> readBytes(url, {Map<String, String> headers});

  /// Sends an HTTP request and asynchronously returns the response.
  Future<StreamedResponse> send(BaseRequest request);

  /// Closes the client and cleans up any resources associated with it. It's
  /// important to close each client when it's done being used; failing to do so
  /// can cause the Dart process to hang.
  void close();
}
