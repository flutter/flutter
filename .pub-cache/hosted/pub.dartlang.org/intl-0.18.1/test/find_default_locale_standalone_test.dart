// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:test/test.dart';

void main() {
  test('Find system locale standalone', () {
    // TODO (alanknight): This only verifies that we found some locale. We
    // should find a way to force the system locale before the test is run
    // and then verify that it's actually the correct value.
    // We have no way of getting this reliably for Windows, so it will fail.
    Intl.systemLocale = 'xx_YY';
    var callback = expectAsync1(verifyLocale);
    findSystemLocale().then(callback);
  });
}

void verifyLocale(_) {
  expect(Intl.systemLocale, isNot(equals('xx_YY')));
  var pattern = RegExp(r'\w\w_[A-Z0-9]+');
  var shortPattern = RegExp(r'\w\w');
  var match = pattern.hasMatch(Intl.systemLocale);
  var shortMatch = shortPattern.hasMatch(Intl.systemLocale);
  expect(match || shortMatch, isTrue);
}
