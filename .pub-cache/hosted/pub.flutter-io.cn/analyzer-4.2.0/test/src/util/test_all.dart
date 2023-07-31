// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'asserts_test.dart' as asserts_test;
import 'either_test.dart' as either_test;
import 'glob_test.dart' as glob_test;
import 'lru_map_test.dart' as lru_map_test;
import 'yaml_test.dart' as yaml_test;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    asserts_test.main();
    either_test.main();
    glob_test.main();
    lru_map_test.main();
    yaml_test.main();
  }, name: 'util');
}
