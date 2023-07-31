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

library webdriver.support.async_test;

import 'package:test/test.dart';
import 'package:webdriver/async_core.dart' as async_core;
import 'package:webdriver/sync_io.dart';

import '../configs/async_io_config.dart' as async_config;
import '../configs/sync_io_config.dart' as config;

void runTests({WebDriverSpec spec = WebDriverSpec.Auto}) {
  group('Sync-async interop', () {
    late WebDriver driver;
    async_core.WebDriver asyncDriver;

    setUp(() async {
      driver = config.createTestDriver(spec: spec);

      asyncDriver = driver.asyncDriver;
      expect(asyncDriver, const TypeMatcher<async_core.WebDriver>());
      await async_config.createTestServerAndGoToTestPage(asyncDriver);
    });

    test('sync to async driver works', () async {
      driver.findElement(const By.tagName('button'));
    });

    test('sync to async web element works', () async {
      final button = driver.findElement(const By.tagName('button'));
      final asyncButton = button.asyncElement;

      expect(button, const TypeMatcher<WebElement>());
      expect(asyncButton, const TypeMatcher<async_core.WebElement>());
      expect(asyncButton.id, button.id);
      expect(await asyncButton.name, button.name);
    });

    test('sync to async web element finding works', () async {
      final table = driver.findElement(const By.tagName('table'));
      final asyncTable = table.asyncElement;
      final element = table.findElement(const By.tagName('tr'));
      final asyncElement =
          await asyncTable.findElement(const async_core.By.tagName('tr'));
      expect(element.id, asyncElement.id);
      expect(element.name, await asyncElement.name);
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
