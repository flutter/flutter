// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:webdriver/sync_io.dart' as sync_io;

import '../common/error.dart';

/// A list of supported browsers
enum Browser {
  /// Chrome: https://www.google.com/chrome/
  chrome,
  /// Edge: https://www.microsoft.com/en-us/windows/microsoft-edge
  edge,
  /// Firefox: https://www.mozilla.org/en-US/firefox/
  firefox,
  /// Safari in iOS: https://www.apple.com/safari/
  iosSafari,
  /// Safari in macOS: https://www.apple.com/safari/
  safari,
}

/// Converts [browserName] string to [Browser]
Browser browserNameToEnum(String browserName){
  switch (browserName) {
    case 'chrome': return Browser.chrome;
    case 'edge': return Browser.edge;
    case 'firefox': return Browser.firefox;
    case 'ios-safari': return Browser.iosSafari;
    case 'safari': return Browser.safari;
  }
  throw DriverError('Browser $browserName not supported');
}

/// Creates a WebDriver instance with the given [settings].
sync_io.WebDriver createDriver(Map<String, dynamic> settings) {
  return _createDriver(
      settings['selenium-port'] as String,
      settings['browser'] as Browser,
      settings['headless'] as bool
  );
}

sync_io.WebDriver _createDriver(String seleniumPort, Browser browser, bool headless) {
  return sync_io.createDriver(
      uri: Uri.parse('http://localhost:$seleniumPort/wd/hub/'),
      desired: getDesiredCapabilities(browser, headless),
      spec: browser != Browser.iosSafari ? sync_io.WebDriverSpec.JsonWire : sync_io.WebDriverSpec.W3c
  );
}

/// Returns desired capabilities for given [browser] and [headless].
@visibleForTesting
Map<String, dynamic> getDesiredCapabilities(Browser browser, bool headless) {
  switch (browser) {
    case Browser.chrome:
      return <String, dynamic>{
        'acceptInsecureCerts': true,
        'browserName': 'chrome',
        'goog:loggingPrefs': <String, String>{ sync_io.LogType.performance: 'ALL'},
        'chromeOptions': <String, dynamic>{
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
            if (headless) '--headless'
          ],
          'perfLoggingPrefs': <String, String>{
            'traceCategories':
              'devtools.timeline,'
              'v8,blink.console,benchmark,blink,'
              'blink.user_timing'
          }
        }
      };
      break;
    case Browser.firefox:
      return <String, dynamic>{
        'acceptInsecureCerts': true,
        'browserName': 'firefox',
        'moz:firefoxOptions' : <String, dynamic>{
          'args': <String>[
            if (headless) '-headless'
          ],
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
      break;
    case Browser.edge:
      return <String, dynamic>{
        'acceptInsecureCerts': true,
        'browserName': 'edge',
      };
      break;
    case Browser.safari:
      return <String, dynamic>{
        'browserName': 'safari',
        'safari.options': <String, dynamic>{
          'skipExtensionInstallation': true,
          'cleanSession': true
        }
      };
      break;
    case Browser.iosSafari:
      return <String, dynamic>{
        'platformName': 'ios',
        'browserName': 'safari',
        'safari:useSimulator': true
      };
    default:
      throw DriverError('Browser $browser not supported.');
  }
}
