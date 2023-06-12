// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test date formatting and parsing using locale data which is available
/// directly in the program as a constant.

library date_time_format_test;

import 'package:test/test.dart';
import 'package:intl/intl.dart';
import 'date_time_format_test_core.dart';

typedef TestListFunc = List<String> Function();

typedef InitializeDateFormattingFunc = Future<void> Function(
    String locale, String filePath);

/// Return only the odd-numbered locales. A simple way to divide the list into
/// two roughly equal parts.
List<String> oddLocales() {
  var i = 1;
  return allLocales().where((x) => (i++).isOdd).toList();
}

/// Return a set of a few locales to run just the tests on a small sample.
List<String> smallSetOfLocales() {
  return allLocales().sublist(0, 10);
}

/// Return only the even-numbered locales. A simple way to divide the list into
/// two roughly equal parts.
List<String> evenLocales() {
  var i = 1;
  return allLocales().where((x) => !(i++).isOdd).toList();
}

void runWith(TestListFunc getSubset, String? dir,
    InitializeDateFormattingFunc initFunction) {
  var notNullDir = dir ?? '';

  // Initialize one locale just so we know what the list is.
  // Also, note that we take the list of locales as a function so that we don't
  // evaluate it until after we know that all the locales are available.

  var initialized = false;

  setUp(() {
    if (initialized) {
      return null;
    }
    return initFunction('en_US', notNullDir).then((_) {
      return Future.forEach(DateFormat.allLocalesWithSymbols(),
          (String locale) {
        return initFunction(locale, notNullDir);
      });
    }).then((_) {
      initialized = true;
    });
  });

  runDateTests(getSubset);
}
