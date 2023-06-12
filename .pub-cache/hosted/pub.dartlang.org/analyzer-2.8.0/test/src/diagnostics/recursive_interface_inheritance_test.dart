// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveInterfaceInheritanceTest);
  });
}

@reflectiveTest
class RecursiveInterfaceInheritanceTest extends PubPackageResolutionTest {
  test_loop() async {
    await assertErrorsInCode('''
class A implements B {}
class B implements A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 30, 1),
    ]);
  }

  test_loop_generic() async {
    await assertErrorsInCode('''
class A<T> implements B<T> {}
class B<T> implements A<T> {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 36, 1),
    ]);
  }

  test_loop_generic_typeArgument() async {
    await assertErrorsInCode('''
class A<T> implements B<List<T>> {}
class B<T> implements A<List<T>> {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 42, 1),
    ]);
  }
}
