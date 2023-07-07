// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'recovery_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AngleBracketsTest);
    defineReflectiveTests(BracesTest);
    defineReflectiveTests(BracketsTest);
    defineReflectiveTests(ParenthesesTest);
  });
}

/// Test how well the parser recovers when angle brackets (`<` and `>`) are
/// mismatched.
@reflectiveTest
class AngleBracketsTest extends AbstractRecoveryTest {
  @failingTest
  void test_typeArguments_inner_last() {
    testRecovery('''
List<List<int>
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
List<List<int>> _s_;
''');
  }

  void test_typeArguments_inner_last2() {
    testRecovery('''
List<List<int> f;
''', [ParserErrorCode.EXPECTED_TOKEN], '''
List<List<int>> f;
''');
  }

  @failingTest
  void test_typeArguments_inner_notLast() {
    testRecovery('''
Map<List<int, List<String>>
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
Map<List<int>, List<String>> _s_;
''');
  }

  void test_typeArguments_inner_notLast2() {
    // TODO(danrubel): Investigate better recovery.
    testRecovery('''
Map<List<int, List<String>> f;
''', [ParserErrorCode.EXPECTED_TOKEN], '''
Map<List<int, List<String>>> f;
''');
  }

  void test_typeArguments_missing_comma() {
    testRecovery('''
List<int double> f;
''', [ParserErrorCode.EXPECTED_TOKEN], '''
List<int, double> f;
''');
  }

  @failingTest
  void test_typeArguments_outer_last() {
    testRecovery('''
List<int
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
List<int> _s_;
''');
  }

  void test_typeArguments_outer_last2() {
    testRecovery('''
List<int f;
''', [ParserErrorCode.EXPECTED_TOKEN], '''
List<int> f;
''');
  }

  void test_typeParameters_extraGt() {
    testRecovery('''
f<T>>() => null;
''', [
      ParserErrorCode.TOP_LEVEL_OPERATOR,
      ParserErrorCode.MISSING_FUNCTION_PARAMETERS,
      ParserErrorCode.MISSING_FUNCTION_BODY
    ], '''
f<T> > () => null;
''', expectedErrorsInValidCode: [
      ParserErrorCode.TOP_LEVEL_OPERATOR,
      ParserErrorCode.MISSING_FUNCTION_PARAMETERS,
      ParserErrorCode.MISSING_FUNCTION_BODY
    ]);
  }

  void test_typeParameters_funct() {
    testRecovery('''
f<T extends Function()() => null;
''', [
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_FUNCTION_PARAMETERS
    ], '''
f<T extends Function()>() => null;
''');
  }

  void test_typeParameters_funct2() {
    testRecovery('''
f<T extends Function<X>()() => null;
''', [
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_FUNCTION_PARAMETERS
    ], '''
f<T extends Function<X>()>() => null;
''');
  }

  void test_typeParameters_gtEq() {
    testRecovery('''
f<T>=() => null;
''', [ParserErrorCode.UNEXPECTED_TOKEN], '''
f<T>() => null;
''');
  }

  void test_typeParameters_gtGtEq() {
    testRecovery('''
f<T extends List<int>>=() => null;
''', [ParserErrorCode.UNEXPECTED_TOKEN], '''
f<T extends List<int>>() => null;
''');
  }

  void test_typeParameters_last() {
    testRecovery('''
f<T() => null;
''', [
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_FUNCTION_PARAMETERS
    ], '''
f<T>() => null;
''');
  }

  void test_typeParameters_outer_last() {
    testRecovery('''
f<T extends List<int>() => null;
''', [
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_FUNCTION_PARAMETERS
    ], '''
f<T extends List<int>>() => null;
''');
  }
}

/// Test how well the parser recovers when curly braces are mismatched.
@reflectiveTest
class BracesTest extends AbstractRecoveryTest {
  void test_statement_if_last() {
    testRecovery('''
f(x) {
  if (x != null) {
}
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {
  if (x != null) {}
}
''');
  }

  @failingTest
  void test_statement_if_while() {
    // Expected a list of length 2; found a list of length 1
    testRecovery('''
f(x) {
  if (x != null) {
  while (x == null) {}
}
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {
  if (x != null) {}
  while (x == null) {}
}
''');
  }

  @failingTest
  void test_unit_functionBody_class() {
    // Parser crashes
    testRecovery('''
f(x) {
class C {}
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {}
class C {}
''');
  }

  @failingTest
  void test_unit_functionBody_function() {
    // Expected a list of length 2; found a list of length 1
    testRecovery('''
f(x) {
g(y) => y;
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {}
g(y) => y;
''');
  }

  void test_unit_functionBody_last() {
    testRecovery('''
f(x) {
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {}
''');
  }

  @failingTest
  void test_unit_functionBody_variable() {
    // Expected a list of length 2; found a list of length 1
    testRecovery('''
f(x) {
int y = 0;
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {}
int y = 0;
''');
  }
}

/// Test how well the parser recovers when square brackets are mismatched.
@reflectiveTest
class BracketsTest extends AbstractRecoveryTest {
  void test_indexOperator() {
    testRecovery('''
f(x) => l[x
''', [ScannerErrorCode.EXPECTED_TOKEN, ParserErrorCode.EXPECTED_TOKEN], '''
f(x) => l[x];
''');
  }

  void test_indexOperator_nullAware() {
    testRecovery('''
f(x) => l?[x
''', [ScannerErrorCode.EXPECTED_TOKEN, ParserErrorCode.EXPECTED_TOKEN], '''
f(x) => l?[x];
''');
  }

  void test_listLiteral_inner_last() {
    testRecovery('''
var x = [[0], [1];
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
var x = [[0], [1]];
''');
  }

  void test_listLiteral_inner_notLast() {
    testRecovery('''
var x = [[0], [1, [2]];
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
var x = [[0], [1, [2]]];
''');
  }

  void test_listLiteral_missing_comma() {
    testRecovery('''
var x = [0 1];
''', [ParserErrorCode.EXPECTED_TOKEN], '''
var x = [0, 1];
''');
  }

  void test_listLiteral_outer_last() {
    testRecovery('''
var x = [0, 1
''', [ScannerErrorCode.EXPECTED_TOKEN, ParserErrorCode.EXPECTED_TOKEN], '''
var x = [0, 1];
''');
  }
}

/// Test how well the parser recovers when parentheses are mismatched.
@reflectiveTest
class ParenthesesTest extends AbstractRecoveryTest {
  @failingTest
  void test_if_last() {
    // Parser crashes
    testRecovery('''
f(x) {
  if (x
}
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {
  if (x);
}
''');
  }

  @failingTest
  void test_if_while() {
    // Parser crashes
    testRecovery('''
f(x) {
  if (x
  while(x != null) {}
}
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {
  if (x);
  while(x != null) {}
}
''');
  }

  void test_parameterList_class() {
    // Parser crashes
    testRecovery('''
f(x
class C {}
''', [ScannerErrorCode.EXPECTED_TOKEN, ParserErrorCode.MISSING_FUNCTION_BODY],
        '''
f(x) {}
class C {}
''');
  }

  void test_parameterList_eof() {
    testRecovery('''
f(x
''', [ScannerErrorCode.EXPECTED_TOKEN, ParserErrorCode.MISSING_FUNCTION_BODY],
        '''
f(x) {}
''');
  }
}
