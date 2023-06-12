// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AwaitInWrongContextTest);
  });
}

@reflectiveTest
class AwaitInWrongContextTest extends PubPackageResolutionTest {
  test_sync() async {
    await assertErrorsInCode(r'''
f(x) {
  return await x;
}
''', [
      error(CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT, 16, 5),
    ]);
  }

  test_syncStar() async {
    await assertErrorsInCode(r'''
f(x) sync* {
  yield await x;
}
''', [
      error(CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT, 21, 5),
    ]);
  }
}
