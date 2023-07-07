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
library webdriver.alert_test;

import 'package:test/test.dart';
import 'package:webdriver/async_core.dart';

import 'configs/async_io_config.dart' as config;

void main() {
  group('Alert', () {
    late WebDriver driver;
    late WebElement button;
    late WebElement output;

    setUp(() async {
      driver = await config.createTestDriver();
      await config.createTestServerAndGoToTestPage(driver);

      button = await driver.findElement(const By.tagName('button'));
      output = await driver.findElement(const By.id('settable'));
    });

    test('no alert', () async {
      try {
        await driver.switchTo.alert.text;
        fail('Expected exception on no alert');
      } catch (e) {
        expect(e, const TypeMatcher<NoSuchAlertException>());
      }
    });

    test('text', () async {
      await button.click();
      var alert = driver.switchTo.alert;
      expect(await alert.text, 'button clicked');
      await alert.dismiss();
    });

    test('accept', () async {
      await button.click();
      var alert = driver.switchTo.alert;
      await alert.accept();
      expect(await output.text, startsWith('accepted'));
    });

    test('dismiss', () async {
      await button.click();
      var alert = driver.switchTo.alert;
      await alert.dismiss();
      expect(await output.text, startsWith('dismissed'));
    });

    test('sendKeys', () async {
      await button.click();
      var alert = driver.switchTo.alert;
      await alert.sendKeys('some keys');
      await alert.accept();
      expect(await output.text, endsWith('some keys'));
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
