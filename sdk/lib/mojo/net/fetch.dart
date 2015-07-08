// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:mojo/core.dart' as core;
import 'package:mojom/mojo/network_service.mojom.dart';
import 'package:mojom/mojo/url_loader.mojom.dart';
import 'package:mojom/mojo/url_request.mojom.dart';
import 'package:mojom/mojo/url_response.mojom.dart';

import '../shell.dart' as shell;

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
  try {
    NetworkServiceProxy net = new NetworkServiceProxy.unbound();
    shell.requestService("mojo:authenticated_network_service", net);

    UrlLoaderProxy loader = new UrlLoaderProxy.unbound();
    net.ptr.createUrlLoader(loader);

    UrlResponse response = (await loader.ptr.start(request)).response;

    loader.close();
    net.close();
    return response;
  } catch (e) {
    return new UrlResponse()..statusCode = 500;
  }
}

Future<UrlResponse> fetchUrl(String relativeUrl) async {
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
