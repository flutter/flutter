// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForInOfInvalidTypeTest);
    defineReflectiveTests(ForInOfInvalidTypeWithoutNullSafetyTest);
    defineReflectiveTests(ForInOfInvalidTypeWithStrictCastsTest);
  });
}

@reflectiveTest
class ForInOfInvalidTypeTest extends PubPackageResolutionTest
    with ForInOfInvalidTypeTestCases {
  test_awaitForIn_never() async {
    await assertErrorsInCode('''
f(Never e) async {
  await for (var id in e) {
    id;
  }
}
''', [
      error(HintCode.DEAD_CODE, 32, 26),
    ]);
    // TODO(scheglov) extract for-in resolution and implement
//    assertType(findNode.simple('id;'), 'Never');
  }

  test_awaitForIn_object() async {
    await assertErrorsInCode('''
f(Object e) async {
  await for (var id in e) {
    id;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 43, 1),
    ]);
  }

  test_forIn_interfaceTypeTypedef_iterable() async {
    await assertNoErrorsInCode('''
typedef L = List<String>;
f(L e) {
  for (var id in e) {
    id;
  }
}
''');
  }

  test_forIn_never() async {
    await assertErrorsInCode('''
f(Never e) {
  for (var id in e) {
    id;
  }
}
''', [
      error(HintCode.DEAD_CODE, 20, 26),
    ]);
    // TODO(scheglov) extract for-in resolution and implement
//    assertType(findNode.simple('id;'), 'Never');
  }

  test_forIn_object() async {
    await assertErrorsInCode('''
f(Object e) async {
  for (var id in e) {
    id;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 37, 1),
    ]);
  }
}

mixin ForInOfInvalidTypeTestCases on PubPackageResolutionTest {
  test_awaitForIn_dynamic() async {
    await assertNoErrorsInCode('''
f(dynamic e) async {
  await for (var id in e) {
    id;
  }
}
''');
  }

  test_awaitForIn_interfaceType_notStream() async {
    await assertErrorsInCode('''
f(bool e) async {
  await for (var id in e) {
    id;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 41, 1),
    ]);
  }

  test_awaitForIn_streamOfDynamic() async {
    await assertNoErrorsInCode('''
f(Stream<dynamic> e) async {
  await for (var id in e) {
    id;
  }
}
''');
  }

  test_awaitForIn_streamOfDynamicSubclass() async {
    await assertNoErrorsInCode('''
abstract class MyStream<T> extends Stream<T> {
  factory MyStream() => throw 0;
}
f(MyStream<dynamic> e) async {
  await for (var id in e) {
    id;
  }
}
''');
  }

  test_forIn_dynamic() async {
    await assertNoErrorsInCode('''
f(dynamic e) {
  for (var id in e) {
    id;
  }
}
''');
  }

  test_forIn_interfaceType_iterable() async {
    await assertNoErrorsInCode('''
f(Iterable e) {
  for (var id in e) {
    id;
  }
}
''');
  }

  test_forIn_interfaceType_notIterable() async {
    await assertErrorsInCode('''
f(bool e) {
  for (var id in e) {
    id;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 29, 1),
    ]);
  }
}

@reflectiveTest
class ForInOfInvalidTypeWithoutNullSafetyTest extends PubPackageResolutionTest
    with ForInOfInvalidTypeTestCases, WithoutNullSafetyMixin {
  test_awaitForIn_object() async {
    await assertNoErrorsInCode('''
f(Object e) async {
  await for (var id in e) {
    id;
  }
}
''');
  }

  test_forIn_object() async {
    await assertNoErrorsInCode('''
f(Object e) async {
  for (var id in e) {
    id;
  }
}
''');
  }
}

@reflectiveTest
class ForInOfInvalidTypeWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_forIn() async {
    await assertErrorsWithStrictCasts('''
f(dynamic e) {
  for (var id in e) {
    id;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 32, 1),
    ]);
  }
}
