// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForInWithConstVariableTest);
  });
}

@reflectiveTest
class ForInWithConstVariableTest extends PubPackageResolutionTest {
  test_forEach_loopVariable() async {
    await assertErrorsInCode(r'''
f() {
  for (const x in [0, 1, 2]) {
    print(x);
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_WITH_CONST_VARIABLE, 13, 5),
    ]);
  }
}
