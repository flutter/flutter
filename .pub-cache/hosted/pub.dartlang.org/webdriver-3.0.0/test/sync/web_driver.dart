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

import 'dart:io';

import 'package:test/test.dart';
import 'package:webdriver/sync_core.dart';

import '../configs/sync_io_config.dart' as config;

void runTests({WebDriverSpec spec = WebDriverSpec.Auto}) {
  group('WebDriver', () {
    group('create', () {
      test('default', () async {
        var driver = config.createTestDriver(spec: spec);
        await config.createTestServerAndGoToTestPage(driver);
        var element = driver.findElement(const By.tagName('button'));
        expect(element.name, 'button');
      });
    });

    group('methods', () {
      late WebDriver driver;

      setUp(() async {
        driver = config.createTestDriver(spec: spec);
        await config.createTestServerAndGoToTestPage(driver);
      });

      test('get', () {
        driver.findElement(const By.tagName('button'));
      });

      test('currentUrl', () {
        var url = driver.currentUrl;
        expect(url, startsWith('http:'));

        expect(url, endsWith('test_page.html'));
      });

      test('findElement -- success', () {
        var element = driver.findElement(const By.tagName('tr'));
        expect(element, config.isWebElement);
      });

      test('findElement -- failure', () {
        try {
          driver.findElement(const By.id('non-existent-id'));
          throw 'expected exception';
        } catch (e) {
          expect(e, const TypeMatcher<NoSuchElementException>());
        }
      });

      test('findElements -- 1 found', () {
        var elements = driver
            .findElements(const By.cssSelector('input[type=text]'))
            .toList();
        expect(elements, hasLength(1));
        expect(elements, everyElement(config.isWebElement));
      });

      test('findElements -- 4 found', () {
        var elements = driver.findElements(const By.tagName('td')).toList();
        expect(elements, hasLength(4));
        expect(elements, everyElement(config.isWebElement));
      });

      test('findElements -- 0 found', () {
        var elements =
            driver.findElements(const By.id('non-existent-id')).toList();
        expect(elements, isEmpty);
      });

      test('title', () {
        expect(driver.title, 'test_page');
      });

      test('pageSource', () {
        expect(driver.pageSource, contains('<title>test_page</title>'));
      });

      test('close/windows', () {
        var numHandles = (driver.windows.toList()).length;
        (driver.findElement(const By.partialLinkText('Open copy'))).click();
        sleep(const Duration(milliseconds: 500)); // Bit slow on Firefox.
        expect(driver.windows.toList(), hasLength(numHandles + 1));
        driver.window.close();
        expect(driver.windows.toList(), hasLength(numHandles));
      });

      test('window', () {
        var orig = driver.window;
        Window? next;

        (driver.findElement(const By.partialLinkText('Open copy'))).click();
        sleep(const Duration(milliseconds: 500)); // Bit slow on Firefox.
        for (final window in driver.windows) {
          if (window != orig) {
            next = window;
            window.setAsActive();
            break;
          }
        }
        expect(driver.window, equals(next));
        driver.window.close();
      });

      test('activeElement', () {
        var element = driver.activeElement!;
        expect(element.name, 'body');
        (driver.findElement(const By.cssSelector('input[type=text]'))).click();
        element = driver.activeElement!;
        expect(element.name, 'input');
      });

      test('windows', () {
        var windows = driver.windows.toList();
        expect(windows, hasLength(isPositive));
        expect(windows, everyElement(isA<Window>()));
      });

      test('execute', () {
        var button = driver.findElement(const By.tagName('button'));
        var script = '''
            arguments[1].textContent = arguments[0];
            return arguments[1];''';
        var e = driver.execute(script, ['new text', button]);
        expect(e.text, 'new text');
      });

      test('executeAsync', () {
        var button = driver.findElement(const By.tagName('button'));
        var script = '''
            arguments[1].textContent = arguments[0];
            arguments[2](arguments[1]);''';
        var e = driver.executeAsync(script, ['new text', button]);
        expect(e.text, 'new text');
      });

      test('captureScreenshot', () {
        var screenshot = driver.captureScreenshotAsList().toList();
        expect(screenshot, hasLength(isPositive));
        expect(screenshot, everyElement(isA<int>()));
      });

      test('captureScreenshotAsList', () {
        var screenshot = driver.captureScreenshotAsList();
        expect(screenshot, hasLength(isPositive));
        expect(screenshot, everyElement(isA<int>()));
      });

      test('captureElementScreenshotAsList', () {
        var element = driver.findElement(const By.tagName('tr'));
        var screenshot = driver.captureElementScreenshotAsList(element);
        expect(screenshot, hasLength(isPositive));
        expect(screenshot, everyElement(isA<int>()));
      });

      test('captureScreenshotAsBase64', () {
        var screenshot = driver.captureScreenshotAsBase64();
        expect(screenshot, hasLength(isPositive));
        expect(screenshot, isA<String>());
      });

      test('captureElementScreenshotAsBase64', () {
        var element = driver.findElement(const By.tagName('tr'));
        var screenshot = driver.captureElementScreenshotAsBase64(element);
        expect(screenshot, hasLength(isPositive));
        expect(screenshot, isA<String>());
      });

      test('event listeners work with script timeouts', () {
        try {
          driver.timeouts.setScriptTimeout(const Duration(seconds: 1));
          driver.executeAsync('', []);
          fail('Did not throw timeout as expected');
        } catch (e) {
          expect(e, const TypeMatcher<ScriptTimeoutException>());
        }
      });

      test('event listeners ordered appropriately', () {
        var eventList = <int>[];
        var current = 0;
        driver.addEventListener((e) {
          eventList.add(current++);
        });

        for (var i = 0; i < 10; i++) {
          driver.title; // GET request.
        }
        expect(eventList, hasLength(10));
        for (var i = 0; i < 10; i++) {
          expect(eventList[i], i);
        }
      });
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
