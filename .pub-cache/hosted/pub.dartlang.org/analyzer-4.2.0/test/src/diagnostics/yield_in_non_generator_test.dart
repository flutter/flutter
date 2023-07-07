// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(YieldInNonGeneratorTest);
  });
}

@reflectiveTest
class YieldInNonGeneratorTest extends PubPackageResolutionTest {
  @FailingTest(
      reason: 'We are currently trying to parse the yield statement as a '
          'binary expression.')
  test_async() async {
    await assertErrorsInCode(r'''
f() async {
  yield 0;
}
''', [
      error(CompileTimeErrorCode.YIELD_IN_NON_GENERATOR, 0, 0),
    ]);
  }

  test_asyncStar() async {
    await assertNoErrorsInCode(r'''
f() async* {
  yield 0;
}
''');
  }

  @FailingTest(
      reason: 'We are currently trying to parse the yield statement as a '
          'binary expression.')
  test_sync() async {
    await assertErrorsInCode(r'''
f() {
  yield 0;
}
''', [
      error(CompileTimeErrorCode.YIELD_IN_NON_GENERATOR, 0, 0),
    ]);
  }

  test_syncStar() async {
    await assertNoErrorsInCode(r'''
f() sync* {
  yield 0;
}
''');
  }
}
