// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test date formatting and parsing while the system time zone is set to
/// America/Sao Paulo.
///
/// In Brazil the time change spring/fall happens at midnight. This can make
/// operations working with dates as midnight on a particular day fail. For
/// example, in the (Brazilian) autumn, a date might "fall back" an hour and be
/// on the previous day. This test verifies that we're handling those
/// situations.

// This test relies on setting the TZ environment variable to affect the
// system's time zone calculations. That's only effective on Linux environments,
// and would only work in a browser if we were able to set it before the browser
// launched, which we aren't. So restrict this test to the VM and Linux.
@TestOn('vm && linux')

import 'package:test/test.dart';
import 'timezone_test_core.dart';

void main() {
  // The test date is Jan 1, so Brazilian Summer Time will be in effect.
  testTimezone('America/Sao_Paulo', expectedUtcOffset: -2);
}
