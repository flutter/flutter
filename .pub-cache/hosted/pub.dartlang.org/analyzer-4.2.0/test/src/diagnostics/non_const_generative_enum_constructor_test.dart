// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstGenerativeEnumConstructorTest);
  });
}

@reflectiveTest
class NonConstGenerativeEnumConstructorTest extends PubPackageResolutionTest {
  test_generative_const() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  const E();
}
''');
  }

  test_generative_nonConst_named() async {
    await assertErrorsInCode(r'''
enum E {
  v.named();
  E.named();
}
''', [
      error(CompileTimeErrorCode.NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR, 24, 7),
    ]);
  }

  test_generative_nonConst_unnamed() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  E();
}
''', [
      error(CompileTimeErrorCode.NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR, 16, 1),
    ]);
  }
}
