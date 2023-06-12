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
library webdriver.command_event_test;

import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';
import 'package:webdriver/async_core.dart';

import 'configs/async_io_config.dart' as config;

void main() {
  group('CommandEvent', () {
    late WebDriver driver;

    var events = <WebDriverCommandEvent>[];

    setUp(() async {
      driver = await config.createTestDriver();
      driver.addEventListener((e) async {
        events.add(e);
      });

      await config.createTestServerAndGoToTestPage(driver);
    });

    tearDown(() async {
      events.clear();
    });

    test('handles exceptions', () async {
      try {
        await driver.switchTo.alert.text;
      } catch (e) {
        // noop
      }
      expect(events, hasLength(2));
      expect(events[1].method, 'GET');
      expect(events[1].endPoint, contains('alert'));
      expect(events[1].exception, isA<WebDriverException>());
      expect(events[1].result, isNull);
      expect(events[1].startTime!.isBefore(events[1].endTime!), isTrue);
      expect(events[1].stackTrace, isA<Chain>());
    });

    test('handles normal operation', () async {
      await driver.findElements(const By.cssSelector('nosuchelement')).toList();
      expect(events, hasLength(2));
      expect(events[1].method, 'POST');
      expect(events[1].endPoint, contains('elements'));
      expect(events[1].exception, isNull);
      expect(events[1].result, isNotNull);
      expect(events[1].startTime!.isBefore(events[1].endTime!), isTrue);
      expect(events[1].stackTrace, const TypeMatcher<Chain>());
    });
  }, testOn: '!js', timeout: const Timeout(Duration(minutes: 2)));
}
