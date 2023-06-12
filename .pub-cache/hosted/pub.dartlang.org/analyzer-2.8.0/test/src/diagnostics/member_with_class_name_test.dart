// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MemberWithClassNameTest);
  });
}

@reflectiveTest
class MemberWithClassNameTest extends PubPackageResolutionTest {
  test_field() async {
    await assertErrorsInCode(r'''
class A {
  int A = 0;
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 16, 1),
    ]);
  }

  test_field_multiple() async {
    await assertErrorsInCode(r'''
class A {
  int z = 0, A = 0, b = 0;
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 23, 1),
    ]);
  }

  test_getter() async {
    await assertErrorsInCode(r'''
class A {
  get A => 0;
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 16, 1),
    ]);
  }

  test_method() async {
    // No test because a method named the same as the enclosing class is
    // indistinguishable from a constructor.
  }
}
