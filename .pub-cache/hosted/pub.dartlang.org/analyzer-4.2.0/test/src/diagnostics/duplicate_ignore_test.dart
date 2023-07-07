// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateIgnoreTest);
  });
}

@reflectiveTest
class DuplicateIgnoreTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        experiments: experiments,
        lints: ['avoid_types_as_parameter_names'],
      ),
    );
  }

  test_name_file() async {
    await assertErrorsInCode(r'''
// ignore_for_file: unused_local_variable, unused_local_variable
void f() {
  var x = 0;
}
''', [
      error(HintCode.DUPLICATE_IGNORE, 43, 21),
    ]);
  }

  test_name_line() async {
    await assertErrorsInCode(r'''
void f() {
  // ignore: unused_local_variable, unused_local_variable
  var x = 0;
}
''', [
      error(HintCode.DUPLICATE_IGNORE, 47, 21),
    ]);
  }

  test_name_lineAndFile() async {
    await assertErrorsInCode(r'''
// ignore_for_file: unused_local_variable
void f() {
  // ignore: unused_local_variable
  var x = 0;
}
''', [
      error(HintCode.DUPLICATE_IGNORE, 66, 21),
    ]);
  }

  test_type_file() async {
    await assertErrorsInCode(r'''
// ignore_for_file: type=lint, TYPE=LINT
void f(arg1(int)) {} // AVOID_TYPES_AS_PARAMETER_NAMES
''', [
      error(HintCode.DUPLICATE_IGNORE, 31, 10),
    ]);
  }

  test_type_line() async {
    await assertErrorsInCode(r'''
void f() {}
// ignore: type=lint, TYPE=LINT
void g(arg1(int)) {} // AVOID_TYPES_AS_PARAMETER_NAMES
''', [
      error(HintCode.DUPLICATE_IGNORE, 34, 10),
    ]);
  }

  test_type_lineAndFile() async {
    await assertErrorsInCode(r'''
// ignore_for_file: type=lint
void f() {}
// ignore: type=lint
void g(arg1(int)) {} // AVOID_TYPES_AS_PARAMETER_NAMES
''', [
      error(HintCode.DUPLICATE_IGNORE, 53, 10),
    ]);
  }
}
