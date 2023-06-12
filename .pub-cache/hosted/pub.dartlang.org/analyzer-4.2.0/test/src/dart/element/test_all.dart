// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'class_element_test.dart' as class_element;
import 'class_hierarchy_test.dart' as class_hierarchy;
import 'display_string_test.dart' as display_string;
import 'element_test.dart' as element;
import 'factor_type_test.dart' as factor_type;
import 'flatten_type_test.dart' as flatten_type;
import 'function_type_test.dart' as function_type;
import 'future_or_base_test.dart' as future_or_base;
import 'future_value_type_test.dart' as future_value_type;
import 'generic_inferrer_test.dart' as generic_inferrer;
import 'inheritance_manager3_test.dart' as inheritance_manager3;
import 'least_greatest_closure_test.dart' as least_greatest_closure_test;
import 'least_upper_bound_helper_test.dart' as least_upper_bound_helper;
import 'normalize_type_test.dart' as normalize_type;
import 'nullability_eliminator_test.dart' as nullability_eliminator;
import 'nullable_test.dart' as nullable;
import 'replace_top_bottom_test.dart' as replace_top_bottom;
import 'resolve_to_bound_test.dart' as resolve_to_bound;
import 'runtime_type_equality_test.dart' as runtime_type_equality;
import 'subtype_test.dart' as subtype;
import 'top_merge_test.dart' as top_merge;
import 'type_algebra_test.dart' as type_algebra;
import 'type_bounded_test.dart' as type_bounded;
import 'type_constraint_gatherer_test.dart' as type_constraint_gatherer;
import 'type_parameter_element_test.dart' as type_parameter_element;
import 'type_references_any_test.dart' as type_references_any;
import 'type_visitor_test.dart' as type_visitor;
import 'upper_lower_bound_test.dart' as upper_bound;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    class_element.main();
    class_hierarchy.main();
    display_string.main();
    element.main();
    factor_type.main();
    flatten_type.main();
    function_type.main();
    future_or_base.main();
    future_value_type.main();
    generic_inferrer.main();
    inheritance_manager3.main();
    least_greatest_closure_test.main();
    least_upper_bound_helper.main();
    normalize_type.main();
    nullability_eliminator.main();
    nullable.main();
    replace_top_bottom.main();
    resolve_to_bound.main();
    runtime_type_equality.main();
    subtype.main();
    top_merge.main();
    type_algebra.main();
    type_bounded.main();
    type_constraint_gatherer.main();
    type_parameter_element.main();
    type_references_any.main();
    type_visitor.main();
    upper_bound.main();
  }, name: 'element');
}
