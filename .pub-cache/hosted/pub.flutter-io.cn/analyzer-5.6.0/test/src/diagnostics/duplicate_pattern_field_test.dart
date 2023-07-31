// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicatePatternFieldTest);
  });
}

@reflectiveTest
class DuplicatePatternFieldTest extends PubPackageResolutionTest {
  test_objectPattern() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case int(sign: 0, sign: 1):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_PATTERN_FIELD, 57, 4,
          contextMessages: [message('/home/test/lib/test.dart', 48, 4)]),
    ]);
  }

  test_recordPattern_dynamicType() async {
    await assertErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (foo: 0, foo: 1):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_PATTERN_FIELD, 45, 3,
          contextMessages: [message('/home/test/lib/test.dart', 37, 3)]),
    ]);
  }

  test_recordPattern_dynamicType_implicitName_duplicate() async {
    await assertErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (foo: 0, :var foo):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_PATTERN_FIELD, 45, 1,
          contextMessages: [message('/home/test/lib/test.dart', 37, 3)]),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 50, 3),
    ]);
  }

  test_recordPattern_dynamicType_implicitName_original() async {
    await assertErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (:var foo, foo: 1):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 42, 3),
      error(CompileTimeErrorCode.DUPLICATE_PATTERN_FIELD, 47, 3,
          contextMessages: [message('/home/test/lib/test.dart', 37, 1)]),
    ]);
  }

  test_recordPattern_interfaceType() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (foo: 0, foo: 1):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_PATTERN_FIELD, 53, 3,
          contextMessages: [message('/home/test/lib/test.dart', 45, 3)]),
    ]);
  }

  test_recordPattern_recordType() async {
    await assertErrorsInCode(r'''
void f(({int foo}) x) {
  switch (x) {
    case (foo: 0, foo: 1):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_PATTERN_FIELD, 57, 3,
          contextMessages: [message('/home/test/lib/test.dart', 49, 3)]),
    ]);
  }
}
