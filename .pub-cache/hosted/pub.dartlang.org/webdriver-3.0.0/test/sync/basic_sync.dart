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
import 'package:webdriver/sync_io.dart';

import '../configs/sync_io_config.dart' as config;

void runTests({WebDriverSpec spec = WebDriverSpec.Auto}) {
  group('Sync IO', () {
    late WebDriver driver;

    setUp(() {
      driver = config.createTestDriver(spec: spec);
    });

    test('can do basic post', () {
      driver.get(config.testPagePath); // This is POST to WebDriver.
    });

    test('can do basic get', () {
      driver.title; // This is a GET request.
    });

    test('can do basic delete', () {
      driver.cookies.deleteAll(); // This is a DELETE request.
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
