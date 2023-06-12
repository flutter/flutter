// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test date formatting and parsing while the system time zone is set to
/// GMT.
///
/// This is the same as UTC, but may be differently named in some systems.

// This test relies on setting the TZ environment variable to affect the
// system's time zone calculations. That's only effective on Linux environments,
// and would only work in a browser if we were able to set it before the browser
// launched, which we aren't. So restrict this test to the VM and Linux.
@TestOn('vm && linux')

import 'package:test/test.dart';
import 'timezone_test_core.dart';

void main() {
  testTimezone('GMT', expectedUtcOffset: 0);
}
