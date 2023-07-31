// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveFactoryRedirectTest);
  });
}

@reflectiveTest
class RecursiveFactoryRedirectTest extends PubPackageResolutionTest {
  test_directSelfReference() async {
    await assertErrorsInCode(r'''
class A {
  factory A() = A;
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 26, 1),
    ]);
  }

  test_diverging() async {
    // Analysis should terminate even though the redirections don't reach a
    // fixed point.  (C<int> redirects to C<C<int>>, then to C<C<C<int>>>, and
    // so on).
    await assertErrorsInCode('''
class C<T> {
  const factory C() = C<C<T>>;
}
main() {
  const C<int>();
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 35, 7),
    ]);
  }

  test_generic() async {
    await assertErrorsInCode(r'''
class A<T> implements B<T> {
  factory A() = C;
}
class B<T> implements C<T> {
  factory B() = A;
}
class C<T> implements A<T> {
  factory C() = B;
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 45, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 56, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 95, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 106, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 145, 1),
    ]);
  }

  test_loop() async {
    await assertErrorsInCode(r'''
class A implements B {
  factory A() = C;
}
class B implements C {
  factory B() = A;
}
class C implements A {
  factory C() = B;
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 39, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 50, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 83, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 94, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 127, 1),
    ]);
  }

  test_named() async {
    await assertErrorsInCode(r'''
class A implements B {
  factory A.nameA() = C.nameC;
}
class B implements C {
  factory B.nameB() = A.nameA;
}
class C implements A {
  factory C.nameC() = B.nameB;
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 45, 7),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 62, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 101, 7),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 118, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 157, 7),
    ]);
  }

  test_outsideCycle() async {
    // "A" references "C" which has cycle with "B". But we should not report
    // problem for "A" - it is not the part of a cycle.
    await assertErrorsInCode(r'''
class A {
  factory A() = C;
}
class B implements C {
  factory B() = C;
}
class C implements A, B {
  factory C() = B;
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 37, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 70, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 81, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 117, 1),
    ]);
  }

  test_valid_redirect() async {
    await assertNoErrorsInCode(r'''
class A {
  factory A() = B;
}
class B implements A {
  factory B() = C;
}
class C implements B {
  factory C() => throw 0;
}
''');
  }
}
