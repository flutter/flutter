// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDriverResolutionTest);
  });
}

@reflectiveTest
class MixinDriverResolutionTest extends PubPackageResolutionTest {
  test_accessor_getter() async {
    await assertNoErrorsInCode(r'''
mixin M {
  int get g => 0;
}
''');

    var element = findElement.mixin('M');

    var accessors = element.accessors;
    expect(accessors, hasLength(1));

    var gElement = accessors[0];
    assertElementName(gElement, 'g', offset: 20);

    var gNode = findNode.methodDeclaration('g =>');
    expect(gNode.declaredElement, same(gElement));

    var fields = element.fields;
    expect(fields, hasLength(1));
    assertElementName(fields[0], 'g', isSynthetic: true);
  }

  test_accessor_method() async {
    await assertNoErrorsInCode(r'''
mixin M {
  void foo() {}
}
''');

    var element = findElement.mixin('M');

    var methods = element.methods;
    expect(methods, hasLength(1));

    var fooElement = methods[0];
    assertElementName(fooElement, 'foo', offset: 17);

    var fooNode = findNode.methodDeclaration('foo()');
    expect(fooNode.declaredElement, same(fooElement));
  }

  test_accessor_setter() async {
    await assertNoErrorsInCode(r'''
mixin M {
  void set s(int _) {}
}
''');

    var element = findElement.mixin('M');

    var accessors = element.accessors;
    expect(accessors, hasLength(1));

    var sElement = accessors[0];
    assertElementName(sElement, 's=', offset: 21);

    var gNode = findNode.methodDeclaration('s(int _)');
    expect(gNode.declaredElement, same(sElement));

    var fields = element.fields;
    expect(fields, hasLength(1));
    assertElementName(fields[0], 's', isSynthetic: true);
  }

  test_classDeclaration_with() async {
    await assertNoErrorsInCode(r'''
mixin M {}
class A extends Object with M {} // A
''');

    var mElement = findElement.mixin('M');

    var aElement = findElement.class_('A');
    assertElementTypes(aElement.mixins, ['M']);

    var mRef = findNode.namedType('M {} // A');
    assertNamedType(mRef, mElement, 'M');
  }

  test_classTypeAlias_with() async {
    await assertNoErrorsInCode(r'''
mixin M {}
class A = Object with M;
''');

    var mElement = findElement.mixin('M');

    var aElement = findElement.class_('A');
    assertElementTypes(aElement.mixins, ['M']);

    var mRef = findNode.namedType('M;');
    assertNamedType(mRef, mElement, 'M');
  }

  test_commentReference() async {
    await assertNoErrorsInCode(r'''
const a = 0;

/// Reference [a] in documentation.
mixin M {}
''');

    var aRef = findNode.commentReference('a]').expression;
    assertElement(aRef, findElement.topGet('a'));
    assertTypeNull(aRef);
  }

  test_element() async {
    await assertNoErrorsInCode(r'''
mixin M {}
''');

    var mixin = findNode.mixin('mixin M');
    var element = findElement.mixin('M');
    assertElement(mixin, element);

    expect(element.typeParameters, isEmpty);

    expect(element.supertype, isNull);
    expect(element.thisType.isDartCoreObject, isFalse);

    assertElementTypes(
      element.superclassConstraints,
      ['Object'],
    );
    assertElementTypes(element.interfaces, []);
  }

  test_element_allSupertypes() async {
    await assertNoErrorsInCode(r'''
class A {}
class B {}
class C {}

mixin M1 on A, B {}
mixin M2 on A implements B, C {}
''');

    assertElementTypes(
      findElement.mixin('M1').allSupertypes,
      ['Object', 'A', 'B'],
    );
    assertElementTypes(
      findElement.mixin('M2').allSupertypes,
      ['Object', 'A', 'B', 'C'],
    );
  }

  test_element_allSupertypes_generic() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {}
class B<T> extends A<int, T> {}

mixin M1 on A<int, double> {}
mixin M2 on B<String> {}
''');

    assertElementTypes(
      findElement.mixin('M1').allSupertypes,
      ['Object', 'A<int, double>'],
    );
    assertElementTypes(
      findElement.mixin('M2').allSupertypes,
      ['Object', 'A<int, String>', 'B<String>'],
    );
  }

  test_field() async {
    await assertNoErrorsInCode(r'''
mixin M<T> {
  late T f;
}
''');

    var element = findElement.mixin('M');

    var typeParameters = element.typeParameters;
    expect(typeParameters, hasLength(1));

    var tElement = typeParameters.single;
    assertElementName(tElement, 'T', offset: 8);
    assertEnclosingElement(tElement, element);

    var tNode = findNode.typeParameter('T> {');
    assertElement(tNode.declaredElement, tElement);

    var fields = element.fields;
    expect(fields, hasLength(1));

    var fElement = fields[0];
    assertElementName(fElement, 'f', offset: 22);
    assertEnclosingElement(fElement, element);

    var fNode = findNode.variableDeclaration('f;');
    assertElement(fNode.declaredElement, fElement);

    assertNamedType(findNode.namedType('T f'), tElement, 'T');

    var accessors = element.accessors;
    expect(accessors, hasLength(2));
    assertElementName(accessors[0], 'f', isSynthetic: true);
    assertElementName(accessors[1], 'f=', isSynthetic: true);
  }

  test_implementsClause() async {
    await assertNoErrorsInCode(r'''
class A {}
class B {}

mixin M implements A, B {} // M
''');

    var element = findElement.mixin('M');
    assertElementTypes(element.interfaces, ['A', 'B']);

    var aRef = findNode.namedType('A, ');
    assertNamedType(aRef, findElement.class_('A'), 'A');

    var bRef = findNode.namedType('B {} // M');
    assertNamedType(bRef, findElement.class_('B'), 'B');
  }

  test_invalid_unresolved_before_mixin() async {
    await assertErrorsInCode(r'''
abstract class A {
  int foo();
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

abstract class X extends A with U1, U2, M {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 121, 2),
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 125, 2),
      error(
          CompileTimeErrorCode
              .MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
          129,
          1),
    ]);
  }

  test_lookUpMemberInInterfaces_Object() async {
    await assertNoErrorsInCode(r'''
class Foo {}

mixin UnhappyMixin on Foo {
  String toString() => '$runtimeType';
}
''');
  }

  test_metadata() async {
    await assertNoErrorsInCode(r'''
const a = 0;

@a
mixin M {}
''');

    var a = findElement.topGet('a');
    var element = findElement.mixin('M');

    var metadata = element.metadata;
    expect(metadata, hasLength(1));
    expect(metadata[0].element, same(a));

    var annotation = findNode.annotation('@a');
    assertElement(annotation, a);
    expect(annotation.elementAnnotation, same(metadata[0]));
  }

  test_methodCallTypeInference_mixinType() async {
    await assertErrorsInCode('''
g(M<T> f<T>()) {
  C<int> c = f();
}

class C<T> {}

mixin M<T> on C<T> {}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 26, 1),
    ]);
    var fInvocation = findNode.functionExpressionInvocation('f()');
    assertInvokeType(fInvocation, 'M<int> Function()');
  }

  test_onClause() async {
    await assertNoErrorsInCode(r'''
class A {}
class B {}

mixin M on A, B {} // M
''');

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, ['A', 'B']);

    var aRef = findNode.namedType('A, ');
    assertNamedType(aRef, findElement.class_('A'), 'A');

    var bRef = findNode.namedType('B {} // M');
    assertNamedType(bRef, findElement.class_('B'), 'B');
  }

  test_recursiveInterfaceInheritance_implements() async {
    await assertErrorsInCode(r'''
mixin A implements B {}
mixin B implements A {}''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 30, 1),
    ]);
  }

  test_recursiveInterfaceInheritance_on() async {
    await assertErrorsInCode(r'''
mixin A on B {}
mixin B on A {}''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 22, 1),
    ]);
  }

  test_recursiveInterfaceInheritanceOn() async {
    await assertErrorsInCode(r'''
mixin A on A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_ON, 6, 1),
    ]);
  }

  test_superInvocation_getter() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
}

mixin M on A {
  void bar() {
    super.foo;
  }
}

class X extends A with M {}
''');

    var access = findNode.propertyAccess('super.foo;');
    assertElement(access, findElement.getter('foo'));
    assertType(access, 'int');
  }

  test_superInvocation_method() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo(int x) {}
}

mixin M on A {
  void bar() {
    super.foo(42);
  }
}

class X extends A with M {}
''');

    var invocation = findNode.methodInvocation('foo(42)');
    assertElement(invocation, findElement.method('foo'));
    assertInvokeType(invocation, 'void Function(int)');
    assertType(invocation, 'void');
  }

  test_superInvocation_setter() async {
    await assertNoErrorsInCode(r'''
class A {
  void set foo(int _) {}
}

mixin M on A {
  void bar() {
    super.foo = 0;
  }
}

class X extends A with M {}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
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
}
