// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests date formatting and parsing using locale data read from the
/// local file system. This tests one half the locales, since testing all
/// of them takes long enough that it may cause timeouts in the test bots.

@Timeout(Duration(seconds: 60))
@TestOn('vm')
library date_time_format_file_test_1;

import 'package:intl/date_symbol_data_file.dart';
import 'package:test/test.dart';
import 'data_directory.dart';
import 'date_time_format_test_stub.dart';

void main() {
  runWith(oddLocales, dataDirectory, initializeDateFormatting);
}
