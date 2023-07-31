// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedCatchClauseTest);
  });
}

@reflectiveTest
class UnusedCatchClauseTest extends PubPackageResolutionTest {
  test_on_unusedException() async {
    await assertErrorsInCode(r'''
main() {
  try {
  } on String catch (exception) {
  }
}
''', [
      error(HintCode.UNUSED_CATCH_CLAUSE, 38, 9),
    ]);
  }

  test_on_usedException() async {
    await assertNoErrorsInCode(r'''
main() {
  try {
  } on String catch (exception) {
    print(exception);
  }
}
''');
  }

  test_unusedException() async {
    await assertNoErrorsInCode(r'''
main() {
  try {
  } catch (exception) {
  }
}
''');
  }

  test_usedException() async {
    await assertNoErrorsInCode(r'''
main() {
  try {
  } catch (exception) {
    print(exception);
  }
}
''');
  }
}
