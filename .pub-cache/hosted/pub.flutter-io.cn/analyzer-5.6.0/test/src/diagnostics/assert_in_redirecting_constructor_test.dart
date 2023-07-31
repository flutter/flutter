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
  test_class_assertBeforeRedirection() async {
    await assertErrorsInCode(r'''
class A {
  A(int x) : assert(x > 0), this.name();
  A.name() {}
}
''', [error(CompileTimeErrorCode.ASSERT_IN_REDIRECTING_CONSTRUCTOR, 23, 13)]);
  }

  test_class_justAssert() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int x) : assert(x > 0);
  A.name() {}
}
''');
  }

  test_class_justRedirection() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int x) : this.name();
  A.name() {}
}
''');
  }

  test_class_redirectionBeforeAssert() async {
    await assertErrorsInCode(r'''
class A {
  A(int x) : this.name(), assert(x > 0);
  A.name() {}
}
''', [error(CompileTimeErrorCode.ASSERT_IN_REDIRECTING_CONSTRUCTOR, 36, 13)]);
  }

  test_enum_assertBeforeRedirection() async {
    await assertErrorsInCode(r'''
enum E {
  v(42);
  const E(int x) : assert(x > 0), this.name();
  const E.name();
}
''', [error(CompileTimeErrorCode.ASSERT_IN_REDIRECTING_CONSTRUCTOR, 37, 13)]);
  }

  test_enum_justAssert() async {
    await assertNoErrorsInCode(r'''
enum E {
  v(42);
  const E(int x) : assert(x > 0);
}
''');
  }

  test_enum_justRedirection() async {
    await assertNoErrorsInCode(r'''
enum E {
  v(0);
  const E(int x) : this.name();
  const E.name();
}
''');
  }

  test_enum_redirectionBeforeAssert() async {
    await assertErrorsInCode(r'''
enum E {
  v(42);
  const E(int x) : this.name(), assert(x > 0);
  const E.name();
}
''', [error(CompileTimeErrorCode.ASSERT_IN_REDIRECTING_CONSTRUCTOR, 50, 13)]);
  }
}
