// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12

import 'package:async_helper/async_minitest.dart'; // ignore: unused_import
import 'package:expect/expect.dart'; // ignore: unused_import

import 'src/matchers.dart'; // ignore: unused_import
import 'src/test_suite.dart';

export 'package:async_helper/async_minitest.dart' hide test;
export 'package:expect/expect.dart';
export 'src/matchers.dart';

final TestSuite _testSuite = TestSuite();

/// Describes the test named [name] given by the function [body].
///
/// After all tests are described, they will be run. All calls to [test] must be
/// made in the same event as the program's `main()` function.
void test(
  String name,
  dynamic Function() body, {
  bool skip = false,
}) {
  _testSuite.test(name, body, skip: skip);
}
