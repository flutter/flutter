// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../http.dart' as http;
import 'base_client.dart';
import 'base_request.dart';
import 'client_stub.dart'
    if (dart.library.html) 'browser_client.dart'
    if (dart.library.io) 'io_client.dart';
import 'exception.dart';
import 'response.dart';
import 'streamed_response.dart';

/// The interface for HTTP clients that take care of maintaining persistent
/// connections across multiple requests to the same server.
///
/// If you only need to send a single request, it's usually easier to use
/// [http.head], [http.get], [http.post], [http.put], [http.patch], or
/// [http.delete] instead.
///
/// When creating an HTTP client class with additional functionality, you must
/// extend [BaseClient] rather than [Client]. In most cases, you can wrap
/// another instance of [Client] and add functionality on top of that. This
/// allows all classes implementing [Client] to be mutually composable.
abstract class Client {
  /// Creates a new platform appropriate client.
  ///
  /// Creates an `IOClient` if `dart:io` is available and a `BrowserClient` if
  /// `dart:html` is available, otherwise it will throw an unsupported error.
  factory Client() => zoneClient ?? createClient();

  /// Sends an HTTP HEAD request with the given headers to the given URL.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> head(Uri url, {Map<String, String>? headers});

  /// Sends an HTTP GET request with the given headers to the given URL.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> get(Uri url, {Map<String, String>? headers});

  /// Sends an HTTP POST request with the given headers and body to the given
  /// URL.
  ///
  /// [body] sets the body of the request. It can be a [String], a [List<int>]
  /// or a [Map<String, String>].
  ///
  /// If [body] is a String, it's encoded using [encoding] and used as the body
  /// of the request. The content-type of the request will default to
  /// "text/plain".
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
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding});

  /// Sends an HTTP PUT request with the given headers and body to the given
  /// URL.
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
  /// [encoding] defaults to [utf8].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding});

  /// Sends an HTTP PATCH request with the given headers and body to the given
  /// URL.
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
  /// [encoding] defaults to [utf8].
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> patch(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding});

  /// Sends an HTTP DELETE request with the given headers to the given URL.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding});

  /// Sends an HTTP GET request with the given headers to the given URL and
  /// returns a Future that completes to the body of the response as a String.
  ///
  /// The Future will emit a [ClientException] if the response doesn't have a
  /// success status code.
  ///
  /// For more fine-grained control over the request and response, use [send] or
  /// [get] instead.
  Future<String> read(Uri url, {Map<String, String>? headers});

  /// Sends an HTTP GET request with the given headers to the given URL and
  /// returns a Future that completes to the body of the response as a list of
  /// bytes.
  ///
  /// The Future will emit a [ClientException] if the response doesn't have a
  /// success status code.
  ///
  /// For more fine-grained control over the request and response, use [send] or
  /// [get] instead.
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers});

  /// Sends an HTTP request and asynchronously returns the response.
  Future<StreamedResponse> send(BaseRequest request);

  /// Closes the client and cleans up any resources associated with it.
  ///
  /// It's important to close each client when it's done being used; failing to
  /// do so can cause the Dart process to hang.
  void close();
}

/// The [Client] for the current [Zone], if one has been set.
///
/// NOTE: This property is explicitly hidden from the public API.
@internal
Client? get zoneClient {
  final client = Zone.current[#_clientToken];
  return client == null ? null : (client as Client Function())();
}

/// Runs [body] in its own [Zone] with the [Client] returned by [clientFactory]
/// set as the default [Client].
///
/// For example:
///
/// ```
/// class MyAndroidHttpClient extends BaseClient {
///   @override
///   Future<http.StreamedResponse> send(http.BaseRequest request) {
///     // your implementation here
///   }
/// }
///
/// void main() {
///   Client client =  Platform.isAndroid ? MyAndroidHttpClient() : Client();
///   runWithClient(myFunction, () => client);
/// }
///
/// void myFunction() {
///   // Uses the `Client` configured in `main`.
///   final response = await get(Uri.https('www.example.com', ''));
///   final client = Client();
/// }
/// ```
///
/// The [Client] returned by [clientFactory] is used by the [Client.new] factory
/// and the convenience HTTP functions (e.g. [http.get])
R runWithClient<R>(R Function() body, Client Function() clientFactory,
        {ZoneSpecification? zoneSpecification}) =>
    runZoned(body,
        zoneValues: {#_clientToken: Zone.current.bindCallback(clientFactory)},
        zoneSpecification: zoneSpecification);
