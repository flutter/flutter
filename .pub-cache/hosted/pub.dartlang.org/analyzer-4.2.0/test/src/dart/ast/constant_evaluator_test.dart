// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/constant_evaluator.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parse_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantEvaluatorTest);
  });
}

@reflectiveTest
class ConstantEvaluatorTest extends ParseBase {
  void test_binary_bitAnd() {
    var value = _getConstantValue("74 & 42") as int;
    expect(value, 74 & 42);
  }

  void test_binary_bitOr() {
    var value = _getConstantValue("74 | 42") as int;
    expect(value, 74 | 42);
  }

  void test_binary_bitXor() {
    var value = _getConstantValue("74 ^ 42") as int;
    expect(value, 74 ^ 42);
  }

  void test_binary_divide_double() {
    var value = _getConstantValue("3.2 / 2.3");
    expect(value, 3.2 / 2.3);
  }

  void test_binary_divide_integer() {
    var value = _getConstantValue("3 / 2");
    expect(value, 1.5);
  }

  void test_binary_equal_boolean() {
    var value = _getConstantValue("true == false");
    expect(value, false);
  }

  void test_binary_equal_integer() {
    var value = _getConstantValue("2 == 3");
    expect(value, false);
  }

  void test_binary_equal_invalidLeft() {
    var value = _getConstantValue("a == 3");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_equal_invalidRight() {
    var value = _getConstantValue("2 == a");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_equal_string() {
    var value = _getConstantValue("'a' == 'b'");
    expect(value, false);
  }

  void test_binary_greaterThan() {
    var value = _getConstantValue("2 > 3");
    expect(value, false);
  }

  void test_binary_greaterThanOrEqual() {
    var value = _getConstantValue("2 >= 3");
    expect(value, false);
  }

  void test_binary_leftShift() {
    var value = _getConstantValue("16 << 2") as int;
    expect(value, 64);
  }

  void test_binary_lessThan() {
    var value = _getConstantValue("2 < 3");
    expect(value, true);
  }

  void test_binary_lessThanOrEqual() {
    var value = _getConstantValue("2 <= 3");
    expect(value, true);
  }

  void test_binary_logicalAnd() {
    var value = _getConstantValue("true && false");
    expect(value, false);
  }

  void test_binary_logicalOr() {
    var value = _getConstantValue("true || false");
    expect(value, true);
  }

  void test_binary_minus_double() {
    var value = _getConstantValue("3.2 - 2.3");
    expect(value, 3.2 - 2.3);
  }

  void test_binary_minus_integer() {
    var value = _getConstantValue("3 - 2");
    expect(value, 1);
  }

  void test_binary_notEqual_boolean() {
    var value = _getConstantValue("true != false");
    expect(value, true);
  }

  void test_binary_notEqual_integer() {
    var value = _getConstantValue("2 != 3");
    expect(value, true);
  }

  void test_binary_notEqual_invalidLeft() {
    var value = _getConstantValue("a != 3");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_notEqual_invalidRight() {
    var value = _getConstantValue("2 != a");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_notEqual_string() {
    var value = _getConstantValue("'a' != 'b'");
    expect(value, true);
  }

  void test_binary_plus_double() {
    var value = _getConstantValue("2.3 + 3.2");
    expect(value, 2.3 + 3.2);
  }

  void test_binary_plus_double_string() {
    var value = _getConstantValue("'world' + 5.5");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_plus_int_string() {
    var value = _getConstantValue("'world' + 5");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_plus_integer() {
    var value = _getConstantValue("2 + 3");
    expect(value, 5);
  }

  void test_binary_plus_string() {
    var value = _getConstantValue("'hello ' + 'world'");
    expect(value, 'hello world');
  }

  void test_binary_plus_string_double() {
    var value = _getConstantValue("5.5 + 'world'");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_plus_string_int() {
    var value = _getConstantValue("5 + 'world'");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_remainder_double() {
    var value = _getConstantValue("3.2 % 2.3");
    expect(value, 3.2 % 2.3);
  }

  void test_binary_remainder_integer() {
    var value = _getConstantValue("8 % 3");
    expect(value, 2);
  }

  void test_binary_rightShift() {
    var value = _getConstantValue("64 >> 2") as int;
    expect(value, 16);
  }

  void test_binary_times_double() {
    var value = _getConstantValue("2.3 * 3.2");
    expect(value, 2.3 * 3.2);
  }

  void test_binary_times_integer() {
    var value = _getConstantValue("2 * 3");
    expect(value, 6);
  }

  void test_binary_truncatingDivide_double() {
    var value = _getConstantValue("3.2 ~/ 2.3") as int;
    expect(value, 1);
  }

  void test_binary_truncatingDivide_integer() {
    var value = _getConstantValue("10 ~/ 3") as int;
    expect(value, 3);
  }

  @failingTest
  void test_constructor() {
    var value = _getConstantValue("?");
    expect(value, null);
  }

  @failingTest
  void test_identifier_class() {
    var value = _getConstantValue("?");
    expect(value, null);
  }

  @failingTest
  void test_identifier_function() {
    var value = _getConstantValue("?");
    expect(value, null);
  }

  @failingTest
  void test_identifier_static() {
    var value = _getConstantValue("?");
    expect(value, null);
  }

  @failingTest
  void test_identifier_staticMethod() {
    var value = _getConstantValue("?");
    expect(value, null);
  }

  @failingTest
  void test_identifier_topLevel() {
    var value = _getConstantValue("?");
    expect(value, null);
  }

  @failingTest
  void test_identifier_typeParameter() {
    var value = _getConstantValue("?");
    expect(value, null);
  }

  void test_literal_boolean_false() {
    var value = _getConstantValue("false");
    expect(value, false);
  }

  void test_literal_boolean_true() {
    var value = _getConstantValue("true");
    expect(value, true);
  }

  void test_literal_list() {
    var value = _getConstantValue("['a', 'b', 'c']") as List<Object>;
    expect(value.length, 3);
    expect(value[0], "a");
    expect(value[1], "b");
    expect(value[2], "c");
  }

  void test_literal_map() {
    var value = _getConstantValue("{'a' : 'm', 'b' : 'n', 'c' : 'o'}")
        as Map<Object, Object>;
    expect(value.length, 3);
    expect(value["a"], "m");
    expect(value["b"], "n");
    expect(value["c"], "o");
  }

  void test_literal_null() {
    var value = _getConstantValue("null");
    expect(value, null);
  }

  void test_literal_number_double() {
    var value = _getConstantValue("3.45");
    expect(value, 3.45);
  }

  void test_literal_number_integer() {
    var value = _getConstantValue("42");
    expect(value, 42);
  }

  void test_literal_string_adjacent() {
    var value = _getConstantValue("'abc' 'def'");
    expect(value, "abcdef");
  }

  void test_literal_string_interpolation_invalid() {
    var value = _getConstantValue("'a\${f()}c'");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_literal_string_interpolation_valid() {
    var value = _getConstantValue("'a\${3}c'");
    expect(value, "a3c");
  }

  void test_literal_string_simple() {
    var value = _getConstantValue("'abc'");
    expect(value, "abc");
  }

  void test_parenthesizedExpression() {
    var value = _getConstantValue("('a')");
    expect(value, "a");
  }

  void test_unary_bitNot() {
    var value = _getConstantValue("~42") as int;
    expect(value, ~42);
  }

  void test_unary_logicalNot() {
    var value = _getConstantValue("!true");
    expect(value, false);
  }

  void test_unary_negated_double() {
    var value = _getConstantValue("-42.3");
    expect(value, -42.3);
  }

  void test_unary_negated_integer() {
    var value = _getConstantValue("-42");
    expect(value, -42);
  }

  Object? _getConstantValue(String expressionCode) {
    var path = convertPath('/test/lib/test.dart');

    newFile(path, '''
void f() {
  ($expressionCode); // ref
}
''');

    var parseResult = parseUnit(path);
    expect(parseResult.errors, isEmpty);

    var findNode = FindNode(parseResult.content, parseResult.unit);
    var expression = findNode.parenthesized('); // ref').expression;

    return expression.accept(ConstantEvaluator());
  }
}
