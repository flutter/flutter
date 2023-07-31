// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumInstantiatedToBoundsIsNotWellBoundedTest);
  });
}

@reflectiveTest
class EnumInstantiatedToBoundsIsNotWellBoundedTest
    extends PubPackageResolutionTest {
  test_enum_it() async {
    await assertErrorsInCode('''
typedef A<X> = X Function(X);

enum E<T extends A<T>, U> {
  v<Never, int>()
}
''', [
      error(
          CompileTimeErrorCode.ENUM_INSTANTIATED_TO_BOUNDS_IS_NOT_WELL_BOUNDED,
          36,
          1),
    ]);
  }
}
