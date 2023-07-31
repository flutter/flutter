// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContinueLabelInvalidTest);
  });
}

@reflectiveTest
class ContinueLabelInvalidTest extends PubPackageResolutionTest {
  test_continueLabelInvalid() async {
    await assertErrorsInCode(r'''
void f() {
  L:
  {
    for (var i in []) {
      continue L;
    }
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 33, 1),
      error(CompileTimeErrorCode.CONTINUE_LABEL_INVALID, 50, 11),
    ]);
  }
}
