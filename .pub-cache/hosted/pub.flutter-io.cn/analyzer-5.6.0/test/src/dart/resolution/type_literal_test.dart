// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeLiteralResolutionTest);
    defineReflectiveTests(TypeLiteralResolutionWithoutConstructorTearoffsTest);
  });
}

@reflectiveTest
class TypeLiteralResolutionTest extends PubPackageResolutionTest {
  test_class() async {
    await assertNoErrorsInCode('''
class C<T> {}
var t = C<int>;
''');

    var typeLiteral = findNode.typeLiteral('C<int>;');
    assertTypeLiteral(typeLiteral, findElement.class_('C'), 'C<int>');
  }

  test_class_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
var t = a.C<int>;
''');

    var typeLiteral = findNode.typeLiteral('C<int>;');
    assertTypeLiteral(
      typeLiteral,
      findElement.importFind('package:test/a.dart').class_('C'),
      'C<int>',
      expectedPrefix: findElement.import('package:test/a.dart').prefix?.element,
    );
  }

  test_class_tooFewTypeArgs() async {
    await assertErrorsInCode('''
class C<T, U> {}
var t = C<int>;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 26, 5),
    ]);

    var typeLiteral = findNode.typeLiteral('C<int>;');
    assertTypeLiteral(
        typeLiteral, findElement.class_('C'), 'C<dynamic, dynamic>');
  }

  test_class_tooManyTypeArgs() async {
    await assertErrorsInCode('''
class C<T> {}
var t = C<int, int>;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 23, 10),
    ]);

    var typeLiteral = findNode.typeLiteral('C<int, int>;');
    assertTypeLiteral(typeLiteral, findElement.class_('C'), 'C<dynamic>');
  }

  test_class_typeArgumentDoesNotMatchBound() async {
    await assertErrorsInCode('''
class C<T extends num> {}
var t = C<String>;
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 36, 6,
          contextMessages: [message('/home/test/lib/test.dart', 34, 9)]),
    ]);

    var typeLiteral = findNode.typeLiteral('C<String>;');
    assertTypeLiteral(typeLiteral, findElement.class_('C'), 'C<String>');
  }

  test_classAlias() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef CA<T> = C<T>;
var t = CA<int>;
''');

    var typeLiteral = findNode.typeLiteral('CA<int>;');
    assertTypeLiteral(typeLiteral, findElement.typeAlias('CA'), 'C<int>');
  }

  test_classAlias_differentTypeArgCount() async {
    await assertNoErrorsInCode('''
class C<T, U> {}
typedef CA<T> = C<T, int>;
var t = CA<String>;
''');

    var typeLiteral = findNode.typeLiteral('CA<String>;');
    assertTypeLiteral(
        typeLiteral, findElement.typeAlias('CA'), 'C<String, int>');
  }

  test_classAlias_functionTypeArg() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef CA<T> = C<T>;
var t = CA<void Function()>;
''');

    var typeLiteral = findNode.typeLiteral('CA<void Function()>;');
    assertTypeLiteral(
        typeLiteral, findElement.typeAlias('CA'), 'C<void Function()>');
  }

  test_classAlias_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
typedef CA<T> = C<T>;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
var t = a.CA<int>;
''');

    var typeLiteral = findNode.typeLiteral('CA<int>;');
    assertTypeLiteral(
      typeLiteral,
      findElement.importFind('package:test/a.dart').typeAlias('CA'),
      'C<int>',
      expectedPrefix: findElement.import('package:test/a.dart').prefix?.element,
    );
  }

  test_classAlias_typeArgumentDoesNotMatchBound() async {
    await assertErrorsInCode('''
class C<T> {}
typedef CA<T extends num> = C<T>;
var t = CA<String>;
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 59, 6,
          contextMessages: [message('/home/test/lib/test.dart', 56, 10)]),
    ]);

    var typeLiteral = findNode.typeLiteral('CA<String>;');
    assertTypeLiteral(typeLiteral, findElement.typeAlias('CA'), 'C<String>');
  }

  test_functionAlias() async {
    await assertNoErrorsInCode('''
typedef Fn<T> = void Function(T);
var t = Fn<int>;
''');

    var typeLiteral = findNode.typeLiteral('Fn<int>;');
    assertTypeLiteral(
        typeLiteral, findElement.typeAlias('Fn'), 'void Function(int)');
  }

  test_functionAlias_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef Fn<T> = void Function(T);
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
var t = a.Fn<int>;
''');

    var typeLiteral = findNode.typeLiteral('Fn<int>;');
    assertTypeLiteral(
      typeLiteral,
      findElement.importFind('package:test/a.dart').typeAlias('Fn'),
      'void Function(int)',
      expectedPrefix: findElement.prefix('a'),
    );
  }

  test_functionAlias_targetOfMethodCall() async {
    await assertErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo();
}

extension E on Type {
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD_ON_FUNCTION_TYPE, 58, 3),
    ]);

    var typeLiteral = findNode.typeLiteral('Fn<int>');
    assertTypeLiteral(
      typeLiteral,
      findElement.typeAlias('Fn'),
      'void Function(int)',
    );
  }

  test_functionAlias_targetOfMethodCall_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef Fn<T> = void Function(T);
''');
    await assertErrorsInCode('''
import 'a.dart' as a;

void bar() {
  a.Fn<int>.foo();
}

extension E on Type {
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD_ON_FUNCTION_TYPE, 48, 3),
    ]);

    var typeLiteral = findNode.typeLiteral('Fn<int>');
    assertTypeLiteral(
      typeLiteral,
      findElement.importFind('package:test/a.dart').typeAlias('Fn'),
      'void Function(int)',
      expectedPrefix: findElement.prefix('a'),
    );
  }

  test_functionAlias_targetOfMethodCall_parenthesized() async {
    await assertNoErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo();
}

extension E on Type {
  void foo() {}
}
''');

    var typeLiteral = findNode.typeLiteral('Fn<int>');
    assertTypeLiteral(
      typeLiteral,
      findElement.typeAlias('Fn'),
      'void Function(int)',
    );
  }

  test_functionAlias_targetOfPropertyAccess_getter() async {
    await assertErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo;
}

extension E on Type {
  int get foo => 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER_ON_FUNCTION_TYPE, 58, 3),
    ]);

    var typeLiteral = findNode.typeLiteral('Fn<int>');
    assertTypeLiteral(
      typeLiteral,
      findElement.typeAlias('Fn'),
      'void Function(int)',
    );
  }

  test_functionAlias_targetOfPropertyAccess_getter_parenthesized() async {
    await assertNoErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo;
}

extension E on Type {
  int get foo => 1;
}
''');

    var typeLiteral = findNode.typeLiteral('Fn<int>');
    assertTypeLiteral(
      typeLiteral,
      findElement.typeAlias('Fn'),
      'void Function(int)',
    );
  }

  test_functionAlias_targetOfPropertyAccess_setter() async {
    await assertErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo = 7;
}

extension E on Type {
  set foo(int value) {}
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER_ON_FUNCTION_TYPE, 58, 3),
    ]);

    var typeLiteral = findNode.typeLiteral('Fn<int>');
    assertTypeLiteral(
      typeLiteral,
      findElement.typeAlias('Fn'),
      'void Function(int)',
    );
  }

  test_functionAlias_targetOfPropertyAccess_setter_parenthesized() async {
    await assertNoErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo = 7;
}

extension E on Type {
  set foo(int value) {}
}
''');

    var typeLiteral = findNode.typeLiteral('Fn<int>');
    assertTypeLiteral(
      typeLiteral,
      findElement.typeAlias('Fn'),
      'void Function(int)',
    );
  }

  test_functionAlias_tooFewTypeArgs() async {
    await assertErrorsInCode('''
typedef Fn<T, U> = void Function(T, U);
var t = Fn<int>;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 50, 5),
    ]);

    var typeLiteral = findNode.typeLiteral('Fn<int>;');
    assertTypeLiteral(
      typeLiteral,
      findElement.typeAlias('Fn'),
      'void Function(dynamic, dynamic)',
    );
  }

  test_functionAlias_tooManyTypeArgs() async {
    await assertErrorsInCode('''
typedef Fn<T> = void Function(T);
var t = Fn<int, String>;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 44, 13),
    ]);

    var typeLiteral = findNode.typeLiteral('Fn<int, String>;');
    assertTypeLiteral(
      typeLiteral,
      findElement.typeAlias('Fn'),
      'void Function(dynamic)',
    );
  }

  test_functionAlias_typeArgumentDoesNotMatchBound() async {
    await assertErrorsInCode('''
typedef Fn<T extends num> = void Function(T);
var t = Fn<String>;
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 57, 6,
          contextMessages: [message('/home/test/lib/test.dart', 54, 10)]),
    ]);

    var typeLiteral = findNode.typeLiteral('Fn<String>;');
    assertTypeLiteral(
      typeLiteral,
      findElement.typeAlias('Fn'),
      'void Function(String)',
    );
  }

  test_mixin() async {
    await assertNoErrorsInCode('''
mixin M<T> {}
var t = M<int>;
''');

    var typeLiteral = findNode.typeLiteral('M<int>;');
    assertTypeLiteral(typeLiteral, findElement.mixin('M'), 'M<int>');
  }

  test_typeVariableTypeAlias() async {
    await assertNoErrorsInCode('''
typedef T<E> = E;
var t = T<int>;
''');

    var typeLiteral = findNode.typeLiteral('T<int>;');
    assertTypeLiteral(typeLiteral, findElement.typeAlias('T'), 'int');
  }

  test_typeVariableTypeAlias_functionTypeArgument() async {
    await assertNoErrorsInCode('''
typedef T<E> = E;
var t = T<void Function()>;
''');

    var typeLiteral = findNode.typeLiteral('T<void Function()>;');
    assertTypeLiteral(
        typeLiteral, findElement.typeAlias('T'), 'void Function()');
  }
}

@reflectiveTest
class TypeLiteralResolutionWithoutConstructorTearoffsTest
    extends PubPackageResolutionTest with WithoutConstructorTearoffsMixin {
  test_class() async {
    await assertErrorsInCode('''
class C<T> {}
var t = C<int>;
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 23, 5),
    ]);
  }

  test_class_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    await assertErrorsInCode('''
import 'a.dart' as a;
var t = a.C<int>;
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 33, 5),
    ]);
  }
}
