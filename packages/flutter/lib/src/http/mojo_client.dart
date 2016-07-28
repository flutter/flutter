// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mojo/core.dart' as mojo;
import 'package:mojo/mojo/http_header.mojom.dart' as mojom;
import 'package:mojo/mojo/url_request.mojom.dart' as mojom;
import 'package:mojo/mojo/url_response.mojom.dart' as mojom;
import 'package:mojo_services/mojo/network_service.mojom.dart' as mojom;
import 'package:mojo_services/mojo/url_loader.mojom.dart' as mojom;

import 'response.dart';

/// A `mojo`-based HTTP client.
class MojoClient {

  /// Sends an HTTP HEAD request with the given headers to the given URL, which
  /// can be a [Uri] or a [String].
  ///
  /// Network errors will be turned into [Response] object with a non-null
  /// [Response.error] field.
  Future<Response> head(dynamic url, { Map<String, String> headers }) {
    return _createResponse(_send("HEAD", url, headers));
  }

  /// Sends an HTTP GET request with the given headers to the given URL, which can
  /// be a [Uri] or a [String].
  ///
  /// Network errors will be turned into [Response] object with a non-null
  /// [Response.error] field.
  Future<Response> get(dynamic url, { Map<String, String> headers }) {
    return _createResponse(_send("GET", url, headers));
  }

  /// Sends an HTTP POST request with the given headers and body to the given URL,
  /// which can be a [Uri] or a [String].
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
  /// [encoding] defaults to [UTF8].
  ///
  /// Network errors will be turned into [Response] object with a non-null
  /// [Response.error] field.
  Future<Response> post(dynamic url, { Map<String, String> headers, dynamic body, Encoding encoding: UTF8 }) {
    return _createResponse(_send("POST", url, headers, body, encoding));
  }

  /// Sends an HTTP PUT request with the given headers and body to the given URL,
  /// which can be a [Uri] or a [String].
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
  /// [encoding] defaults to [UTF8].
  ///
  /// Network errors will be turned into [Response] object with a non-null
  /// [Response.error] field.
  Future<Response> put(dynamic url, { Map<String, String> headers, dynamic body, Encoding encoding: UTF8 }) {
    return _createResponse(_send("PUT", url, headers, body, encoding));
  }

  /// Sends an HTTP PATCH request with the given headers and body to the given
  /// URL, which can be a [Uri] or a [String].
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
  /// [encoding] defaults to [UTF8].
  ///
  /// Network errors will be turned into [Response] object with a non-null
  /// [Response.error] field.
  Future<Response> patch(dynamic url, {Map<String, String> headers, dynamic body, Encoding encoding: UTF8 }) {
    return _createResponse(_send("PATCH", url, headers, body, encoding));
  }

  /// Sends an HTTP DELETE request with the given headers to the given URL, which
  /// can be a [Uri] or a [String].
  ///
  /// Network errors will be turned into [Response] object with a non-null
  /// [Response.error] field.
  Future<Response> delete(dynamic url, { Map<String, String> headers }) {
    return _createResponse(_send("DELETE", url, headers));
  }

  /// Sends an HTTP GET request with the given headers to the given URL, which can
  /// be a [Uri] or a [String], and returns a Future that completes to the body of
  /// the response as a [String].
  ///
  /// The Future will resolve with an error in the case of a network error or if
  /// the response doesn't have a success status code.
  Future<String> read(dynamic url, { Map<String, String> headers }) {
    return get(url, headers: headers).then((Response response) {
      _requireSuccess(url, response.statusCode, response.error);
      return response.body;
    });
  }

  /// Sends an HTTP GET request with the given headers to the given URL, which can
  /// be a [Uri] or a [String], and returns a Future that completes to the body of
  /// the response as a list of bytes.
  ///
  /// The Future will resolve with an error in the case of a network error or if
  /// the response doesn't have a success status code.
  Future<Uint8List> readBytes(dynamic url, { Map<String, String> headers }) {
    return get(url, headers: headers).then((Response response) {
      _requireSuccess(url, response.statusCode, response.error);
      return response.bodyBytes;
    });
  }

  /// Sends an HTTP GET request with the given headers to the given URL, which can
  /// be a [Uri] or a [String], and returns a Future that completes to the body of
  /// the response as a [mojo.MojoDataPipeConsumer].
  ///
  /// The Future will resolve with an error in the case of a network error or if
  /// the response doesn't have a success status code.
  Future<mojo.MojoDataPipeConsumer> readDataPipe(dynamic url, { Map<String, String> headers }) {
    return _send('GET', url, headers).then((mojom.UrlResponse response) {
      _requireSuccess(url, response.statusCode, response.statusLine);
      return response.body;
    });
  }

  mojom.UrlRequest _prepareRequest(String method, dynamic url, Map<String, String> headers, [dynamic body, Encoding encoding = UTF8]) {
    List<mojom.HttpHeader> mojoHeaders = <mojom.HttpHeader>[];
    headers?.forEach((String name, String value) {
      mojom.HttpHeader header = new mojom.HttpHeader()
        ..name = name
        ..value = value;
      mojoHeaders.add(header);
    });
    mojom.UrlRequest request = new mojom.UrlRequest()
      ..url = url.toString()
      ..headers = mojoHeaders
      ..method = method
      ..autoFollowRedirects = true;
    if (body != null) {
      mojo.MojoDataPipe pipe = new mojo.MojoDataPipe();
      request.body = <mojo.MojoDataPipeConsumer>[pipe.consumer];
      Uint8List encodedBody = encoding.encode(body);
      ByteData data = new ByteData.view(encodedBody.buffer);
      mojo.DataPipeFiller.fillHandle(pipe.producer, data);
    }
    return request;
  }

  Future<mojom.UrlResponse> _send(String method, dynamic url, Map<String, String> headers, [dynamic body, Encoding encoding = UTF8]) {
    Completer<mojom.UrlResponse> completer = new Completer<mojom.UrlResponse>();
    mojom.UrlLoaderProxy loader = new mojom.UrlLoaderProxy.unbound();
    networkService.createUrlLoader(loader);
    mojom.UrlRequest request = _prepareRequest(method, url, headers, body, encoding);
    loader.start(request, (mojom.UrlResponse response) async {
      loader.close();
      try {
        if (response.error != null)
          throw new Exception('Request to "$url" failed with error ${response.error.code}.\n${response.error.description}');
        if (!response.body.handle.isValid)
          throw new Exception('Response body does not have a valid handle, but no error was reported.\n${response.body}');
        completer.complete(response);
      } catch (e, stack) {
        FlutterError.reportError(new FlutterErrorDetails(
          exception: e,
          stack: stack,
          library: 'networking HTTP library',
          context: 'while interacting with the Mojo network library',
          silent: true
        ));
        completer.completeError(e);
      }
    });
    return completer.future;
  }

  Future<Response> _createResponse(Future<mojom.UrlResponse> futureResponse) async {
    try {
      mojom.UrlResponse response = await futureResponse;
      try {
        ByteData data = await mojo.DataPipeDrainer.drainHandle(response.body);
        Uint8List bodyBytes = new Uint8List.view(data.buffer);
        Map<String, String> headers = <String, String>{};
        if (response.headers != null) {
          for (mojom.HttpHeader header in response.headers) {
            String headerName = header.name.toLowerCase();
            String existingValue = headers[headerName];
            headers[headerName] = existingValue != null ? '$existingValue, ${header.value}' : header.value;
          }
        }
        return new Response.bytes(bodyBytes, response.statusCode, headers: headers, error: response.statusLine);
      } catch (e, stack) {
        FlutterError.reportError(new FlutterErrorDetails(
          exception: e,
          stack: stack,
          library: 'networking HTTP library',
          context: 'while interacting with the Mojo network library',
          silent: true
        ));
        rethrow;
      }
    } catch (e) {
      return new Response.bytes(null, 500, error: e);
    }
  }

  void _requireSuccess(dynamic url, int statusCode, dynamic error) {
    if (error is Exception)
      throw error;
    if (statusCode >= 400) {
      String extra;
      if (error is String && error != '') {
        extra = '\nServer response: "$error"';
      } else if (error != null) {
        extra = '\n$error';
      } else {
        extra = '';
      }
      throw new Exception('Request to "$url" failed with status $statusCode.$extra');
    }
  }

  static mojom.NetworkServiceProxy _initNetworkService() {
    return shell.connectToApplicationService('mojo:authenticated_network_service', mojom.NetworkService.connectToService);
  }

  /// A handle to the [NetworkService] object used by [MojoClient].
  static final mojom.NetworkServiceProxy networkService = _initNetworkService();
}
