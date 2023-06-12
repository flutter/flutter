/// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
/// for details. All rights reserved. Use of this source code is governed by a
/// BSD-style license that can be found in the LICENSE file.

/// Number format tests for the web - excludes numbers too big to compile for
/// the web.
@TestOn('browser')
library number_format_web_test;

import 'package:test/test.dart';
import 'number_format_test_core.dart' as core;

void main() {
  core.runTests(core.testNumbers);
}
