// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:mojo/mojo/url_request.mojom.dart' as mojom;
import 'package:mojo/mojo/url_response.mojom.dart' as mojom;
import 'package:mojo_services/mojo/url_loader.mojom.dart' as mojom;

import '../http/mojo_client.dart';
import 'print.dart';

export 'package:mojo/mojo/url_response.mojom.dart' show UrlResponse;

Future<mojom.UrlResponse> fetch(mojom.UrlRequest request, { bool require200: false }) async {
  mojom.UrlLoaderProxy loader = new mojom.UrlLoaderProxy.unbound();
  try {
    MojoClient.networkService.ptr.createUrlLoader(loader);
    mojom.UrlResponse response = (await loader.ptr.start(request)).response;
    if (require200 && (response.error != null || response.statusCode != 200)) {
      StringBuffer message = new StringBuffer();
      message.writeln('Could not ${request.method ?? "fetch"} ${request.url ?? "resource"}');
      if (response.error != null)
        message.writeln('Network error: ${response.error.code} ${response.error.description ?? "<unknown network error>"}');
      if (response.statusCode != 200)
        message.writeln('Protocol error: ${response.statusCode} ${response.statusLine ?? "<no server message>"}');
      if (response.url != request.url)
        message.writeln('Final URL after redirects was: ${response.url}');
      throw message;
    }
    return response;
  } catch (exception) {
    debugPrint('-- EXCEPTION CAUGHT BY NETWORKING HTTP LIBRARY -------------------------');
    debugPrint('An exception was raised while sending bytes to the Mojo network library:');
    debugPrint('$exception');
    debugPrint('------------------------------------------------------------------------');
    return null;
  } finally {
    loader.close();
  }
}

Future<mojom.UrlResponse> fetchUrl(String relativeUrl, { bool require200: false }) {
  String url = Uri.base.resolve(relativeUrl).toString();
  mojom.UrlRequest request = new mojom.UrlRequest()
    ..url = url
    ..autoFollowRedirects = true;
  return fetch(request, require200: require200);
}
