// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/src/services/shell.dart';
import 'package:mojo_services/mojo/network_service.mojom.dart' as mojo;
import 'package:mojo_services/mojo/url_loader.mojom.dart' as mojo;
import 'package:mojo/core.dart' as mojo;
import 'package:mojo/mojo/url_request.mojom.dart' as mojo;
import 'package:mojo/mojo/url_response.mojom.dart' as mojo;

import 'response.dart';

mojo.NetworkServiceProxy _initNetworkService() {
  mojo.NetworkServiceProxy networkService = new mojo.NetworkServiceProxy.unbound();
  shell.connectToService("mojo:authenticated_network_service", networkService);
  return networkService;
}

final mojo.NetworkServiceProxy _networkService = _initNetworkService();

/// A `mojo`-based HTTP client
class MojoClient {

  Future<Response> head(url, {Map<String, String> headers}) =>
    _send("HEAD", url, headers);

  Future<Response> get(url, {Map<String, String> headers}) =>
    _send("GET", url, headers);

  Future<Response> post(url, {Map<String, String> headers, body,
      Encoding encoding}) =>
    _send("POST", url, headers, body, encoding);

  Future<Response> put(url, {Map<String, String> headers, body,
      Encoding encoding}) =>
    _send("PUT", url, headers, body, encoding);

  Future<Response> patch(url, {Map<String, String> headers, body,
      Encoding encoding}) =>
    _send("PATCH", url, headers, body, encoding);

  Future<Response> delete(url, {Map<String, String> headers}) =>
    _send("DELETE", url, headers);

  Future<String> read(url, {Map<String, String> headers}) {
    return get(url, headers: headers).then((response) {
      _checkResponseSuccess(url, response);
      return response.body;
    });
  }

  Future<Uint8List> readBytes(url, {Map<String, String> headers}) {
    return get(url, headers: headers).then((Response response) {
      _checkResponseSuccess(url, response);
      return response.bodyBytes;
    });
  }

  Future<Response> _send(String method, url,
      Map<String, String> headers, [body, Encoding encoding]) async {

    mojo.UrlLoaderProxy loader = new mojo.UrlLoaderProxy.unbound();
    mojo.UrlRequest request = new mojo.UrlRequest()
      ..url = url.toString()
      ..method = method;
    if (body != null) {
      mojo.MojoDataPipe pipe = new mojo.MojoDataPipe();
      request.body = <mojo.MojoDataPipeConsumer>[pipe.consumer];
      Uint8List encodedBody = UTF8.encode(body);
      ByteData data = new ByteData.view(encodedBody.buffer);
      mojo.DataPipeFiller.fillHandle(pipe.producer, data);
    }
    try {
      _networkService.ptr.createUrlLoader(loader);
      mojo.UrlResponse response = (await loader.ptr.start(request)).response;
      ByteData data = await mojo.DataPipeDrainer.drainHandle(response.body);
      Uint8List bodyBytes = new Uint8List.view(data.buffer);
      String body = new String.fromCharCodes(bodyBytes);
      return new Response(body: body, bodyBytes: bodyBytes, statusCode: response.statusCode);
    } catch (e) {
      print("NetworkService unavailable $e");
      return new Response(statusCode: 500);
    } finally {
      loader.close();
    }
  }

  void _checkResponseSuccess(url, Response response) {
    if (response.statusCode < 400)
      return;
    throw new Exception("Request to $url failed with status ${response.statusCode}.");
  }

  void close() {}
}
