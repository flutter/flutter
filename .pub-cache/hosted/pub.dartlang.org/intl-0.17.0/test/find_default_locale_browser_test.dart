// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library find_default_locale_browser_test;

import 'package:intl/intl.dart';
import 'package:intl/intl_browser.dart';
import 'package:test/test.dart';

void main() {
  test('Find system locale in browser', () {
    // TODO (alanknight): This only verifies that we found some locale. We
    // should find a way to force the system locale before the test is run
    // and then verify that it's actually the correct value.
    Intl.systemLocale = 'xx_YY';
    var callback = expectAsync1(verifyLocale);
    findSystemLocale().then(callback);
  });
}

void verifyLocale(_) {
  expect(Intl.systemLocale, isNot(equals('xx_YY')));
  // Allow either en_US or just en type locales. Windows in particular may
  // give us just ru for ru_RU
  var pattern = RegExp(r'\w\w_[A-Z0-9]+');
  var shortPattern = RegExp(r'\w\w');
  var match = pattern.hasMatch(Intl.systemLocale);
  var shortMatch = shortPattern.hasMatch(Intl.systemLocale);
  expect(match || shortMatch, isTrue);
}
