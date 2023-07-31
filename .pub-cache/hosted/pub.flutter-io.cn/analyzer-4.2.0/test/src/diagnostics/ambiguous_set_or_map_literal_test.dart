// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AmbiguousSetOrMapLiteralBothTest);
    defineReflectiveTests(AmbiguousSetOrMapLiteralBothWithoutNullSafetyTest);
    defineReflectiveTests(AmbiguousSetOrMapLiteralEitherTest);
    defineReflectiveTests(AmbiguousSetOrMapLiteralEitherWithoutNullSafetyTest);
  });
}

@reflectiveTest
class AmbiguousSetOrMapLiteralBothTest extends PubPackageResolutionTest
    with AmbiguousSetOrMapLiteralBothTestCases {
  test_map_keyNonNullable_valueNullable() async {
    await assertNoErrorsInCode('''
f(Map<int, int?> map) {
  return {...map};
}
''');
  }

  test_map_keyNullable_valueNonNullable() async {
    await assertNoErrorsInCode('''
f(Map<int?, int> map) {
  return {...map};
}
''');
  }

  test_map_keyNullable_valueNullable() async {
    await assertNoErrorsInCode('''
f(Map<int?, int?> map) {
  return {...map};
}
''');
  }

  test_set_elementNullable() async {
    await assertNoErrorsInCode('''
f(Set<int?> set) {
  return {...set};
}
''');
  }

  test_setAndMap_nullable() async {
    await assertErrorsInCode('''
f(Map<int?, int> map, Set<int?> set) {
  return {...set, ...map};
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH, 48, 16),
    ]);
  }
}

mixin AmbiguousSetOrMapLiteralBothTestCases on PubPackageResolutionTest {
  test_map() async {
    await assertNoErrorsInCode('''
f(Map<int, int> map) {
  return {...map};
}
''');
  }

  test_map_dynamic() async {
    await assertNoErrorsInCode('''
f(Map map) {
  return {...map};
}
''');
  }

  test_set() async {
    await assertNoErrorsInCode('''
f(Set<int> set) {
  return {...set};
}
''');
  }

  test_set_dynamic() async {
    await assertNoErrorsInCode('''
f(Set set) {
  return {...set};
}
''');
  }

  test_setAndMap() async {
    await assertErrorsInCode('''
f(Map<int, int> map, Set<int> set) {
  return {...set, ...map};
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH, 46, 16),
    ]);
  }
}

@reflectiveTest
class AmbiguousSetOrMapLiteralBothWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with AmbiguousSetOrMapLiteralBothTestCases, WithoutNullSafetyMixin {}

@reflectiveTest
class AmbiguousSetOrMapLiteralEitherTest extends PubPackageResolutionTest
    with AmbiguousSetOrMapLiteralEitherTestCases {}

mixin AmbiguousSetOrMapLiteralEitherTestCases on PubPackageResolutionTest {
  test_invalidPrefixOperator() async {
    // Guard against an exception being thrown.
    await assertErrorsInCode('''
union(a, b) => !{...a, ...b};
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER, 16, 12),
    ]);
  }

  test_setAndMap() async {
    await assertErrorsInCode('''
var map;
var set;
var c = {...set, ...map};
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER, 26, 16),
    ]);
  }
}

@reflectiveTest
class AmbiguousSetOrMapLiteralEitherWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with AmbiguousSetOrMapLiteralEitherTestCases, WithoutNullSafetyMixin {}
