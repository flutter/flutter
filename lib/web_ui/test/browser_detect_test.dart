// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/browser_detection.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('detectBrowserEngineByVendorAgent', () {
    test('Should detect Blink', () {
      // Chrome Version 89.0.4389.90 (Official Build) (x86_64) / MacOS
      final BrowserEngine browserEngine = detectBrowserEngineByVendorAgent(
          'Google Inc.',
          'mozilla/5.0 (macintosh; intel mac os x 11_2_3) applewebkit/537.36 '
              '(khtml, like gecko) chrome/89.0.4389.90 safari/537.36');
      expect(browserEngine, BrowserEngine.blink);
    });

    test('Should detect Firefox', () {
      // 85.0.2 (64-bit) / MacOS
      final BrowserEngine browserEngine = detectBrowserEngineByVendorAgent(
          '',
          'mozilla/5.0 (macintosh; intel mac os x 10.16; rv:85.0) '
              'gecko/20100101 firefox/85.0');
      expect(browserEngine, BrowserEngine.firefox);
    });

    test('Should detect Safari', () {
      final BrowserEngine browserEngine = detectBrowserEngineByVendorAgent(
          'Apple Computer, Inc.',
          'mozilla/5.0 (macintosh; intel mac os x 10_15_6) applewebkit/605.1.15 '
              '(khtml, like gecko) version/14.0.3 safari/605.1.15');
      expect(browserEngine, BrowserEngine.webkit);
    });

    test('Should detect Samsung browser', () {
      // Samsung 13.2.1.70 on Galaxy Tab S6.
      final BrowserEngine browserEngine = detectBrowserEngineByVendorAgent(
          'Google Inc.',
          'mozilla/5.0 (x11; linux x86_64) applewebkit/537.36 (khtml, like gecko)'
              ' samsungbrowser/13.2 chrome/83.0.4103.106 safari/537.36');
      expect(browserEngine, BrowserEngine.samsung);
    });
  });

  group('detectOperatingSystem', () {
    void expectOs(
      OperatingSystem expectedOs, {
      String platform = 'any',
      String ua = 'any',
      int touchPoints = 0,
    }) {
      expect(
          detectOperatingSystem(
            overridePlatform: platform,
            overrideUserAgent: ua,
            overrideMaxTouchPoints: touchPoints,
          ),
          expectedOs);
    }

    test('Determine unknown for weird values of platform/ua', () {
      expectOs(OperatingSystem.unknown);
    });

    test('Determine MacOS if platform starts by Mac', () {
      expectOs(
        OperatingSystem.macOs,
        platform: 'MacIntel',
      );
      expectOs(
        OperatingSystem.macOs,
        platform: 'MacAnythingElse',
      );
    });

    test('Determine iOS if platform contains iPhone/iPad/iPod', () {
      expectOs(
        OperatingSystem.iOs,
        platform: 'iPhone',
      );
      expectOs(
        OperatingSystem.iOs,
        platform: 'iPhone Simulator',
      );
      expectOs(
        OperatingSystem.iOs,
        platform: 'iPad',
      );
      expectOs(
        OperatingSystem.iOs,
        platform: 'iPad Simulator',
      );
      expectOs(
        OperatingSystem.iOs,
        platform: 'iPod',
      );
      expectOs(
        OperatingSystem.iOs,
        platform: 'iPod Simulator',
      );
    });

    // See https://github.com/flutter/flutter/issues/81918
    test('Tell apart MacOS from iOS requesting a desktop site.', () {
      expectOs(
        OperatingSystem.macOs,
        platform: 'MacARM',
      );

      expectOs(
        OperatingSystem.iOs,
        platform: 'MacARM',
        touchPoints: 5,
      );
    });

    test('Determine Android if user agent contains Android', () {
      expectOs(
        OperatingSystem.android,
        ua: 'Mozilla/5.0 (Linux; U; Android 2.2) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1',
      );
    });

    test('Determine Linux if the platform begins with Linux', () {
      expectOs(
        OperatingSystem.linux,
        platform: 'Linux',
      );
      expectOs(
        OperatingSystem.linux,
        platform: 'Linux armv8l',
      );
      expectOs(
        OperatingSystem.linux,
        platform: 'Linux x86_64',
      );
    });

    test('Determine Windows if the platform begins with Win', () {
      expectOs(
        OperatingSystem.windows,
        platform: 'Windows',
      );
      expectOs(
        OperatingSystem.windows,
        platform: 'Win32',
      );
      expectOs(
        OperatingSystem.windows,
        platform: 'Win16',
      );
      expectOs(
        OperatingSystem.windows,
        platform: 'WinCE',
      );
    });
  });
}
