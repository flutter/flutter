/// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
/// for details. All rights reserved. Use of this source code is governed by a
/// BSD-style license that can be found in the LICENSE file.

/// Number tests for the VM - includes numbers that can only be compiled for the
/// VM.
@TestOn('vm')
library number_format_vm_test;

import 'package:test/test.dart';
import 'number_format_test_core.dart' as core;

/// Test numbers that won't work in Javascript because they're too big.
var testNumbersOnlyForTheVM = {
  '9,000,000,000,000,000,000': 9000000000000000000,
  '9,223,372,036,854,775,807': 9223372036854775807
};

void main() {
  core.runTests(core.testNumbers..addAll(testNumbersOnlyForTheVM));
}
