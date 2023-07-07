// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

/// Defines the supported HTTP methods for loading a page in [WebView].
enum WebViewRequestMethod {
  /// HTTP GET method.
  get,

  /// HTTP POST method.
  post,
}

/// Extension methods on the [WebViewRequestMethod] enum.
extension WebViewRequestMethodExtensions on WebViewRequestMethod {
  /// Converts [WebViewRequestMethod] to [String] format.
  String serialize() {
    switch (this) {
      case WebViewRequestMethod.get:
        return 'get';
      case WebViewRequestMethod.post:
        return 'post';
    }
  }
}

/// Defines the parameters that can be used to load a page in the [WebView].
class WebViewRequest {
  /// Creates the [WebViewRequest].
  WebViewRequest({
    required this.uri,
    required this.method,
    this.headers = const <String, String>{},
    this.body,
  });

  /// URI for the request.
  final Uri uri;

  /// HTTP method used to make the request.
  final WebViewRequestMethod method;

  /// Headers for the request.
  final Map<String, String> headers;

  /// HTTP body for the request.
  final Uint8List? body;

  /// Serializes the [WebViewRequest] to JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'uri': uri.toString(),
        'method': method.serialize(),
        'headers': headers,
        'body': body,
      };
}
