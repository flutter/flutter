// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../node_text_expectations.dart';
import 'collection_elements_test.dart' as collection_elements;
import 'equality_expressions_test.dart' as equality_expressions;
import 'extension_methods_test.dart' as extension_methods;
import 'function_expression_test.dart' as function_expression;
import 'function_test.dart' as function;
import 'inference_update_1_test.dart' as inference_update_1;
import 'list_literal_test.dart' as list_literal;
import 'local_variable_test.dart' as local_variable;
import 'logical_boolean_expressions_test.dart' as logical_boolean_expressions;
import 'map_literal_test.dart' as map_literal;
import 'set_literal_test.dart' as set_literal;
import 'statements_test.dart' as statements;
import 'tear_off_test.dart' as tear_off;
import 'throw_test.dart' as throw_expression;
import 'type_test_expressions_test.dart' as type_test_expressions;

main() {
  defineReflectiveSuite(() {
    collection_elements.main();
    equality_expressions.main();
    extension_methods.main();
    function.main();
    function_expression.main();
    inference_update_1.main();
    list_literal.main();
    local_variable.main();
    logical_boolean_expressions.main();
    map_literal.main();
    set_literal.main();
    statements.main();
    tear_off.main();
    throw_expression.main();
    type_test_expressions.main();
    defineReflectiveTests(UpdateNodeTextExpectations);
  }, name: 'type inference');
}
