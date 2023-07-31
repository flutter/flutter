// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnqualifiedReferenceToNonLocalStaticMemberTest);
  });
}

@reflectiveTest
class UnqualifiedReferenceToNonLocalStaticMemberTest
    extends PubPackageResolutionTest {
  CompileTimeErrorCode get _errorCode =>
      CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER;

  test_getter() async {
    await assertErrorsInCode(r'''
class A {
  static int get a => 0;
}
class B extends A {
  int b() {
    return a;
  }
}
''', [
      error(_errorCode, 80, 1),
    ]);
  }

  test_getter_invokeTarget() async {
    await assertErrorsInCode(r'''
class A {
  static int foo = 1;
}

class B extends A {
  static bar() {
    foo.abs();
  }
}
''', [
      error(_errorCode, 76, 3),
    ]);
  }

  test_methodTearoff() async {
    await assertErrorsInCode('''
class A {
  static void a<T>() {}
}
class B extends A {
  void b() {
    a<int>;
  }
}
''', [
      error(_errorCode, 73, 1),
    ]);
  }

  test_readWrite() async {
    await assertErrorsInCode(r'''
class A {
  static int get x => 0;
  static set x(int _) {}
}
class B extends A {
  void f() {
    x = 0;
    x += 1;
    ++x;
    x++;
  }
}
''', [
      error(_errorCode, 99, 1),
      error(_errorCode, 110, 1),
      error(_errorCode, 124, 1),
      error(_errorCode, 131, 1),
    ]);
  }
}
