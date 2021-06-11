// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/drive/web_driver_service.dart';
import 'package:webdriver/sync_io.dart' as sync_io;

import '../../src/common.dart';

void main() {
  testWithoutContext('getDesiredCapabilities Chrome with headless on', () {
    final Map<String, dynamic> expected = <String, dynamic>{
      'acceptInsecureCerts': true,
      'browserName': 'chrome',
      'goog:loggingPrefs': <String, String>{
        sync_io.LogType.browser: 'INFO',
        sync_io.LogType.performance: 'ALL',
      },
      'chromeOptions': <String, dynamic>{
        'w3c': false,
        'args': <String>[
          '--bwsi',
          '--disable-background-timer-throttling',
          '--disable-default-apps',
          '--disable-extensions',
          '--disable-popup-blocking',
          '--disable-translate',
          '--no-default-browser-check',
          '--no-sandbox',
          '--no-first-run',
          '--headless'
        ],
        'perfLoggingPrefs': <String, String>{
          'traceCategories':
          'devtools.timeline,'
              'v8,blink.console,benchmark,blink,'
              'blink.user_timing'
        }
      }
    };

    expect(getDesiredCapabilities(Browser.chrome, true), expected);
  });

  testWithoutContext('getDesiredCapabilities Chrome with headless off', () {
    const String chromeBinary = 'random-binary';
    final Map<String, dynamic> expected = <String, dynamic>{
      'acceptInsecureCerts': true,
      'browserName': 'chrome',
      'goog:loggingPrefs': <String, String>{
        sync_io.LogType.browser: 'INFO',
        sync_io.LogType.performance: 'ALL',
      },
      'chromeOptions': <String, dynamic>{
        'binary': chromeBinary,
        'w3c': false,
        'args': <String>[
          '--bwsi',
          '--disable-background-timer-throttling',
          '--disable-default-apps',
          '--disable-extensions',
          '--disable-popup-blocking',
          '--disable-translate',
          '--no-default-browser-check',
          '--no-sandbox',
          '--no-first-run',
        ],
        'perfLoggingPrefs': <String, String>{
          'traceCategories':
          'devtools.timeline,'
              'v8,blink.console,benchmark,blink,'
              'blink.user_timing'
        }
      }
    };

    expect(getDesiredCapabilities(Browser.chrome, false, chromeBinary), expected);

  });

  testWithoutContext('getDesiredCapabilities Firefox with headless on', () {
    final Map<String, dynamic> expected = <String, dynamic>{
      'acceptInsecureCerts': true,
      'browserName': 'firefox',
      'moz:firefoxOptions' : <String, dynamic>{
        'args': <String>['-headless'],
        'prefs': <String, dynamic>{
          'dom.file.createInChild': true,
          'dom.timeout.background_throttling_max_budget': -1,
          'media.autoplay.default': 0,
          'media.gmp-manager.url': '',
          'media.gmp-provider.enabled': false,
          'network.captive-portal-service.enabled': false,
          'security.insecure_field_warning.contextual.enabled': false,
          'test.currentTimeOffsetSeconds': 11491200
        },
        'log': <String, String>{'level': 'trace'}
      }
    };

    expect(getDesiredCapabilities(Browser.firefox, true), expected);
  });

  testWithoutContext('getDesiredCapabilities Firefox with headless off', () {
    final Map<String, dynamic> expected = <String, dynamic>{
      'acceptInsecureCerts': true,
      'browserName': 'firefox',
      'moz:firefoxOptions' : <String, dynamic>{
        'args': <String>[],
        'prefs': <String, dynamic>{
          'dom.file.createInChild': true,
          'dom.timeout.background_throttling_max_budget': -1,
          'media.autoplay.default': 0,
          'media.gmp-manager.url': '',
          'media.gmp-provider.enabled': false,
          'network.captive-portal-service.enabled': false,
          'security.insecure_field_warning.contextual.enabled': false,
          'test.currentTimeOffsetSeconds': 11491200
        },
        'log': <String, String>{'level': 'trace'}
      }
    };

    expect(getDesiredCapabilities(Browser.firefox, false), expected);
  });

  testWithoutContext('getDesiredCapabilities Edge', () {
    final Map<String, dynamic> expected = <String, dynamic>{
      'acceptInsecureCerts': true,
      'browserName': 'edge',
    };

    expect(getDesiredCapabilities(Browser.edge, false), expected);
  });

  testWithoutContext('getDesiredCapabilities macOS Safari', () {
    final Map<String, dynamic> expected = <String, dynamic>{
      'browserName': 'safari',
    };

    expect(getDesiredCapabilities(Browser.safari, false), expected);
  });

  testWithoutContext('getDesiredCapabilities iOS Safari', () {
    final Map<String, dynamic> expected = <String, dynamic>{
      'platformName': 'ios',
      'browserName': 'safari',
      'safari:useSimulator': true
    };

    expect(getDesiredCapabilities(Browser.iosSafari, false), expected);
  });

  testWithoutContext('getDesiredCapabilities android chrome', () {
    final Map<String, dynamic> expected = <String, dynamic>{
      'browserName': 'chrome',
      'platformName': 'android',
      'goog:chromeOptions': <String, dynamic>{
        'androidPackage': 'com.android.chrome',
        'args': <String>['--disable-fullscreen']
      },
    };

    expect(getDesiredCapabilities(Browser.androidChrome, false), expected);
  });
}
