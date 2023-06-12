// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectToAbstractClassConstructorTest);
  });
}

@reflectiveTest
class RedirectToAbstractClassConstructorTest extends PubPackageResolutionTest {
  test_abstractRedirectsToSelf() async {
    await assertErrorsInCode(r'''
abstract class A {
  factory A() = A._;
  A._();
}
''', [
      error(CompileTimeErrorCode.REDIRECT_TO_ABSTRACT_CLASS_CONSTRUCTOR, 35, 3),
    ]);
  }

  test_redirectsToAbstractSubclass() async {
    await assertErrorsInCode(r'''
class A {
  factory A.named() = B;
  A();
}

abstract class B extends A {}
''', [
      error(CompileTimeErrorCode.REDIRECT_TO_ABSTRACT_CLASS_CONSTRUCTOR, 32, 1),
    ]);
  }

  test_redirectsToSubclass() async {
    await assertNoErrorsInCode(r'''
class A {
  factory A.named() = B;
  A();
}

class B extends A {}
''');
  }

  test_redirectsToSubclass_asTypedef() async {
    await assertNoErrorsInCode(r'''
class A {
  factory A.named() = C;
  A();
}

class B extends A {}
typedef C = B;
''');
  }
}
