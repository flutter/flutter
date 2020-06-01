// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:test_api/src/backend/runtime.dart';

import 'browser.dart';
import 'chrome.dart';
import 'chrome_installer.dart';
import 'common.dart';
import 'edge.dart';
import 'environment.dart';
import 'edge_installation.dart';
import 'firefox.dart';
import 'firefox_installer.dart';
import 'safari.dart';
import 'safari_installation.dart';

/// Utilities for browsers, that tests are supported.
///
/// Extending [Browser] is not enough for supporting test.
///
/// Each new browser should be added to the [Runtime] map, to the [getBrowser]
/// method.
///
/// One should also implement [BrowserArgParser] and add it to the [argParsers].
class SupportedBrowsers {
  final List<BrowserArgParser> argParsers = List.of([
    ChromeArgParser.instance,
    EdgeArgParser.instance,
    FirefoxArgParser.instance,
    SafariArgParser.instance
  ]);

  final List<String> supportedBrowserNames = [
    'chrome',
    'edge',
    'firefox',
    'safari'
  ];

  final Map<String, Runtime> supportedBrowsersToRuntimes = {
    'chrome': Runtime.chrome,
    'edge': Runtime.internetExplorer,
    'firefox': Runtime.firefox,
    'safari': Runtime.safari,
    'ios-safari': Runtime.safari,
  };

  final Map<String, String> supportedBrowserToPlatform = {
    'chrome': 'chrome',
    'edge': 'ie',
    'firefox': 'firefox',
    'safari': 'safari',
    'ios-safari': 'safari',
  };

  final Map<String, String> browserToConfiguration = {
    'chrome':
        '--configuration=${environment.webUiRootDir.path}/dart_test_chrome.yaml',
    'edge':
        '--configuration=${environment.webUiRootDir.path}/dart_test_edge.yaml',
    'firefox':
        '--configuration=${environment.webUiRootDir.path}/dart_test_firefox.yaml',
    'safari':
        '--configuration=${environment.webUiRootDir.path}/dart_test_safari.yaml',
    'ios-safari':
        '--configuration=${environment.webUiRootDir.path}/dart_test_safari.yaml',
  };

  static final SupportedBrowsers _singletonInstance = SupportedBrowsers._();

  /// The [SupportedBrowsers] singleton.
  static SupportedBrowsers get instance => _singletonInstance;

  SupportedBrowsers._();

  Browser getBrowser(Runtime runtime, Uri url, {bool debug = false}) {
    if (runtime == Runtime.chrome) {
      return Chrome(url, debug: debug);
    } else if (runtime == Runtime.internetExplorer) {
      return Edge(url, debug: debug);
    } else if (runtime == Runtime.firefox) {
      return Firefox(url, debug: debug);
    } else if (runtime == Runtime.safari) {
      return Safari(url, debug: debug);
    } else {
      throw new UnsupportedError('The browser type not supported in tests');
    }
  }
}
