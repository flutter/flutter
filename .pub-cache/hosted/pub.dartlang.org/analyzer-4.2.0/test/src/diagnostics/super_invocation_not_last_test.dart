// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInvocationNotLastTest);
  });
}

@reflectiveTest
class SuperInvocationNotLastTest extends PubPackageResolutionTest {
  test_superBeforeAssert() async {
    await assertErrorsInCode(r'''
class A {
  A(int? x) : super(), assert(x != null);
}
''', [
      error(CompileTimeErrorCode.SUPER_INVOCATION_NOT_LAST, 24, 5),
    ]);
  }

  test_superBeforeAssignment() async {
    await assertErrorsInCode(r'''
class A {
  final int x;
  A() : super(), x = 1;
}
''', [
      error(CompileTimeErrorCode.SUPER_INVOCATION_NOT_LAST, 33, 5),
    ]);
  }

  test_superIsLast() async {
    await assertNoErrorsInCode(r'''
class A {
  final int x;
  A() : x = 1, super();
}
''');
  }
}
