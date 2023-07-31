// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'recovery_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidCodeTest);
    defineReflectiveTests(MisplacedCodeTest);
  });
}

@reflectiveTest
class InvalidCodeTest extends AbstractRecoveryTest {
  @failingTest
  void test_const_mistyped() {
    // https://github.com/dart-lang/sdk/issues/9714
    testRecovery('''
List<String> fruits = cont <String>['apples', 'bananas', 'pears'];
''', [], '''
List<String> fruits = const <String>['apples', 'bananas', 'pears'];
''');
  }

  void test_default_asVariableName() {
    testRecovery('''
const default = const Object();
''', [
      ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
    ], '''
const default = const Object();
''', expectedErrorsInValidCode: [
      ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
    ]);
  }

  void test_expressionInPlaceOfTypeName() {
    // https://github.com/dart-lang/sdk/issues/30370
    testRecovery('''
f() {
  return <g('')>[0, 1, 2];
}
''', [ParserErrorCode.EXPECTED_TOKEN], '''
f() {
  return <g>[0, 1, 2];
}
''');
  }

  void test_expressionInPlaceOfTypeName2() {
    // https://github.com/dart-lang/sdk/issues/30370
    testRecovery('''
f() {
  return <test('', (){})>[0, 1, 2];
}
''', [ParserErrorCode.EXPECTED_TOKEN], '''
f() {
  return <test>[0, 1, 2];
}
''');
  }

  @failingTest
  void test_functionInPlaceOfTypeName() {
    // https://github.com/dart-lang/sdk/issues/30370
    // TODO(danrubel): Improve recovery. Currently, the fasta scanner
    // does not associate `<` with `>` in this situation.
    testRecovery('''
f() {
  return <test('', (){});>[0, 1, 2];
}
''', [ParserErrorCode.UNEXPECTED_TOKEN], '''
f() {
  return _s_ < test('', (){}); _s_ > [0, 1, 2];
}
''');
  }

  void test_with_asArgumentName() {
    testRecovery('''
f() {}
g() {
  f(with: 3);
}
''', [
      ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
    ], '''
f() {}
g() {
  f(with: 3);
}
''', expectedErrorsInValidCode: [
      ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
    ]);
  }

  @failingTest
  void test_with_asParameterName() {
    testRecovery('''
f({int with: 0}) {}
''', [], '''
f({int _s_}) {}
''');
  }
}

@reflectiveTest
class MisplacedCodeTest extends AbstractRecoveryTest {
  @failingTest
  void test_const_mistyped() {
    // https://github.com/dart-lang/sdk/issues/10554
    testRecovery('''
var allValues = [];
allValues.forEach((enum) {});
''', [], '''
var allValues = [];
''');
  }
}
