// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:html' hide Platform;

import 'package:test/test.dart';
import 'package:universal_io/io.dart';

void testPlatformInBrowser() {
  if (window.navigator.languages!.isNotEmpty) {
    final locale = window.navigator.languages!.first;
    test("Platform.localeName == '$locale'", () {
      expect(Platform.localeName, locale);
    });
  }

  final userAgent = (window.navigator.userAgent ?? '').toLowerCase();
  if (userAgent.contains('mac os x')) {
    test('Platform.isMacOS == true', () {
      expect(Platform.isMacOS, true);
    });
    test('Platform.isWindows == false', () {
      expect(Platform.isWindows, false);
    });
    test('Platform.isLinux == false', () {
      expect(Platform.isLinux, false);
    });
    test('Platform.operatingSystemVersion', () {
      expect(Platform.operatingSystemVersion, isNotEmpty);
    });
  } else if (userAgent.contains('windows')) {
    test('Platform.isMacOS == false', () {
      expect(Platform.isMacOS, false);
    });
    test('Platform.isWindows == true', () {
      expect(Platform.isWindows, true);
    });
    test('Platform.isLinux == false', () {
      expect(Platform.isLinux, false);
    });
    test('Platform.operatingSystemVersion', () {
      expect(Platform.operatingSystemVersion, isNotEmpty);
    });
  } else if (userAgent.contains('linux')) {
    test('Platform.isMacOS == false', () {
      expect(Platform.isMacOS, false);
    });
    test('Platform.isWindows == false', () {
      expect(Platform.isWindows, false);
    });
    test('Platform.isLinux == true', () {
      expect(Platform.isLinux, true);
    });
    test('Platform.operatingSystemVersion', () {
      expect(Platform.operatingSystemVersion, isNotEmpty);
    });
  }
}
