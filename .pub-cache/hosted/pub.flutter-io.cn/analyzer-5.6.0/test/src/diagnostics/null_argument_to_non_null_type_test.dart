// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:analyzer/src/utilities/legacy.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullArgumentToNonNullCompleterCompleteTest);
    defineReflectiveTests(NullArgumentToNonNullFutureValueTest);
  });
}

@reflectiveTest
class NullArgumentToNonNullCompleterCompleteTest
    extends PubPackageResolutionTest {
  test_absent() async {
    await assertErrorsInCode('''
import 'dart:async';
void f() => Completer<int>().complete();
''', [
      error(WarningCode.NULL_ARGUMENT_TO_NON_NULL_TYPE, 33, 27),
    ]);
  }

  test_dynamic() async {
    await assertNoErrorsInCode('''
import 'dart:async';
void f() {
  Completer<int>().complete(null as dynamic);
}
''');
  }

  test_legacy() async {
    noSoundNullSafety = false;
    await assertNoErrorsInCode('''
// @dart=2.9
import 'dart:async';

void f() {
  final c = Completer<int>();
  c.complete();
  c.complete(null);
}
''');
  }

  test_null() async {
    await assertErrorsInCode('''
import 'dart:async';
void f() => Completer<int>().complete(null);
''', [
      error(WarningCode.NULL_ARGUMENT_TO_NON_NULL_TYPE, 59, 4),
    ]);
  }

  test_nullable() async {
    await assertNoErrorsInCode('''
import 'dart:async';
void f() {
  final c = Completer<int?>();
  c.complete();
  c.complete(null);
}
''');
  }

  test_nullType() async {
    await assertErrorsInCode('''
import 'dart:async';
void f(Null a) => Completer<int>().complete(a);
''', [
      error(WarningCode.NULL_ARGUMENT_TO_NON_NULL_TYPE, 65, 1),
    ]);
  }
}

@reflectiveTest
class NullArgumentToNonNullFutureValueTest extends PubPackageResolutionTest {
  test_absent() async {
    await assertErrorsInCode('''
void foo() => Future<int>.value();
''', [
      error(WarningCode.NULL_ARGUMENT_TO_NON_NULL_TYPE, 14, 19),
    ]);
  }

  test_dynamic() async {
    await assertNoErrorsInCode('''
import 'dart:async';
void f() {
  Future<int>.value(null as dynamic);
}
''');
  }

  test_legacy() async {
    noSoundNullSafety = false;
    await assertNoErrorsInCode('''
// @dart=2.9
void f() {
  Future<int>.value();
  Future<int>.value(null);
}
''');
  }

  test_null() async {
    await assertErrorsInCode('''
void foo() => Future<int>.value(null);
''', [
      error(WarningCode.NULL_ARGUMENT_TO_NON_NULL_TYPE, 32, 4),
    ]);
  }

  test_nullable() async {
    await assertNoErrorsInCode('''
void f() {
  Future<int?>.value();
  Future<int?>.value(null);
}
''');
  }

  test_nullType() async {
    await assertErrorsInCode('''
void foo(Null a) => Future<int>.value(a);
''', [
      error(WarningCode.NULL_ARGUMENT_TO_NON_NULL_TYPE, 38, 1),
    ]);
  }
}
