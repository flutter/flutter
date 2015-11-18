// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:mojo/mojo/url_request.mojom.dart';
import 'package:mojo/mojo/url_response.mojom.dart';
import 'package:mojo_services/mojo/url_loader.mojom.dart';

import '../http/mojo_client.dart';

export 'package:mojo/mojo/url_response.mojom.dart' show UrlResponse;

Future<UrlResponse> fetch(UrlRequest request) async {
  UrlLoaderProxy loader = new UrlLoaderProxy.unbound();
  try {
    MojoClient.networkService.ptr.createUrlLoader(loader);
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
