// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentOfDoNotStoreTest);
    defineReflectiveTests(AssignmentOfDoNotStoreInTestsTest);
  });
}

@reflectiveTest
class AssignmentOfDoNotStoreInTestsTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_noHintsInTestDir() async {
    // Code that is in a test dir (the default for PubPackageResolutionTests)
    // should not trigger the hint.
    // (See:https://github.com/dart-lang/sdk/issues/45594)
    await assertNoErrorsInCode(
      '''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  String get v => '';
}

class B {
  String f = A().v;
}
''',
    );
  }
}

@reflectiveTest
class AssignmentOfDoNotStoreTest extends PubPackageResolutionTest {
  /// Override the default which is in .../test and should not trigger hints.
  @override
  String get testPackageRootPath => '$workspaceRootPath/test_project';

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_classMemberGetter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  String get v => '';
}

class B {
  String f = A().v;
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 106, 5,
          messageContains: ["'v'"]),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48476')
  test_classMemberVariable() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A{
  @doNotStore
  final f = '';
}

class B {
  String f = A().f;
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 99, 5),
    ]);
  }

  test_classStaticGetter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  static String get v => '';
}

class B {
  String f = A.v;
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 113, 3),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48476')
  test_classStaticVariable() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A{
  @doNotStore
  static final f = '';
}

class B {
  String f = A.f;
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 106, 3),
    ]);
  }

  test_functionAssignment() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String g(int i) => '';

class C {
  String Function(int) f = g;
}
''');
  }

  test_functionReturnValue() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String getV() => '';

class A {
  final f = getV();
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 90, 6),
    ]);
  }

  test_methodReturnValue() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  String getV() => '';
}

class B {
  final f = A().getV();
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 106, 10),
    ]);
  }

  test_tearOff() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String getV() => '';

class A {
  final f = getV;
}
''');
  }

  test_topLevelGetter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String get v => '';

class A {
  final f = v;
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 89, 1),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48476')
  test_topLevelVariable() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
final v = '';

class A {
  final f = v;
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 83, 1),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48476')
  test_topLevelVariable_assignment_field() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

String top = A().f;

class A{
  @doNotStore
  final f = '';
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 47, 5,
          messageContains: ["'f'"]),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48476')
  test_topLevelVariable_assignment_functionExpression() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String _v = '';

var c = ()=> _v;

String v = c();
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 76, 2),
    ]);
  }

  test_topLevelVariable_assignment_getter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

String top = v;

@doNotStore
String get v => '';
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 47, 1,
          messageContains: ["'v'"]),
    ]);
  }

  test_topLevelVariable_assignment_method() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

String top = A().v();

class A{
  @doNotStore
  String v() => '';
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 47, 7,
          messageContains: ["'v'"]),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48476')
  test_topLevelVariable_binaryExpression() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
final String? v = '';

class A {
  final f = v ?? v;
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 91, 1),
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 96, 1),
    ]);
  }

  test_topLevelVariable_libraryAnnotation() async {
    newFile('$testPackageLibPath/library.dart', '''
@doNotStore
library lib;

import 'package:meta/meta.dart';

final v = '';
''');

    await assertErrorsInCode('''
import 'library.dart';

class A {
  final f = v;
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 46, 1),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48476')
  test_topLevelVariable_ternary() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
final v = '';

class A {
  static bool c = false;
  final f = c ? v : v;
}
''', [
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 112, 1),
      error(HintCode.ASSIGNMENT_OF_DO_NOT_STORE, 116, 1),
    ]);
  }
}
