// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializerRedirectingConstructorTest);
  });
}

@reflectiveTest
class FieldInitializerRedirectingConstructorTest
    extends PubPackageResolutionTest {
  test_class_afterRedirection() async {
    await assertErrorsInCode(r'''
class A {
  int x = 0;
  A.named() {}
  A() : this.named(), x = 42;
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, 60,
          6),
    ]);
  }

  test_class_beforeRedirection() async {
    await assertErrorsInCode(r'''
class A {
  int x = 0;
  A.named() {}
  A() : x = 42, this.named();
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, 46,
          6),
    ]);
  }

  test_class_redirectionOnly() async {
    await assertErrorsInCode(r'''
class A {
  int x = 0;
  A.named() {}
  A(this.x) : this.named();
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, 42,
          6),
    ]);
  }

  test_enum_afterRedirection() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final int x;
  const E.named() : x = 0;
  const E() : this.named(), x = 42;
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, 84,
          6),
    ]);
  }

  test_enum_beforeRedirection() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final int x;
  const E.named() : x = 0;
  const E() : x = 42, this.named();
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, 70,
          6),
    ]);
  }

  test_enum_redirectionOnly() async {
    await assertErrorsInCode(r'''
enum E {
  v(0);
  final int x;
  const E.named() : x = 0;
  const E(this.x) : this.named();
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, 69,
          6),
    ]);
  }
}
