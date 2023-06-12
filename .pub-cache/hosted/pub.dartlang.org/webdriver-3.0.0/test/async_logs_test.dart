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
library webdriver.logs_test;

import 'package:test/test.dart';
import 'package:webdriver/async_core.dart';

import 'configs/async_io_config.dart' as config;

void main() {
  group('Logs', () {
    late WebDriver driver;

    setUp(() async {
      var capabilities = <String, dynamic>{
        // ignore: deprecated_member_use_from_same_package
        Capabilities.loggingPrefs: {LogType.performance: LogLevel.info}
      };

      driver =
          await config.createTestDriver(additionalCapabilities: capabilities);
      await config.createTestServerAndGoToTestPage(driver);
    });

    test('get logs', () async {
      var logs = await driver.logs.get(LogType.performance).toList();
      if (driver.capabilities['browserName'] == 'firefox') {
        expect(logs, isEmpty);
        return;
      }

      expect(logs, isNotEmpty);
      logs.forEach((entry) {
        expect(entry.level, equals(LogLevel.info));
      });
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
