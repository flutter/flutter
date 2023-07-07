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
library webdriver.options_test;

import 'package:test/test.dart';
import 'package:webdriver/sync_core.dart';

import '../configs/sync_io_config.dart' as config;

final _expiryDate = DateTime.now().add(const Duration(days: 180));

void runTests({WebDriverSpec spec = WebDriverSpec.Auto}) {
  group('Cookies', () {
    late WebDriver driver;

    setUp(() {
      driver = config.createTestDriver(spec: spec);
      driver.get('http://www.google.com/ncr');
    });

    test('add simple cookie and get', () {
      driver.cookies.add(Cookie('mycookie', 'myvalue'));

      final cookie = driver.cookies.getCookie('mycookie');
      expect(cookie.value, 'myvalue');
    });

    test('add complex cookie and get', () {
      driver.cookies.add(Cookie('mycookie', 'myvalue',
          path: '/',
          domain: '.google.com',
          secure: false,
          expiry: _expiryDate));

      final cookie = driver.cookies.getCookie('mycookie');
      expect(cookie.value, 'myvalue');
      expect(cookie.domain, '.google.com');
    });

    test('get all cookies', () {
      driver.cookies.add(Cookie('mycookie', 'myvalue'));
      driver.cookies.add(Cookie('mycomplexcookie', 'mycomplexvalue',
          path: '/',
          domain: '.google.com',
          secure: false,
          expiry: _expiryDate));

      var found = false;
      for (var cookie in driver.cookies.all) {
        if (cookie.name == 'mycookie') {
          found = true;
          expect(cookie.value, 'myvalue');
          break;
        }
      }
      expect(found, isTrue);

      found = false;
      for (var cookie in driver.cookies.all) {
        if (cookie.name == 'mycomplexcookie') {
          found = true;
          expect(cookie.value, 'mycomplexvalue');
          expect(cookie.domain, '.google.com');
          break;
        }
      }

      expect(found, isTrue);
    });

    test('delete cookie', () {
      driver.cookies.add(Cookie('mycookie', 'myvalue'));
      driver.cookies.delete('mycookie');
      var found = false;
      for (var cookie in driver.cookies.all) {
        if (cookie.name == 'mycookie') {
          found = true;
          break;
        }
      }
      expect(found, isFalse);
    });

    test('delete all cookies', () {
      // Testing for empty cookies will make the test unreliable as cookies will
      // "come back" after a short amount of time.
      // So instead, we plant two cookies and test that they are actually
      // removed by [deleteAll].
      driver.cookies.add(Cookie('mycookie', 'myvalue'));
      driver.cookies.add(Cookie('mycomplexcookie', 'mycomplexvalue',
          path: '/',
          domain: '.google.com',
          secure: false,
          expiry: _expiryDate));

      driver.cookies.deleteAll();

      var found = false;
      for (final cookie in driver.cookies.all) {
        if (cookie.name == 'mycookie' || cookie.name == 'mycomplexcookie') {
          found = true;
          break;
        }
      }

      expect(found, isFalse);
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
