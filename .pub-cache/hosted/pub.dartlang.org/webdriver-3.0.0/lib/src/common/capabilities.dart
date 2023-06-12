// Copyright 2017 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Capabilities constants.
class Capabilities {
  static const String browserName = 'browserName';
  static const String browserVersion = 'browserVersion';
  static const String platformName = 'platformName';
  static const String acceptInsecureCerts = 'acceptInsecureCerts';
  static const String pageLoadStrategy = 'pageLoadStrategy';
  static const String proxy = 'proxy';
  static const String setWindowRect = 'setWindowRect';
  static const String timeouts = 'timeouts';
  static const String unhandledPromptBehavior = 'unhandledPromptBehavior';
  static const String chromeOptions = 'goog:chromeOptions';
  static const String firefoxOptions = 'moz:firefoxOptions';

  @Deprecated('This is not supported in the W3C spec.')
  static const String takesScreenshot = 'takesScreenshot';
  @Deprecated('This is not supported in the W3C spec.')
  static const String supportsAlerts = 'handlesAlerts';
  @Deprecated('This is not supported in the W3C spec.')
  static const String supportSqlDatabase = 'databaseEnabled';
  @Deprecated('This is not supported in the W3C spec.')
  static const String supportsLocationContext = 'locationContextEnabled';
  @Deprecated('This is not supported in the W3C spec.')
  static const String supportsApplicationCache = 'applicationCacheEnabled';
  @Deprecated('This is not supported in the W3C spec.')
  static const String supportsBrowserConnection = 'browserConnectionEnabled';
  @Deprecated('This is not supported in the W3C spec.')
  static const String supportsFindingByCss = 'cssSelectorsEnabled';
  @Deprecated('This is not supported in the W3C spec.')
  static const String supportsWebStorage = 'webStorageEnabled';
  @Deprecated('This is not supported in the W3C spec.')
  static const String rotatable = 'rotatable';
  @Deprecated('This is not supported in the W3C spec.')
  static const String acceptSslCerts = 'acceptSslCerts';
  @Deprecated('This is not supported in the W3C spec.')
  static const String hasNativeEvents = 'nativeEvents';
  @Deprecated('This is not supported in the W3C spec.')
  static const String unexpectedAlertBehaviour = 'unexpectedAlertBehaviour';
  @Deprecated('This is not supported in the W3C spec.')
  static const String loggingPrefs = 'loggingPrefs';
  @Deprecated('This is not supported in the W3C spec.')
  static const String enableProfiling = 'webdriver.logging.profiler.enabled';

  static Map<String, dynamic> get chrome => {browserName: Browser.chrome};

  static Map<String, dynamic> get firefox => {browserName: Browser.firefox};

  static Map<String, dynamic> get android => {browserName: Browser.android};

  static Map<String, dynamic> get empty => {};
}

/// Browser name constants.
class Browser {
  static const String firefox = 'firefox';
  static const String safari = 'safari';
  static const String opera = 'opera';
  static const String chrome = 'chrome';
  static const String android = 'android';
  static const String ie = 'internet explorer';
}

/// Browser operating system constants.
class BrowserPlatform {
  static const String android = 'android';
  static const String windows = 'windows';
  static const String mac = 'mac';
  static const String linux = 'linux';
}
