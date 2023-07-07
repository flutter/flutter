// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/src/types/types.dart';

void main() {
  test('WebViewRequestMethod should serialize correctly', () {
    expect(WebViewRequestMethod.get.serialize(), 'get');
    expect(WebViewRequestMethod.post.serialize(), 'post');
  });

  test('WebViewRequest should serialize correctly', () {
    WebViewRequest request;
    Map<String, dynamic> serializedRequest;
    // Test serialization without headers or a body
    request = WebViewRequest(
      uri: Uri.parse('https://flutter.dev'),
      method: WebViewRequestMethod.get,
    );
    serializedRequest = request.toJson();
    expect(serializedRequest['uri'], 'https://flutter.dev');
    expect(serializedRequest['method'], 'get');
    expect(serializedRequest['headers'], <String, String>{});
    expect(serializedRequest['body'], null);
    // Test serialization of headers and body
    request = WebViewRequest(
      uri: Uri.parse('https://flutter.dev'),
      method: WebViewRequestMethod.get,
      headers: <String, String>{'foo': 'bar'},
      body: Uint8List.fromList('Example Body'.codeUnits),
    );
    serializedRequest = request.toJson();
    expect(serializedRequest['headers'], <String, String>{'foo': 'bar'});
    expect(serializedRequest['body'], 'Example Body'.codeUnits);
  });
}
