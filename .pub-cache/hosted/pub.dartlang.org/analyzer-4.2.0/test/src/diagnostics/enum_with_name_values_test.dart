// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumWithNameValuesTest);
  });
}

@reflectiveTest
class EnumWithNameValuesTest extends PubPackageResolutionTest {
  test_name() async {
    await assertErrorsInCode(r'''
enum values {
  v
}
''', [
      error(CompileTimeErrorCode.ENUM_WITH_NAME_VALUES, 5, 6),
    ]);
  }
}
