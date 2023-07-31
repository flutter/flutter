// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionalParameterInOperatorTest);
  });
}

@reflectiveTest
class OptionalParameterInOperatorTest extends PubPackageResolutionTest {
  test_named() async {
    await assertErrorsInCode(r'''
class A {
  operator +({p}) {}
}
''', [
      error(CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR, 24, 1),
    ]);
  }

  test_positional() async {
    await assertErrorsInCode(r'''
class A {
  operator +([p]) {}
}
''', [
      error(CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR, 24, 1),
    ]);
  }

  test_single_required_parameter() async {
    await assertNoErrorsInCode(r'''
class A {
  operator +(p) {}
}
''');
  }
}
