// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'all_the_rest_test.dart' as all_the_rest;
import 'class_member_parser_test.dart' as class_member_parser;
import 'collection_literal_parser_test.dart' as collection_literal_parser;
import 'complex_parser_test.dart' as complex_parser;
// ignore: deprecated_member_use_from_same_package
import 'constant_test.dart' as constant_test;
import 'element_resolver_test.dart' as element_resolver_test;
import 'error_parser_test.dart' as error_parser;
import 'error_suppression_test.dart' as error_suppression;
import 'expression_parser_test.dart' as expression_parser;
import 'extension_methods_parser_test.dart' as extension_methods_parser;
import 'formal_parameter_parser_test.dart' as formal_parameter_parser;
import 'function_reference_parser_test.dart' as function_reference_parser;
import 'generic_metadata_parser_test.dart' as generic_metadata_parser;
import 'invalid_code_test.dart' as invalid_code;
import 'issues_test.dart' as issues;
import 'java_core_test.dart' as java_core_test;
import 'new_as_identifier_parser_test.dart' as new_as_identifier_parser;
import 'nnbd_parser_test.dart' as nnbd_parser;
import 'non_error_parser_test.dart' as non_error_parser;
import 'non_error_resolver_test.dart' as non_error_resolver;
import 'non_hint_code_test.dart' as non_hint_code;
import 'patterns_parser_test.dart' as patterns_parser;
import 'recovery_parser_test.dart' as recovery_parser;
import 'resolver_test.dart' as resolver_test;
import 'scanner_test.dart' as scanner_test;
import 'sdk_test.dart' as sdk_test;
import 'simple_parser_test.dart' as simple_parser;
import 'simple_resolver_test.dart' as simple_resolver_test;
import 'source_factory_test.dart' as source_factory_test;
import 'statement_parser_test.dart' as statement_parser;
import 'static_type_analyzer_test.dart' as static_type_analyzer_test;
import 'static_type_warning_code_test.dart' as static_type_warning_code;
import 'static_warning_code_test.dart' as static_warning_code;
import 'strong_mode_test.dart' as strong_mode;
import 'top_level_parser_test.dart' as top_level_parser;
import 'type_system_test.dart' as type_system_test;
import 'utilities_dart_test.dart' as utilities_dart_test;
import 'utilities_test.dart' as utilities_test;
import 'variance_parser_test.dart' as variance_parser;

main() {
  defineReflectiveSuite(() {
    all_the_rest.main();
    class_member_parser.main();
    collection_literal_parser.main();
    complex_parser.main();
    constant_test.main();
    element_resolver_test.main();
    error_parser.main();
    error_suppression.main();
    expression_parser.main();
    extension_methods_parser.main();
    formal_parameter_parser.main();
    function_reference_parser.main();
    generic_metadata_parser.main();
    invalid_code.main();
    issues.main();
    java_core_test.main();
    new_as_identifier_parser.main();
    nnbd_parser.main();
    non_error_parser.main();
    non_error_resolver.main();
    non_hint_code.main();
    patterns_parser.main();
    recovery_parser.main();
    resolver_test.main();
    scanner_test.main();
    sdk_test.main();
    simple_parser.main();
    simple_resolver_test.main();
    source_factory_test.main();
    statement_parser.main();
    static_type_analyzer_test.main();
    static_type_warning_code.main();
    static_warning_code.main();
    strong_mode.main();
    top_level_parser.main();
    type_system_test.main();
    utilities_dart_test.main();
    utilities_test.main();
    variance_parser.main();
  }, name: 'generated');
}
