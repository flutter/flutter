// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorResolverTest);
    defineReflectiveTests(PrefixedNamespaceTest);
    defineReflectiveTests(StrictModeTest);
    defineReflectiveTests(StrictModeWithoutNullSafetyTest);
    defineReflectiveTests(TypePropagationTest);
  });
}

@reflectiveTest
class ErrorResolverTest extends PubPackageResolutionTest {
  test_breakLabelOnSwitchMember() async {
    await assertErrorsInCode(r'''
class A {
  void m(int i) {
    switch (i) {
      l: case 0:
        break;
      case 1:
        break l;
    }
  }
}''', [
      error(CompileTimeErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER, 105, 1),
    ]);
  }

  test_breakLabelOnSwitchMember_language218() async {
    await assertErrorsInCode(r'''
// @dart = 2.18
class A {
  void m(int i) {
    switch (i) {
      l: case 0:
        break;
      case 1:
        break l;
    }
  }
}''', [
      error(CompileTimeErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER, 121, 1),
    ]);
  }

  test_continueLabelOnSwitch() async {
    await assertErrorsInCode(r'''
class A {
  void m(int i) {
    l: switch (i) {
      case 0:
        continue l;
    }
  }
}''', [
      error(CompileTimeErrorCode.CONTINUE_LABEL_INVALID, 70, 11),
    ]);
  }

  test_continueLabelOnSwitch_language218() async {
    await assertErrorsInCode(r'''
// @dart = 2.18
class A {
  void m(int i) {
    l: switch (i) {
      case 0:
        continue l;
    }
  }
}''', [
      error(CompileTimeErrorCode.CONTINUE_LABEL_INVALID, 86, 11),
    ]);
  }

  test_enclosingElement_invalidLocalFunction() async {
    await assertErrorsInCode(r'''
class C {
  C() {
    int get x => 0;
  }
}''', [
      error(ParserErrorCode.EXPECTED_TOKEN, 26, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 26, 3),
      error(HintCode.UNUSED_ELEMENT, 30, 1),
      error(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 32, 2),
    ]);

    var constructor = findElement.unnamedConstructor('C');
    var x = findElement.localFunction('x');
    expect(x.enclosingElement, constructor);
  }
}

@reflectiveTest
class PrefixedNamespaceTest extends PubPackageResolutionTest {
  void test_lookup_missing() {
    ClassElement element = ElementFactory.classElement2('A');
    PrefixedNamespace namespace = PrefixedNamespace('p', _toMap([element]));
    expect(namespace.get('p.B'), isNull);
  }

  void test_lookup_missing_matchesPrefix() {
    ClassElement element = ElementFactory.classElement2('A');
    PrefixedNamespace namespace = PrefixedNamespace('p', _toMap([element]));
    expect(namespace.get('p'), isNull);
  }

  void test_lookup_valid() {
    ClassElement element = ElementFactory.classElement2('A');
    PrefixedNamespace namespace = PrefixedNamespace('p', _toMap([element]));
    expect(namespace.get('p.A'), same(element));
  }

  Map<String, Element> _toMap(List<Element> elements) {
    Map<String, Element> map = HashMap<String, Element>();
    for (Element element in elements) {
      map[element.name!] = element;
    }
    return map;
  }
}

/// The class `StrictModeTest` contains tests to ensure that the correct errors
/// and warnings are reported when the analysis engine is run in strict mode.
@reflectiveTest
class StrictModeTest extends PubPackageResolutionTest with StrictModeTestCases {
  test_conditional_isNot() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  return (n is! int) ? 0 : n & 0x0F;
}
''');
  }

  test_conditional_or_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  return (n is! int || n < 0) ? 0 : n & 0x0F;
}
''');
  }

  test_if_isNot() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  if (n is! int) {
    return 0;
  } else {
    return n & 0x0F;
  }
}
''');
  }

  test_if_isNot_abrupt() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  if (n is! int) {
    return 0;
  }
  return n & 0x0F;
}
''');
  }

  test_if_or_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  if (n is! int || n < 0) {
    return 0;
  } else {
    return n & 0x0F;
  }
}
''');
  }
}

mixin StrictModeTestCases on PubPackageResolutionTest {
  test_assert_is() async {
    await assertErrorsInCode(r'''
int f(num n) {
  assert (n is int);
  return n & 0x0F;
}''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 47, 1),
    ]);
  }

  test_conditional_and_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  return (n is int && n > 0) ? n & 0x0F : 0;
}''');
  }

  test_conditional_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  return (n is int) ? n & 0x0F : 0;
}''');
  }

  test_for() async {
    await assertNoErrorsInCode(r'''
void f(List<int> list) {
  num sum = 0; // ignore: unused_local_variable
  for (int i = 0; i < list.length; i++) {
    sum += list[i];
  }
}
''');
  }

  test_forEach() async {
    await assertErrorsInCode(r'''
void f(List<int> list) {
  num sum = 0; // ignore: unused_local_variable
  for (num n in list) {
    sum += n & 0x0F;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 110, 1),
    ]);
  }

  test_if_and_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  if (n is int && n > 0) {
    return n & 0x0F;
  }
  return 0;
}''');
  }

  test_if_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  if (n is int) {
    return n & 0x0F;
  }
  return 0;
}''');
  }

  test_localVar() async {
    await assertErrorsInCode(r'''
int f() {
  num n = 1234;
  return n & 0x0F;
}''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 37, 1),
    ]);
  }
}

/// The class `StrictModeTest` contains tests to ensure that the correct errors
/// and warnings are reported when the analysis engine is run in strict mode.
@reflectiveTest
class StrictModeWithoutNullSafetyTest extends PubPackageResolutionTest
    with StrictModeTestCases, WithoutNullSafetyMixin {
  test_conditional_isNot() async {
    await assertErrorsInCode(r'''
int f(num n) {
  return (n is! int) ? 0 : n & 0x0F;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 44, 1),
    ]);
  }

  test_conditional_or_is() async {
    await assertErrorsInCode(r'''
int f(num n) {
  return (n is! int || n < 0) ? 0 : n & 0x0F;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 53, 1),
    ]);
  }

  test_if_isNot() async {
    await assertErrorsInCode(r'''
int f(num n) {
  if (n is! int) {
    return 0;
  } else {
    return n & 0x0F;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 72, 1),
    ]);
  }

  test_if_isNot_abrupt() async {
    await assertErrorsInCode(r'''
int f(num n) {
  if (n is! int) {
    return 0;
  }
  return n & 0x0F;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 63, 1),
    ]);
  }

  test_if_or_is() async {
    await assertErrorsInCode(r'''
int f(num n) {
  if (n is! int || n < 0) {
    return 0;
  } else {
    return n & 0x0F;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 81, 1),
    ]);
  }
}

@reflectiveTest
class TypePropagationTest extends PubPackageResolutionTest {
  test_assignment_null() async {
    String code = r'''
main() {
  int v; // declare
  v = null;
  return v; // return
}''';
    await resolveTestCode(code);
    assertType(findElement.localVar('v').type, 'int');
    assertType(findNode.simple('v; // return'), 'int');
  }

  test_initializer_hasStaticType() async {
    await resolveTestCode(r'''
f() {
  int v = 0;
  return v;
}''');
    assertType(findElement.localVar('v').type, 'int');
    assertType(findNode.simple('v;'), 'int');
  }

  test_initializer_hasStaticType_parameterized() async {
    await resolveTestCode(r'''
f() {
  List<int> v = <int>[];
  return v;
}''');
    assertType(findElement.localVar('v').type, 'List<int>');
    assertType(findNode.simple('v;'), 'List<int>');
  }

  test_initializer_null() async {
    await resolveTestCode(r'''
main() {
  int v = null;
  return v;
}''');
    assertType(findElement.localVar('v').type, 'int');
    assertType(findNode.simple('v;'), 'int');
  }

  test_invocation_target_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
int max(int x, int y) => 0;
''');
    await resolveTestCode('''
import 'a.dart' as helper;
main() {
  helper.max(10, 10); // marker
}''');
    assertElement(
      findNode.simple('max(10, 10)'),
      findElement.importFind('package:test/a.dart').topFunction('max'),
    );
  }

  test_is_subclass() async {
    await resolveTestCode(r'''
class A {}
class B extends A {
  B m() => this;
}
A f(A p) {
  if (p is B) {
    return p.m();
  }
  return p;
}''');
    assertElement(
      findNode.methodInvocation('p.m()'),
      findElement.method('m', of: 'B'),
    );
  }

  test_mutatedOutsideScope() async {
    // https://code.google.com/p/dart/issues/detail?id=22732
    await assertNoErrorsInCode(r'''
class Base {
}

class Derived extends Base {
  get y => null;
}

class C {
  void f(Base x) {
    x = Base();
    if (x is Derived) {
      print(x.y); // BAD
    }
    x = Base();
  }
}

void g(Base x) {
  x = Base();
  if (x is Derived) {
    print(x.y); // GOOD
  }
  x = Base();
}
''');
  }

  test_objectAccessInference_disabled_for_library_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
dynamic get hashCode => 42;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as helper;
main() {
  helper.hashCode;
}''');
    assertTypeDynamic(findNode.prefixed('helper.hashCode'));
  }

  test_objectAccessInference_disabled_for_local_getter() async {
    await assertNoErrorsInCode('''
dynamic get hashCode => null;
main() {
  hashCode; // marker
}''');
    assertTypeDynamic(findNode.simple('hashCode; // marker'));
  }

  test_objectMethodInference_disabled_for_library_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
dynamic toString = (int x) => x + 42;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as helper;
main() {
  helper.toString();
}''');
    assertTypeDynamic(
      findNode.functionExpressionInvocation('helper.toString()'),
    );
  }

  test_objectMethodInference_disabled_for_local_function() async {
    await resolveTestCode('''
main() {
  dynamic toString = () => null;
  toString(); // marker
}''');
    assertTypeDynamic(findElement.localVar('toString').type);
    assertTypeDynamic(findNode.simple('toString(); // marker'));
  }

  @failingTest
  test_propagatedReturnType_functionExpression() async {
    // TODO(scheglov) disabled because we don't resolve function expression
    await resolveTestCode(r'''
main() {
  var v = (() {return 42;})();
}''');
    assertTypeDynamic(findNode.simple('v = '));
  }
}
