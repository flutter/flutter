// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericTypeAliasDriverResolutionTest);
    defineReflectiveTests(
        GenericTypeAliasDriverResolutionWithoutGenericMetadataTest);
  });
}

@reflectiveTest
class GenericTypeAliasDriverResolutionTest extends PubPackageResolutionTest
    with GenericTypeAliasDriverResolutionTestCases {
  test_genericFunctionTypeCannotBeTypeArgument_def_class() async {
    await assertNoErrorsInCode(r'''
class C<T> {}

typedef G = Function<S>();

C<G>? x;
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_class() async {
    await assertNoErrorsInCode(r'''
class C<T> {}

C<Function<S>()>? x;
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_function() async {
    await assertNoErrorsInCode(r'''
void f<T>(T) {}

main() {
  f<Function<S>()>(null);
}
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_functionType() async {
    await assertNoErrorsInCode(r'''
late T Function<T>(T?) f;

main() {
  f<Function<S>()>(null);
}
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_method() async {
    await assertNoErrorsInCode(r'''
class C {
  void f<T>(T) {}
}

main() {
  new C().f<Function<S>()>(null);
}
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_typedef() async {
    await assertNoErrorsInCode(r'''
typedef T F<T>(T t);

F<Function<S>()>? x;
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_optOutOfGenericMetadata() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef G = Function<S>();
''');
    await assertErrorsInCode('''
// @dart=2.12
import 'a.dart';
class C<T> {}
C<G>? x;
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
          47, 1),
    ]);
  }
}

mixin GenericTypeAliasDriverResolutionTestCases on PubPackageResolutionTest {
  test_genericFunctionTypeCannotBeTypeArgument_OK_def_class() async {
    await assertNoErrorsInCode(r'''
class C<T> {}

typedef G = Function();

C<G> x = C();
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_OK_literal_class() async {
    await assertNoErrorsInCode(r'''
class C<T> {}

C<Function()> x = C();
''');
  }

  test_missingGenericFunction() async {
    await assertErrorsInCode(r'''
typedef F<T> = ;

void f() {
  F.a;
}
''', [
      error(ParserErrorCode.EXPECTED_TYPE_NAME, 15, 1),
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 15, 0),
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 33, 1),
    ]);
  }

  test_missingGenericFunction_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef F<T> = ;
''');
    await assertErrorsInCode(r'''
import 'a.dart' as p;

void f() {
  p.F.a;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 40, 1),
    ]);
  }

  test_type_element() async {
    await assertNoErrorsInCode(r'''
G<int>? g;

typedef G<T> = T Function(double);
''');
    var type = findElement.topVar('g').type as FunctionType;
    assertType(type, 'int Function(double)?');
    assertTypeAlias(
      type,
      element: findElement.typeAlias('G'),
      typeArguments: ['int'],
    );
  }

  test_typeParameters() async {
    await assertNoErrorsInCode(r'''
class A {}

class B {}

typedef F<T extends A> = B Function<U extends B>(T a, U b);
''');
    var f = findElement.typeAlias('F');
    expect(f.typeParameters, hasLength(1));

    var t = f.typeParameters[0];
    expect(t.name, 'T');
    assertType(t.bound, 'A');

    var ff = f.aliasedElement as GenericFunctionTypeElement;
    expect(ff.typeParameters, hasLength(1));

    var u = ff.typeParameters[0];
    expect(u.name, 'U');
    assertType(u.bound, 'B');
  }
}

@reflectiveTest
class GenericTypeAliasDriverResolutionWithoutGenericMetadataTest
    extends PubPackageResolutionTest
    with GenericTypeAliasDriverResolutionTestCases {
  @override
  List<String> get experiments =>
      super.experiments..remove(EnableString.generic_metadata);

  test_genericFunctionTypeCannotBeTypeArgument_def_class() async {
    await assertErrorsInCode(r'''
// @dart=2.12
class C<T> {}

typedef G = Function<S>();

C<G>? x;
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
          59, 1),
    ]);
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_class() async {
    await assertErrorsInCode(r'''
// @dart=2.12
class C<T> {}

C<Function<S>()>? x;
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
          31, 13),
    ]);
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_function() async {
    await assertErrorsInCode(r'''
// @dart=2.12
void f<T>(T) {}

main() {
  f<Function<S>()>(null);
}
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
          44, 13),
    ]);
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_functionType() async {
    await assertErrorsInCode(r'''
// @dart=2.12
late T Function<T>(T?) f;

main() {
  f<Function<S>()>(null);
}
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
          54, 13),
    ]);
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_method() async {
    await assertErrorsInCode(r'''
// @dart=2.12
class C {
  void f<T>(T) {}
}

main() {
  new C().f<Function<S>()>(null);
}
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
          66, 13),
    ]);
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_typedef() async {
    await assertErrorsInCode(r'''
// @dart=2.12
typedef T F<T>(T t);

F<Function<S>()>? x;
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
          38, 13),
    ]);
  }
}
