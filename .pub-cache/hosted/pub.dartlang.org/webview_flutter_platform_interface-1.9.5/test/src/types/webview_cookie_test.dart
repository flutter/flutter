// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/src/types/types.dart';

void main() {
  test('WebViewCookie should serialize correctly', () {
    WebViewCookie cookie;
    Map<String, String> serializedCookie;
    // Test serialization
    cookie = const WebViewCookie(
        name: 'foo', value: 'bar', domain: 'example.com', path: '/test');
    serializedCookie = cookie.toJson();
    expect(serializedCookie['name'], 'foo');
    expect(serializedCookie['value'], 'bar');
    expect(serializedCookie['domain'], 'example.com');
    expect(serializedCookie['path'], '/test');
  });
}
