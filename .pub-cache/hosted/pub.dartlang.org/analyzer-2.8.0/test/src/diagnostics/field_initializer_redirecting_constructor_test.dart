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
  test_afterRedirection() async {
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

  test_beforeRedirection() async {
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

  test_redirectionOnly() async {
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
}
