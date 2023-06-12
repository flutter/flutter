// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionOverrideTest);
    defineReflectiveTests(ExtensionOverrideWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ExtensionOverrideTest extends PubPackageResolutionTest
    with ExtensionOverrideTestCases {
  test_indexExpression_read_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  int operator [](int index) => 0;
}

void f(int? a) {
  E(a)?[0];
}
''');

    assertIndexExpression(
      findNode.index('[0]'),
      readElement: findElement.method('[]', of: 'E'),
      writeElement: null,
      type: 'int?',
    );
  }

  test_indexExpression_write_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  operator []=(int index, int value) {}
}

void f(int? a) {
  E(a)?[0] = 1;
}
''');

    assertAssignment(
      findNode.assignment('[0] ='),
      readElement: null,
      readType: null,
      writeElement: findElement.method('[]=', of: 'E'),
      writeType: 'int',
      operatorElement: null,
      type: 'int?',
    );
  }

  test_methodInvocation_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  int foo() => 0;
}

void f(int? a) {
  E(a)?.foo();
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('foo();'),
      element: findElement.method('foo'),
      typeArgumentTypes: [],
      invokeType: 'int Function()',
      type: 'int?',
    );
  }

  test_propertyAccess_getter_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  int get foo => 0;
}

void f(int? a) {
  E(a)?.foo;
}
''');

    assertPropertyAccess2(
      findNode.propertyAccess('?.foo'),
      element: findElement.getter('foo'),
      type: 'int?',
    );
  }

  test_propertyAccess_setter_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  set foo(int _) {}
}

void f(int? a) {
  E(a)?.foo = 0;
}
''');
  }
}

mixin ExtensionOverrideTestCases on PubPackageResolutionTest {
  late ExtensionElement extension;
  late ExtensionOverride extensionOverride;

  void findDeclarationAndOverride(
      {required String declarationName,
      required String overrideSearch,
      String? declarationUri}) {
    if (declarationUri == null) {
      ExtensionDeclaration declaration =
          findNode.extensionDeclaration('extension $declarationName');
      extension = declaration.declaredElement as ExtensionElement;
    } else {
      extension =
          findElement.importFind(declarationUri).extension_(declarationName);
    }
    extensionOverride = findNode.extensionOverride(overrideSearch);
  }

  test_call_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  int call(String s) => 0;
}
void f(A a) {
  E(a)('');
}
''');
    findDeclarationAndOverride(declarationName: 'E ', overrideSearch: 'E(a)');
    validateOverride();
    validateCall();
  }

  test_call_noPrefix_typeArguments() async {
    // The test is failing because we're not yet doing type inference.
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  int call(T s) => 0;
}
void f(A a) {
  E<String>(a)('');
}
''');
    findDeclarationAndOverride(declarationName: 'E<T>', overrideSearch: 'E<S');
    validateOverride(typeArguments: [stringType]);
    validateCall();
  }

  test_call_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class A {}
extension E on A {
  int call(String s) => 0;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a)('');
}
''');
    findDeclarationAndOverride(
        declarationName: 'E',
        declarationUri: 'package:test/lib.dart',
        overrideSearch: 'E(a)');
    validateOverride();
    validateCall();
  }

  test_call_prefix_typeArguments() async {
    // The test is failing because we're not yet doing type inference.
    newFile('$testPackageLibPath/lib.dart', content: '''
class A {}
extension E<T> on A {
  int call(T s) => 0;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<String>(a)('');
}
''');
    findDeclarationAndOverride(
        declarationName: 'E',
        declarationUri: 'package:test/lib.dart',
        overrideSearch: 'E<S');
    validateOverride(typeArguments: [stringType]);
    validateCall();
  }

  test_getter_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  int get g => 0;
}
void f(A a) {
  E(a).g;
}
''');
    findDeclarationAndOverride(declarationName: 'E ', overrideSearch: 'E(a)');
    validateOverride();

    assertPropertyAccess2(
      findNode.propertyAccess('.g'),
      element: findElement.getter('g'),
      type: 'int',
    );
  }

  test_getter_noPrefix_noTypeArguments_functionExpressionInvocation() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  double Function(int) get g => (b) => 2.0;
}

void f(A a) {
  E(a).g(0);
}
''');
    findDeclarationAndOverride(declarationName: 'E ', overrideSearch: 'E(a)');
    validateOverride();

    var invocation = findNode.functionExpressionInvocation('g(0)');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var function = invocation.function as PropertyAccess;
    assertElement(function.propertyName, findElement.getter('g', of: 'E'));
    assertType(function.propertyName, 'double Function(int)');
  }

  test_getter_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  int get g => 0;
}
void f(A a) {
  E<int>(a).g;
}
''');
    findDeclarationAndOverride(declarationName: 'E', overrideSearch: 'E<int>');
    validateOverride(typeArguments: [intType]);

    assertPropertyAccess2(
      findNode.propertyAccess('.g'),
      element: elementMatcher(
        findElement.getter('g'),
        substitution: {'T': 'int'},
      ),
      type: 'int',
    );
  }

  test_getter_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class A {}
extension E on A {
  int get g => 0;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a).g;
}
''');
    findDeclarationAndOverride(
        declarationName: 'E',
        declarationUri: 'package:test/lib.dart',
        overrideSearch: 'E(a)');
    validateOverride();

    var importFind = findElement.importFind('package:test/lib.dart');
    assertPropertyAccess2(
      findNode.propertyAccess('.g'),
      element: importFind.getter('g'),
      type: 'int',
    );
  }

  test_getter_prefix_typeArguments() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class A {}
extension E<T> on A {
  int get g => 0;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a).g;
}
''');
    findDeclarationAndOverride(
        declarationName: 'E',
        declarationUri: 'package:test/lib.dart',
        overrideSearch: 'E<int>');
    validateOverride(typeArguments: [intType]);

    var importFind = findElement.importFind('package:test/lib.dart');
    assertPropertyAccess2(
      findNode.propertyAccess('.g'),
      element: elementMatcher(
        importFind.getter('g'),
        substitution: {'T': 'int'},
      ),
      type: 'int',
    );
  }

  test_method_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  void m() {}
}
void f(A a) {
  E(a).m();
}
''');
    findDeclarationAndOverride(declarationName: 'E ', overrideSearch: 'E(a)');
    validateOverride();
    validateInvocation();
  }

  test_method_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  void m() {}
}
void f(A a) {
  E<int>(a).m();
}
''');
    findDeclarationAndOverride(declarationName: 'E', overrideSearch: 'E<int>');
    validateOverride(typeArguments: [intType]);
    validateInvocation();
  }

  test_method_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class A {}
extension E on A {
  void m() {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a).m();
}
''');
    findDeclarationAndOverride(
        declarationName: 'E',
        declarationUri: 'package:test/lib.dart',
        overrideSearch: 'E(a)');
    validateOverride();
    validateInvocation();
  }

  test_method_prefix_typeArguments() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class A {}
extension E<T> on A {
  void m() {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a).m();
}
''');
    findDeclarationAndOverride(
        declarationName: 'E',
        declarationUri: 'package:test/lib.dart',
        overrideSearch: 'E<int>');
    validateOverride(typeArguments: [intType]);
    validateInvocation();
  }

  test_operator_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  void operator +(int offset) {}
}
void f(A a) {
  E(a) + 1;
}
''');
    findDeclarationAndOverride(declarationName: 'E ', overrideSearch: 'E(a)');
    validateOverride();
    validateBinaryExpression();
  }

  test_operator_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  void operator +(int offset) {}
}
void f(A a) {
  E<int>(a) + 1;
}
''');
    findDeclarationAndOverride(declarationName: 'E', overrideSearch: 'E<int>');
    validateOverride(typeArguments: [intType]);
    validateBinaryExpression();
  }

  test_operator_onTearOff() async {
    // https://github.com/dart-lang/sdk/issues/38653
    await assertErrorsInCode('''
extension E on int {
  v() {}
}

f(){
  E(0).v++;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER, 45, 1),
    ]);
    findDeclarationAndOverride(declarationName: 'E ', overrideSearch: 'E(0)');
    validateOverride();
  }

  test_operator_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class A {}
extension E on A {
  void operator +(int offset) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a) + 1;
}
''');
    findDeclarationAndOverride(
        declarationName: 'E',
        declarationUri: 'package:test/lib.dart',
        overrideSearch: 'E(a)');
    validateOverride();
    validateBinaryExpression();
  }

  test_operator_prefix_typeArguments() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class A {}
extension E<T> on A {
  void operator +(int offset) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a) + 1;
}
''');
    findDeclarationAndOverride(
        declarationName: 'E',
        declarationUri: 'package:test/lib.dart',
        overrideSearch: 'E<int>');
    validateOverride(typeArguments: [intType]);
    validateBinaryExpression();
  }

  test_setter_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  set s(int x) {}
}
void f(A a) {
  E(a).s = 0;
}
''');
    findDeclarationAndOverride(declarationName: 'E ', overrideSearch: 'E(a)');
    validateOverride();

    assertAssignment(
      findNode.assignment('s ='),
      readElement: null,
      readType: null,
      writeElement: findElement.setter('s', of: 'E'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_setter_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  set s(int x) {}
}
void f(A a) {
  E<int>(a).s = 0;
}
''');
    findDeclarationAndOverride(declarationName: 'E', overrideSearch: 'E<int>');
    validateOverride(typeArguments: [intType]);

    assertAssignment(
      findNode.assignment('s ='),
      readElement: null,
      readType: null,
      writeElement: elementMatcher(
        findElement.setter('s', of: 'E'),
        substitution: {'T': 'int'},
      ),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_setter_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class A {}
extension E on A {
  set s(int x) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a).s = 0;
}
''');
    findDeclarationAndOverride(
        declarationName: 'E',
        declarationUri: 'package:test/lib.dart',
        overrideSearch: 'E(a)');
    validateOverride();

    var importFind = findElement.importFind('package:test/lib.dart');
    assertAssignment(
      findNode.assignment('s ='),
      readElement: null,
      readType: null,
      writeElement: importFind.setter('s', of: 'E'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_setter_prefix_typeArguments() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class A {}
extension E<T> on A {
  set s(int x) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a).s = 0;
}
''');
    findDeclarationAndOverride(
        declarationName: 'E',
        declarationUri: 'package:test/lib.dart',
        overrideSearch: 'E<int>');
    validateOverride(typeArguments: [intType]);

    var importFind = findElement.importFind('package:test/lib.dart');
    assertAssignment(
      findNode.assignment('s ='),
      readElement: null,
      readType: null,
      writeElement: elementMatcher(
        importFind.setter('s', of: 'E'),
        substitution: {'T': 'int'},
      ),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_setterAndGetter_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  int get s => 0;
  set s(int x) {}
}
void f(A a) {
  E(a).s += 0;
}
''');
    findDeclarationAndOverride(declarationName: 'E ', overrideSearch: 'E(a)');
    validateOverride();

    assertAssignment(
      findNode.assignment('s +='),
      readElement: findElement.getter('s', of: 'E'),
      readType: 'int',
      writeElement: findElement.setter('s', of: 'E'),
      writeType: 'int',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_setterAndGetter_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  int get s => 0;
  set s(int x) {}
}
void f(A a) {
  E<int>(a).s += 0;
}
''');
    findDeclarationAndOverride(declarationName: 'E', overrideSearch: 'E<int>');
    validateOverride(typeArguments: [intType]);

    assertAssignment(
      findNode.assignment('s +='),
      readElement: elementMatcher(
        findElement.getter('s', of: 'E'),
        substitution: {'T': 'int'},
      ),
      readType: 'int',
      writeElement: elementMatcher(
        findElement.setter('s', of: 'E'),
        substitution: {'T': 'int'},
      ),
      writeType: 'int',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_setterAndGetter_prefix_noTypeArguments() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class A {}
extension E on A {
  int get s => 0;
  set s(int x) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a).s += 0;
}
''');
    findDeclarationAndOverride(
        declarationName: 'E',
        declarationUri: 'package:test/lib.dart',
        overrideSearch: 'E(a)');
    validateOverride();

    var importFind = findElement.importFind('package:test/lib.dart');
    assertAssignment(
      findNode.assignment('s +='),
      readElement: importFind.getter('s', of: 'E'),
      readType: 'int',
      writeElement: importFind.setter('s', of: 'E'),
      writeType: 'int',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_setterAndGetter_prefix_typeArguments() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class A {}
extension E<T> on A {
  int get s => 0;
  set s(int x) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a).s += 0;
}
''');
    findDeclarationAndOverride(
        declarationName: 'E',
        declarationUri: 'package:test/lib.dart',
        overrideSearch: 'E<int>');
    validateOverride(typeArguments: [intType]);

    var importFind = findElement.importFind('package:test/lib.dart');
    assertAssignment(
      findNode.assignment('s +='),
      readElement: elementMatcher(
        importFind.getter('s', of: 'E'),
        substitution: {'T': 'int'},
      ),
      readType: 'int',
      writeElement: elementMatcher(
        importFind.setter('s', of: 'E'),
        substitution: {'T': 'int'},
      ),
      writeType: 'int',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_tearOff() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  void a(int x) {}
}

f(C c) => E(c).a;
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.method('a'));
    assertType(identifier, 'void Function(int)');
  }

  void validateBinaryExpression() {
    BinaryExpression binary = extensionOverride.parent as BinaryExpression;
    Element? resolvedElement = binary.staticElement;
    expect(resolvedElement, extension.getMethod('+'));
  }

  void validateCall() {
    FunctionExpressionInvocation invocation =
        extensionOverride.parent as FunctionExpressionInvocation;
    Element? resolvedElement = invocation.staticElement;
    expect(resolvedElement, extension.getMethod('call'));

    NodeList<Expression> arguments = invocation.argumentList.arguments;
    for (int i = 0; i < arguments.length; i++) {
      expect(arguments[i].staticParameterElement, isNotNull);
    }
  }

  void validateInvocation() {
    MethodInvocation invocation = extensionOverride.parent as MethodInvocation;

    assertMethodInvocation(
      invocation,
      extension.getMethod('m'),
      'void Function()',
    );

    NodeList<Expression> arguments = invocation.argumentList.arguments;
    for (int i = 0; i < arguments.length; i++) {
      expect(arguments[i].staticParameterElement, isNotNull);
    }
  }

  void validateOverride({List<DartType>? typeArguments}) {
    expect(extensionOverride.extensionName.staticElement, extension);

    expect(extensionOverride.staticType, isNull);
    expect(extensionOverride.extensionName.staticType, isNull);

    if (typeArguments == null) {
      expect(extensionOverride.typeArguments, isNull);
    } else {
      expect(
          extensionOverride.typeArguments!.arguments
              .map((annotation) => annotation.type),
          unorderedEquals(typeArguments));
    }
    expect(extensionOverride.argumentList.arguments, hasLength(1));
  }
}

@reflectiveTest
class ExtensionOverrideWithoutNullSafetyTest extends PubPackageResolutionTest
    with ExtensionOverrideTestCases, WithoutNullSafetyMixin {}
