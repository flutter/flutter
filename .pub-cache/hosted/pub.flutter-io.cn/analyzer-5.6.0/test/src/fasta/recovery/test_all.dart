// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'code_order_test.dart' as code_order;
import 'extra_code_test.dart' as extra_code;
import 'invalid_code_test.dart' as invalid_code_test;
import 'missing_code_test.dart' as missing_code;
import 'paired_tokens_test.dart' as paired_tokens;
import 'partial_code/test_all.dart' as partial_code;

main() {
  defineReflectiveSuite(() {
    code_order.main();
    extra_code.main();
    invalid_code_test.main();
    missing_code.main();
    paired_tokens.main();
    partial_code.main();
  }, name: 'recovery');
}
