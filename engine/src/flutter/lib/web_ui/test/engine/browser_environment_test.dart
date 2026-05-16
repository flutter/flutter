// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/dom.dart';

@JS('_flutter._supportsWasmGC')
external bool supportsWasmGC();

void mockUserAgent(String userAgent) {
  objectConstructor.defineProperty(
    domWindow.navigator as JSObject,
    'userAgent',
    DomPropertyDataDescriptor(value: userAgent, configurable: true),
  );
}

void mockVendor(String vendor) {
  objectConstructor.defineProperty(
    domWindow.navigator as JSObject,
    'vendor',
    DomPropertyDataDescriptor(value: vendor, configurable: true),
  );
}

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('browserEnvironment supportsWasmGC', () {
    late String originalUserAgent;
    late String originalVendor;

    setUpAll(() {
      originalUserAgent = domWindow.navigator.userAgent;
      originalVendor = domWindow.navigator.vendor;
    });

    tearDownAll(() {
      mockVendor(originalVendor);
      mockUserAgent(originalUserAgent);
    });

    test('correctly identifies and gates WebKit / Safari versions', () {
      // 1. Desktop Safari 18.2 UA (Crashing version)
      mockVendor('Apple Computer, Inc.');
      mockUserAgent(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
        '(KHTML, like Gecko) Version/18.2 Safari/605.1.15',
      );
      expect(supportsWasmGC(), isFalse);

      // 2. Desktop Safari 26.0 UA (Fixed version)
      mockUserAgent(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
        '(KHTML, like Gecko) Version/26.0 Safari/605.1.15',
      );
      expect(supportsWasmGC(), isTrue);

      // 3. iOS WKWebView UA (iOS 18_2)
      mockUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
      );
      expect(supportsWasmGC(), isFalse);

      // 4. iOS WKWebView UA (iOS 26_0)
      mockUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
      );
      expect(supportsWasmGC(), isTrue);

      // 5. macOS WKWebView UA (Frozen OS version)
      mockUserAgent(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko)',
      );
      expect(supportsWasmGC(), isFalse);
    });
  });
}
