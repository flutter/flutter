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
library webdriver.web_element_test;

import 'package:test/test.dart';
import 'package:webdriver/async_core.dart';

import 'configs/async_io_config.dart' as config;

void main() {
  group('WebElement', () {
    late WebDriver driver;
    late WebElement table;
    late WebElement button;
    late WebElement form;
    late WebElement formSubmit;
    late WebElement textInput;
    late WebElement checkbox;
    late WebElement disabled;
    late WebElement invisible;
    late WebElement inner;

    setUp(() async {
      driver = await config.createTestDriver();
      await config.createTestServerAndGoToTestPage(driver);
      table = await driver.findElement(const By.tagName('table'));
      button = await driver.findElement(const By.tagName('button'));
      form = await driver.findElement(const By.tagName('form'));
      formSubmit =
          await form.findElement(const By.cssSelector('input[type=submit]'));
      textInput =
          await driver.findElement(const By.cssSelector('input[type=text]'));
      checkbox = await driver
          .findElement(const By.cssSelector('input[type=checkbox]'));
      disabled = await driver
          .findElement(const By.cssSelector('input[type=password]'));
      invisible = await driver.findElement(const By.id('invisible-div'));
      inner = await driver.findElement(const By.id('inner-div'));
    });

    test('click', () async {
      await button.click();
      var alert = driver.switchTo.alert;
      await alert.accept();
    });

    test('submit', () async {
      await formSubmit.click();
      var alert = driver.switchTo.alert;
      expect(await alert.text, 'form submitted');
      await alert.accept();
    });

    test('sendKeys', () async {
      await textInput.sendKeys('some keys');
      expect(await textInput.properties['value'], 'some keys');
    });

    test('clear', () async {
      await textInput.sendKeys('some keys');
      await textInput.clear();
      expect(await textInput.properties['value'], '');
    });

    test('enabled', () async {
      expect(await table.enabled, isTrue);
      expect(await button.enabled, isTrue);
      expect(await form.enabled, isTrue);
      expect(await textInput.enabled, isTrue);
      expect(await checkbox.enabled, isTrue);
      expect(await disabled.enabled, isFalse);
    });

    test('displayed', () async {
      expect(await table.displayed, isTrue);
      expect(await button.displayed, isTrue);
      expect(await form.displayed, isTrue);
      expect(await textInput.displayed, isTrue);
      expect(await checkbox.displayed, isTrue);
      expect(await disabled.displayed, isTrue);
      expect(await invisible.displayed, isFalse);
      expect(await inner.displayed, isFalse);
    });

    test('location -- table', () async {
      var location = await table.location;
      expect(location, config.isPoint);
      expect(location.x, isNonNegative);
      expect(location.y, isNonNegative);
    });

    test('location -- invisible', () async {
      var location = await invisible.location;
      expect(location, config.isPoint);
      expect(location.x, 0);
      expect(location.y, 0);
    });

    test('size -- table', () async {
      var size = await table.size;
      expect(size, config.isRectangle);
      expect(size.width, isNonNegative);
      expect(size.height, isNonNegative);
    });

    test('size -- invisible', () async {
      var size = await invisible.size;
      expect(size, config.isRectangle);
      expect(size.width, isNonNegative);
      expect(size.height, isNonNegative);
    });

    test('name', () async {
      expect(await table.name, 'table');
      expect(await button.name, 'button');
      expect(await form.name, 'form');
      expect(await textInput.name, 'input');
    });

    test('text', () async {
      expect(await table.text, 'r1c1 r1c2\nr2c1 r2c2');
      expect(await button.text, 'button');
      expect(await invisible.text, '');
    });

    test('findElement -- success', () async {
      var element = await table.findElement(const By.tagName('tr'));
      expect(element, config.isWebElement);
    });

    test('findElement -- failure', () async {
      try {
        await button.findElement(const By.tagName('tr'));
        throw 'Expected NoSuchElementException';
      } on NoSuchElementException {
        // noop
      }
    });

    test('findElements -- 1 found', () async {
      var elements = await form
          .findElements(const By.cssSelector('input[type=text]'))
          .toList();
      expect(elements, hasLength(1));
      expect(elements, everyElement(config.isWebElement));
    });

    test('findElements -- 4 found', () async {
      var elements = await table.findElements(const By.tagName('td')).toList();
      expect(elements, hasLength(4));
      expect(elements, everyElement(config.isWebElement));
    });

    test('findElements -- 0 found', () async {
      var elements = await form.findElements(const By.tagName('td')).toList();
      expect(elements, isEmpty);
    });

    test('attributes', () async {
      expect(await table.attributes['id'], 'table1');
      expect(await table.attributes['non-standard'], 'a non standard attr');
      expect(await table.attributes['disabled'], isNull);
      expect(await disabled.attributes['disabled'], isNotNull);
    });

    test('cssProperties', () async {
      expect(await invisible.cssProperties['display'], 'none');
      final backgroundColor = await invisible.cssProperties['background-color'];
      expect(backgroundColor, contains('255, 0, 0'));
      expect(backgroundColor, startsWith('rgb'));
      expect(await invisible.cssProperties['direction'], 'ltr');
    });

    test('equals', () async {
      expect(await invisible.equals(disabled), isFalse);
      var element = await driver.findElement(const By.cssSelector('table'));
      expect(await element.equals(table), isTrue);
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
