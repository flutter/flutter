// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticAccessToInstanceMemberTest);
  });
}

@reflectiveTest
class StaticAccessToInstanceMemberTest extends PubPackageResolutionTest {
  test_annotation() async {
    await assertNoErrorsInCode(r'''
class A {
  const A.name();
}
@A.name()
main() {
}
''');
  }

  test_extension_getter() async {
    await assertErrorsInCode('''
extension E on int {
  int get g => 0;
}
f() {
  E.g;
}
''', [
      error(CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 51, 1),
    ]);
  }

  test_extension_method() async {
    await assertErrorsInCode('''
extension E on int {
  void m() {}
}
f() {
  E.m();
}
''', [
      error(CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 47, 1),
    ]);
  }

  test_extension_setter() async {
    await assertErrorsInCode('''
extension E on int {
  void set s(int i) {}
}
f() {
  E.s = 2;
}
''', [
      error(CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 56, 1),
    ]);
  }

  test_method_invocation() async {
    await assertErrorsInCode('''
class A {
  m() {}
}
main() {
  A.m();
}''', [
      error(CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 34, 1),
    ]);
  }

  test_method_reference() async {
    await assertErrorsInCode('''
class A {
  m() {}
}
main() {
  A.m;
}''', [
      error(CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 34, 1),
    ]);
  }

  test_propertyAccess_field() async {
    await assertErrorsInCode('''
class A {
  var f;
}
main() {
  A.f;
}''', [
      error(CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 34, 1),
    ]);
  }

  test_propertyAccess_field_toplevel_generic() async {
    await assertErrorsInCode('''
class C<T> {
  List<T> t = [];
}
var x = C.t;
''', [
      error(CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 43, 1),
    ]);
  }

  test_propertyAccess_getter() async {
    await assertErrorsInCode('''
class A {
  get f => 42;
}
main() {
  A.f;
}''', [
      error(CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 40, 1),
    ]);
  }

  test_propertyAccess_setter() async {
    await assertErrorsInCode('''
class A {
  set f(x) {}
}
main() {
  A.f = 42;
}''', [
      error(CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 39, 1),
    ]);
  }

  test_static_method() async {
    await assertNoErrorsInCode(r'''
class A {
  static m() {}
}
main() {
  A.m;
  A.m();
}
''');
  }

  test_static_propertyAccess_field() async {
    await assertNoErrorsInCode(r'''
class A {
  static var f;
}
main() {
  A.f;
  A.f = 1;
}
''');
  }

  test_static_propertyAccess_propertyAccessor() async {
    await assertNoErrorsInCode(r'''
class A {
  static get f => 42;
  static set f(x) {}
}
main() {
  A.f;
  A.f = 1;
}
''');
  }
}
