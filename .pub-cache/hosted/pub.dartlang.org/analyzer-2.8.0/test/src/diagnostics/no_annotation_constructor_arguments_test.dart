// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoAnnotationConstructorArgumentsTest);
  });
}

@reflectiveTest
class NoAnnotationConstructorArgumentsTest extends PubPackageResolutionTest {
  test_missingArgumentList() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
@A
main() {
}
''', [
      error(CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS, 25, 2),
    ]);
  }
}
