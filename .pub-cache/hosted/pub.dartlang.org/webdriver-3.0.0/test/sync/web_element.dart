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
import 'package:webdriver/sync_core.dart';

import '../configs/sync_io_config.dart' as config;

void runTests({WebDriverSpec spec = WebDriverSpec.Auto}) {
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
      driver = config.createTestDriver(spec: spec);
      await config.createTestServerAndGoToTestPage(driver);

      table = driver.findElement(const By.tagName('table'));
      button = driver.findElement(const By.tagName('button'));
      form = driver.findElement(const By.tagName('form'));
      formSubmit = form.findElement(const By.cssSelector('input[type=submit]'));
      textInput = driver.findElement(const By.cssSelector('input[type=text]'));
      checkbox =
          driver.findElement(const By.cssSelector('input[type=checkbox]'));
      disabled =
          driver.findElement(const By.cssSelector('input[type=password]'));
      invisible = driver.findElement(const By.id('invisible-div'));
      inner = driver.findElement(const By.id('inner-div'));
    });

    test('click', () {
      button.click();
      var alert = driver.switchTo.alert;
      alert.accept();
    });

    test('submit', () {
      formSubmit.click();
      var alert = driver.switchTo.alert;
      expect(alert.text, 'form submitted');
      alert.accept();
    });

    test('sendKeys', () {
      textInput.sendKeys('some keys');
      expect(textInput.properties['value'], 'some keys');
    });

    test('clear', () {
      textInput.sendKeys('some keys');
      textInput.clear();
      expect(textInput.properties['value'], '');
    });

    test('enabled', () {
      expect(table.enabled, isTrue);
      expect(button.enabled, isTrue);
      expect(form.enabled, isTrue);
      expect(textInput.enabled, isTrue);
      expect(checkbox.enabled, isTrue);
      expect(disabled.enabled, isFalse);
    });

    test('displayed', () {
      expect(table.displayed, isTrue);
      expect(button.displayed, isTrue);
      expect(form.displayed, isTrue);
      expect(textInput.displayed, isTrue);
      expect(checkbox.displayed, isTrue);
      expect(disabled.displayed, isTrue);
      expect(invisible.displayed, isFalse);
      expect(inner.displayed, isFalse);
    });

    test('rect -- table', () {
      var rect = table.rect;
      expect(rect, config.isRectangle);
      expect(rect.left, isNonNegative);
      expect(rect.top, isNonNegative);
      expect(rect.width, isNonNegative);
      expect(rect.height, isNonNegative);
    });

    test('rect -- invisible', () {
      var rect = invisible.rect;
      expect(rect, config.isRectangle);
      expect(rect.left, 0);
      expect(rect.top, 0);
      expect(rect.width, isNonNegative);
      expect(rect.height, isNonNegative);
    });

    test('location -- table', () {
      var location = table.location;
      expect(location, config.isPoint);
      expect(location.x, isNonNegative);
      expect(location.y, isNonNegative);
    });

    test('location -- invisible', () {
      var location = invisible.location;
      expect(location, config.isPoint);
      expect(location.x, 0);
      expect(location.y, 0);
    });

    test('size -- table', () {
      var size = table.size;
      expect(size, config.isRectangle);
      expect(size.width, isNonNegative);
      expect(size.height, isNonNegative);
    });

    test('size -- invisible', () {
      var size = invisible.size;
      expect(size, config.isRectangle);
      expect(size.width, isNonNegative);
      expect(size.height, isNonNegative);
    });

    test('name', () {
      expect(table.name, 'table');
      expect(button.name, 'button');
      expect(form.name, 'form');
      expect(textInput.name, 'input');
    });

    test('text', () {
      expect(table.text, 'r1c1 r1c2\nr2c1 r2c2');
      expect(button.text, 'button');
      expect(invisible.text, '');
    });

    test('findElement -- success', () {
      var element = table.findElement(const By.tagName('tr'));
      expect(element, config.isWebElement);
    });

    test('findElement -- failure', () {
      try {
        button.findElement(const By.tagName('tr'));
        throw 'Expected NoSuchElementException';
      } catch (e) {
        expect(e, const TypeMatcher<NoSuchElementException>());
      }
    });

    test('findElements -- 1 found', () {
      var elements =
          form.findElements(const By.cssSelector('input[type=text]')).toList();
      expect(elements, hasLength(1));
      expect(elements, everyElement(config.isWebElement));
    });

    test('findElements -- 4 found', () {
      var elements = table.findElements(const By.tagName('td')).toList();
      expect(elements, hasLength(4));
      expect(elements, everyElement(config.isWebElement));
    });

    test('findElements -- 0 found', () {
      var elements = form.findElements(const By.tagName('td')).toList();
      expect(elements, isEmpty);
    });

    test('attributes', () {
      expect(table.attributes['id'], 'table1');
      expect(table.attributes['non-standard'], 'a non standard attr');
      expect(table.attributes['disabled'], isNull);
      expect(disabled.attributes['disabled'], isNotNull);
    });

    test('cssProperties', () {
      expect(invisible.cssProperties['display'], 'none');
      final backgroundColor = invisible.cssProperties['background-color'];
      expect(backgroundColor, contains('255, 0, 0'));
      expect(backgroundColor, startsWith('rgb'));
      expect(invisible.cssProperties['direction'], 'ltr');
    });

    test('equals', () {
      expect(invisible.equals(disabled), isFalse);
      var element = driver.findElement(const By.cssSelector('table'));
      expect(element.equals(table), isTrue);
    });

    test('toStringDeep()', () {
      expect(
          form.toStringDeep(),
          '<form>\n'
          '\n'
          'HTML:\n'
          '<form onsubmit="alert(&quot;form submitted&quot;)">\n'
          '    <input type="text">\n'
          '    <input type="checkbox">\n'
          '    <input type="password" disabled="">\n'
          '    <input type="submit">\n'
          '</form>');
      expect(
          form
              .findElements(const By.cssSelector('input[type=text]'))
              .first
              .toStringDeep(),
          '<input>\n'
          '\n'
          'HTML:\n'
          '<input type="text">');
    });

    test('parents', () {
      expect(inner.parents, hasLength(4));
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
