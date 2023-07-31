// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'options_test.dart' as options_test;
import 'strong/test_all.dart' as strong_mode_test_all;

main() {
  defineReflectiveSuite(() {
    options_test.main();
    strong_mode_test_all.main();
  }, name: 'task');
}
