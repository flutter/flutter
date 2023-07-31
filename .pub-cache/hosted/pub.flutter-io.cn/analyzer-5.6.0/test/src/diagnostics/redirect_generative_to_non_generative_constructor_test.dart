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
  test_nonGenerative() async {
    await assertErrorsInCode(r'''
class A {
  A() : this.x();
  factory A.x() => throw 0;
}
''', [
      error(
          CompileTimeErrorCode
              .REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR,
          18,
          8),
    ]);
  }
}
