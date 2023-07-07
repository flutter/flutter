// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumConstantWithNonConstConstructorTest);
  });
}

@reflectiveTest
class EnumConstantWithNonConstConstructorTest extends PubPackageResolutionTest {
  test_named() async {
    await assertErrorsInCode(r'''
enum E {
  v.named();
  factory E.named() => throw 0;
  const E(); 
}
''', [
      error(
          CompileTimeErrorCode.ENUM_CONSTANT_WITH_NON_CONST_CONSTRUCTOR, 13, 5),
    ]);
  }

  test_unnamed_withArguments() async {
    await assertErrorsInCode(r'''
enum E {
  v();
  factory E() => throw 0;
}
''', [
      error(
          CompileTimeErrorCode.ENUM_CONSTANT_WITH_NON_CONST_CONSTRUCTOR, 11, 1),
    ]);
  }

  test_unnamed_withoutArguments() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  factory E() => throw 0;
}
''', [
      error(
          CompileTimeErrorCode.ENUM_CONSTANT_WITH_NON_CONST_CONSTRUCTOR, 11, 1),
    ]);
  }
}
