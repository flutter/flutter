// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
        PositionalSuperFormalParameterWithPositionalArgumentTest);
  });
}

@reflectiveTest
class PositionalSuperFormalParameterWithPositionalArgumentTest
    extends PubPackageResolutionTest {
  test_notReported() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

class B extends A {
  B(super.a) : super();
}
''');
  }

  test_reported() async {
    await assertErrorsInCode(r'''
class A {
  A(int a, int b);
}

class B extends A {
  B(super.b) : super(0);
}
''', [
      error(
          CompileTimeErrorCode
              .POSITIONAL_SUPER_FORMAL_PARAMETER_WITH_POSITIONAL_ARGUMENT,
          62,
          1)
    ]);
  }
}
