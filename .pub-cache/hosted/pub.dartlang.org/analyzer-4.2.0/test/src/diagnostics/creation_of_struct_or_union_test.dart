// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreationOfStructOrUnionTest);
  });
}

@reflectiveTest
class CreationOfStructOrUnionTest extends PubPackageResolutionTest {
  test_struct() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

class A extends Struct {
  @Int32()
  external int a;
}

void f() {
  A();
}
''', [
      error(FfiCode.CREATION_OF_STRUCT_OR_UNION, 90, 1),
    ]);
  }

  test_union() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

class A extends Union {
  @Int32()
  external int a;
}

void f() {
  A();
}
''', [
      error(FfiCode.CREATION_OF_STRUCT_OR_UNION, 89, 1),
    ]);
  }
}
