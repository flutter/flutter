// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnInGeneratorTest);
  });
}

@reflectiveTest
class ReturnInGeneratorTest extends PubPackageResolutionTest {
  test_async() async {
    await assertNoErrorsInCode(r'''
f() async {
  return 0;
}
''');
  }

  test_asyncStar_blockBody() async {
    await assertErrorsInCode(r'''
f() async* {
  return 0;
}
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATOR, 15, 6),
    ]);
  }

  test_asyncStar_blockBody_noValue() async {
    await assertNoErrorsInCode('''
Stream<int> f() async* {
  return;
}
''');
  }

  test_asyncStar_expressionBody() async {
    await assertErrorsInCode(r'''
f() async* => 0;
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATOR, 11, 2),
    ]);
  }

  test_sync() async {
    await assertNoErrorsInCode(r'''
f() {
  return 0;
}
''');
  }

  test_syncStar_blockBody() async {
    await assertErrorsInCode(r'''
f() sync* {
  return 0;
}
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATOR, 14, 6),
    ]);
  }

  test_syncStar_blockBody_noValue() async {
    await assertNoErrorsInCode('''
Iterable<int> f() sync* {
  return;
}
''');
  }

  test_syncStar_expressionBody() async {
    await assertErrorsInCode(r'''
f() sync* => 0;
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATOR, 10, 2),
    ]);
  }
}
