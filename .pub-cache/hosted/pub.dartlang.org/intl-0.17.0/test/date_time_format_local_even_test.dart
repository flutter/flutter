// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test date formatting and parsing using locale data which is available
/// directly in the program as a constant. This tests one half the locales,
/// since testing all of them takes long enough that it may cause timeouts in
/// the test bots.

library date_time_format_test_2;

import 'package:intl/date_symbol_data_local.dart';
import 'date_time_format_test_stub.dart';

void main() {
  runWith(evenLocales, null, initializeDateFormatting);
}
