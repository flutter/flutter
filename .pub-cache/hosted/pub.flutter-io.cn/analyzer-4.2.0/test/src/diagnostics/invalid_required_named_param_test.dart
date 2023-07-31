// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidRequiredNamedParamTest);
  });
}

@reflectiveTest
class InvalidRequiredNamedParamTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_namedParameter_withDefault() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

m({@required a = 1}) => null;
''', [
      error(HintCode.INVALID_REQUIRED_NAMED_PARAM, 37, 15),
    ]);
  }

  test_namedParameter_withDefault_asSecond() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

m(a, {@required b = 1}) => null;
''', [
      error(HintCode.INVALID_REQUIRED_NAMED_PARAM, 40, 15),
    ]);
  }

  test_valid() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

m1({a}) => null;
m2({a = 5}) => null;
m3({@required a}) => null;
m4({a, @required b}) => null;
''');
  }
}
