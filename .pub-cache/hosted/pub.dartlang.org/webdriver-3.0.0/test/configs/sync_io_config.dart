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
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:webdriver/sync_core.dart'
    show WebDriver, WebDriverSpec, WebElement;
import 'package:webdriver/sync_io.dart' show createDriver;

import 'common_config.dart';

export 'common_config.dart';

final Matcher isWebElement = const TypeMatcher<WebElement>();

WebDriver createTestDriver({
  Map<String, dynamic>? additionalCapabilities,
  WebDriverSpec spec = defaultSpec,
}) {
  final capabilities = getCapabilities(spec);
  if (additionalCapabilities != null) {
    capabilities.addAll(additionalCapabilities);
  }

  final driver = createDriver(
    desired: capabilities,
    uri: getWebDriverUri(spec),
    spec: spec,
  );

  addTearDown(driver.quit);

  return driver;
}

Future<void> createTestServerAndGoToTestPage(WebDriver driver) async {
  final server = await createLocalServer();
  server.listen((request) {
    if (request.method == 'GET' && request.uri.path.endsWith('.html')) {
      var testPagePath = '$testHomePath${request.uri.path}';
      var file = File(testPagePath);
      if (file.existsSync()) {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.set('Content-type', 'text/html');
        file.openRead().cast<List<int>>().pipe(request.response);
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
      }
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..close();
    }
  });

  // TODO(b/140553567): Use sync driver when we have a separate server.
  await driver.asyncDriver.get(
    'http://$testHostname:${server.port}/test_page.html',
  );

  addTearDown(() async {
    await server.close(force: true);
  });
}

Uri get testPagePath => path.toUri(path.join(testHomePath, 'test_page.html'));
