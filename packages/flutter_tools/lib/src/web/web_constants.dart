// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;

const String kWasmMoreInfo = 'See https://flutter.dev/to/wasm for more information.';

/// Headers required to run Wasm-compiled applications with multi-threading.
///
/// See https://developer.chrome.com/blog/coep-credentialless-origin-trial
/// for more information.
const Map<String, String> kMultiThreadedHeaders = <String, String>{
  'Cross-Origin-Opener-Policy': 'same-origin',
  'Cross-Origin-Embedder-Policy': 'credentialless',
};

shelf.Response jsResponse(Object? content) => simpleResponse(content, 'text/javascript');

shelf.Response simpleResponse(Object? content, String contentType) {
  if (content == null) {
    return shelf.Response.notFound('');
  }
  return shelf.Response.ok(
    content,
    headers: <String, String>{HttpHeaders.contentTypeHeader: contentType},
  );
}
