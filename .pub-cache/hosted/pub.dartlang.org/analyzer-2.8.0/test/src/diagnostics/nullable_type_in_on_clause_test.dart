// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullableTypeInOnClauseTest);
  });
}

@reflectiveTest
class NullableTypeInOnClauseTest extends PubPackageResolutionTest {
  test_nonNullable() async {
    await assertNoErrorsInCode('''
class A {}
mixin B on A {}
''');
  }

  test_nullable() async {
    await assertErrorsInCode('''
class A {}
mixin B on A? {}
''', [
      error(CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE, 22, 2),
    ]);
  }

  test_nullable_alias() async {
    await assertErrorsInCode('''
class A {}
typedef B = A;
mixin C on B? {}
''', [
      error(CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE, 37, 2),
    ]);
  }

  test_nullable_alias2() async {
    await assertErrorsInCode('''
class A {}
typedef B = A?;
mixin C on B {}
''', [
      error(CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE, 38, 1),
    ]);
  }
}
