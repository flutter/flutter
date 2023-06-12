// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AsyncKeywordUsedAsIdentifierTest);
  });
}

@reflectiveTest
class AsyncKeywordUsedAsIdentifierTest extends PubPackageResolutionTest {
  test_async_async() async {
    await assertErrorsInCode(r'''
class A {
  m() async {
    int async;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 32, 5),
    ]);
  }

  test_await_async() async {
    await assertErrorsInCode('''
f() async {
  var await = 1;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 18, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 5),
    ]);
  }

  test_await_asyncStar() async {
    await assertErrorsInCode('''
f() async* {
  var await = 1;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 19, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 19, 5),
    ]);
  }

  test_await_syncStar() async {
    await assertErrorsInCode('''
f() sync* {
  var await = 1;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 18, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 5),
    ]);
  }

  test_yield_async() async {
    await assertErrorsInCode('''
f() async {
  var yield = 1;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 18, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 5),
    ]);
  }

  test_yield_asyncStar() async {
    await assertErrorsInCode('''
f() async* {
  var yield = 1;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 19, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 19, 5),
    ]);
  }

  test_yield_syncStar() async {
    await assertErrorsInCode('''
f() sync* {
  var yield = 1;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 18, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 5),
    ]);
  }
}
