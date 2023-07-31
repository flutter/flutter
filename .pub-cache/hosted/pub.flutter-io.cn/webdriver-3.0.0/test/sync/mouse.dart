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

import 'package:test/test.dart';
import 'package:webdriver/sync_core.dart';

import '../configs/sync_io_config.dart' as config;

void runTests({WebDriverSpec spec = WebDriverSpec.Auto}) {
  group('Mouse', () {
    late WebDriver driver;
    late WebElement button;

    bool hasAlert() {
      try {
        driver.switchTo.alert.dismiss();
        return true;
      } on NoSuchAlertException {
        return false;
      }
    }

    bool mouseOnButton() {
      driver.mouse.click();
      return hasAlert();
    }

    setUp(() async {
      driver = config.createTestDriver(spec: spec);
      await config.createTestServerAndGoToTestPage(driver);
      button = driver.findElement(const By.tagName('button'));
    });

    test('moveTo element/click', () {
      driver.mouse.moveTo(element: button);
      expect(mouseOnButton(), true);
    });

    test('moveTo coordinates/click', () {
      var pos = button.location;
      driver.mouse.moveTo(xOffset: pos.x + 5, yOffset: pos.y + 5);
      expect(mouseOnButton(), true);
    });

    test('moveTo absolute coordinates/click', () {
      if (driver.spec == WebDriverSpec.W3c) {
        var pos = button.location;
        driver.mouse.moveTo(xOffset: pos.x + 200, yOffset: pos.y + 200);
        expect(mouseOnButton(), false);
        driver.mouse
            .moveTo(xOffset: pos.x + 5, yOffset: pos.y + 5, absolute: true);
        expect(mouseOnButton(), true);
      }
    });

    test('moveTo out of bounds', () {
      if (driver.spec == WebDriverSpec.W3c) {
        try {
          driver.mouse.moveTo(xOffset: -10000, yOffset: -10000);
          throw 'Expected MoveTargetOutOfBoundsException';
        } catch (e) {
          expect(e, const TypeMatcher<MoveTargetOutOfBoundsException>());
        }
      }
    });

    test('moveTo element coordinates/click', () {
      driver.mouse.moveTo(element: button, xOffset: 15, yOffset: 15);
      // W3C uses center and JsonWire uses top left corner.
      expect(mouseOnButton(), driver.spec == WebDriverSpec.JsonWire);
    });

    test('moveTo element coordinates outside of element/click', () {
      driver.mouse.moveTo(element: button, xOffset: -5, yOffset: -5);
      // W3C uses center and JsonWire uses top left corner.
      expect(mouseOnButton(), driver.spec == WebDriverSpec.W3c);
    });

    test('moveToElementCenter moves to correct positions', () {
      driver.mouse.moveToElementCenter(button, xOffset: -5, yOffset: -5);
      expect(mouseOnButton(), true);
      driver.mouse.moveToElementCenter(button, xOffset: 15, yOffset: 15);
      expect(mouseOnButton(), false);
    });

    test('moveToElementTopLeft moves to correct positions', () {
      driver.mouse.moveToElementTopLeft(button, xOffset: -5, yOffset: -5);
      expect(mouseOnButton(), false);
      driver.mouse.moveToElementTopLeft(button, xOffset: 15, yOffset: 15);
      expect(mouseOnButton(), true);
    });

    test('hide moves away from the current location', () {
      driver.mouse.moveTo(element: button);
      expect(mouseOnButton(), true);
      driver.mouse.hide();
      expect(mouseOnButton(), false);
    });

    test('hide moves to given location in w3c.', () {
      if (driver.spec == WebDriverSpec.W3c) {
        var pos = button.location;
        driver.mouse.moveTo(element: button);
        expect(mouseOnButton(), true);
        driver.mouse.moveTo(xOffset: 0, yOffset: 0, absolute: true);
        expect(mouseOnButton(), false);
        driver.mouse.hide(w3cXOffset: pos.x + 5, w3cYOffset: pos.y + 5);
        expect(mouseOnButton(), true);
      }
    });

    // TODO(DrMarcII): Better up/down tests
    test('down/up', () {
      driver.mouse.moveTo(element: button);
      driver.mouse.down();
      driver.mouse.up();
      var alert = driver.switchTo.alert;
      alert.dismiss();
    });

    // TODO(DrMarcII): Better double click test
    test('doubleClick', () {
      driver.mouse.moveTo(element: button);
      driver.mouse.doubleClick();
      var alert = driver.switchTo.alert;
      alert.dismiss();
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
