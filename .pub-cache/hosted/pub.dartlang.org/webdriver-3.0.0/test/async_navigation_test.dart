// Copyright 2015 Google Inc. All Rights Reserved.
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

@TestOn('vm')
library webdriver.navigation_test;

import 'package:test/test.dart';
import 'package:webdriver/async_core.dart';
import 'package:webdriver/support/async.dart';

import 'configs/async_io_config.dart' as config;

void main() {
  group('Navigation', () {
    late WebDriver driver;

    setUp(() async {
      driver = await config.createTestDriver();
      await config.createTestServerAndGoToTestPage(driver);
    });

    test('refresh', () async {
      var element = await driver.findElement(const By.tagName('button'));
      await driver.refresh();
      await waitFor(() async {
        try {
          await element.name;
        } on StaleElementReferenceException {
          return true;
        }
        return 'expected StaleElementReferenceException';
      });
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
