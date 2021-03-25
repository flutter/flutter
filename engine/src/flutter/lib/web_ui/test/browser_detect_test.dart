// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('Should detect Blink', () {
    // Chrome Version 89.0.4389.90 (Official Build) (x86_64) / MacOS
    BrowserEngine browserEngine = detectBrowserEngineByVendorAgent(
        'Google Inc.',
        'mozilla/5.0 (macintosh; intel mac os x 11_2_3) applewebkit/537.36 '
        '(khtml, like gecko) chrome/89.0.4389.90 safari/537.36');
    expect(browserEngine, BrowserEngine.blink);
  });

  test('Should detect Firefox', () {
    // 85.0.2 (64-bit) / MacOS
    BrowserEngine browserEngine = detectBrowserEngineByVendorAgent(
        '',
        'mozilla/5.0 (macintosh; intel mac os x 10.16; rv:85.0) '
        'gecko/20100101 firefox/85.0');
    expect(browserEngine, BrowserEngine.firefox);
  });

  test('Should detect Safari', () {
    BrowserEngine browserEngine = detectBrowserEngineByVendorAgent(
      'Apple Computer, Inc.',
      'mozilla/5.0 (macintosh; intel mac os x 10_15_6) applewebkit/605.1.15 '
      '(khtml, like gecko) version/14.0.3 safari/605.1.15');
    expect(browserEngine, BrowserEngine.webkit);
  });

  test('Should detect Samsung browser', () {
    // Samsung 13.2.1.70 on Galaxy Tab S6.
    BrowserEngine browserEngine = detectBrowserEngineByVendorAgent(
        'Google Inc.',
        'mozilla/5.0 (x11; linux x86_64) applewebkit/537.36 (khtml, like gecko)'
        ' samsungbrowser/13.2 chrome/83.0.4103.106 safari/537.36');
    expect(browserEngine, BrowserEngine.samsung);
  });
}
