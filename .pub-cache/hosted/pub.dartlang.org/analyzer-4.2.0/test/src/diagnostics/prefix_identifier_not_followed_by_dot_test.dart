// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixIdentifierNotFollowedByDotTest);
  });
}

@reflectiveTest
class PrefixIdentifierNotFollowedByDotTest extends PubPackageResolutionTest {
  test_assignment_compound_in_method() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
class C {
  f() {
    p += 1;
  }
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 46, 1),
    ]);
  }

  test_assignment_compound_not_in_method() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p += 1;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 32, 1),
    ]);
  }

  test_assignment_in_method() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
class C {
  f() {
    p = 1;
  }
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 46, 1),
    ]);
  }

  test_assignment_in_method_hasSuperField() async {
    await assertErrorsInCode('''
// ignore:unused_import
import 'dart:math' as p;

class A {
  var p;
}

class B extends A {
  void f() {
    p = 1;
  }
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 109, 1),
    ]);
  }

  test_assignment_not_in_method() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p = 1;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 32, 1),
    ]);
  }

  test_compoundAssignment() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p += 1;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 32, 1),
    ]);
  }

  test_conditionalMethodInvocation() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
g() {}
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p?.g();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 32, 1),
    ]);
  }

  test_conditionalPropertyAccess_call_loadLibrary() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' deferred as p;
f() {
  p?.loadLibrary();
}
''', [
      error(HintCode.UNUSED_IMPORT, 7, 10),
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 41, 1),
    ]);
  }

  test_conditionalPropertyAccess_get() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
var x;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  return p?.x;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 39, 1),
    ]);
  }

  test_conditionalPropertyAccess_get_loadLibrary() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' deferred as p;
f() {
  return p?.loadLibrary;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 48, 1),
    ]);
  }

  test_conditionalPropertyAccess_set() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
var x;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p?.x = null;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 32, 1),
    ]);
  }

  test_conditionalPropertyAccess_set_loadLibrary() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' deferred as p;
f() {
  p?.loadLibrary = null;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 41, 1),
    ]);
  }

  test_prefix_not_followed_by_dot() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  return p;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 39, 1),
    ]);
  }
}
