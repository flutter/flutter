// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorReferenceResolutionTest);
    defineReflectiveTests(ConstructorReferenceResolution_TypeArgsTest);
    defineReflectiveTests(
        ConstructorReferenceResolutionWithoutConstructorTearoffsTest);
  });
}

@reflectiveTest
class ConstructorReferenceResolution_TypeArgsTest
    extends PubPackageResolutionTest {
  test_alias_generic_const() async {
    await assertNoErrorsInCode('''
class A<T, U> {
  const A.foo();
}
typedef TA<T, U> = A<U, T>;

const a = TA<int, String>.foo;
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('TA<int, String>.foo;'),
      elementMatcher(classElement.getNamedConstructor('foo')!,
          substitution: {'T': 'String', 'U': 'int'}),
      classElement,
      'A<String, int> Function()',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }

  test_alias_generic_const_differingNumberOfTypeParamters() async {
    await assertNoErrorsInCode('''
class A<T, U> {
  A.foo() {}
}
typedef TA<T> = A<T, String>;

const x = TA<int>.foo;
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('TA<int>.foo;'),
      elementMatcher(classElement.getNamedConstructor('foo')!,
          substitution: {'T': 'int', 'U': 'String'}),
      classElement,
      'A<int, String> Function()',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }

  test_alias_generic_named() async {
    await assertNoErrorsInCode('''
class A<T, U> {
  A.foo();
}
typedef TA<T, U> = A<U, T>;

void bar() {
  TA<int, String>.foo;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('TA<int, String>.foo;'),
      elementMatcher(classElement.getNamedConstructor('foo')!,
          substitution: {'T': 'String', 'U': 'int'}),
      classElement,
      'A<String, int> Function()',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }

  test_alias_generic_uninstantiated_const() async {
    await assertNoErrorsInCode('''
class A<T, U> {
  const A.foo();
}
typedef TA<T, U> = A<U, T>;

const a = TA.foo;
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('TA.foo;'),
      classElement.getNamedConstructor('foo'),
      classElement,
      'A<U, T> Function<T, U>()',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }

  test_alias_generic_unnamed() async {
    await assertNoErrorsInCode('''
class A<T> {
  A();
}
typedef TA<T> = A<T>;

void bar() {
  TA<int>.new;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('TA<int>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }

  test_alias_genericWithBound_unnamed() async {
    await assertNoErrorsInCode('''
class A<T> {
  A();
}
typedef TA<T extends num> = A<T>;

void bar() {
  TA<int>.new;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('TA<int>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }

  test_alias_genericWithBound_unnamed_badBound() async {
    await assertErrorsInCode('''
class A<T> {
  A();
}
typedef TA<T extends num> = A<T>;

void bar() {
  TA<String>.new;
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 75, 6),
    ]);

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('TA<String>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'String'}),
      classElement,
      'A<String> Function()',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }

  test_class_generic_const() async {
    await assertNoErrorsInCode('''
class A<T> {
  const A();
}

const a = A<int>.new;
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
    );
  }

  test_class_generic_named() async {
    await assertNoErrorsInCode('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>.foo;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>.foo;'),
      elementMatcher(classElement.getNamedConstructor('foo')!,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
    );
  }

  test_class_generic_named_cascade() async {
    await assertErrorsInCode('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>..foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 43, 1),
      error(ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, 47, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 48, 2),
    ]);
    // The parser produces nonsense here because the `<` disambiguates as a
    // relational operator, so no need to assert anything about analysis
    // results.
  }

  test_class_generic_named_nullAware() async {
    await assertErrorsInCode('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>?.foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 43, 1),
      error(ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, 47, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 48, 2),
    ]);
    // The parser produces nonsense here because the `<` disambiguates as a
    // relational operator, so no need to assert anything about analysis
    // results.
  }

  test_class_generic_named_typeArgs() async {
    await assertErrorsInCode('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>.foo<int>;
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 52,
          5,
          messageContains: ["The constructor 'A.foo'"]),
    ]);

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>.foo<int>;'),
      elementMatcher(classElement.getNamedConstructor('foo')!,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
    );
  }

  test_class_generic_new_typeArgs() async {
    await assertErrorsInCode('''
class A<T> {
  A.new();
}

void bar() {
  A<int>.new<int>;
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 52,
          5,
          messageContains: ["The constructor 'A.new'"]),
    ]);

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>.new<int>;'),
      elementMatcher(classElement.unnamedConstructor!,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
    );
  }

  test_class_generic_nonConstructor() async {
    await assertErrorsInCode('''
class A<T> {
  static int i = 1;
}

void bar() {
  A<int>.i;
}
''', [
      error(CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_STATIC_MEMBER,
          51, 8),
    ]);

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>.i;'),
      null,
      classElement,
      'dynamic',
    );
  }

  test_class_generic_nothing_hasNamedConstructor() async {
    await assertErrorsInCode('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>.;
}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 49, 1),
    ]);

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>.;'),
      null,
      classElement,
      'dynamic',
    );
  }

  test_class_generic_unnamed() async {
    await assertNoErrorsInCode('''
class A<T> {
  A();
}

void bar() {
  A<int>.new;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
    );
  }

  test_class_generic_unnamed_partOfPropertyAccess() async {
    await assertNoErrorsInCode('''
class A<T> {
  A();
}

void bar() {
  A<int>.new.runtimeType;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>.new'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
    );
  }

  test_class_genericWithBound_unnamed() async {
    await assertNoErrorsInCode('''
class A<T extends num> {
  A();
}

void bar() {
  A<int>.new;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
    );
  }

  test_class_genericWithBound_unnamed_badBound() async {
    await assertErrorsInCode('''
class A<T extends num> {
  A();
}

void bar() {
  A<String>.new;
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 52, 6),
    ]);

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<String>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'String'}),
      classElement,
      'A<String> Function()',
    );
  }

  test_prefixedAlias_generic_unnamed() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A<T> {
  A();
}
typedef TA<T> = A<T>;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
void bar() {
  a.TA<int>.new;
}
''');

    var classElement =
        findElement.importFind('package:test/a.dart').class_('A');
    assertConstructorReference(
      findNode.constructorReference('a.TA<int>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedPrefix: findElement.import('package:test/a.dart').prefix,
      expectedTypeNameElement:
          findElement.importFind('package:test/a.dart').typeAlias('TA'),
    );
  }

  test_prefixedClass_generic_named() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A<T> {
  A.foo();
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
void bar() {
  a.A<int>.foo;
}
''');

    var classElement =
        findElement.importFind('package:test/a.dart').class_('A');
    assertConstructorReference(
      findNode.constructorReference('a.A<int>.foo;'),
      elementMatcher(classElement.getNamedConstructor('foo')!,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedPrefix: findElement.import('package:test/a.dart').prefix,
    );
  }

  test_prefixedClass_generic_targetOfFunctionCall() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A<T> {
  A();
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
extension on Function {
  void m() {}
}
void bar() {
  a.A<int>.new.m();
}
''');

    var classElement =
        findElement.importFind('package:test/a.dart').class_('A');
    assertConstructorReference(
      findNode.constructorReference('a.A<int>.new'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedPrefix: findElement.import('package:test/a.dart').prefix,
    );
  }

  test_prefixedClass_generic_unnamed() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A<T> {
  A();
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
void bar() {
  a.A<int>.new;
}
''');

    var classElement =
        findElement.importFind('package:test/a.dart').class_('A');
    assertConstructorReference(
      findNode.constructorReference('a.A<int>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedPrefix: findElement.import('package:test/a.dart').prefix,
    );
  }
}

@reflectiveTest
class ConstructorReferenceResolutionTest extends PubPackageResolutionTest {
  test_abstractClass_factory() async {
    await assertNoErrorsInCode('''
abstract class A {
  factory A() => A2();
}

class A2 implements A {}

foo() {
  A.new;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A.new;'),
      classElement.unnamedConstructor,
      classElement,
      'A Function()',
    );
  }

  test_abstractClass_generative() async {
    await assertErrorsInCode('''
abstract class A {
  A();
}

foo() {
  A.new;
}
''', [
      error(
          CompileTimeErrorCode
              .TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS,
          39,
          5),
    ]);

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A.new;'),
      classElement.unnamedConstructor,
      classElement,
      'A Function()',
    );
  }

  test_abstractClass_redirecting() async {
    await assertErrorsInCode('''
abstract class A {
  A(): this.two();

  A.two();
}

foo() {
  A.new;
}
''', [
      error(
          CompileTimeErrorCode
              .TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS,
          63,
          5),
    ]);

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A.new;'),
      classElement.unnamedConstructor,
      classElement,
      'A Function()',
    );
  }

  test_class_generic_inferFromContext_badTypeArgument() async {
    await assertErrorsInCode('''
class A<T extends num> {
  A.foo();
}

A<String> Function() bar() {
  return A.foo;
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 41, 6,
          contextMessages: [message('/home/test/lib/test.dart', 39, 9)]),
    ]);

    var classElement = findElement.class_('A');
    var constructorElement = classElement.getNamedConstructor('foo')!;
    assertConstructorReference(
      findNode.constructorReference('A.foo;'),
      constructorElement,
      classElement,
      'A<Never> Function()',
    );
  }

  test_class_generic_named_inferTypeFromContext() async {
    await assertNoErrorsInCode('''
class A<T> {
  A.foo();
}

A<int> Function() bar() {
  return A.foo;
}
''');

    var classElement = findElement.class_('A');
    var constructorElement = classElement.getNamedConstructor('foo')!;
    assertConstructorReference(
      findNode.constructorReference('A.foo;'),
      constructorElement,
      classElement,
      'A<int> Function()',
    );
  }

  test_class_generic_named_uninstantiated() async {
    await assertNoErrorsInCode('''
class A<T> {
  A.foo();
}

void bar() {
  A.foo;
}
''');

    var classElement = findElement.class_('A');
    var constructorElement = classElement.getNamedConstructor('foo')!;
    assertConstructorReference(
      findNode.constructorReference('A.foo;'),
      constructorElement,
      classElement,
      'A<T> Function<T>()',
    );
  }

  test_class_generic_named_uninstantiated_bound() async {
    await assertNoErrorsInCode('''
class A<T extends num> {
  A.foo();
}

void bar() {
  A.foo;
}
''');

    var classElement = findElement.class_('A');
    var constructorElement = classElement.getNamedConstructor('foo')!;
    assertConstructorReference(
      findNode.constructorReference('A.foo;'),
      constructorElement,
      classElement,
      'A<T> Function<T extends num>()',
    );
  }

  test_class_nonGeneric_const() async {
    await assertNoErrorsInCode('''
class A {
  const A();
}

const a1 = A.new;
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A.new;'),
      classElement.unnamedConstructor,
      classElement,
      'A Function()',
    );
  }

  test_class_nonGeneric_named() async {
    await assertNoErrorsInCode('''
class A {
  A.foo();
}

void bar() {
  A.foo;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A.foo;'),
      classElement.getNamedConstructor('foo')!,
      classElement,
      'A Function()',
    );
  }

  test_class_nonGeneric_unnamed() async {
    await assertNoErrorsInCode('''
class A {
  A();
}

bar() {
  A.new;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A.new;'),
      classElement.unnamedConstructor,
      classElement,
      'A Function()',
    );
  }

  test_prefixedAlias_nonGeneric_named() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  A.foo();
}
typedef TA = A;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
bar() {
  a.TA.foo;
}
''');

    var classElement =
        findElement.importFind('package:test/a.dart').class_('A');
    assertConstructorReference(
      findNode.constructorReference('a.TA.foo;'),
      classElement.getNamedConstructor('foo'),
      classElement,
      'A Function()',
      expectedPrefix: findElement.import('package:test/a.dart').prefix,
      expectedTypeNameElement:
          findElement.importFind('package:test/a.dart').typeAlias('TA'),
    );
  }

  test_prefixedAlias_nonGeneric_unnamed() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  A();
}
typedef TA = A;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
bar() {
  a.TA.new;
}
''');

    var classElement =
        findElement.importFind('package:test/a.dart').class_('A');
    assertConstructorReference(
      findNode.constructorReference('a.TA.new;'),
      classElement.unnamedConstructor,
      classElement,
      'A Function()',
      expectedPrefix: findElement.import('package:test/a.dart').prefix,
      expectedTypeNameElement:
          findElement.importFind('package:test/a.dart').typeAlias('TA'),
    );
  }

  test_prefixedClass_nonGeneric_named() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  A.foo();
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
bar() {
  a.A.foo;
}
''');

    var classElement =
        findElement.importFind('package:test/a.dart').class_('A');
    assertConstructorReference(
      findNode.constructorReference('a.A.foo;'),
      classElement.getNamedConstructor('foo'),
      classElement,
      'A Function()',
      expectedPrefix: findElement.import('package:test/a.dart').prefix,
    );
  }

  test_prefixedClass_nonGeneric_unnamed() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  A();
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
bar() {
  a.A.new;
}
''');

    var classElement =
        findElement.importFind('package:test/a.dart').class_('A');
    assertConstructorReference(
      findNode.constructorReference('a.A.new;'),
      classElement.unnamedConstructor,
      classElement,
      'A Function()',
      expectedPrefix: findElement.import('package:test/a.dart').prefix,
    );
  }

  test_typeAlias_generic_const() async {
    await assertNoErrorsInCode('''
class A<T> {
  const A();
}
typedef TA<T> = A<T>;

const a = TA.new;
''');

    var classElement = findElement.class_('A');
    var constructorElement = classElement.unnamedConstructor!;
    assertConstructorReference(
      findNode.constructorReference('TA.new;'),
      constructorElement,
      classElement,
      'A<T> Function<T>()',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }

  test_typeAlias_generic_named_uninstantiated() async {
    await assertNoErrorsInCode('''
class A<T, U> {
  A.foo();
}
typedef TA<U> = A<String, U>;

bar() {
  TA.foo;
}
''');

    var classElement = findElement.class_('A');
    var constructorElement = classElement.getNamedConstructor('foo')!;
    assertConstructorReference(
      findNode.constructorReference('TA.foo;'),
      constructorElement,
      findElement.class_('A'),
      'A<String, U> Function<U>()',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }

  test_typeAlias_instantiated_const() async {
    await assertNoErrorsInCode('''
class A<T> {
  const A();
}
typedef TA = A<int>;

const a = TA.new;
''');

    var classElement = findElement.class_('A');
    var constructorElement = classElement.unnamedConstructor!;
    assertConstructorReference(
      findNode.constructorReference('TA.new;'),
      elementMatcher(constructorElement, substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }

  test_typeAlias_instantiated_named() async {
    await assertNoErrorsInCode('''
class A<T> {
  A.foo();
}
typedef TA = A<int>;

bar() {
  TA.foo;
}
''');

    var classElement = findElement.class_('A');
    var constructorElement = classElement.getNamedConstructor('foo')!;
    assertConstructorReference(
      findNode.constructorReference('TA.foo;'),
      elementMatcher(constructorElement, substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }
}

@reflectiveTest
class ConstructorReferenceResolutionWithoutConstructorTearoffsTest
    extends PubPackageResolutionTest with WithoutConstructorTearoffsMixin {
  test_class_generic_nonConstructor() async {
    await assertErrorsInCode('''
class A<T> {
  static int i = 1;
}

void bar() {
  A<int>.i;
}
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 52, 5),
    ]);

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>.i;'),
      null,
      classElement,
      'dynamic',
    );
  }

  test_constructorTearoff() async {
    await assertErrorsInCode('''
class A {
  A.foo();
}

void bar() {
  A.foo;
}
''', [
      error(HintCode.SDK_VERSION_CONSTRUCTOR_TEAROFFS, 39, 5),
    ]);

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A.foo;'),
      classElement.getNamedConstructor('foo')!,
      classElement,
      'A Function()',
    );
  }
}
