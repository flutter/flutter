// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../shell.dart' as shell;
import 'dart:async';
import 'dart:sky' as sky;
import 'dart:typed_data';
import 'package:mojo/core.dart' as core;
import 'package:mojom/mojo/network_service.mojom.dart';
import 'package:mojom/mojo/url_loader.mojom.dart';
import 'package:mojom/mojo/url_request.mojom.dart';

class Response {
  ByteData body;

  Response(this.body);

  String bodyAsString() {
    return new String.fromCharCodes(new Uint8List.view(body.buffer));
  }
}

Future<Response> fetch(String relativeUrl) async {
  String url = new sky.URL(relativeUrl, sky.document.baseURI).href;

  var net = new NetworkServiceProxy.unbound();
  shell.requestService("mojo:network_service", net);

  var loader = new UrlLoaderProxy.unbound();
  net.ptr.createUrlLoader(loader);

  var request = new UrlRequest()
    ..url = url
    ..autoFollowRedirects = true;
  var response = (await loader.ptr.start(request)).response;

  loader.close();
  net.close();

  if (response.body == null) return new Response(null);

  ByteData data = await core.DataPipeDrainer.drainHandle(response.body);
  return new Response(data);
}
