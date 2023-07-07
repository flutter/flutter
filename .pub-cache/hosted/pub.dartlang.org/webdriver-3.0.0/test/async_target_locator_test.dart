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
library webdriver.target_locator_test;

import 'package:test/test.dart';
import 'package:webdriver/async_core.dart';

import 'configs/async_io_config.dart' as config;

/// Tests for switchTo.frame(). switchTo.window() and switchTo.alert are tested
/// in other classes.
void main() {
  group('TargetLocator', () {
    late WebDriver driver;
    late WebElement frame;

    setUp(() async {
      driver = await config.createTestDriver();
      await config.createTestServerAndGoToTestPage(driver);
      frame = await driver.findElement(const By.id('frame'));
    });

    test('frame index', () async {
      await driver.switchTo.frame(0);
      expect(await driver.pageSource, contains('this is a frame'));
    });

    test('frame id', () async {
      await driver.switchTo.frame('frame');
      expect(await driver.pageSource, contains('this is a frame'));
    });

    test('frame element', () async {
      await driver.switchTo.frame(frame);
      expect(await driver.pageSource, contains('this is a frame'));
    });

    test('root frame', () async {
      await driver.switchTo.frame(frame);
      await driver.switchTo.frame();
      await driver.findElement(const By.tagName('button'));
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
