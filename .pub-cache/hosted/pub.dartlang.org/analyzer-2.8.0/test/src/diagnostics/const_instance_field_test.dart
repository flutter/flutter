// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstInstanceFieldTest);
  });
}

@reflectiveTest
class ConstInstanceFieldTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
class C {
  const int f = 0;
}
''', [
      error(CompileTimeErrorCode.CONST_INSTANCE_FIELD, 12, 5),
    ]);
  }

  test_mixin() async {
    await assertErrorsInCode(r'''
mixin C {
  const int f = 0;
}
''', [
      error(CompileTimeErrorCode.CONST_INSTANCE_FIELD, 12, 5),
    ]);
  }
}
