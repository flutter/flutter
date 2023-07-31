// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionOverrideArgumentNotAssignableTest);
    defineReflectiveTests(
      ExtensionOverrideArgumentNotAssignableWithoutNullSafetyTest,
    );
  });
}

@reflectiveTest
class ExtensionOverrideArgumentNotAssignableTest
    extends PubPackageResolutionTest {
  test_override_onNonNullable() async {
    await assertErrorsInCode(r'''
extension E on String {
  void m() {}
}
f() {
  E(null).m();
}
''', [
      error(CompileTimeErrorCode.EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE, 50,
          4),
    ]);
  }

  test_override_onNullable() async {
    await assertNoErrorsInCode(r'''
extension E on String? {
  void m() {}
}
f() {
  E(null).m();
}
''');
  }
}

@reflectiveTest
class ExtensionOverrideArgumentNotAssignableWithoutNullSafetyTest
    extends PubPackageResolutionTest with WithoutNullSafetyMixin {
  test_subtype() async {
    await assertNoErrorsInCode('''
class A {}
class B extends A {}
extension E on A {
  void m() {}
}
void f(B b) {
  E(b).m();
}
''');
  }

  test_supertype() async {
    // This will be an error under NNBD.
    await assertNoErrorsInCode('''
class A {}
class B extends A {}
extension E on B {
  void m() {}
}
void f(A a) {
  E(a).m();
}
''');
  }

  test_unrelated() async {
    await assertErrorsInCode('''
class A {}
class B {}
extension E on A {
  void m() {}
}
void f(B b) {
  E(b).m();
}
''', [
      error(CompileTimeErrorCode.EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE, 75,
          1),
    ]);
  }
}
