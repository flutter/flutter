// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test date formatting and parsing using locale data directly imported.
///
/// This is a copy of date_time_format_local_even_test.dart which also
/// verifies the time zone against an environment variable.

import 'dart:io';

import 'package:intl/date_symbol_data_local.dart';
import 'package:test/test.dart';

import 'date_time_format_test_stub.dart';

void main() {
  var tzOffset = Platform.environment['EXPECTED_TZ_OFFSET_FOR_TEST'];
  var timezoneName = Platform.environment['TZ'];
  if (tzOffset != null) {
    test('Actually running in the correct time zone: $timezoneName', () {
      // Pick a constant Date so that the offset is known.
      var d = DateTime(2012, 1, 1, 7, 6, 5);
      print('Time zone offset is ${d.timeZoneOffset.inHours}');
      print('Time zone name is ${d.timeZoneName}');
      expect(tzOffset, '${d.timeZoneOffset.inHours}');
    });
  }

  // Run the main date formatting tests with a large set of locales.
  runWith(evenLocales, null, initializeDateFormatting);
}
