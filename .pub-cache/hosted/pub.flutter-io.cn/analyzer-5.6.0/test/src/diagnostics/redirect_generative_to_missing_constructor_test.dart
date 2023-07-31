// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectGenerativeToNonGenerativeConstructorTest);
  });
}

@reflectiveTest
class RedirectGenerativeToNonGenerativeConstructorTest
    extends PubPackageResolutionTest {
  test_class_missing() async {
    await assertErrorsInCode(r'''
class A {
  A() : this.noSuchConstructor();
}
''', [
      error(CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR, 18,
          24),
    ]);
  }

  test_enum_missing() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  const E() : this.noSuchConstructor();
}
''', [
      error(CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR, 28,
          24),
    ]);
  }
}
