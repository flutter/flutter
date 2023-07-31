// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'evaluation_test.dart' as evaluation;
import 'has_type_parameter_reference_test.dart' as has_type_parameter_reference;
import 'potentially_constant_test.dart' as potentially_constant;
import 'value_test.dart' as value;

main() {
  defineReflectiveSuite(() {
    evaluation.main();
    has_type_parameter_reference.main();
    potentially_constant.main();
    value.main();
  }, name: 'constant');
}
