// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'ast_test.dart' as ast;
import 'constant_evaluator_test.dart' as constant_evaluator;
import 'element_locator_test.dart' as element_locator;
import 'to_source_visitor_test.dart' as to_source_visitor;
import 'utilities_test.dart' as utilities;

main() {
  defineReflectiveSuite(() {
    ast.main();
    constant_evaluator.main();
    element_locator.main();
    to_source_visitor.main();
    utilities.main();
  }, name: 'ast');
}
