// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbstractSuperMemberReferenceTest);
  });
}

@reflectiveTest
class AbstractSuperMemberReferenceTest extends PubPackageResolutionTest {
  test_methodInvocation_mixin_implements() async {
    await assertErrorsInCode(r'''
class A {
  void foo(int _) {}
}

mixin M implements A {
  void bar() {
    super.foo(0);
  }
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE, 82, 3),
    ]);

    var node = findNode.methodInvocation('super.foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: M
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_methodInvocation_mixinHasConcrete() async {
    await assertNoErrorsInCode('''
class A {}

class M {
  void foo() {}
}

class B = A with M;

class C extends B {
  void bar() {
    super.foo();
  }
}
''');

    var node = findNode.methodInvocation('super.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::M::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_methodInvocation_mixinHasNoSuchMethod() async {
    await assertErrorsInCode('''
class A {
  void foo();
  noSuchMethod(im) => 42;
}

class B extends Object with A {
  void foo() => super.foo(); // ref
  noSuchMethod(im) => 87;
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE, 107, 3),
    ]);

    var node = findNode.methodInvocation('super.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_methodInvocation_superHasAbstract() async {
    await assertErrorsInCode(r'''
abstract class A {
  void foo(int _);
}

abstract class B extends A {
  void bar() {
    super.foo(0);
  }

  void foo(int _) {} // does not matter
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE, 95, 3),
    ]);

    var node = findNode.methodInvocation('super.foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_methodInvocation_superHasConcrete_mixinHasAbstract() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

abstract class B {
  void foo();
}

class C extends A with B {
  void bar() {
    super.foo(); // ref
  }
}
''');

    var node = findNode.methodInvocation('foo(); // ref');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_methodInvocation_superHasNoSuchMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo();
  noSuchMethod(im) => 42;
}

class B extends A {
  int foo() => super.foo(); // ref
  noSuchMethod(im) => 87;
}
''');

    var node = findNode.methodInvocation('super.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_methodInvocation_superSuperHasConcrete() async {
    await assertNoErrorsInCode('''
abstract class A {
  void foo() {}
}

abstract class B extends A {
  void foo();
}

class C extends B {
  void bar() {
    super.foo();
  }
}
''');

    var node = findNode.methodInvocation('super.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_propertyAccess_getter() async {
    await assertErrorsInCode(r'''
abstract class A {
  int get foo;
}

abstract class B extends A {
  bar() {
    super.foo; // ref
  }
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE, 86, 3),
    ]);

    assertPropertyAccess(
      findNode.propertyAccess('super.foo'),
      findElement.getter('foo'),
      'int',
    );
  }

  test_propertyAccess_getter_mixin_implements() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

mixin M implements A {
  void bar() {
    super.foo;
  }
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE, 81, 3),
    ]);

    assertPropertyAccess2(
      findNode.propertyAccess('super.foo'),
      element: findElement.getter('foo', of: 'A'),
      type: 'int',
    );
  }

  test_propertyAccess_getter_mixinHasNoSuchMethod() async {
    await assertErrorsInCode('''
class A {
  int get foo;
  noSuchMethod(im) => 1;
}

class B extends Object with A {
  int get foo => super.foo; // ref
  noSuchMethod(im) => 2;
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE, 108, 3),
    ]);

    assertPropertyAccess(
      findNode.propertyAccess('super.foo'),
      findElement.getter('foo', of: 'A'),
      'int',
    );
  }

  test_propertyAccess_getter_superHasNoSuchMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo;
  noSuchMethod(im) => 1;
}

class B extends A {
  get foo => super.foo; // ref
  noSuchMethod(im) => 2;
}
''');

    assertPropertyAccess(
      findNode.propertyAccess('super.foo'),
      findElement.getter('foo', of: 'A'),
      'int',
    );
  }

  test_propertyAccess_getter_superImplements() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

abstract class B implements A {
}

class C extends B {
  int get foo => super.foo; // ref
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE, 111, 3),
    ]);

    assertPropertyAccess(
      findNode.propertyAccess('super.foo'),
      findElement.getter('foo', of: 'A'),
      'int',
    );
  }

  test_propertyAccess_getter_superSuperHasConcrete() async {
    await assertNoErrorsInCode('''
abstract class A {
  int get foo => 0;
}

abstract class B extends A {
  int get foo;
}

class C extends B {
  int get bar => super.foo; // ref
}
''');

    assertPropertyAccess(
      findNode.propertyAccess('super.foo'),
      findElement.getter('foo', of: 'A'),
      'int',
    );
  }

  test_propertyAccess_method_tearOff_abstract() async {
    await assertErrorsInCode(r'''
abstract class A {
  void foo();
}

abstract class B extends A {
  void bar() {
    super.foo; // ref
  }
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE, 90, 3),
    ]);

    assertPropertyAccess(
      findNode.propertyAccess('super.foo'),
      findElement.method('foo'),
      'void Function()',
    );
  }

  test_propertyAccess_setter() async {
    await assertErrorsInCode(r'''
abstract class A {
  set foo(int _);
}

abstract class B extends A {
  void bar() {
    super.foo = 0;
  }
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE, 94, 3),
    ]);

    assertSuperExpression(findNode.super_('super.foo'));

    assertResolvedNodeText(findNode.assignment('foo ='), r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: self::@class::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_propertyAccess_setter_mixin_implements() async {
    await assertErrorsInCode(r'''
class A {
  set foo(int _) {}
}

mixin M implements A {
  void bar() {
    super.foo = 0;
  }
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE, 81, 3),
    ]);

    assertSuperExpression(findNode.super_('super.foo'));

    assertResolvedNodeText(findNode.assignment('foo ='), r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: M
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: self::@class::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_propertyAccess_setter_mixinHasNoSuchMethod() async {
    await assertErrorsInCode('''
class A {
  set foo(int a);
  noSuchMethod(im) {}
}

class B extends Object with A {
  set foo(int a) => super.foo = a; // ref
  noSuchMethod(im) {}
}
''', [
      error(CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE, 111, 3),
    ]);

    assertSuperExpression(findNode.super_('super.foo'));

    assertResolvedNodeText(findNode.assignment('foo ='), r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: a
    parameter: self::@class::A::@setter::foo::@parameter::a
    staticElement: self::@class::B::@setter::foo::@parameter::a
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_propertyAccess_setter_superHasNoSuchMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  set foo(int a);
  noSuchMethod(im) => 1;
}

class B extends A {
  set foo(int a) => super.foo = a; // ref
  noSuchMethod(im) => 2;
}
''');

    assertSuperExpression(findNode.super_('super.foo'));

    assertResolvedNodeText(findNode.assignment('foo ='), r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: a
    parameter: self::@class::A::@setter::foo::@parameter::a
    staticElement: self::@class::B::@setter::foo::@parameter::a
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_propertyAccess_setter_superSuperHasConcrete() async {
    await assertNoErrorsInCode('''
abstract class A {
  void set foo(int _) {}
}

abstract class B extends A {
  void set foo(int _);
}

class C extends B {
  void bar() {
    super.foo = 0;
  }
}
''');

    assertSuperExpression(findNode.super_('super.foo'));

    assertResolvedNodeText(findNode.assignment('foo ='), r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: self::@class::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }
}
