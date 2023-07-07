// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'annotation_test.dart' as annotation;
import 'assert_statement_test.dart' as assert_statement;
import 'break_statement_test.dart' as break_statement;
import 'class_declaration_test.dart' as class_declaration;
import 'constructor_declaration_test.dart' as constructor_declaration;
import 'continue_statement_test.dart' as continue_statement;
import 'do_statement_test.dart' as do_statement;
import 'enum_declaration_test.dart' as enum_declaration;
import 'export_directive_test.dart' as export_directive;
import 'extension_declaration_test.dart' as extension_declaration;
import 'field_declaration_test.dart' as field_declaration;
import 'for_each_statement_test.dart' as for_each_statement;
import 'for_statement_test.dart' as for_statement;
import 'if_statement_test.dart' as if_statement;
import 'import_directive_test.dart' as import_directive;
import 'index_expression_test.dart' as index_expression;
import 'instance_creation_test.dart' as instance_creation;
import 'library_directive_test.dart' as library_directive;
import 'local_variable_test.dart' as local_variable;
import 'method_declaration_test.dart' as method_declaration;
import 'mixin_declaration_test.dart' as mixin_declaration;
import 'parameter_test.dart' as parameter;
import 'part_directive_test.dart' as part_directive;
import 'part_of_directive_test.dart' as part_of_directive;
import 'return_statement_test.dart' as return_statement;
import 'switch_statement_test.dart' as switch_statement;
import 'top_level_variable_test.dart' as top_level_variable;
import 'try_statement_test.dart' as try_statement;
import 'typedef_test.dart' as typedef_declaration;
import 'while_statement_test.dart' as while_statement;
import 'yield_statement_test.dart' as yield_statement;

main() {
  group('partial_code', () {
    annotation.main();
    assert_statement.main();
    break_statement.main();
    class_declaration.main();
    constructor_declaration.main();
    continue_statement.main();
    do_statement.main();
    enum_declaration.main();
    export_directive.main();
    extension_declaration.main();
    field_declaration.main();
    for_statement.main();
    for_each_statement.main();
    if_statement.main();
    import_directive.main();
    index_expression.main();
    instance_creation.main();
    library_directive.main();
    local_variable.main();
    method_declaration.main();
    mixin_declaration.main();
    parameter.main();
    part_directive.main();
    part_of_directive.main();
    return_statement.main();
    switch_statement.main();
    top_level_variable.main();
    try_statement.main();
    typedef_declaration.main();
    while_statement.main();
    yield_statement.main();
  });
}
