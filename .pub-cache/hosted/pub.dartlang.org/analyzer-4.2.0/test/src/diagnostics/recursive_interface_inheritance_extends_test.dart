// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveInterfaceInheritanceExtendsTest);
  });
}

@reflectiveTest
class RecursiveInterfaceInheritanceExtendsTest
    extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
class A extends A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS, 6, 1),
    ]);
  }

  test_class_abstract() async {
    await assertErrorsInCode(r'''
class C extends C {
  var foo = 0;
  bar();
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS, 6, 1),
    ]);
  }
}
