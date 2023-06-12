// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'checker_test.dart' as checker_test;
import 'dart2_inference_test.dart' as dart2_inference_test;
import 'inferred_type_test.dart' as inferred_type_test;

main() {
  defineReflectiveSuite(() {
    checker_test.main();
    dart2_inference_test.main();
    inferred_type_test.main();
  }, name: 'strong');
}
