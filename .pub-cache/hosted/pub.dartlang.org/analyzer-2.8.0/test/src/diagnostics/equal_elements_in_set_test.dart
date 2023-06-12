// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EqualElementsInSetTest);
  });
}

@reflectiveTest
class EqualElementsInSetTest extends PubPackageResolutionTest {
  test_constant_constant() async {
    await assertErrorsInCode('''
const a = 1;
const b = 1;
var s = {a, b};
''', [
      error(HintCode.EQUAL_ELEMENTS_IN_SET, 38, 1),
    ]);
  }

  test_literal_constant() async {
    await assertErrorsInCode('''
const one = 1;
var s = {1, one};
''', [
      error(HintCode.EQUAL_ELEMENTS_IN_SET, 27, 3),
    ]);
  }

  test_literal_literal() async {
    await assertErrorsInCode('''
var s = {1, 1};
''', [
      error(HintCode.EQUAL_ELEMENTS_IN_SET, 12, 1),
    ]);
  }
}
