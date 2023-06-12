// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedShownNameTest);
  });
}

@reflectiveTest
class UnusedShownNameTest extends PubPackageResolutionTest {
  test_extension_instance_method_unused() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String empty() => '';
}
String s = '';
''');
    await assertErrorsInCode('''
import 'lib1.dart' show E, s;

f() {
  s.length;
}
''', [
      error(HintCode.UNUSED_SHOWN_NAME, 24, 1),
    ]);
  }

  test_extension_instance_method_used() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String empty() => '';
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart' show E;

f() {
  ''.empty();
}
''');
  }

  test_referenced_prefixed_assignmentExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
var a = 0;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as p show a;

void f() {
  p.a = 0;
}
''');
  }

  test_referenced_prefixed_postfixExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
var a = 0;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as p show a;

void f() {
  p.a++;
}
''');
  }

  test_referenced_prefixed_prefixExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
var a = 0;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as p show a;

void f() {
  ++p.a;
}
''');
  }

  test_referenced_unprefixed_assignmentExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
var a = 0;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' show a;

void f() {
  a = 0;
}
''');
  }

  test_referenced_unprefixed_postfixExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
var a = 0;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' show a;

void f() {
  a++;
}
''');
  }

  test_referenced_unprefixed_prefixExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
var a = 0;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' show a;

void f() {
  ++a;
}
''');
  }

  test_unreferenced() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' show A, B;
A a = A();
''', [
      error(HintCode.UNUSED_SHOWN_NAME, 27, 1),
    ]);
  }

  test_unresolved() async {
    await assertErrorsInCode(r'''
import 'dart:math' show max, FooBar;
main() {
  print(max(1, 2));
}
''', [
      error(HintCode.UNDEFINED_SHOWN_NAME, 29, 6),
    ]);
  }

  test_unusedShownName_as() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' as p show A, B;
p.A a = p.A();
''', [
      error(HintCode.UNUSED_SHOWN_NAME, 32, 1),
    ]);
  }

  test_unusedShownName_duplicates() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
class C {}
class D {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' show A, B;
import 'lib1.dart' show C, D;
A a = A();
C c = C();
''', [
      error(HintCode.UNUSED_SHOWN_NAME, 27, 1),
      error(HintCode.UNUSED_SHOWN_NAME, 57, 1),
    ]);
  }

  test_unusedShownName_topLevelVariable() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int var1 = 1;
const int var2 = 2;
const int var3 = 3;
const int var4 = 4;
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' show var1, var2;
import 'lib1.dart' show var3, var4;
int a = var1;
int b = var2;
int c = var3;
''', [
      error(HintCode.UNUSED_SHOWN_NAME, 66, 4),
    ]);
  }
}
