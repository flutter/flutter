// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoCombinedSuperSignatureTest);
  });
}

@reflectiveTest
class NoCombinedSuperSignatureTest extends PubPackageResolutionTest {
  test_conflictingParameter() async {
    await assertErrorsInCode('''
abstract class A {
  void foo(int x);
}

abstract class B {
  void foo(double x);
}

abstract class C implements A, B {
  foo(num x);
}
''', [
      error(CompileTimeErrorCode.NO_COMBINED_SUPER_SIGNATURE, 122, 3),
    ]);
  }

  /// If the method is subject to override inference, it is already an error
  /// when no combined super signature exist.
  ///
  /// It does not matter that the conflicting component (the return type here)
  /// was resolved.
  test_conflictingReturnType() async {
    await assertErrorsInCode('''
abstract class A {
  int foo(int x);
}

abstract class B {
  double foo(int x);
}

abstract class C implements A, B {
  Never foo(x);
}
''', [
      error(CompileTimeErrorCode.NO_COMBINED_SUPER_SIGNATURE, 126, 3),
    ]);
  }

  test_noInvalidOverrideErrors() async {
    await assertErrorsInCode('''
abstract class A {
  String foo(String a);
}

abstract class B {
  int foo(int a);
}

abstract class C implements A, B {
  foo(a);
}
''', [
      error(CompileTimeErrorCode.NO_COMBINED_SUPER_SIGNATURE, 123, 3),
    ]);
  }
}
