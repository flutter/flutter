// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedImportTest);
  });
}

@reflectiveTest
class UnusedImportTest extends PubPackageResolutionTest {
  test_annotationOnDirective() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {
  const A() {}
}
''');
    await assertNoErrorsInCode(r'''
@A()
import 'lib1.dart';
''');
  }

  test_as() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart';
import 'lib1.dart' as one;
one.A a = one.A();
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
    ]);
  }

  test_as_equalPrefixes_referenced() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
class B {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as one;
import 'lib2.dart' as one;
one.A a = one.A();
one.B b = one.B();
''');
  }

  test_as_equalPrefixes_referenced_via_export() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
class B {}
''');
    newFile('$testPackageLibPath/lib3.dart', r'''
export 'lib2.dart';
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as one;
import 'lib3.dart' as one;
one.A a = one.A();
one.B b = one.B();
''');
  }

  test_as_equalPrefixes_unreferenced() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
class B {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' as one;
import 'lib2.dart' as one;
one.A a = one.A();
''', [
      error(HintCode.UNUSED_IMPORT, 34, 11),
    ]);
  }

  test_as_show_multipleElements() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as one show A, B;
one.A a = one.A();
one.B b = one.B();
''');
  }

  test_as_showTopLevelFunction() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class One {}
topLevelFunction() {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' hide topLevelFunction;
import 'lib1.dart' as one show topLevelFunction;
class A {
  static void x() {
    One o;
    one.topLevelFunction();
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 129, 1),
    ]);
  }

  test_as_showTopLevelFunction_multipleDirectives() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class One {}
topLevelFunction() {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' hide topLevelFunction;
import 'lib1.dart' as one show topLevelFunction;
import 'lib1.dart' as two show topLevelFunction;
class A {
  static void x(One o) {
    one.topLevelFunction();
    two.topLevelFunction();
  }
}
''');
  }

  test_as_systemLibrary() async {
    newFile('$testPackageLibPath/a.dart', '''
class File {}
''');
    await assertErrorsInCode(r'''
import 'dart:io' as prefix;
import 'a.dart' as prefix;
prefix.File? f;
''', [
      error(HintCode.UNUSED_IMPORT, 7, 9),
    ]);
  }

  test_core_library() async {
    await assertNoErrorsInCode(r'''
import 'dart:core';
''');
  }

  test_export() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
export 'lib2.dart';
class One {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
class Two {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart';
Two two = Two();
''');
  }

  test_export2() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
export 'lib2.dart';
class One {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
export 'lib3.dart';
class Two {}
''');
    newFile('$testPackageLibPath/lib3.dart', r'''
class Three {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart';
Three? three;
''');
  }

  test_export_infiniteLoop() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
export 'lib2.dart';
class One {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
export 'lib3.dart';
class Two {}
''');
    newFile('$testPackageLibPath/lib3.dart', r'''
export 'lib2.dart';
class Three {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart';
Two? two;
''');
  }

  test_extension_instance_call() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on int {
  int call(int x) => 0;
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  7(9);
}
''');
  }

  test_extension_instance_getter() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String get empty => '';
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  ''.empty;
}
''');
  }

  test_extension_instance_method() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String empty() => '';
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  ''.empty();
}
''');
  }

  test_extension_instance_operator_binary() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String operator -(String s) => this;
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  'abc' - 'c';
}
''');
  }

  test_extension_instance_operator_index() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on int {
  int operator [](int i) => 0;
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  9[7];
}
''');
  }

  test_extension_instance_operator_unary() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  void operator -() {}
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  -'abc';
}
''');
  }

  test_extension_instance_setter() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  void set foo(int i) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  'abc'.foo = 2;
}
''');
  }

  test_extension_override_getter() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String get empty => '';
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  E('').empty;
}
''');
  }

  test_extension_prefixed_isUsed() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String empty() => '';
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart' as lib1;

f() {
  ''.empty();
}
''');
  }

  test_extension_prefixed_notUsed() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String empty() => '';
}
''');
    await assertErrorsInCode('''
import 'lib1.dart' as lib1;
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
    ]);
  }

  test_extension_static_field() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  static const String empty = '';
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';

f() {
  E.empty;
}
''');
  }

  test_hide() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart';
import 'lib1.dart' hide A;
A? a;
''', [
      error(HintCode.UNUSED_IMPORT, 27, 11),
    ]);
  }

  test_inComment_libraryDirective() async {
    await assertNoErrorsInCode(r'''
/// Use [Future] class.
import 'dart:async';
''');
  }

  test_metadata() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const x = 0;
''');
    await assertNoErrorsInCode(r'''
@A(x)
import 'lib1.dart';
class A {
  final int value;
  const A(this.value);
}
''');
  }

  test_multipleExtensions() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String a() => '';
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
extension E on String {
  String b() => '';
}
''');
    await assertErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';

f() {
  ''.b();
}
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
    ]);
  }

  test_show() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' show A;
import 'lib1.dart' show B;
A a = A();
''', [
      error(HintCode.UNUSED_IMPORT, 34, 11),
    ]);
  }

  test_systemLibrary() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class File {}
''');
    await assertErrorsInCode(r'''
import 'dart:io';
import 'lib1.dart';
File? f;
''', [
      error(HintCode.UNUSED_IMPORT, 7, 9),
    ]);
  }

  test_unusedImport() async {
    newFile('$testPackageLibPath/lib1.dart', '');
    await assertErrorsInCode(r'''
import 'lib1.dart';
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
    ]);
  }
}
