// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelInstanceGetterTest);
  });
}

@reflectiveTest
class TopLevelInstanceGetterTest extends PubPackageResolutionTest {
  test_call() async {
    await assertNoErrorsInCode('''
class A {
  int Function() get g => () => 0;
}
var a = new A();
var b = a.g();
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_field() async {
    await assertNoErrorsInCode('''
class A {
  int g = 0;
}
var b = new A().g;
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_field_call() async {
    await assertNoErrorsInCode('''
class A {
  int Function() g = () => 0;
}
var a = new A();
var b = a.g();
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_field_imported() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  int f = 0;
}
''');
    await assertNoErrorsInCode('''
import 'a.dart';
var b = new A().f;
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_field_prefixedIdentifier() async {
    await assertNoErrorsInCode('''
class A {
  int g = 0;
}
var a = new A();
var b = a.g;
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_getter() async {
    await assertNoErrorsInCode('''
class A {
  int get g => 0;
}
var b = new A().g;
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_implicitlyTyped() async {
    await assertNoErrorsInCode('''
class A {
  get g => 0;
}
var b = new A().g;
''');
    assertTypeDynamic(findElement.topVar('b').type);
  }

  test_implicitlyTyped_call() async {
    await assertNoErrorsInCode('''
class A {
  get g => () => 0;
}
var a = new A();
var b = a.g();
''');
    assertTypeDynamic(findElement.topVar('b').type);
  }

  test_implicitlyTyped_field() async {
    await assertNoErrorsInCode('''
class A {
  var g = 0;
}
var b = new A().g;
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_implicitlyTyped_field_call() async {
    await assertNoErrorsInCode('''
class A {
  var g = () => 0;
}
var a = new A();
var b = a.g();
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_implicitlyTyped_field_prefixedIdentifier() async {
    await assertNoErrorsInCode('''
class A {
  var g = 0;
}
var a = new A();
var b = a.g;
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_implicitlyTyped_fn() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
int f<T>(x) => 0;
var a = new A();
var b = f(a.x);
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_implicitlyTyped_fn_explicit_type_params() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
int f<T>(x) => 0;
var a = new A();
var b = f<int>(a.x);
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_implicitlyTyped_fn_not_generic() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
int f(x) => 0;
var a = new A();
var b = f(a.x);
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_implicitlyTyped_indexExpression() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
  int operator[](int value) => 0;
}
var a = new A();
var b = a[a.x];
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_implicitlyTyped_invoke() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
var a = new A();
var b = (<T>(y) => 0)(a.x);
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_implicitlyTyped_invoke_explicit_type_params() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
var a = new A();
var b = (<T>(y) => 0)<int>(a.x);
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_implicitlyTyped_invoke_not_generic() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
var a = new A();
var b = ((y) => 0)(a.x);
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_implicitlyTyped_method() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
  int f<T>(int x) => 0;
}
var a = new A();
var b = a.f(a.x);
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_implicitlyTyped_method_explicit_type_params() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
  int f<T>(x) => 0;
}
var a = new A();
var b = a.f<int>(a.x);
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_implicitlyTyped_method_not_generic() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
  int f(x) => 0;
}
var a = new A();
var b = a.f(a.x);
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_implicitlyTyped_new() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
class B<T> {
  B(T x);
}
var a = new A();
var b = new B(a.x);
''');
    assertType(findElement.topVar('b').type, 'B<int>');
  }

  test_implicitlyTyped_new_explicit_type_params() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
class B<T> {
  B(x);
}
var a = new A();
var b = new B<int>(a.x);
''');
    assertType(findElement.topVar('b').type, 'B<int>');
  }

  test_implicitlyTyped_new_explicit_type_params_named() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
class B<T> {
  B.named(x);
}
var a = new A();
var b = new B<int>.named(a.x);
''');
    assertType(findElement.topVar('b').type, 'B<int>');
  }

  test_implicitlyTyped_new_explicit_type_params_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class B<T> {
  B(x);
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart' as foo;
class A {
  var x = 0;
}
var a = new A();
var b = new foo.B<int>(a.x);
''');
    assertType(findElement.topVar('b').type, 'B<int>');
  }

  test_implicitlyTyped_new_named() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
class B<T> {
  B.named(T x);
}
var a = new A();
var b = new B.named(a.x);
''');
    assertType(findElement.topVar('b').type, 'B<int>');
  }

  test_implicitlyTyped_new_not_generic() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
class B {
  B(x);
}
var a = new A();
var b = new B(a.x);
''');
    assertType(findElement.topVar('b').type, 'B');
  }

  test_implicitlyTyped_new_not_generic_named() async {
    await assertNoErrorsInCode('''
class A {
  var x = 0;
}
class B {
  B.named(x);
}
var a = new A();
var b = new B.named(a.x);
''');
    assertType(findElement.topVar('b').type, 'B');
  }

  test_implicitlyTyped_new_not_generic_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class B {
  B(x);
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart' as foo;
class A {
  var x = 0;
}
var a = new A();
var b = new foo.B(a.x);
''');
    assertType(findElement.topVar('b').type, 'B');
  }

  test_implicitlyTyped_new_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class B<T> {
  B(T x);
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart' as foo;
class A {
  var x = 0;
}
var a = new A();
var b = new foo.B(a.x);
''');
    assertType(findElement.topVar('b').type, 'B<int>');
  }

  test_implicitlyTyped_prefixedIdentifier() async {
    await assertNoErrorsInCode('''
class A {
  get g => 0;
}
var a = new A();
var b = a.g;
''');
    assertType(findElement.topVar('b').type, 'dynamic');
  }

  test_implicitlyTyped_propertyAccessLhs() async {
    await assertNoErrorsInCode('''
class A {
  var x = new B();
  int operator[](int value) => 0;
}
class B {
  int y = 0;
}
var a = new A();
var b = (a.x).y;
''');
    assertType(findElement.topVar('b').type, 'int');
  }

  test_prefixedIdentifier() async {
    await assertNoErrorsInCode('''
class A {
  int get g => 0;
}
var a = new A();
var b = a.g;
''');
    assertType(findElement.topVar('b').type, 'int');
  }
}
