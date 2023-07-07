// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart' show expect;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IntegerLiteralImpreciseAsDoubleTest);
  });
}

@reflectiveTest
class IntegerLiteralImpreciseAsDoubleTest extends PubPackageResolutionTest {
  test_excessiveExponent() async {
    await assertErrorsInCode(
        'double x = 0xfffffffffffff80000000000000000000000000000000000000000000'
        '0000000000000000000000000000000000000000000000000000000000000000000000'
        '0000000000000000000000000000000000000000000000000000000000000000000000'
        '000000000000000000000000000000000000000000000000000000000000;',
        [
          error(CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE, 11,
              259),
        ]);
    AnalysisError firstError = result.errors[0];

    // Check that we suggest the max double instead.
    expect(
        true,
        firstError.correction!.contains(
            '179769313486231570814527423731704356798070567525844996598917476803'
            '157260780028538760589558632766878171540458953514382464234321326889'
            '464182768467546703537516986049910576551282076245490090389328944075'
            '868508455133942304583236903222948165808559332123348274797826204144'
            '723168738177180919299881250404026184124858368'));
  }

  test_excessiveMantissa() async {
    await assertErrorsInCode('''
double x = 9223372036854775809;
''', [
      error(CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE, 11, 19),
    ]);
    AnalysisError firstError = result.errors[0];
    // Check that we suggest a valid double instead.
    expect(true, firstError.correction!.contains('9223372036854775808'));
  }
}
