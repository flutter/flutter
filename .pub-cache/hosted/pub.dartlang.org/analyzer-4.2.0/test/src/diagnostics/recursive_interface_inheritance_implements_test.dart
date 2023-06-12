// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveInterfaceInheritanceImplementsTest);
  });
}

@reflectiveTest
class RecursiveInterfaceInheritanceImplementsTest
    extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode('''
class A implements A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS, 6,
          1),
    ]);
  }

  test_class_tail() async {
    await assertErrorsInCode(r'''
abstract class A implements A {}
class B implements A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS, 15,
          1),
    ]);
  }

  test_classTypeAlias() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class B = A with M implements B;
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS, 28,
          1),
    ]);
  }
}
