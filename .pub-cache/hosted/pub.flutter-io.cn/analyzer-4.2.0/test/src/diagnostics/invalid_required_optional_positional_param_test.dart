// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidRequiredOptionalPositionalParamTest);
  });
}

@reflectiveTest
class InvalidRequiredOptionalPositionalParamTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_positionalParameter_noDefault() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

m([@required a]) => null;
''', [
      error(HintCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM, 37, 11),
    ]);
  }

  test_positionalParameter_noDefault_asSecond() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

m(a, [@required b]) => null;
''', [
      error(HintCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM, 40, 11),
    ]);
  }

  test_positionalParameter_withDefault() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

m([@required a = 1]) => null;
''', [
      error(HintCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM, 37, 15),
    ]);
  }

  test_positionalParameter_withDefault_withTwo() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

m([a, @required b = 1]) => null;
''', [
      error(HintCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM, 40, 15),
    ]);
  }

  test_valid() async {
    await assertNoErrorsInCode(r'''
m1([a]) => null;
m2([a = 1]) => null;
m3([a, b]) => null;
''');
  }
}
