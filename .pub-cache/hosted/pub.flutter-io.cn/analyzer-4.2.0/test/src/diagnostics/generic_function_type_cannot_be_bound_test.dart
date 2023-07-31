// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericFunctionTypeCannotBeBoundTest);
    defineReflectiveTests(
        GenericFunctionTypeCannotBeBoundWithoutGenericMetadataTest);
  });
}

@reflectiveTest
class GenericFunctionTypeCannotBeBoundTest extends PubPackageResolutionTest {
  test_class() async {
    await assertNoErrorsInCode(r'''
class C<T extends S Function<S>(S)> {
}
''');
  }

  test_genericFunction() async {
    await assertNoErrorsInCode(r'''
late T Function<T extends S Function<S>(S)>(T) fun;
''');
  }

  test_genericFunction_optOutOfGenericMetadata() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef F = S Function<S>(S);
''');
    await assertErrorsInCode('''
// @dart=2.12
import 'a.dart';
late T Function<T extends F>(T) fun;
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND, 57, 1),
    ]);
  }

  test_genericFunctionTypedef() async {
    await assertNoErrorsInCode(r'''
typedef foo = T Function<T extends S Function<S>(S)>(T t);
''');
  }

  test_parameterOfFunction() async {
    await assertNoErrorsInCode(r'''
class C<T extends void Function(S Function<S>(S))> {}
''');
  }

  test_typedef() async {
    await assertNoErrorsInCode(r'''
typedef T foo<T extends S Function<S>(S)>(T t);
''');
  }
}

@reflectiveTest
class GenericFunctionTypeCannotBeBoundWithoutGenericMetadataTest
    extends PubPackageResolutionTest {
  @override
  List<String> get experiments =>
      super.experiments..remove(EnableString.generic_metadata);

  test_class() async {
    await assertErrorsInCode(r'''
// @dart=2.12
class C<T extends S Function<S>(S)> {
}
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND, 32, 16),
    ]);
  }

  test_genericFunction() async {
    await assertErrorsInCode(r'''
// @dart=2.12
late T Function<T extends S Function<S>(S)>(T) fun;
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND, 40, 16),
    ]);
  }

  test_genericFunctionTypedef() async {
    await assertErrorsInCode(r'''
// @dart=2.12
typedef foo = T Function<T extends S Function<S>(S)>(T t);
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND, 49, 16),
    ]);
  }

  test_parameterOfFunction() async {
    await assertNoErrorsInCode(r'''
class C<T extends void Function(S Function<S>(S))> {}
''');
  }

  test_typedef() async {
    await assertErrorsInCode(r'''
// @dart=2.12
typedef T foo<T extends S Function<S>(S)>(T t);
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND, 38, 16),
    ]);
  }
}
