// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrongNumberOfParametersForOperatorTest);
  });
}

@reflectiveTest
class WrongNumberOfParametersForOperatorTest extends PubPackageResolutionTest {
  test_binaryOperators() async {
    await _checkTooFewAndTooMany('<');
    await _checkTooFewAndTooMany('>');
    await _checkTooFewAndTooMany('<=');
    await _checkTooFewAndTooMany('>=');
    await _checkTooFewAndTooMany('+');
    await _checkTooFewAndTooMany('/');
    await _checkTooFewAndTooMany('~/');
    await _checkTooFewAndTooMany('*');
    await _checkTooFewAndTooMany('%');
    await _checkTooFewAndTooMany('|');
    await _checkTooFewAndTooMany('^');
    await _checkTooFewAndTooMany('&');
    await _checkTooFewAndTooMany('<<');
    await _checkTooFewAndTooMany('>>');
    await _checkTooFewAndTooMany('>>>');
    await _checkTooFewAndTooMany('[]');
  }

  test_correct_number_of_parameters_binary() async {
    await _checkCorrectSingle("<");
    await _checkCorrectSingle(">");
    await _checkCorrectSingle("<=");
    await _checkCorrectSingle(">=");
    await _checkCorrectSingle("+");
    await _checkCorrectSingle("/");
    await _checkCorrectSingle("~/");
    await _checkCorrectSingle("*");
    await _checkCorrectSingle("%");
    await _checkCorrectSingle("|");
    await _checkCorrectSingle("^");
    await _checkCorrectSingle("&");
    await _checkCorrectSingle("<<");
    await _checkCorrectSingle(">>");
    await _checkCorrectSingle(">>>");
    await _checkCorrectSingle("[]");
  }

  test_correct_number_of_parameters_index_assignment() async {
    await assertNoErrorsInCode(r'''
class A {
  operator []=(a, b) {}
}
''');
  }

  test_correct_number_of_parameters_minus() async {
    await _checkCorrect("-", "");
    await _checkCorrect("-", "a");
  }

  test_unaryMinus() async {
    await assertErrorsInCode(r'''
class A {
  operator -(a, b) {}
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS,
          21, 1),
    ]);
  }

  test_unaryTilde() async {
    await _check('~', 'a');
    await _check('~', 'a, b');
    await _check('~', 'a, [b]');
    await _check('~', 'a, {b}');
  }

  Future<void> _check(String name, String parameters) async {
    await assertErrorsInCode('''
class A {
  operator $name($parameters) {}
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR, 21, 1),
    ]);
  }

  Future<void> _checkCorrect(String name, String parameters) async {
    await assertNoErrorsInCode('''
class A {
  operator $name($parameters) {}
}
''');
  }

  Future<void> _checkCorrectSingle(String name) async {
    await _checkCorrect(name, 'a');
  }

  Future<void> _checkTooFewAndTooMany(String name) async {
    await _check(name, '');
    await _check(name, 'a, b');
    await _check(name, 'a, [b]');
    await _check(name, 'a, {b}');
  }
}
