// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OverrideOnNonOverridingFieldTest);
  });
}

@reflectiveTest
class OverrideOnNonOverridingFieldTest extends PubPackageResolutionTest {
  test_inInterface() async {
    await assertErrorsInCode(r'''
class A {
  int get a => 0;
  void set b(_) {}
  int c = 0;
}
class B implements A {
  @override
  final int a = 1;
  @override
  int b = 0;
  @override
  int c = 0;
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 134, 1),
    ]);
  }

  test_inSuperclass() async {
    await assertErrorsInCode(r'''
class A {
  int get a => 0;
  void set b(_) {}
  int c = 0;
}
class B extends A {
  @override
  final int a = 1;
  @override
  int b = 0;
  @override
  int c = 0;
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 131, 1),
    ]);
  }

  test_invalid() async {
    await assertErrorsInCode(r'''
class A {
}
class B extends A {
  @override
  final int m = 1;
}''', [
      error(HintCode.OVERRIDE_ON_NON_OVERRIDING_FIELD, 56, 1),
    ]);
  }
}
