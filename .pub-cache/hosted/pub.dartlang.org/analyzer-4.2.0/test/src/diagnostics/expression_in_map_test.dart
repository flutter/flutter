// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpressionInMapTest);
  });
}

@reflectiveTest
class ExpressionInMapTest extends PubPackageResolutionTest {
  test_map() async {
    await assertErrorsInCode('''
var m = <String, int>{'a', 'b' : 2};
''', [
      error(CompileTimeErrorCode.EXPRESSION_IN_MAP, 22, 3),
    ]);
  }

  test_map_const() async {
    await assertErrorsInCode('''
const m = <String, int>{'a', 'b' : 2};
''', [
      error(CompileTimeErrorCode.EXPRESSION_IN_MAP, 24, 3),
    ]);
  }
}
