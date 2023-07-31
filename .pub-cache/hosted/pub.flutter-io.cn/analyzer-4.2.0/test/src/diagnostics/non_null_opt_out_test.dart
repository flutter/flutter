// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNullOptOutTest);
  });
}

@reflectiveTest
class NonNullOptOutTest extends PubPackageResolutionTest {
  ImportFindElement get _import_a {
    return findElement.importFind('package:test/a.dart');
  }

  test_assignment_indexExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void operator[]=(int a, int b) {}
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a[null] = null;
}
''');

    var assignment = findNode.assignment(' = null;');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::main::@parameter::a
      staticType: A*
    leftBracket: [
    index: NullLiteral
      literal: null
      parameter: ParameterMember
        base: package:test/a.dart::@class::A::@method::[]=::@parameter::a
        isLegacy: true
      staticType: Null*
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: NullLiteral
    literal: null
    parameter: ParameterMember
      base: package:test/a.dart::@class::A::@method::[]=::@parameter::b
      isLegacy: true
    staticType: Null*
  readElement: <null>
  readType: null
  writeElement: MethodMember
    base: package:test/a.dart::@class::A::@method::[]=
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: Null*
''');
  }

  test_assignment_prefixedIdentifier_instanceTarget_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a.foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::main::@parameter::a
      staticType: A*
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@class::A::@setter::foo::@parameter::_foo
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@class::A::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_prefixedIdentifier_instanceTarget_extension_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  void set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a.foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::main::@parameter::a
      staticType: A*
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@extension::E::@setter::foo::@parameter::_
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@extension::E::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_prefixedIdentifier_staticTarget_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A.foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: package:test/a.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@class::A::@setter::foo::@parameter::_foo
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@class::A::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_prefixedIdentifier_staticTarget_extension_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  static int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  E.foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      staticElement: package:test/a.dart::@extension::E
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@extension::E::@setter::foo::@parameter::_foo
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@extension::E::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_prefixedIdentifier_topLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
int foo = 0;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart' as p;

main() {
  p.foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      staticElement: self::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@setter::foo::@parameter::_foo
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_propertyAccess_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A().foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: SimpleIdentifier
            token: A
            staticElement: package:test/a.dart::@class::A
            staticType: null
          type: A*
        staticElement: ConstructorMember
          base: package:test/a.dart::@class::A::@constructor::•
          isLegacy: true
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A*
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@class::A::@setter::foo::@parameter::_foo
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@class::A::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_propertyAccess_extension_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  void set foo(int a) {}
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A().foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: SimpleIdentifier
            token: A
            staticElement: package:test/a.dart::@class::A
            staticType: null
          type: A*
        staticElement: ConstructorMember
          base: package:test/a.dart::@class::A::@constructor::•
          isLegacy: true
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A*
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@extension::E::@setter::foo::@parameter::a
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@extension::E::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_propertyAccess_extensionOverride_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  void set foo(int a) {}
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  E(a).foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      extensionName: SimpleIdentifier
        token: E
        staticElement: package:test/a.dart::@extension::E
        staticType: null
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::main::@parameter::a
            staticType: A*
        rightParenthesis: )
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@extension::E::@setter::foo::@parameter::a
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@extension::E::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_propertyAccess_superTarget() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  void bar() {
    super.foo = 0;
  }
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B*
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@class::A::@setter::foo::@parameter::_foo
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@class::A::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_simpleIdentifier_topLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
int foo = 0;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  foo = null;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: NullLiteral
    literal: null
    parameter: ParameterMember
      base: package:test/a.dart::@setter::foo::@parameter::_foo
      isLegacy: true
    staticType: Null*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: Null*
''');
  }

  test_binaryExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int operator+(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a + null;
}
''');
    var binaryExpression = findNode.binary('a +');
    assertInvokeType(binaryExpression, 'int* Function(int*)*');
    assertType(binaryExpression, 'int*');

    var element = binaryExpression.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('+'));
  }

  test_functionExpressionInvocation() async {
    newFile('$testPackageLibPath/a.dart', r'''
int Function(int, int?)? foo;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  foo(null, null);
}
''');
    var invocation = findNode.functionExpressionInvocation('foo');
    assertInvokeType(invocation, 'int* Function(int*, int*)*');
    assertType(invocation, 'int*');

    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*, int*)*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.topGet('foo'));
  }

  test_functionExpressionInvocation_call() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int call(int a, int? b) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a(null, null);
}
''');
    var invocation = findNode.functionExpressionInvocation('a(null');
    assertInvokeType(invocation, 'int* Function(int*, int*)*');
    assertType(invocation, 'int*');

    var identifier = invocation.function;
    assertType(identifier, 'A*');

    var element = invocation.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('call'));
  }

  test_functionExpressionInvocation_extension_staticTarget() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  static int Function(int) get foo => (_) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  E.foo(null);
}
''');
    var invocation = findNode.functionExpressionInvocation('foo');
    assertInvokeType(invocation, 'int* Function(int*)*');
    assertType(invocation, 'int*');

    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*)*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_instanceCreation() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A(int a, int? b);
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A(null, null);
}
''');
    var instanceCreation = findNode.instanceCreation('A(null');
    assertType(instanceCreation, 'A*');

    _assertLegacyMember(
      instanceCreation.constructorName.staticElement,
      _import_a.unnamedConstructor('A'),
    );
  }

  test_instanceCreation_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A(T a, T? b);
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A<int>(null, null);
}
''');
    var instanceCreation = findNode.instanceCreation('A<int>(null');
    assertType(instanceCreation, 'A<int*>*');

    _assertLegacyMember(
      instanceCreation.constructorName.staticElement,
      _import_a.unnamedConstructor('A'),
      expectedSubstitution: {'T': 'int*'},
    );
  }

  test_instanceCreation_generic_instantiateToBounds() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T extends num> {}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

var v = A();
''');

    var v = findElement.topVar('v');
    assertType(v.type, 'A<num*>*');
  }

  test_methodInvocation_extension_functionTarget() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on void Function() {
  int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(void Function() a) {
  a.foo(null);
}
''');
    var invocation = findNode.methodInvocation('foo');
    assertInvokeType(invocation, 'int* Function(int*)*');
    assertType(invocation, 'int*');

    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*)*');

    var element = identifier.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('foo'));
  }

  test_methodInvocation_extension_interfaceTarget() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  0.foo(null);
}
''');
    var invocation = findNode.methodInvocation('foo');
    assertInvokeType(invocation, 'int* Function(int*)*');
    assertType(invocation, 'int*');

    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*)*');

    var element = identifier.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('foo'));
  }

  test_methodInvocation_extension_nullTarget() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  void bar() {
    foo(null);
  }
}
''');
    var invocation = findNode.methodInvocation('foo');
    assertInvokeType(invocation, 'int* Function(int*)*');
    assertType(invocation, 'int*');

    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*)*');

    var element = identifier.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('foo'));
  }

  test_methodInvocation_extension_staticTarget() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  static int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  E.foo(null);
}
''');
    var invocation = findNode.methodInvocation('foo');
    assertInvokeType(invocation, 'int* Function(int*)*');
    assertType(invocation, 'int*');

    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*)*');

    var element = identifier.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('foo'));
  }

  test_methodInvocation_extensionOverride() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  E(0).foo(null);
}
''');
    var invocation = findNode.methodInvocation('foo');
    assertInvokeType(invocation, 'int* Function(int*)*');
    assertType(invocation, 'int*');

    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*)*');

    var element = identifier.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('foo'));
  }

  test_methodInvocation_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
int foo(int a, int? b) => 0;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  foo(null, null);
}
''');
    var invocation = findNode.methodInvocation('foo');
    assertInvokeType(invocation, 'int* Function(int*, int*)*');
    assertType(invocation, 'int*');

    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*, int*)*');

    var element = identifier.staticElement as FunctionElement;
    _assertLegacyMember(element, _import_a.topFunction('foo'));
  }

  test_methodInvocation_function_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
int foo(int a, int? b) => 0;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart' as p;

main() {
  p.foo(null, null);
}
''');
    var invocation = findNode.methodInvocation('foo');
    assertInvokeType(invocation, 'int* Function(int*, int*)*');
    assertType(invocation, 'int*');

    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*, int*)*');

    var element = identifier.staticElement as FunctionElement;
    _assertLegacyMember(element, _import_a.topFunction('foo'));
  }

  test_methodInvocation_method_cascade() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a..foo(null, null);
}
''');
    var invocation = findNode.methodInvocation('foo(');
    assertInvokeType(invocation, 'int* Function(int*, int*)*');
    assertType(invocation, 'int*');

    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*, int*)*');

    var element = identifier.staticElement as MethodElement;
    assertType(element.type, 'int* Function(int*, int*)*');
  }

  test_methodInvocation_method_interfaceTarget() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a.foo(null, null);
}
''');
    var invocation = findNode.methodInvocation('a.foo');
    assertInvokeType(invocation, 'int* Function(int*, int*)*');
    assertType(invocation, 'int*');

    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*, int*)*');

    var element = identifier.staticElement as MethodElement;
    assertType(element.type, 'int* Function(int*, int*)*');
  }

  test_methodInvocation_method_nullTarget() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  m() {
    foo(null, null);
  }
}
''');
    var invocation = findNode.methodInvocation('foo');
    assertInvokeType(invocation, 'int* Function(int*, int*)*');
    assertType(invocation, 'int*');

    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*, int*)*');

    var element = identifier.staticElement as MethodElement;
    assertType(element.type, 'int* Function(int*, int*)*');
  }

  test_methodInvocation_method_staticTarget() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static int foo(int a, int? b) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A.foo(null, null);
}
''');
    var invocation = findNode.methodInvocation('A.foo');
    assertInvokeType(invocation, 'int* Function(int*, int*)*');
    assertType(invocation, 'int*');

    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*, int*)*');

    var element = identifier.staticElement as MethodElement;
    assertType(element.type, 'int* Function(int*, int*)*');
  }

  test_methodInvocation_method_superTarget() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  m() {
    super.foo(null, null);
  }
}
''');
    var invocation = findNode.methodInvocation('foo');
    assertInvokeType(invocation, 'int* Function(int*, int*)*');
    assertType(invocation, 'int*');

    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*, int*)*');

    var element = identifier.staticElement as MethodElement;
    assertType(element.type, 'int* Function(int*, int*)*');
  }

  test_nnbd_optOut_invalidSyntax() async {
    await assertErrorsInCode('''
// @dart = 2.2
// NNBD syntax is not allowed
f(x, z) { (x is String?) ? x : z; }
''', [error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 67, 1)]);
  }

  test_nnbd_optOut_late() async {
    await assertNoErrorsInCode('''
// @dart = 2.2
class C {
  // "late" is allowed as an identifier
  int late;
}
''');
  }

  test_nnbd_optOut_transformsOptedInSignatures() async {
    await assertNoErrorsInCode('''
// @dart = 2.2
f(String x) {
  x + null; // OK because we're in a nullable library.
}
''');
  }

  test_postfixExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A operator+(int a) => this;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a++;
}
''');
    var prefixExpression = findNode.postfix('a++');
    assertType(prefixExpression, 'A*');

    var element = prefixExpression.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('+'));
  }

  test_prefixExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int operator-() => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  -a;
}
''');
    var prefixExpression = findNode.prefix('-a');
    assertType(prefixExpression, 'int*');

    var element = prefixExpression.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('unary-'));
  }

  test_read_indexExpression_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int operator[](int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a[null];
}
''');
    var indexExpression = findNode.index('a[');
    assertType(indexExpression, 'int*');

    var element = indexExpression.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('[]'));
  }

  test_read_prefixedIdentifier_instanceTarget_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('a.foo');
    assertType(prefixedIdentifier, 'int*');

    var identifier = prefixedIdentifier.identifier;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_prefixedIdentifier_instanceTarget_extension_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('a.foo');
    assertType(prefixedIdentifier, 'int*');

    var identifier = prefixedIdentifier.identifier;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_prefixedIdentifier_staticTarget_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static int foo;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('A.foo');
    assertType(prefixedIdentifier, 'int*');

    var identifier = prefixedIdentifier.identifier;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_prefixedIdentifier_staticTarget_class_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('A.foo');
    assertType(prefixedIdentifier, 'int* Function(int*)*');

    var identifier = prefixedIdentifier.identifier;
    assertType(identifier, 'int* Function(int*)*');

    var element = identifier.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('foo'));
  }

  test_read_prefixedIdentifier_staticTarget_extension_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E {
  static int foo;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  E.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('E.foo');
    assertType(prefixedIdentifier, 'int*');

    var identifier = prefixedIdentifier.identifier;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_prefixedIdentifier_staticTarget_extension_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E {
  static int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  E.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('E.foo');
    assertType(prefixedIdentifier, 'int* Function(int*)*');

    var identifier = prefixedIdentifier.identifier;
    assertType(identifier, 'int* Function(int*)*');

    var element = identifier.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('foo'));
  }

  test_read_prefixedIdentifier_topLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
int foo = 0;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart' as p;

main() {
  p.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('p.foo');
    assertType(prefixedIdentifier, 'int*');

    var identifier = prefixedIdentifier.identifier;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.topGet('foo'));
  }

  test_read_propertyAccessor_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A().foo;
}
''');
    var propertyAccess = findNode.propertyAccess('foo');
    assertType(propertyAccess, 'int*');

    var identifier = propertyAccess.propertyName;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_propertyAccessor_class_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo() => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A().foo;
}
''');
    var propertyAccess = findNode.propertyAccess('foo');
    assertType(propertyAccess, 'int* Function()*');

    var identifier = propertyAccess.propertyName;
    assertType(identifier, 'int* Function()*');

    var element = identifier.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('foo'));
  }

  test_read_propertyAccessor_extensionOverride_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  E(a).foo;
}
''');
    var propertyAccess = findNode.propertyAccess('foo');
    assertType(propertyAccess, 'int*');

    var identifier = propertyAccess.propertyName;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_propertyAccessor_superTarget() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  void bar() {
    super.foo;
  }
}
''');
    var propertyAccess = findNode.propertyAccess('foo');
    assertType(propertyAccess, 'int*');

    var identifier = propertyAccess.propertyName;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_simpleIdentifier_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  void bar() {
    foo;
  }
}
''');
    var identifier = findNode.simple('foo');
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_simpleIdentifier_class_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  void bar() {
    foo;
  }
}
''');
    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*)*');

    var element = identifier.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('foo'));
  }

  test_read_simpleIdentifier_extension_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  void bar() {
    foo;
  }
}
''');
    var identifier = findNode.simple('foo');
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_simpleIdentifier_extension_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  void bar() {
    foo;
  }
}
''');
    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*)*');

    var element = identifier.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('foo'));
  }

  test_read_simpleIdentifier_topLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
int foo = 0;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  foo;
}
''');
    var identifier = findNode.simple('foo');
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.topGet('foo'));
  }

  test_superConstructorInvocation() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A(int a, int? b);
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  B() : super(null, null);
}
''');
    var instanceCreation = findNode.superConstructorInvocation('super(');

    _assertLegacyMember(
      instanceCreation.staticElement,
      _import_a.unnamedConstructor('A'),
    );
  }

  void _assertLegacyMember(
    Element? actualElement,
    Element declaration, {
    Map<String, String> expectedSubstitution = const {},
  }) {
    var actualMember = actualElement as Member;
    expect(actualMember.declaration, same(declaration));
    expect(actualMember.isLegacy, isTrue);
    assertSubstitution(actualMember.substitution, expectedSubstitution);
  }
}
