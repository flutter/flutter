// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceMemberInferenceClassTest);
  });
}

@reflectiveTest
class InstanceMemberInferenceClassTest extends PubPackageResolutionTest {
  test_invalid_inheritanceCycle() async {
    await resolveTestCode('''
class A extends C {}
class B extends A {}
class C extends B {}
''');
  }

  test_method_parameter_named_multiple_combined() async {
    await resolveTestCode('''
class A {
  void foo({int p}) {}
}
class B {
  void foo({num p}) {}
}
mixin M on A, B {
  void foo({p}) {}
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertType(p.type, 'num');
  }

  test_method_parameter_named_multiple_incompatible() async {
    await resolveTestCode('''
class A {
  void foo({int p}) {}
}
class B {
  void foo({int q}) {}
}
mixin M on A, B {
  void foo({p}) {}
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertTypeDynamic(p.type);
  }

  test_method_parameter_named_multiple_same() async {
    await resolveTestCode('''
class A {
  void foo({int p}) {}
}
class B {
  void foo({int p}) {}
}
mixin M on A, B {
  void foo({p}) {}
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertType(p.type, 'int');
  }

  test_method_parameter_namedAndRequired() async {
    await resolveTestCode('''
class A {
  void foo({int p}) {}
}
class B {
  void foo(int p) {}
}
mixin M on A, B {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertTypeDynamic(p.type);
  }

  test_method_parameter_required_multiple_combined() async {
    await resolveTestCode('''
class A {
  void foo(int p) {}
}
class B {
  void foo(num p) {}
}
mixin M on A, B {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertType(p.type, 'num');
  }

  test_method_parameter_required_multiple_different_merge() async {
    await resolveTestCode('''
class A {
  void foo(Object? p) {}
}

class B {
  void foo(dynamic p) {}
}

mixin M on A, B {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertType(p.type, 'Object?');
  }

  test_method_parameter_required_multiple_incompatible() async {
    await resolveTestCode('''
class A {
  void foo(int p) {}
}
class B {
  void foo(double p) {}
}
mixin M on A, B {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertTypeDynamic(p.type);
  }

  test_method_parameter_required_multiple_same() async {
    await resolveTestCode('''
class A {
  void foo(int p) {}
}
class B {
  void foo(int p) {}
}
mixin M on A, B {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertType(p.type, 'int');
  }

  test_method_parameter_required_single_generic() async {
    await resolveTestCode('''
class A<E> {
  void foo(E p) {}
}
mixin M<T> on A<T> {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertType(p.type, 'T');
  }

  test_method_parameter_requiredAndPositional() async {
    await resolveTestCode('''
class A {
  void foo(int p) {}
}
class B {
  void foo([int p]) {}
}
mixin M on A, B {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'M').parameters[0];
    assertType(p.type, 'int');
  }

  test_method_return_multiple_different_combined() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B {
  num foo() => 0.0;
}
mixin M on A, B {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertType(foo.returnType, 'int');
  }

  test_method_return_multiple_different_dynamic() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B {
  foo() => 0;
}
mixin M on A, B {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertType(foo.returnType, 'int');
  }

  test_method_return_multiple_different_generic() async {
    await resolveTestCode('''
class A<E> {
  E foo() => throw 0;
}
class B<E> {
  E foo() => throw 0;
}
mixin M on A<int>, B<double> {
  foo() => throw 0;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_different_incompatible() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B {
  double foo() => 0.0;
}
mixin M on A, B {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_different_merge() async {
    await resolveTestCode('''
class A {
  Object? foo() => throw 0;
}

class B {
  dynamic foo() => throw 0;
}

mixin M on A, B {
  foo() => throw 0;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertType(foo.returnType, 'Object?');
  }

  test_method_return_multiple_different_void() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B {
  void foo() => 0;
}
mixin M on A, B {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertType(foo.returnType, 'int');
  }

  test_method_return_multiple_same_generic() async {
    await resolveTestCode('''
class A<E> {
  E foo() => 0;
}
class B<E> {
  E foo() => 0;
}
mixin M<T> on A<T>, B<T> {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertType(foo.returnType, 'T');
  }

  test_method_return_multiple_same_nonVoid() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B {
  int foo() => 0;
}
mixin M on A, B {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertType(foo.returnType, 'int');
  }

  test_method_return_multiple_same_void() async {
    await resolveTestCode('''
class A {
  void foo() {};
}
class B {
  void foo() {};
}
mixin M on A, B {
  foo() {};
}
''');
    var foo = findElement.method('foo', of: 'M');
    assertType(foo.returnType, 'void');
  }

  test_method_return_single() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B extends A {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'B');
    assertType(foo.returnType, 'int');
  }

  test_method_return_single_generic() async {
    await resolveTestCode('''
class A<E> {
  E foo() => throw 0;
}
class B<T> extends A<T> {
  foo() => throw 0;
}
''');
    var foo = findElement.method('foo', of: 'B');
    assertType(foo.returnType, 'T');
  }
}
