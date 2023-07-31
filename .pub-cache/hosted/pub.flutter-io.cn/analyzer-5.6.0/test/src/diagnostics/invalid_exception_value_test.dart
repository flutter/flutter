// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidExceptionValueTest);
  });
}

@reflectiveTest
class InvalidExceptionValueTest extends PubPackageResolutionTest {
  test_missing() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef T = Void Function(Int8);
void f(int i) {}
void g() {
  Pointer.fromFunction<T>(f, 42);
}
''', [
      error(FfiCode.INVALID_EXCEPTION_VALUE, 109, 2),
    ]);
  }
}
