// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeadNullAwareExpressionTest);
  });
}

@reflectiveTest
class DeadNullAwareExpressionTest extends PubPackageResolutionTest {
  test_assignCompound_legacy() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.5
var x = 0;
''');

    await assertErrorsInCode('''
import 'a.dart';

f() {
  x ??= 0;
}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);
  }

  test_assignCompound_map() async {
    await assertNoErrorsInCode(r'''
class MyMap<K, V> {
  V? operator[](K key) => null;
  void operator[]=(K key, V value) {}
}

f(MyMap<int, int> map) {
  map[0] ??= 0;
}
''');
  }

  test_assignCompound_nonNullable() async {
    await assertErrorsInCode(r'''
f(int x) {
  x ??= 0;
}
''', [
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 19, 1),
    ]);
  }

  test_assignCompound_nullable() async {
    await assertNoErrorsInCode(r'''
f(int? x) {
  x ??= 0;
}
''');
  }

  test_binary_legacy() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.5
var x = 0;
''');

    await assertErrorsInCode('''
import 'a.dart';

f() {
  x ?? 0;
}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);
  }

  test_binary_nonNullable() async {
    await assertErrorsInCode(r'''
f(int x) {
  x ?? 0;
}
''', [
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 18, 1),
    ]);
  }

  test_binary_nullable() async {
    await assertNoErrorsInCode(r'''
f(int? x) {
  x ?? 0;
}
''');
  }

  test_binary_nullType() async {
    await assertNoErrorsInCode(r'''
f(Null x) {
  x ?? 1;
}
''');
  }
}
