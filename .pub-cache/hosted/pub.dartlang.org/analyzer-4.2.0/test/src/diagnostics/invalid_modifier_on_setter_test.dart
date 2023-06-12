// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidModifierOnSetterTest);
  });
}

@reflectiveTest
class InvalidModifierOnSetterTest extends PubPackageResolutionTest {
  test_member_async() async {
    await assertErrorsInCode(r'''
class A {
  set x(v) async {}
}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 21, 5),
    ]);
  }

  test_member_asyncStar() async {
    await assertErrorsInCode(r'''
class A {
  set x(v) async* {}
}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 21, 5),
    ]);
  }

  test_member_syncStar() async {
    await assertErrorsInCode(r'''
class A {
  set x(v) sync* {}
}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 21, 4),
    ]);
  }

  test_topLevel_async() async {
    await assertErrorsInCode('''
set x(v) async {}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 9, 5),
    ]);
  }

  test_topLevel_asyncStar() async {
    await assertErrorsInCode('''
set x(v) async* {}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 9, 5),
    ]);
  }

  test_topLevel_syncStar() async {
    await assertErrorsInCode('''
set x(v) sync* {}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 9, 4),
    ]);
  }
}
