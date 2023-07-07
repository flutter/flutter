// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidFactoryNameNotAClassTest);
  });
}

@reflectiveTest
class InvalidFactoryNameNotAClassTest extends PubPackageResolutionTest {
  test_notClassName() async {
    await assertErrorsInCode(r'''
int B = 0;
class A {
  factory B() => throw 0;
}
''', [
      error(CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS, 31, 1),
    ]);
  }

  test_notEnclosingClassName() async {
    await assertErrorsInCode(r'''
class A {
  factory B() => throw 0;
}
''', [
      error(CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS, 20, 1),
    ]);
  }

  test_valid() async {
    await assertNoErrorsInCode(r'''
class A {
  factory A() => throw 0;
}
''');
  }
}
