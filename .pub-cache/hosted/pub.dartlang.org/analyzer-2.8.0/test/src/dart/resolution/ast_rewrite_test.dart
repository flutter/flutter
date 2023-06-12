// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstRewriteImplicitCallReferenceTest);
    defineReflectiveTests(AstRewriteMethodInvocationTest);
    defineReflectiveTests(AstRewritePrefixedIdentifierTest);

    // TODO(srawlins): Add AstRewriteInstanceCreationExpressionTest test, likely
    // moving many test cases from ConstructorReferenceResolutionTest,
    // FunctionReferenceResolutionTest, and TypeLiteralResolutionTest.
    // TODO(srawlins): Add AstRewritePropertyAccessTest test, likely
    // moving many test cases from ConstructorReferenceResolutionTest,
    // FunctionReferenceResolutionTest, and TypeLiteralResolutionTest.
  });
}

@reflectiveTest
class AstRewriteImplicitCallReferenceTest extends PubPackageResolutionTest {
  test_assignment_indexExpression() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

void Function(int) foo(C c) {
  var map = <int, C>{};
  return map[1] = c;
}
''');

    assertImplicitCallReference(
      findNode.implicitCallReference('map[1] = c'),
      findElement.method('call'),
      'void Function(int)',
    );
  }

  test_explicitTypeArguments() async {
    await assertNoErrorsInCode('''
class C {
  T call<T>(T t) => t;
}

void foo() {
  var c = C();
  c<int>;
}
''');

    assertImplicitCallReference(
      findNode.implicitCallReference('c<int>'),
      findElement.method('call'),
      'int Function(int)',
    );
  }

  test_ifNull() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

void Function(int) foo(C? c1, C c2) {
  return c1 ?? c2;
}
''');

    assertImplicitCallReference(
      findNode.implicitCallReference('c1 ?? c2'),
      findElement.method('call'),
      'void Function(int)',
    );
  }

  test_listLiteral_element() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

List<void Function(int)> foo(C c) {
  return [c];
}
''');

    assertImplicitCallReference(
      findNode.implicitCallReference('c]'),
      findElement.method('call'),
      'void Function(int)',
    );
  }

  test_listLiteral_forElement() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

List<void Function(int)> foo(C c) {
  return [
    for (var _ in [1, 2, 3]) c,
  ];
}
''');

    assertImplicitCallReference(
      findNode.implicitCallReference('c,'),
      findElement.method('call'),
      'void Function(int)',
    );
  }

  test_listLiteral_ifElement() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

List<void Function(int)> foo(C c) {
  return [
    if (1==2) c,
  ];
}
''');

    assertImplicitCallReference(
      findNode.implicitCallReference('c,'),
      findElement.method('call'),
      'void Function(int)',
    );
  }

  test_listLiteral_ifElement_else() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

List<void Function(int)> foo(C c1, C c2) {
  return [
    if (1==2) c1
    else c2,
  ];
}
''');

    assertImplicitCallReference(
      findNode.implicitCallReference('c2,'),
      findElement.method('call'),
      'void Function(int)',
    );
  }

  test_prefixedIdentifier() async {
    await assertNoErrorsInCode('''
abstract class C {
  C get c;
  void call(int t) => t;
}

void Function(int) foo(C c) {
  return c.c;
}
''');

    assertImplicitCallReference(
      findNode.implicitCallReference('c.c;'),
      findElement.method('call'),
      'void Function(int)',
    );
  }

  test_propertyAccess() async {
    await assertNoErrorsInCode('''
abstract class C {
  C get c;
  void call(int t) => t;
}

void Function(int) foo(C c) {
  return c.c.c;
}
''');

    assertImplicitCallReference(
      findNode.implicitCallReference('c.c.c;'),
      findElement.method('call'),
      'void Function(int)',
    );
  }

  test_setOrMapLiteral_element() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

Set<void Function(int)> foo(C c) {
  return {c};
}
''');

    assertImplicitCallReference(
      findNode.implicitCallReference('c}'),
      findElement.method('call'),
      'void Function(int)',
    );
  }

  test_setOrMapLiteral_mapLiteralEntry_key() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

Map<void Function(int), int> foo(C c) {
  return {c: 1};
}
''');

    assertImplicitCallReference(
      findNode.implicitCallReference('c:'),
      findElement.method('call'),
      'void Function(int)',
    );
  }

  test_setOrMapLiteral_mapLiteralEntry_value() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

Map<int, void Function(int)> foo(C c) {
  return {1: c};
}
''');

    assertImplicitCallReference(
      findNode.implicitCallReference('c}'),
      findElement.method('call'),
      'void Function(int)',
    );
  }

  test_simpleIdentifier() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

void Function(int) foo(C c) {
  return c;
}
''');

    assertImplicitCallReference(
      findNode.implicitCallReference('c;'),
      findElement.method('call'),
      'void Function(int)',
    );
  }
}

@reflectiveTest
class AstRewriteMethodInvocationTest extends PubPackageResolutionTest
    with AstRewriteMethodInvocationTestCases {}

mixin AstRewriteMethodInvocationTestCases on PubPackageResolutionTest {
  test_targetNull_cascade() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

f(A a) {
  a..foo();
}
''');

    var invocation = findNode.methodInvocation('foo();');
    assertElement(invocation, findElement.method('foo'));
  }

  test_targetNull_class() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A(int a);
}

f() {
  A<int, String>(0);
}
''');

    var creation = findNode.instanceCreation('A<int, String>(0);');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int, String>',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int', 'U': 'String'},
    );
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetNull_extension() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E<T> on A {
  void foo() {}
}

f(A a) {
  E<int>(a).foo();
}
''');

    var override = findNode.extensionOverride('E<int>(a)');
    _assertExtensionOverride(
      override,
      expectedElement: findElement.extension_('E'),
      expectedTypeArguments: ['int'],
      expectedExtendedType: 'A',
    );
  }

  test_targetNull_function() async {
    await assertNoErrorsInCode(r'''
void A<T, U>(int a) {}

f() {
  A<int, String>(0);
}
''');

    var invocation = findNode.methodInvocation('A<int, String>(0);');
    assertElement(invocation, findElement.topFunction('A'));
    assertInvokeType(invocation, 'void Function(int)');
    _assertArgumentList(invocation.argumentList, ['0']);
  }

  test_targetNull_typeAlias_interfaceType() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A(int _);
}

typedef X<T, U> = A<T, U>;

void f() {
  X<int, String>(0);
}
''');

    var creation = findNode.instanceCreation('X<int, String>(0);');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int, String>',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int', 'U': 'String'},
      expectedTypeNameElement: findElement.typeAlias('X'),
    );
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetNull_typeAlias_Never() async {
    await assertErrorsInCode(r'''
typedef X = Never;

void f() {
  X(0);
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION, 33, 1),
    ]);

    // Not rewritten.
    findNode.methodInvocation('X(0)');
  }

  test_targetPrefixedIdentifier_prefix_class_constructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T> {
  A.named(T a);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A.named(0);
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var creation = findNode.instanceCreation('A.named(0);');
    assertInstanceCreation(
      creation,
      importFind.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedPrefix: importFind.prefix,
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetPrefixedIdentifier_prefix_class_constructor_typeArguments() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T> {
  A.named(int a);
}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A.named<int>(0);
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 50,
          5,
          messageContains: ["The constructor 'prefix.A.named'"]),
    ]);

    var importFind = findElement.importFind('package:test/a.dart');

    var creation = findNode.instanceCreation('named<int>(0);');
    assertInstanceCreation(
      creation,
      importFind.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedPrefix: importFind.prefix,
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
    _assertTypeArgumentList(
      creation.constructorName.type2.typeArguments,
      ['int'],
    );
    expect((creation as InstanceCreationExpressionImpl).typeArguments, isNull);
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetPrefixedIdentifier_prefix_class_constructor_typeArguments_new() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T> {
  A.new(int a);
}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A.new<int>(0);
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 48,
          5,
          messageContains: ["The constructor 'prefix.A.new'"]),
    ]);

    var importFind = findElement.importFind('package:test/a.dart');

    var creation = findNode.instanceCreation('new<int>(0);');
    assertInstanceCreation(
      creation,
      importFind.class_('A'),
      'A<int>',
      expectedPrefix: importFind.prefix,
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
    _assertTypeArgumentList(
      creation.constructorName.type2.typeArguments,
      ['int'],
    );
    expect((creation as InstanceCreationExpressionImpl).typeArguments, isNull);
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetPrefixedIdentifier_prefix_getter_method() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
A get foo => A();

class A {
  void bar(int a) {}
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.foo.bar(0);
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('bar(0);');
    assertElement(invocation, importFind.class_('A').getMethod('bar'));
    assertInvokeType(invocation, 'void Function(int)');
    _assertArgumentList(invocation.argumentList, ['0']);
  }

  test_targetPrefixedIdentifier_typeAlias_interfaceType_constructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T> {
  A.named(T a);
}

typedef X<T> = A<T>;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f() {
  prefix.X.named(0);
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var creation = findNode.instanceCreation('X.named(0);');
    assertInstanceCreation(
      creation,
      importFind.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
      expectedPrefix: findElement.prefix('prefix'),
      expectedTypeNameElement: importFind.typeAlias('X'),
    );
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetSimpleIdentifier_class_constructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T a);
}

f() {
  A.named(0);
}
''');

    var creation = findNode.instanceCreation('A.named(0);');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetSimpleIdentifier_class_constructor_typeArguments() async {
    await assertErrorsInCode(r'''
class A<T, U> {
  A.named(int a);
}

f() {
  A.named<int, String>(0);
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 52,
          13,
          messageContains: ["The constructor 'A.named'"]),
    ]);

    var creation = findNode.instanceCreation('named<int, String>(0);');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      // TODO(scheglov) Move type arguments
      'A<dynamic, dynamic>',
//      'A<int, String>',
      constructorName: 'named',
      expectedConstructorMember: true,
      // TODO(scheglov) Move type arguments
      expectedSubstitution: {'T': 'dynamic', 'U': 'dynamic'},
//      expectedSubstitution: {'T': 'int', 'U': 'String'},
    );
    // TODO(scheglov) Move type arguments
//    _assertTypeArgumentList(
//      creation.constructorName.type.typeArguments,
//      ['int', 'String'],
//    );
    // TODO(scheglov) Fix and uncomment.
//    expect((creation as InstanceCreationExpressionImpl).typeArguments, isNull);
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetSimpleIdentifier_class_constructor_typeArguments_new() async {
    await assertErrorsInCode(r'''
class A<T, U> {
  A.new(int a);
}

f() {
  A.new<int, String>(0);
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 48,
          13,
          messageContains: ["The constructor 'A.new'"]),
    ]);

    var creation = findNode.instanceCreation('new<int, String>(0);');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      // TODO(scheglov) Move type arguments
      'A<dynamic, dynamic>',
//      'A<int, String>',
      expectedConstructorMember: true,
      // TODO(scheglov) Move type arguments
      expectedSubstitution: {'T': 'dynamic', 'U': 'dynamic'},
//      expectedSubstitution: {'T': 'int', 'U': 'String'},
    );
    // TODO(scheglov) Move type arguments
//    _assertTypeArgumentList(
//      creation.constructorName.type.typeArguments,
//      ['int', 'String'],
//    );
    // TODO(scheglov) Fix and uncomment.
//    expect((creation as InstanceCreationExpressionImpl).typeArguments, isNull);
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetSimpleIdentifier_class_staticMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  static void foo(int a) {}
}

f() {
  A.foo(0);
}
''');

    var invocation = findNode.methodInvocation('foo(0);');
    assertElement(invocation, findElement.method('foo'));
  }

  test_targetSimpleIdentifier_prefix_class() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T, U> {
  A(int a);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A<int, String>(0);
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var creation = findNode.instanceCreation('A<int, String>(0);');
    assertInstanceCreation(
      creation,
      importFind.class_('A'),
      'A<int, String>',
      expectedPrefix: importFind.prefix,
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int', 'U': 'String'},
    );
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetSimpleIdentifier_prefix_extension() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {}

extension E<T> on A {
  void foo() {}
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f(prefix.A a) {
  prefix.E<int>(a).foo();
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var override = findNode.extensionOverride('E<int>(a)');
    _assertExtensionOverride(
      override,
      expectedElement: importFind.extension_('E'),
      expectedTypeArguments: ['int'],
      expectedExtendedType: 'A',
    );
    assertImportPrefix(findNode.simple('prefix.E'), importFind.prefix);
  }

  test_targetSimpleIdentifier_prefix_function() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
void A<T, U>(int a) {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A<int, String>(0);
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('A<int, String>(0);');
    assertElement(invocation, importFind.topFunction('A'));
    assertInvokeType(invocation, 'void Function(int)');
    _assertArgumentList(invocation.argumentList, ['0']);
  }

  test_targetSimpleIdentifier_typeAlias_interfaceType_constructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T a);
}

typedef X<T> = A<T>;

void f() {
  X.named(0);
}
''');

    var creation = findNode.instanceCreation('X.named(0);');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
      expectedTypeNameElement: findElement.typeAlias('X'),
    );
    _assertArgumentList(creation.argumentList, ['0']);
  }

  void _assertArgumentList(
    ArgumentList argumentList,
    List<String> expectedArguments,
  ) {
    var argumentStrings = argumentList.arguments
        .map((e) => result.content.substring(e.offset, e.end))
        .toList();
    expect(argumentStrings, expectedArguments);
  }

  void _assertExtensionOverride(
    ExtensionOverride override, {
    required ExtensionElement expectedElement,
    required List<String> expectedTypeArguments,
    required String expectedExtendedType,
  }) {
    expect(override.staticElement, expectedElement);

    assertTypeNull(override);
    assertTypeNull(override.extensionName);

    assertElementTypes(
      override.typeArgumentTypes,
      expectedTypeArguments,
    );
    assertType(override.extendedType, expectedExtendedType);
  }

  void _assertTypeArgumentList(
    TypeArgumentList? argumentList,
    List<String> expectedArguments,
  ) {
    if (argumentList == null) {
      fail('Expected TypeArgumentList, actually null.');
    }

    var argumentStrings = argumentList.arguments
        .map((e) => result.content.substring(e.offset, e.end))
        .toList();
    expect(argumentStrings, expectedArguments);
  }
}

@reflectiveTest
class AstRewritePrefixedIdentifierTest extends PubPackageResolutionTest {
  test_constructorReference_inAssignment_onLeftSide() async {
    await assertErrorsInCode('''
class C {}

void f() {
  C.new = 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 27, 3),
    ]);

    var identifier = findNode.prefixed('C.new');
    // The left side of the assignment is resolved by
    // [PropertyElementResolver._resolveTargetClassElement], which looks for
    // getters and setters on `C`, and does not recover with other elements
    // (methods, constructors). This prefixed identifier can have a real
    // `staticElement` if we add such recovery.
    assertElement(identifier, null);
  }

  test_constructorReference_inAssignment_onRightSide() async {
    await assertNoErrorsInCode('''
class C {}

Function? f;
void g() {
  f = C.new;
}
''');

    var identifier = findNode.constructorReference('C.new');
    assertElement(identifier, findElement.unnamedConstructor('C'));
  }

  // TODO(srawlins): Complete tests of all cases of rewriting (or not) a
  // prefixed identifier.
}
