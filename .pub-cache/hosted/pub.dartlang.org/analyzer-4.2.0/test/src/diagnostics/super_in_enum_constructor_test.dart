// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInEnumConstructorTest);
  });
}

@reflectiveTest
class SuperInEnumConstructorTest extends PubPackageResolutionTest {
  test_hasRedirect() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  const E.named();
  const E() : this.named(), super();
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_ENUM_CONSTRUCTOR, 61, 5),
    ]);
  }

  test_one() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  const E() : super();
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_ENUM_CONSTRUCTOR, 28, 5),
    ]);
  }

  test_two() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  const E() : super(), super();
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_ENUM_CONSTRUCTOR, 28, 5),
      error(CompileTimeErrorCode.SUPER_IN_ENUM_CONSTRUCTOR, 37, 5),
    ]);
  }
}
