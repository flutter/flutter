// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:test_api/src/backend/runtime.dart'; // ignore: implementation_imports
import '../executable_settings.dart';

/// Default settings for starting browser executables.
final defaultSettings = UnmodifiableMapView({
  Runtime.chrome: ExecutableSettings(
      linuxExecutable: 'google-chrome',
      macOSExecutable:
          '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
      windowsExecutable: r'Google\Chrome\Application\chrome.exe'),
  Runtime.firefox: ExecutableSettings(
      linuxExecutable: 'firefox',
      macOSExecutable: '/Applications/Firefox.app/Contents/MacOS/firefox-bin',
      windowsExecutable: r'Mozilla Firefox\firefox.exe'),
  Runtime.internetExplorer:
      ExecutableSettings(windowsExecutable: r'Internet Explorer\iexplore.exe'),
  Runtime.safari: ExecutableSettings(
      macOSExecutable: '/Applications/Safari.app/Contents/MacOS/Safari')
});
