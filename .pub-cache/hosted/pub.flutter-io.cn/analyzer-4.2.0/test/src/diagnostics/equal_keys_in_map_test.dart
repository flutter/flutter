// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EqualKeysInMapTest);
  });
}

@reflectiveTest
class EqualKeysInMapTest extends PubPackageResolutionTest {
  test_constant_constant() async {
    await assertErrorsInCode('''
const a = 1;
const b = 1;
var s = {a: 2, b: 3};
''', [
      error(HintCode.EQUAL_KEYS_IN_MAP, 41, 1),
    ]);
  }

  test_literal_constant() async {
    await assertErrorsInCode('''
const one = 1;
var s = {1: 2, one: 3};
''', [
      error(HintCode.EQUAL_KEYS_IN_MAP, 30, 3),
    ]);
  }

  test_literal_literal() async {
    await assertErrorsInCode('''
var s = {1: 2, 1: 3};
''', [
      error(HintCode.EQUAL_KEYS_IN_MAP, 15, 1),
    ]);
  }
}
