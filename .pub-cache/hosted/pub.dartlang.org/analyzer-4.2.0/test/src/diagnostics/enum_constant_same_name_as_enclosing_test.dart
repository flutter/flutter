// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumConstantSameNameAsEnclosingTest);
  });
}

@reflectiveTest
class EnumConstantSameNameAsEnclosingTest extends PubPackageResolutionTest {
  test_name() async {
    await assertErrorsInCode(r'''
enum E {
  E
}
''', [
      error(CompileTimeErrorCode.ENUM_CONSTANT_SAME_NAME_AS_ENCLOSING, 11, 1),
    ]);
  }
}
