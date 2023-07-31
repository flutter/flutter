// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingExceptionValueTest);
  });
}

@reflectiveTest
class MissingExceptionValueTest extends PubPackageResolutionTest {
  test_missing() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef T = Int8 Function(Int8);
int f(int i) => i * 2;
void g() {
  Pointer.fromFunction<T>(f);
}
''', [
      error(FfiCode.MISSING_EXCEPTION_VALUE, 96, 12),
    ]);
  }
}
