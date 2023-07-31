// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixedIdentifierResolutionTest);
    defineReflectiveTests(PrefixedIdentifierResolutionWithoutNullSafetyTest);
  });
}

@reflectiveTest
class PrefixedIdentifierResolutionTest extends PubPackageResolutionTest
    with PrefixedIdentifierResolutionTestCases {
  test_deferredImportPrefix_loadLibrary_optIn_fromOptOut() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    await assertErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' deferred as a;

main() {
  a.loadLibrary;
}
''', [
      error(HintCode.UNUSED_IMPORT, 22, 8),
    ]);

    var import = findElement.importFind('package:test/a.dart');

    assertPrefixedIdentifier(
      findNode.prefixed('a.loadLibrary'),
      element: elementMatcher(
        import.importedLibrary.loadLibraryFunction,
        isLegacy: true,
      ),
      type: 'Future<dynamic>* Function()*',
    );
  }

  test_enum_read() async {
    await assertNoErrorsInCode('''
enum E {
  v;
  int get foo => 0;
}

void f(E e) {
  e.foo;
}
''');

    var prefixed = findNode.prefixed('e.foo');
    assertPrefixedIdentifier(
      prefixed,
      element: findElement.getter('foo'),
      type: 'int',
    );

    assertSimpleIdentifier(
      prefixed.prefix,
      element: findElement.parameter('e'),
      type: 'E',
    );

    assertSimpleIdentifier(
      prefixed.identifier,
      element: findElement.getter('foo'),
      type: 'int',
    );
  }

  test_enum_write() async {
    await assertNoErrorsInCode('''
enum E {
  v;
  set foo(int _) {}
}

void f(E e) {
  e.foo = 1;
}
''');

    var assignment = findNode.assignment('foo = 1');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: e
      staticElement: self::@function::f::@parameter::e
      staticType: E
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: self::@enum::E::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@enum::E::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_hasReceiver_typeAlias_staticGetter() async {
    await assertNoErrorsInCode(r'''
class A {
  static int get foo => 0;
}

typedef B = A;

void f() {
  B.foo;
}
''');

    assertPrefixedIdentifier(
      findNode.prefixed('B.foo'),
      element: findElement.getter('foo'),
      type: 'int',
    );

    assertTypeAliasRef(
      findNode.simple('B.foo'),
      findElement.typeAlias('B'),
    );

    assertSimpleIdentifier(
      findNode.simple('foo;'),
      element: findElement.getter('foo'),
      type: 'int',
    );
  }

  test_implicitCall_tearOff_nullable() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int call() => 0;
}

A? a;
''');
    await assertErrorsInCode('''
import 'a.dart';

int Function() foo() {
  return a;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 50, 1),
    ]);

    var identifier = findNode.simple('a;');
    assertElement(
      identifier,
      findElement.importFind('package:test/a.dart').topGet('a'),
    );
    assertType(identifier, 'A?');
  }

  test_read_typedef_interfaceType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef A = List<int>;
''');

    await assertNoErrorsInCode('''
import 'a.dart' as p;

void f() {
  p.A;
}
''');

    var importFind = findElement.importFind('package:test/a.dart');
    var A = importFind.typeAlias('A');

    var prefixed = findNode.prefixed('p.A');
    assertPrefixedIdentifier(
      prefixed,
      element: A,
      type: 'Type',
    );

    assertImportPrefix(prefixed.prefix, importFind.prefix);

    assertSimpleIdentifier(
      prefixed.identifier,
      element: A,
      type: 'Type',
    );
  }
}

mixin PrefixedIdentifierResolutionTestCases on PubPackageResolutionTest {
  test_class_read() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f(A a) {
  a.foo;
}
''');

    var prefixed = findNode.prefixed('a.foo');
    assertPrefixedIdentifier(
      prefixed,
      element: findElement.getter('foo'),
      type: 'int',
    );

    assertSimpleIdentifier(
      prefixed.prefix,
      element: findElement.parameter('a'),
      type: 'A',
    );

    assertSimpleIdentifier(
      prefixed.identifier,
      element: findElement.getter('foo'),
      type: 'int',
    );
  }

  test_class_read_staticMethod_generic() async {
    await assertNoErrorsInCode('''
class A<T> {
  static void foo<U>(int a, U u) {}
}

void f() {
  A.foo;
}
''');

    var prefixed = findNode.prefixed('A.foo');
    assertPrefixedIdentifier(
      prefixed,
      element: findElement.method('foo'),
      type: 'void Function<U>(int, U)',
    );

    assertSimpleIdentifier(
      prefixed.prefix,
      element: findElement.class_('A'),
      type: null,
    );

    assertSimpleIdentifier(
      prefixed.identifier,
      element: findElement.method('foo'),
      type: 'void Function<U>(int, U)',
    );
  }

  test_class_read_staticMethod_ofGenericClass() async {
    await assertNoErrorsInCode('''
class A<T> {
  static void foo(int a) {}
}

void f() {
  A.foo;
}
''');

    var prefixed = findNode.prefixed('A.foo');
    assertPrefixedIdentifier(
      prefixed,
      element: findElement.method('foo'),
      type: 'void Function(int)',
    );

    assertSimpleIdentifier(
      prefixed.prefix,
      element: findElement.class_('A'),
      type: null,
    );

    assertSimpleIdentifier(
      prefixed.identifier,
      element: findElement.method('foo'),
      type: 'void Function(int)',
    );
  }

  test_class_read_typedef_functionType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef A = void Function();
''');

    await assertNoErrorsInCode('''
import 'a.dart' as p;

void f() {
  p.A;
}
''');

    var importFind = findElement.importFind('package:test/a.dart');
    var A = importFind.typeAlias('A');

    var prefixed = findNode.prefixed('p.A');
    assertPrefixedIdentifier(
      prefixed,
      element: A,
      type: 'Type',
    );

    assertImportPrefix(prefixed.prefix, importFind.prefix);

    assertSimpleIdentifier(
      prefixed.identifier,
      element: A,
      type: 'Type',
    );
  }

  test_class_readWrite_assignment() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f(A a) {
  a.foo += 1;
}
''');

    var assignment = findNode.assignment('foo += 1');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@getter::foo
  readType: int
  writeElement: self::@class::A::@setter::foo
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A*
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: ParameterMember
      base: dart:core::@class::num::@method::+::@parameter::other
      isLegacy: true
    staticType: int*
  readElement: self::@class::A::@getter::foo
  readType: int*
  writeElement: self::@class::A::@setter::foo
  writeType: int*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
  }

  test_class_write() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f(A a) {
  a.foo = 1;
}
''');

    var assignment = findNode.assignment('foo = 1');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: self::@class::A::@setter::foo::@parameter::_foo
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
    } else {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
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
    literal: 1
    parameter: self::@class::A::@setter::foo::@parameter::_foo
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::foo
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
    }
  }

  test_dynamic_explicitCore_withPrefix() async {
    await assertNoErrorsInCode(r'''
import 'dart:core' as mycore;

main() {
  mycore.dynamic;
}
''');

    assertPrefixedIdentifier(
      findNode.prefixed('mycore.dynamic'),
      element: dynamicElement,
      type: 'Type',
    );
  }

  test_functionType_call_read() async {
    await assertNoErrorsInCode('''
void f(int Function(String) a) {
  a.call;
}
''');

    assertPrefixedIdentifier(
      findNode.prefixed('.call;'),
      element: null,
      type: 'int Function(String)',
    );
  }

  test_implicitCall_tearOff() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int call() => 0;
}

A a;
''');
    await assertNoErrorsInCode('''
import 'a.dart';

int Function() foo() {
  return a;
}
''');

    var identifier = findNode.simple('a;');
    assertElement(
      identifier,
      findElement.importFind('package:test/a.dart').topGet('a'),
    );
    assertType(identifier, 'A');
  }
}

@reflectiveTest
class PrefixedIdentifierResolutionWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with PrefixedIdentifierResolutionTestCases, WithoutNullSafetyMixin {}
