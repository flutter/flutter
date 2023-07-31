// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A composable, [Future]-based library for making HTTP requests.
import 'dart:convert';
import 'dart:typed_data';

import 'src/client.dart';
import 'src/exception.dart';
import 'src/request.dart';
import 'src/response.dart';
import 'src/streamed_request.dart';

export 'src/base_client.dart';
export 'src/base_request.dart';
export 'src/base_response.dart';
export 'src/byte_stream.dart';
export 'src/client.dart' hide zoneClient;
export 'src/exception.dart';
export 'src/multipart_file.dart';
export 'src/multipart_request.dart';
export 'src/request.dart';
export 'src/response.dart';
export 'src/streamed_request.dart';
export 'src/streamed_response.dart';

/// Sends an HTTP HEAD request with the given headers to the given URL.
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request, use [Request] instead.
Future<Response> head(Uri url, {Map<String, String>? headers}) =>
    _withClient((client) => client.head(url, headers: headers));

/// Sends an HTTP GET request with the given headers to the given URL.
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request, use [Request] instead.
Future<Response> get(Uri url, {Map<String, String>? headers}) =>
    _withClient((client) => client.get(url, headers: headers));

/// Sends an HTTP POST request with the given headers and body to the given URL.
///
/// [body] sets the body of the request. It can be a [String], a [List<int>] or
/// a [Map<String, String>]. If it's a String, it's encoded using [encoding] and
/// used as the body of the request. The content-type of the request will
/// default to "text/plain".
///
/// If [body] is a List, it's used as a list of bytes for the body of the
/// request.
///
/// If [body] is a Map, it's encoded as form fields using [encoding]. The
/// content-type of the request will be set to
/// `"application/x-www-form-urlencoded"`; this cannot be overridden.
///
/// [encoding] defaults to [utf8].
///
/// For more fine-grained control over the request, use [Request] or
/// [StreamedRequest] instead.
Future<Response> post(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _withClient((client) =>
        client.post(url, headers: headers, body: body, encoding: encoding));

/// Sends an HTTP PUT request with the given headers and body to the given URL.
///
/// [body] sets the body of the request. It can be a [String], a [List<int>] or
/// a [Map<String, String>]. If it's a String, it's encoded using [encoding] and
/// used as the body of the request. The content-type of the request will
/// default to "text/plain".
///
/// If [body] is a List, it's used as a list of bytes for the body of the
/// request.
///
/// If [body] is a Map, it's encoded as form fields using [encoding]. The
/// content-type of the request will be set to
/// `"application/x-www-form-urlencoded"`; this cannot be overridden.
///
/// [encoding] defaults to [utf8].
///
/// For more fine-grained control over the request, use [Request] or
/// [StreamedRequest] instead.
Future<Response> put(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _withClient((client) =>
        client.put(url, headers: headers, body: body, encoding: encoding));

/// Sends an HTTP PATCH request with the given headers and body to the given
/// URL.
///
/// [body] sets the body of the request. It can be a [String], a [List<int>] or
/// a [Map<String, String>]. If it's a String, it's encoded using [encoding] and
/// used as the body of the request. The content-type of the request will
/// default to "text/plain".
///
/// If [body] is a List, it's used as a list of bytes for the body of the
/// request.
///
/// If [body] is a Map, it's encoded as form fields using [encoding]. The
/// content-type of the request will be set to
/// `"application/x-www-form-urlencoded"`; this cannot be overridden.
///
/// [encoding] defaults to [utf8].
///
/// For more fine-grained control over the request, use [Request] or
/// [StreamedRequest] instead.
Future<Response> patch(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _withClient((client) =>
        client.patch(url, headers: headers, body: body, encoding: encoding));

/// Sends an HTTP DELETE request with the given headers to the given URL.
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request, use [Request] instead.
Future<Response> delete(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _withClient((client) =>
        client.delete(url, headers: headers, body: body, encoding: encoding));

/// Sends an HTTP GET request with the given headers to the given URL and
/// returns a Future that completes to the body of the response as a [String].
///
/// The Future will emit a [ClientException] if the response doesn't have a
/// success status code.
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request and response, use [Request]
/// instead.
Future<String> read(Uri url, {Map<String, String>? headers}) =>
    _withClient((client) => client.read(url, headers: headers));

/// Sends an HTTP GET request with the given headers to the given URL and
/// returns a Future that completes to the body of the response as a list of
/// bytes.
///
/// The Future will emit a [ClientException] if the response doesn't have a
/// success status code.
///
/// This automatically initializes a new [Client] and closes that client once
/// the request is complete. If you're planning on making multiple requests to
/// the same server, you should use a single [Client] for all of those requests.
///
/// For more fine-grained control over the request and response, use [Request]
/// instead.
Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) =>
    _withClient((client) => client.readBytes(url, headers: headers));

Future<T> _withClient<T>(Future<T> Function(Client) fn) async {
  var client = Client();
  try {
    return await fn(client);
  } finally {
    client.close();
  }
}
