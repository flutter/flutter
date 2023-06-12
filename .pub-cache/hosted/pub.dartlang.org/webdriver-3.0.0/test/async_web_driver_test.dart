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
library webdriver.web_driver_test;

import 'dart:async';

import 'package:test/test.dart';
import 'package:webdriver/core.dart';

import 'configs/async_io_config.dart' as config;

void main() {
  group('WebDriver', () {
    group('create', () {
      test('default', () async {
        var driver = await config.createTestDriver();
        await config.createTestServerAndGoToTestPage(driver);
        var element = await driver.findElement(const By.tagName('button'));
        expect(await element.name, 'button');
      });
    });

    group('methods', () {
      late WebDriver driver;

      setUp(() async {
        driver = await config.createTestDriver();
        await config.createTestServerAndGoToTestPage(driver);
      });

      test('get', () async {
        await driver.findElement(const By.tagName('button'));
      });

      test('currentUrl', () async {
        var url = await driver.currentUrl;
        expect(url, anyOf(startsWith('file:'), startsWith('http:')));
        expect(url, endsWith('test_page.html'));
      });

      test('findElement -- success', () async {
        var element = await driver.findElement(const By.tagName('tr'));
        expect(element, config.isWebElement);
      });

      test('findElement -- failure', () async {
        try {
          await driver.findElement(const By.id('non-existent-id'));
          throw 'expected NoSuchElementException';
        } on NoSuchElementException {
          // noop
        }
      });

      test('findElements -- 1 found', () async {
        var elements = await driver
            .findElements(const By.cssSelector('input[type=text]'))
            .toList();
        expect(elements, hasLength(1));
        expect(elements, everyElement(config.isWebElement));
      });

      test('findElements -- 4 found', () async {
        var elements =
            await driver.findElements(const By.tagName('td')).toList();
        expect(elements, hasLength(4));
        expect(elements, everyElement(config.isWebElement));
      });

      test('findElements -- 0 found', () async {
        var elements =
            await driver.findElements(const By.id('non-existent-id')).toList();
        expect(elements, isEmpty);
      });

      test('pageSource', () async {
        expect(await driver.pageSource, contains('<title>test_page</title>'));
      });

      test('close/windows', () async {
        var numHandles = (await driver.windows.toList()).length;
        await (await driver.findElement(const By.partialLinkText('Open copy')))
            .click();
        expect(await driver.windows.toList(), hasLength(numHandles + 1));
        await (await driver.window).close();
        expect(await driver.windows.toList(), hasLength(numHandles));
      });

      test('window', () async {
        var orig = await driver.window;
        Window? next;

        await (await driver.findElement(const By.partialLinkText('Open copy')))
            .click();
        await for (Window window in driver.windows) {
          if (window != orig) {
            next = window;
            await driver.switchTo.window(window);
            break;
          }
        }
        expect(await driver.window, equals(next));
        await (await driver.window).close();
      });

      test('activeElement', () async {
        var element = (await driver.activeElement)!;
        expect(await element.name, 'body');
        await (await driver
                .findElement(const By.cssSelector('input[type=text]')))
            .click();
        element = (await driver.activeElement)!;
        expect(await element.name, 'input');
      });

      test('windows', () async {
        var windows = await driver.windows.toList();
        expect(windows, hasLength(isPositive));
        expect(windows, everyElement(isA<Window>()));
      });

      test('execute', () async {
        var button = await driver.findElement(const By.tagName('button'));
        var script = '''
            arguments[1].textContent = arguments[0];
            return arguments[1];''';
        var e = await driver.execute(script, ['new text', button]);
        expect(await e.text, 'new text');
      });

      test('executeAsync', () async {
        var button = await driver.findElement(const By.tagName('button'));
        var script = '''
            arguments[1].textContent = arguments[0];
            arguments[2](arguments[1]);''';
        var e = await driver.executeAsync(script, ['new text', button]);
        expect(await e.text, 'new text');
      });

      test('captureScreenshot', () async {
        // ignore: deprecated_member_use_from_same_package
        var screenshot = await driver.captureScreenshot().toList();
        expect(screenshot, hasLength(isPositive));
        expect(screenshot, everyElement(isA<int>()));
      });

      test('captureScreenshotAsList', () async {
        var screenshot = await driver.captureScreenshotAsList();
        expect(screenshot, hasLength(isPositive));
        expect(screenshot, everyElement(const TypeMatcher<int>()));
      });

      test('captureElementScreenshotAsList', () async {
        var element = await driver.findElement(const By.tagName('tr'));
        var screenshot = await driver.captureElementScreenshotAsList(element);
        expect(screenshot, hasLength(isPositive));
        expect(screenshot, everyElement(const TypeMatcher<int>()));
      });

      test('captureScreenshotAsBase64', () async {
        var screenshot = await driver.captureScreenshotAsBase64();
        expect(screenshot, hasLength(isPositive));
        expect(screenshot, const TypeMatcher<String>());
      });

      test('captureElementScreenshotAsBase64', () async {
        var element = await driver.findElement(const By.tagName('tr'));
        var screenshot = await driver.captureElementScreenshotAsBase64(element);
        expect(screenshot, hasLength(isPositive));
        expect(screenshot, const TypeMatcher<String>());
      });

      test('future based event listeners work with script timeouts', () async {
        driver.addEventListener((WebDriverCommandEvent e) async =>
            await Future.delayed(const Duration(milliseconds: 1000), (() {})));

        try {
          await driver.timeouts.setScriptTimeout(const Duration(seconds: 1));
          await driver.executeAsync('', []);
          fail('Did not throw timeout as expected');
        } catch (e) {
          expect(e, const TypeMatcher<ScriptTimeoutException>());
        }
      });

      test('future based event listeners ordered appropriately', () async {
        var eventList = <int>[];
        var millisDelay = 2000;
        var current = 0;
        driver.addEventListener((WebDriverCommandEvent e) async =>
            await Future.delayed(Duration(milliseconds: millisDelay), (() {
              eventList.add(current++);
              millisDelay = (millisDelay / 2).round();
            })));

        for (var i = 0; i < 10; i++) {
          await driver.title; // GET request.
        }
        expect(eventList, hasLength(10));
        for (var i = 0; i < 10; i++) {
          expect(eventList[i], i);
        }
      });
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
