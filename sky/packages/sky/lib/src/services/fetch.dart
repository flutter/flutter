// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:mojo/core.dart' as core;
import 'package:mojo/mojo/url_request.mojom.dart';
import 'package:mojo/mojo/url_response.mojom.dart';
import 'package:mojo_services/mojo/network_service.mojom.dart';
import 'package:mojo_services/mojo/url_loader.mojom.dart';

import 'shell.dart';

export 'package:mojo/mojo/url_response.mojom.dart' show UrlResponse;

NetworkServiceProxy _initNetworkService() {
  NetworkServiceProxy networkService = new NetworkServiceProxy.unbound();
  shell.connectToService("mojo:authenticated_network_service", networkService);
  return networkService;
}

final NetworkServiceProxy _networkService = _initNetworkService();

class Response {
  ByteData body;

  Response(this.body);

  String bodyAsString() {
    if (body == null)
      return null;
    return new String.fromCharCodes(new Uint8List.view(body.buffer));
  }
}

Future<UrlResponse> fetch(UrlRequest request) async {
  UrlLoaderProxy loader = new UrlLoaderProxy.unbound();
  try {
    _networkService.ptr.createUrlLoader(loader);
    UrlResponse response = (await loader.ptr.start(request)).response;
    return response;
  } catch (e) {
    print("NetworkService unavailable $e");
    return new UrlResponse()..statusCode = 500;
  } finally {
    loader.close();
  }
}

Future<UrlResponse> fetchUrl(String relativeUrl) {
  String url = Uri.base.resolve(relativeUrl).toString();
  UrlRequest request = new UrlRequest()
    ..url = url
    ..autoFollowRedirects = true;
  return fetch(request);
}

Future<Response> fetchBody(String relativeUrl) async {
  UrlResponse response = await fetchUrl(relativeUrl);
  if (response.body == null) return new Response(null);

  ByteData data = await core.DataPipeDrainer.drainHandle(response.body);
  return new Response(data);
}

Future<String> fetchString(String relativeUrl) async {
  Response response = await fetchBody(relativeUrl);
  return response.bodyAsString();
}
