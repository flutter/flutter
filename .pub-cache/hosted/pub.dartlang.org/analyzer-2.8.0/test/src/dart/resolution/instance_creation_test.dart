// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceCreationTest);
    defineReflectiveTests(InstanceCreationWithoutConstructorTearoffsTest);
  });
}

@reflectiveTest
class InstanceCreationTest extends PubPackageResolutionTest
    with InstanceCreationTestCases {}

mixin InstanceCreationTestCases on PubPackageResolutionTest {
  test_class_generic_named_inferTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T t);
}

void f() {
  A.named(0);
}

''');

    var creation = findNode.instanceCreation('A.named(0)');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
  }

  test_class_generic_named_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named();
}

void f() {
  A<int>.named();
}

''');

    var creation = findNode.instanceCreation('A<int>');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
    assertNamedType(findNode.namedType('int>'), intElement, 'int');
  }

  test_class_generic_unnamed_inferTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T t);
}

void f() {
  A(0);
}

''');

    var creation = findNode.instanceCreation('A(0)');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
  }

  test_class_generic_unnamed_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

void f() {
  A<int>();
}

''');

    var creation = findNode.instanceCreation('A<int>');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
    assertNamedType(findNode.namedType('int>'), intElement, 'int');
  }

  test_class_notGeneric() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

void f() {
  A(0);
}

''');

    var creation = findNode.instanceCreation('A(0)');
    assertInstanceCreation(creation, findElement.class_('A'), 'A');
  }

  test_demoteType() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T t);
}

void f<S>(S s) {
  if (s is int) {
    A(s);
  }
}

''');

    assertType(
      findNode.instanceCreation('A(s)'),
      'A<S>',
    );
  }

  test_error_newWithInvalidTypeParameters_implicitNew_inference_top() async {
    await assertErrorsInCode(r'''
final foo = Map<int>();
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 12, 8),
    ]);

    var creation = findNode.instanceCreation('Map<int>');
    assertInstanceCreation(
      creation,
      mapElement,
      'Map<dynamic, dynamic>',
      expectedConstructorMember: true,
      expectedSubstitution: {'K': 'dynamic', 'V': 'dynamic'},
    );
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew() async {
    await assertErrorsInCode(r'''
class Foo<X> {
  Foo.bar();
}

main() {
  new Foo.bar<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 53,
          5,
          messageContains: ["The constructor 'Foo.bar'"]),
    ]);

    var creation = findNode.instanceCreation('Foo.bar<int>');
    assertInstanceCreation(
      creation,
      findElement.class_('Foo'),
      'Foo<dynamic>',
      constructorName: 'bar',
      expectedConstructorMember: true,
      expectedSubstitution: {'X': 'dynamic'},
    );
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew_new() async {
    await assertErrorsInCode(r'''
class Foo<X> {
  Foo.new();
}

main() {
  new Foo.new<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 53,
          5,
          messageContains: ["The constructor 'Foo.new'"]),
    ]);

    var creation = findNode.instanceCreation('Foo.new<int>');
    assertInstanceCreation(
      creation,
      findElement.class_('Foo'),
      'Foo<dynamic>',
      expectedConstructorMember: true,
      expectedSubstitution: {'X': 'dynamic'},
    );
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew_prefix() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class Foo<X> {
  Foo.bar();
}
''');
    await assertErrorsInCode('''
import 'a.dart' as p;

main() {
  new p.Foo.bar<int>();
}
''', [
      error(ParserErrorCode.CONSTRUCTOR_WITH_TYPE_ARGUMENTS, 44, 3),
    ]);

    // TODO(brianwilkerson) Test this more carefully after we can re-write the
    // AST to reflect the expected structure.
//    var creation = findNode.instanceCreation('Foo.bar<int>');
//    var import = findElement.import('package:test/a.dart');
//    assertInstanceCreation(
//      creation,
//      import.importedLibrary.getType('Foo'),
//      'Foo',
//      constructorName: 'bar',
//      expectedPrefix: import.prefix,
//    );
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_implicitNew() async {
    await assertErrorsInCode(r'''
class Foo<X> {
  Foo.bar();
}

main() {
  Foo.bar<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 49,
          5),
    ]);

    var creation = findNode.instanceCreation('Foo.bar<int>');
    assertInstanceCreation(
      creation,
      findElement.class_('Foo'),
      // TODO(scheglov) Move type arguments
      'Foo<dynamic>',
//      'Foo<int>',
      constructorName: 'bar',
      expectedConstructorMember: true,
      // TODO(scheglov) Move type arguments
      expectedSubstitution: {'X': 'dynamic'},
//      expectedSubstitution: {'X': 'int'},
    );
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_implicitNew_prefix() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class Foo<X> {
  Foo.bar();
}
''');
    await assertErrorsInCode('''
import 'a.dart' as p;

main() {
  p.Foo.bar<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 43,
          5),
    ]);

    var import = findElement.import('package:test/a.dart');

    var creation = findNode.instanceCreation('Foo.bar<int>');
    assertInstanceCreation(
      creation,
      import.importedLibrary!.getType('Foo')!,
      'Foo<int>',
      constructorName: 'bar',
      expectedConstructorMember: true,
      expectedPrefix: import.prefix,
      expectedSubstitution: {'X': 'int'},
    );
  }

  test_namedArgument_anywhere() async {
    await assertNoErrorsInCode('''
class A {}
class B {}
class C {}
class D {}

class X {
  X(A a, B b, {C? c, D? d});
}

T g1<T>() => throw 0;
T g2<T>() => throw 0;
T g3<T>() => throw 0;
T g4<T>() => throw 0;

void f() {
  X(g1(), c: g3(), g2(), d: g4());
}
''');

    assertInstanceCreation(
      findNode.instanceCreation('X(g'),
      findElement.class_('X'),
      'X',
    );

    var g1 = findNode.methodInvocation('g1()');
    assertType(g1, 'A');
    assertParameterElement(g1, findElement.parameter('a'));

    var g2 = findNode.methodInvocation('g2()');
    assertType(g2, 'B');
    assertParameterElement(g2, findElement.parameter('b'));

    var named_g3 = findNode.namedExpression('c: g3()');
    assertType(named_g3.expression, 'C?');
    assertParameterElement(named_g3, findElement.parameter('c'));
    assertNamedParameterRef('c:', 'c');

    var named_g4 = findNode.namedExpression('d: g4()');
    assertType(named_g4.expression, 'D?');
    assertParameterElement(named_g4, findElement.parameter('d'));
    assertNamedParameterRef('d:', 'd');
  }

  test_typeAlias_generic_class_generic_named_infer_all() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T t);
}

typedef B<U> = A<U>;

void f() {
  B.named(0);
}
''');

    var creation = findNode.instanceCreation('B.named(0)');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedTypeNameElement: findElement.typeAlias('B'),
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
  }

  test_typeAlias_generic_class_generic_named_infer_partial() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A.named(T t, U u);
}

typedef B<V> = A<V, String>;

void f() {
  B.named(0, '');
}
''');

    var creation = findNode.instanceCreation('B.named(0, ');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int, String>',
      constructorName: 'named',
      expectedTypeNameElement: findElement.typeAlias('B'),
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int', 'U': 'String'},
    );
  }

  test_typeAlias_generic_class_generic_unnamed_infer_all() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T t);
}

typedef B<U> = A<U>;

void f() {
  B(0);
}
''');

    var creation = findNode.instanceCreation('B(0)');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      expectedTypeNameElement: findElement.typeAlias('B'),
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
  }

  test_typeAlias_generic_class_generic_unnamed_infer_partial() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A(T t, U u);
}

typedef B<V> = A<V, String>;

void f() {
  B(0, '');
}
''');

    var creation = findNode.instanceCreation('B(0, ');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int, String>',
      expectedTypeNameElement: findElement.typeAlias('B'),
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int', 'U': 'String'},
    );
  }

  test_typeAlias_notGeneric_class_generic_named_argumentTypeMismatch() async {
    await assertErrorsInCode(r'''
class A<T> {
  A.named(T t);
}

typedef B = A<String>;

void f() {
  B.named(0);
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 77, 1),
    ]);

    var creation = findNode.instanceCreation('B.named(0)');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<String>',
      constructorName: 'named',
      expectedTypeNameElement: findElement.typeAlias('B'),
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'String'},
    );
  }

  test_typeAlias_notGeneric_class_generic_unnamed_argumentTypeMismatch() async {
    await assertErrorsInCode(r'''
class A<T> {
  A(T t);
}

typedef B = A<String>;

void f() {
  B(0);
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 65, 1),
    ]);

    var creation = findNode.instanceCreation('B(0)');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<String>',
      expectedTypeNameElement: findElement.typeAlias('B'),
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'String'},
    );
  }

  test_unnamed_declaredNew() async {
    await assertNoErrorsInCode('''
class A {
  A.new(int a);
}

void f() {
  A(0);
}

''');

    var creation = findNode.instanceCreation('A(0)');
    assertInstanceCreation(creation, findElement.class_('A'), 'A');
  }

  test_unnamedViaNew_declaredNew() async {
    await assertNoErrorsInCode('''
class A {
  A.new(int a);
}

void f() {
  A.new(0);
}

''');

    var creation = findNode.instanceCreation('A.new(0)');
    assertInstanceCreation(creation, findElement.class_('A'), 'A');
  }

  test_unnamedViaNew_declaredUnnamed() async {
    await assertNoErrorsInCode('''
class A {
  A(int a);
}

void f() {
  A.new(0);
}

''');

    var creation = findNode.instanceCreation('A.new(0)');
    assertInstanceCreation(creation, findElement.class_('A'), 'A');
  }
}

@reflectiveTest
class InstanceCreationWithoutConstructorTearoffsTest
    extends PubPackageResolutionTest with WithoutConstructorTearoffsMixin {
  test_unnamedViaNew() async {
    await assertErrorsInCode('''
class A {
  A(int a);
}

void f() {
  A.new(0);
}

''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 40, 3),
    ]);

    // Resolution should continue even though the experiment is not enabled.
    var creation = findNode.instanceCreation('A.new(0)');
    assertInstanceCreation(creation, findElement.class_('A'), 'A');
  }
}
