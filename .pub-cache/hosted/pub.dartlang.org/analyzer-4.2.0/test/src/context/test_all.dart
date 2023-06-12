// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'builder_test.dart' as builder_test;
import 'packages_test.dart' as packages_test;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    builder_test.main();
    packages_test.main();
  }, name: 'context');
}
