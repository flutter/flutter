// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MustCallSuperTest);
  });
}

@reflectiveTest
class MustCallSuperTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_containsSuperCall() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class C extends A {
  @override
  void a() {
    super.a(); // OK
  }
}
''');
  }

  test_fromExtendingClass() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class B extends A {
  @override
  void a() {}
}
''', [
      error(HintCode.MUST_CALL_SUPER, 115, 1),
    ]);
  }

  test_fromExtendingClass_abstractInSubclass() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
abstract class A {
  @mustCallSuper
  void a() {}
}
class B extends A {
  @override
  void a();
}
''');
  }

  test_fromExtendingClass_abstractInSuperclass() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
abstract class A {
  @mustCallSuper
  void a();
}
class B extends A {
  @override
  void a() {}
}
''');
  }

  test_fromExtendingClass_genericClass() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A<T> {
  @mustCallSuper
  void a() {}
}
class B extends A<int> {
  @override
  void a() {}
}
''', [
      error(HintCode.MUST_CALL_SUPER, 123, 1),
    ]);
  }

  test_fromExtendingClass_genericMethod() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a<T>() {}
}
class B extends A {
  @override
  void a<T>() {}
}
''', [
      error(HintCode.MUST_CALL_SUPER, 118, 1),
    ]);
  }

  test_fromExtendingClass_getter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  int get a => 1;
}
class B extends A {
  @override
  int get a => 2;
}
''', [
      error(HintCode.MUST_CALL_SUPER, 122, 1),
    ]);
  }

  test_fromExtendingClass_getter_containsSuperCall() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  int get a => 1;
}
class B extends A {
  @override
  int get a {
    super.a;
    return 2;
  }
}
''');
  }

  test_fromExtendingClass_getter_invokesSuper_setter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int get foo => 0;

  set foo(int _) {}
}

class B extends A {
  int get foo {
    super.foo = 0;
    return 0;
  }
}
''', [
      error(HintCode.MUST_CALL_SUPER, 135, 3),
    ]);
  }

  test_fromExtendingClass_operator() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  operator ==(Object o) => o is A;
}
class B extends A {
  @override
  operator ==(Object o) => o is B;
}
''', [
      error(HintCode.MUST_CALL_SUPER, 140, 2),
    ]);
  }

  test_fromExtendingClass_operator_containsSuperCall() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  operator ==(Object o) => o is A;
}
class B extends A {
  @override
  operator ==(Object o) => o is B && super == o;
}
''');
  }

  test_fromExtendingClass_setter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  set a(int value) {}
}
class B extends A {
  @override
  set a(int value) {}
}
''', [
      error(HintCode.MUST_CALL_SUPER, 122, 1),
    ]);
  }

  test_fromExtendingClass_setter_containsSuperCall() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  set a(int value) {}
}
class B extends A {
  @override
  set a(int value) {
    super.a = value;
  }
}
''');
  }

  test_fromExtendingClass_setter_invokesSuper_getter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  int get foo => 0;

  @mustCallSuper
  set foo(int _) {}
}

class B extends A {
  set foo(int _) {
    super.foo;
  }
}
''', [
      error(HintCode.MUST_CALL_SUPER, 131, 3),
    ]);
  }

  test_fromInterface() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class C implements A {
  @override
  void a() {}
}
''');
  }

  test_fromMixin() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class Mixin {
  @mustCallSuper
  void a() {}
}
class C with Mixin {
  @override
  void a() {}
}
''', [
      error(HintCode.MUST_CALL_SUPER, 120, 1),
    ]);
  }

  test_fromMixin_setter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class Mixin {
  @mustCallSuper
  void set a(int value) {}
}
class C with Mixin {
  @override
  void set a(int value) {}
}
''', [
      error(HintCode.MUST_CALL_SUPER, 137, 1),
    ]);
  }

  test_fromMixin_throughExtendingClass() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
mixin M {
  @mustCallSuper
  void a() {}
}
class C with M {}
class D extends C {
  @override
  void a() {}
}
''', [
      error(HintCode.MUST_CALL_SUPER, 133, 1),
    ]);
  }

  test_indirectlyInherited() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class C extends A {
  @override
  void a() {
    super.a();
  }
}
class D extends C {
  @override
  void a() {}
}
''', [
      error(HintCode.MUST_CALL_SUPER, 181, 1),
    ]);
  }

  test_indirectlyInheritedFromMixin() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class Mixin {
  @mustCallSuper
  void b() {}
}
class C extends Object with Mixin {}
class D extends C {
  @override
  void b() {}
}
''', [
      error(HintCode.MUST_CALL_SUPER, 156, 1),
    ]);
  }

  test_indirectlyInheritedFromMixinConstraint() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
mixin C on A {
  @override
  void a() {}
}
''', [
      error(HintCode.MUST_CALL_SUPER, 110, 1),
    ]);
  }

  test_overriddenWithFuture() async {
    // https://github.com/flutter/flutter/issues/11646
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  Future<Null> bar() => new Future<Null>.value();
}
class C extends A {
  @override
  Future<Null> bar() {
    final value = super.bar();
    return value.then((Null _) {
      return null;
    });
  }
}
''');
  }

  test_overriddenWithFuture2() async {
    // https://github.com/flutter/flutter/issues/11646
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  Future<Null> bar() => new Future<Null>.value();
}
class C extends A {
  @override
  Future<Null> bar() {
    return super.bar().then((Null _) {
      return null;
    });
  }
}
''');
  }
}
