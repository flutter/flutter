// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveInterfaceInheritanceWithTest);
  });
}

@reflectiveTest
class RecursiveInterfaceInheritanceWithTest extends PubPackageResolutionTest {
  test_classTypeAlias() async {
    await assertErrorsInCode(r'''
class M = Object with M;
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_WITH, 6, 1),
    ]);
  }
}
