// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInitializerInObjectTest);
  });
}

@reflectiveTest
class SuperInitializerInObjectTest extends PubPackageResolutionTest {
  @failingTest
  test_superInitializerInObject() async {
    await assertErrorsInCode(r'''
class Object {
  Object() : super();
}
''', [
      error(CompileTimeErrorCode.SUPER_INITIALIZER_IN_OBJECT, 0, 0),
    ]);
  }
}
