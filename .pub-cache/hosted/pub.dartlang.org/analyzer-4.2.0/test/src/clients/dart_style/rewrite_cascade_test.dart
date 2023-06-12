// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/clients/dart_style/rewrite_cascade.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RewriteCascadeTest);
  });
}

@reflectiveTest
class RewriteCascadeTest {
  test_fixCascadeByParenthesizingTarget() {
    const pairs = {
      'c ? a : b..method();': '(c ? a : b)..method();',
      'a ?? b..method();': '(a ?? b)..method();',
      'a && b..method();': '(a && b)..method();',
      'a || b..method();': '(a || b)..method();',
      'a == b..method();': '(a == b)..method();',
      'a != b..method();': '(a != b)..method();',
      'a < b..method();': '(a < b)..method();',
      'a > b..method();': '(a > b)..method();',
      'a <= b..method();': '(a <= b)..method();',
      'a >= b..method();': '(a >= b)..method();',
      'a ^ b..method();': '(a ^ b)..method();',
      'a | b..method();': '(a | b)..method();',
      'a << b..method();': '(a << b)..method();',
      'a >> b..method();': '(a >> b)..method();',
      'a + b..method();': '(a + b)..method();',
      'a - b..method();': '(a - b)..method();',
      'a * b..method();': '(a * b)..method();',
      'a / b..method();': '(a / b)..method();',
      'a ~/ b..method();': '(a ~/ b)..method();',
      '-a..method();': '(-a)..method();',
      '!a..method();': '(!a)..method();',
      '~a..method();': '(~a)..method();',
      'a++..method();': '(a++)..method();',
      'a--..method();': '(a--)..method();',
    };

    void assertSingle({
      required String input,
      required String expected,
    }) {
      var statement = _parseStringToFindNode('''
void f() {
  $input
}
''').expressionStatement(input);
      var result = fixCascadeByParenthesizingTarget(
        expressionStatement: statement,
        cascadeExpression: statement.expression as CascadeExpression,
      );
      expect(result.toSource(), expected);
      expect(result.semicolon, same(statement.semicolon));
    }

    for (var entry in pairs.entries) {
      assertSingle(
        input: entry.key,
        expected: entry.value,
      );
    }
  }

  test_insertCascadeTargetIntoExpression() {
    void assertSingle({
      required String input,
      required String expected,
    }) {
      var statement = _parseStringToFindNode('''
void f() {
  $input;
    }
    ''').expressionStatement(input);
      var cascadeExpression = statement.expression as CascadeExpression;
      var result = insertCascadeTargetIntoExpression(
        expression: cascadeExpression.cascadeSections.single,
        cascadeTarget: cascadeExpression.target,
      );
      expect(result.toSource(), expected);
    }

    const pairs = {
      'obj..method()': 'obj.method()',
      'obj..getter': 'obj.getter',
      'obj..setter = 3': 'obj.setter = 3',
      'obj..[subscript] = 3': 'obj[subscript] = 3',
      'obj?..[subscript] = 3': 'obj?[subscript] = 3',
      'obj..index[subscript] = 3': 'obj.index[subscript] = 3',
      'obj..index?[subscript] = 3': 'obj.index?[subscript] = 3',
      // Nested
      'obj..foo().bar().method()': 'obj.foo().bar().method()',
      'obj..foo.bar.getter': 'obj.foo.bar.getter',
      'obj..foo.bar.setter = 0': 'obj.foo.bar.setter = 0',
    };

    for (var entry in pairs.entries) {
      assertSingle(
        input: entry.key,
        expected: entry.value,
      );
    }
  }

  FindNode _parseStringToFindNode(String content) {
    var parseResult = parseString(
      content: content,
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    return FindNode(parseResult.content, parseResult.unit);
  }
}
