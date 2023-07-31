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

@TestOn('vm')
library webdriver.spec_inference_test;

import 'package:test/test.dart';
import 'package:webdriver/sync_core.dart';

import '../configs/sync_io_config.dart' as config;

void main() {
  group('Spec inference', () {
    late WebDriver driver;

    test('chrome works', () async {
      driver = config.createTestDriver(spec: WebDriverSpec.W3c);
      await config.createTestServerAndGoToTestPage(driver);
      final button = driver.findElement(const By.tagName('button'));
      try {
        button.findElement(const By.tagName('tr'));
        throw 'Expected NoSuchElementException';
      } catch (e) {
        expect(e, const TypeMatcher<NoSuchElementException>());
        expect(e.toString(), contains('Unable to locate element'));
      }
    }, tags: ['ff']);

    test('firefox work', () async {
      driver = config.createTestDriver(spec: WebDriverSpec.JsonWire);
      await config.createTestServerAndGoToTestPage(driver);
      final button = driver.findElement(const By.tagName('button'));
      try {
        button.findElement(const By.tagName('tr'));
        throw 'Expected W3cWebDriverException';
      } catch (e) {
        expect(e, const TypeMatcher<NoSuchElementException>());
        expect(e.toString(), contains('Unable to locate element'));
      }
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
