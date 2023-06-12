// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixShadowedByLocalDeclarationTest);
  });
}

@reflectiveTest
class PrefixShadowedByLocalDeclarationTest extends PubPackageResolutionTest {
  test_function_return_type_not_shadowed_by_parameter() async {
    await assertNoErrorsInCode('''
import 'dart:async' as a;
a.Future? f(int a) {
  return null;
}
''');
  }

  test_local_variable_type_inside_function_with_shadowing_parameter() async {
    await assertErrorsInCode('''
import 'dart:async' as a;
f(int a) {
  a.Future? x = null;
  return x;
}
''', [
      error(HintCode.UNUSED_IMPORT, 7, 12),
      error(CompileTimeErrorCode.PREFIX_SHADOWED_BY_LOCAL_DECLARATION, 39, 1),
    ]);
  }

  test_local_variable_type_inside_function_with_shadowing_variable_after() async {
    await assertErrorsInCode('''
import 'dart:async' as a;
f() {
  a.Future? x = null;
  int a = 0;
  return [x, a];
}
''', [
      error(HintCode.UNUSED_IMPORT, 7, 12),
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 34, 1,
          contextMessages: [message('$testPackageLibPath/test.dart', 60, 1)]),
      error(CompileTimeErrorCode.PREFIX_SHADOWED_BY_LOCAL_DECLARATION, 34, 1),
    ]);
  }

  test_local_variable_type_inside_function_with_shadowing_variable_before() async {
    await assertErrorsInCode('''
import 'dart:async' as a;
f() {
  int a = 0;
  a.Future? x = null;
  return [x, a];
}
''', [
      error(HintCode.UNUSED_IMPORT, 7, 12),
      error(CompileTimeErrorCode.PREFIX_SHADOWED_BY_LOCAL_DECLARATION, 47, 1),
    ]);
  }
}
