// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInRedirectingConstructorTest);
  });
}

@reflectiveTest
class SuperInRedirectingConstructorTest extends PubPackageResolutionTest {
  test_redirectionSuper() async {
    await assertErrorsInCode(r'''
class A {
  A() : this.name(), super();
  A.name() {}
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR, 31, 7),
    ]);
  }

  test_superRedirection() async {
    await assertErrorsInCode(r'''
class A {
  A() : super(), this.name();
  A.name() {}
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR, 18, 7),
    ]);
  }
}
