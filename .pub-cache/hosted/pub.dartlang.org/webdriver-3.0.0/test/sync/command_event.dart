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
import 'package:webdriver/sync_core.dart';

import '../configs/sync_io_config.dart' as config;

void runTests({WebDriverSpec spec = WebDriverSpec.Auto}) {
  group('CommandEvent', () {
    late WebDriver driver;

    var events = <WebDriverCommandEvent>[];

    setUp(() async {
      driver = config.createTestDriver(spec: spec);
      driver.addEventListener(events.add);

      await config.createTestServerAndGoToTestPage(driver);
    });

    tearDown(() async {
      events.clear();
    });

    test('handles exceptions', () {
      try {
        driver.switchTo.alert.text;
        fail('Expected exception on no alert');
      } on NoSuchAlertException {
        // noop
      }
      // TODO(b/140553567): There should be two events.
      expect(events, hasLength(1));
      expect(events[0].method, 'GET');
      expect(events[0].endPoint, contains('alert'));
      expect(events[0].exception, const TypeMatcher<WebDriverException>());
      expect(events[0].result, isNull);
      expect(events[0].startTime!.isBefore(events[0].endTime!), isTrue);
      expect(events[0].stackTrace, const TypeMatcher<Chain>());
    });

    test('handles normal operation', () {
      driver.findElements(const By.cssSelector('nosuchelement')).toList();
      // TODO(b/140553567): There should be two events.
      expect(events, hasLength(1));
      expect(events[0].method, 'POST');
      expect(events[0].endPoint, contains('elements'));
      expect(events[0].exception, isNull);
      expect(events[0].result, isNotNull);
      expect(events[0].startTime!.isBefore(events[0].endTime!), isTrue);
      expect(events[0].stackTrace, const TypeMatcher<Chain>());
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
