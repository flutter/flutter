// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AsyncForInWrongContextTest);
  });
}

@reflectiveTest
class AsyncForInWrongContextTest extends PubPackageResolutionTest {
  test_syncFunction() async {
    await assertErrorsInCode(r'''
f(list) {
  await for (var e in list) {
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 27, 1),
      error(CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT, 29, 2),
    ]);
  }
}
