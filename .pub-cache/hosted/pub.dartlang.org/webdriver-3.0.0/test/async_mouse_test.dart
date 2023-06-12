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
library webdriver.mouse_test;

import 'dart:async';

import 'package:test/test.dart';
import 'package:webdriver/async_core.dart';

import 'configs/async_io_config.dart' as config;

void main() {
  group('Mouse', () {
    late WebDriver driver;
    late WebElement button;

    Future<bool> hasAlert() async {
      try {
        await driver.switchTo.alert.dismiss();
        return true;
      } on NoSuchAlertException {
        return false;
      }
    }

    Future<bool> mouseOnButton() async {
      await driver.mouse.click();
      return await hasAlert();
    }

    setUp(() async {
      driver = await config.createTestDriver();
      await config.createTestServerAndGoToTestPage(driver);

      button = await driver.findElement(const By.tagName('button'));
    });

    test('moveTo element/click', () async {
      await driver.mouse.moveTo(element: button);
      expect(await mouseOnButton(), true);
    });

    test('moveTo coordinates/click', () async {
      var pos = await button.location;
      await driver.mouse.moveTo(xOffset: pos.x + 5, yOffset: pos.y + 5);
      expect(await mouseOnButton(), true);
    });

    test('moveTo element coordinates/click', () async {
      await driver.mouse.moveTo(element: button, xOffset: 15, yOffset: 15);
      // W3C uses center and JsonWire uses top left corner.
      expect(await mouseOnButton(), driver.spec == WebDriverSpec.JsonWire);
    });

    test('moveTo element coordinates outside of element/click', () async {
      await driver.mouse.moveTo(element: button, xOffset: -5, yOffset: -5);
      // W3C uses center and JsonWire uses top left corner.
      expect(await mouseOnButton(), driver.spec == WebDriverSpec.W3c);
    });

    test('moveToElementCenter moves to correct positions', () async {
      await driver.mouse.moveToElementCenter(button, xOffset: -5, yOffset: -5);
      expect(await mouseOnButton(), true);
      await driver.mouse.moveToElementCenter(button, xOffset: 15, yOffset: 15);
      expect(await mouseOnButton(), false);
    });

    test('moveToElementTopLeft moves to correct positions', () async {
      await driver.mouse.moveToElementTopLeft(button, xOffset: -5, yOffset: -5);
      expect(await mouseOnButton(), false);
      await driver.mouse.moveToElementTopLeft(button, xOffset: 15, yOffset: 15);
      expect(await mouseOnButton(), true);
    });

    test('hide moves away from the current location', () async {
      await driver.mouse.moveTo(element: button);
      expect(await mouseOnButton(), true);
      await driver.mouse.hide();
      expect(await mouseOnButton(), false);
    });

    test('hide moves to given location in w3c.', () async {
      if (driver.spec == WebDriverSpec.W3c) {
        var pos = await button.location;
        await driver.mouse.moveTo(element: button);
        expect(await mouseOnButton(), true);
        await driver.mouse.moveTo(xOffset: 0, yOffset: 0, absolute: true);
        expect(await mouseOnButton(), false);
        await driver.mouse.hide(w3cXOffset: pos.x + 5, w3cYOffset: pos.y + 5);
        expect(await mouseOnButton(), true);
      }
    });

    // TODO(DrMarcII): Better up/down tests
    test('down/up', () async {
      await driver.mouse.moveTo(element: button);
      await driver.mouse.down();
      await driver.mouse.up();
      expect(await hasAlert(), true);
    });

    // TODO(DrMarcII): Better double click test
    test('doubleClick', () async {
      await driver.mouse.moveTo(element: button);
      await driver.mouse.doubleClick();
      expect(await hasAlert(), true);
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
