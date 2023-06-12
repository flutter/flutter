// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryQuestionMarkTest);
  });
}

@reflectiveTest
class UnnecessaryQuestionMarkTest extends PubPackageResolutionTest {
  test_dynamic() async {
    await assertNoErrorsInCode('''
dynamic a;
''');
  }

  test_dynamicQuestionMark() async {
    await assertErrorsInCode('''
dynamic? a;
''', [
      error(HintCode.UNNECESSARY_QUESTION_MARK, 7, 1),
    ]);
  }

  test_Null() async {
    await assertNoErrorsInCode('''
Null a;
''');
  }

  test_NullQuestionMark() async {
    await assertErrorsInCode('''
Null? a;
''', [
      error(HintCode.UNNECESSARY_QUESTION_MARK, 4, 1),
    ]);
  }

  test_typeAliasQuestionMark() async {
    await assertNoErrorsInCode('''
typedef n = Null;
n? a;
''');
  }
}
