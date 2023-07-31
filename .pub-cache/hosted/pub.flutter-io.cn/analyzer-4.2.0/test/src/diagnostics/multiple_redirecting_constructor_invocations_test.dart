// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MultipleRedirectingConstructorInvocationsTest);
  });
}

@reflectiveTest
class MultipleRedirectingConstructorInvocationsTest
    extends PubPackageResolutionTest {
  test_class_twoNamed() async {
    await assertErrorsInCode(r'''
class A {
  A() : this.a(), this.b();
  A.a() {}
  A.b() {}
}
''', [
      error(CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS,
          28, 8),
    ]);
  }

  test_enum_twoNamed() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  const E() : this.foo(), this.bar();
  const E.foo();
  const E.bar();
}
''', [
      error(CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS,
          40, 10),
    ]);
  }
}
