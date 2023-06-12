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
import 'package:webdriver/sync_core.dart';

import '../configs/sync_io_config.dart' as config;

void runTests({WebDriverSpec spec = WebDriverSpec.Auto}) {
  group('Alert', () {
    late WebDriver driver;
    late WebElement button;
    late WebElement output;

    setUp(() async {
      driver = config.createTestDriver(spec: spec);
      await config.createTestServerAndGoToTestPage(driver);

      button = driver.findElement(const By.tagName('button'));
      output = driver.findElement(const By.id('settable'));
    });

    test('no alert', () {
      try {
        driver.switchTo.alert.text;
        fail('Expected exception on no alert');
      } catch (e) {
        expect(e, const TypeMatcher<NoSuchAlertException>());
      }
    });

    test('text', () {
      button.click();
      var alert = driver.switchTo.alert;
      expect(alert.text, 'button clicked');
      alert.dismiss();
    });

    test('accept', () {
      button.click();
      var alert = driver.switchTo.alert;
      alert.accept();
      expect(output.text, startsWith('accepted'));
    });

    test('dismiss', () {
      button.click();
      var alert = driver.switchTo.alert;
      alert.dismiss();
      expect(output.text, startsWith('dismissed'));
    });

    test('sendKeys', () {
      button.click();
      var alert = driver.switchTo.alert;
      alert.sendKeys('some keys');
      alert.accept();
      expect(output.text, endsWith('some keys'));
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
