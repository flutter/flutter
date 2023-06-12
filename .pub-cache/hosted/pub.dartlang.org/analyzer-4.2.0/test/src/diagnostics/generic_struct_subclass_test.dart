// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericStructSubclassTest);
  });
}

@reflectiveTest
class GenericStructSubclassTest extends PubPackageResolutionTest {
  test_genericStruct() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class S<T> extends Struct {
  external Pointer notEmpty;
}
''', [
      error(FfiCode.GENERIC_STRUCT_SUBCLASS, 25, 1, messageContains: ["'S'"]),
    ]);
  }

  test_genericUnion() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class S<T> extends Union {
  external Pointer notEmpty;
}
''', [
      error(FfiCode.GENERIC_STRUCT_SUBCLASS, 25, 1, messageContains: ["'S'"]),
    ]);
  }

  test_validStruct() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
class S extends Struct {
  external Pointer notEmpty;
}
''');
  }
}
