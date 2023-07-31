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

import 'dart:async';
import 'dart:io' show HttpServer, InternetAddress, Platform;
import 'dart:math' show Point, Rectangle;

import 'package:matcher/matcher.dart' show Matcher, TypeMatcher;
import 'package:path/path.dart' as path;
import 'package:webdriver/async_core.dart';

final Uri _defaultChromeUri = Uri.parse('http://127.0.0.1:4444/wd/hub/');
final Uri _defaultFirefoxUri = Uri.parse('http://127.0.0.1:4445/');

const WebDriverSpec defaultSpec = WebDriverSpec.JsonWire;

final Matcher isRectangle = const TypeMatcher<Rectangle<int>>();
final Matcher isPoint = const TypeMatcher<Point<int>>();

Future<HttpServer> createLocalServer() =>
    HttpServer.bind(InternetAddress.anyIPv4, 0);

String get testHostname => '127.0.0.1';

String get testHomePath => path.absolute('test');

Uri? getWebDriverUri(WebDriverSpec spec) {
  switch (spec) {
    case WebDriverSpec.W3c:
      return _defaultFirefoxUri;
    case WebDriverSpec.JsonWire:
      return _defaultChromeUri;
    default:
      return null;
  }
}

Map<String, dynamic> getCapabilities(WebDriverSpec spec) {
  switch (spec) {
    case WebDriverSpec.W3c:
      return Capabilities.firefox;
    case WebDriverSpec.JsonWire:
      var capabilities = Capabilities.chrome;
      Map env = Platform.environment;

      var chromeOptions = {};

      if (env['CHROMEDRIVER_BINARY'] != null) {
        chromeOptions['binary'] = env['CHROMEDRIVER_BINARY'];
      }

      if (env['CHROMEDRIVER_ARGS'] != null) {
        chromeOptions['args'] = env['CHROMEDRIVER_ARGS'].split(' ');
      }

      if (chromeOptions.isNotEmpty) {
        capabilities[Capabilities.chromeOptions] = chromeOptions;
      }
      return capabilities;
    default:
      return <String, dynamic>{};
  }
}
