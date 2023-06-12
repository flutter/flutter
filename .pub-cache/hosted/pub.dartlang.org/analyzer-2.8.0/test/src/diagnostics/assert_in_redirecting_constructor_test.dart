// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssertInRedirectingConstructorTest);
  });
}

@reflectiveTest
class AssertInRedirectingConstructorTest extends PubPackageResolutionTest {
  test_assertBeforeRedirection() async {
    await assertErrorsInCode(r'''
class A {}
class B {
  B(int x) : assert(x > 0), this.name();
  B.name() {}
}
''', [error(CompileTimeErrorCode.ASSERT_IN_REDIRECTING_CONSTRUCTOR, 34, 13)]);
  }

  test_justAssert() async {
    await assertNoErrorsInCode(r'''
class A {}
class B {
  B(int x) : assert(x > 0);
  B.name() {}
}
''');
  }

  test_justRedirection() async {
    await assertNoErrorsInCode(r'''
class A {}
class B {
  B(int x) : this.name();
  B.name() {}
}
''');
  }

  test_redirectionBeforeAssert() async {
    await assertErrorsInCode(r'''
class A {}
class B {
  B(int x) : this.name(), assert(x > 0);
  B.name() {}
}
''', [error(CompileTimeErrorCode.ASSERT_IN_REDIRECTING_CONSTRUCTOR, 47, 13)]);
  }
}
