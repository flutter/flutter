// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnUninitializedVariableTest);
  });
}

/// Tests of HintCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE with the
/// "strict-inference" static analysis option.
@reflectiveTest
class InferenceFailureOnUninitializedVariableTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        strictInference: true,
      ),
    );
  }

  test_field() async {
    await assertErrorsInCode(r'''
class C {
  var a;
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE, 16, 1),
    ]);
  }

  test_field_withInitializer() async {
    await assertNoErrorsInCode(r'''
class C {
  static var c = 3;
  static final d = 5;

  var a = 7;
  final b = 9;
}
''');
  }

  test_field_withType() async {
    await assertNoErrorsInCode(r'''
class C {
  static int c = 0;
  static final int d = 5;

  int a = 0;
  final int b;

  C(this.b);
}
''');
  }

  test_finalField() async {
    await assertErrorsInCode(r'''
class C {
  final a;
  C(this.a);
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE, 18, 1),
    ]);
  }

  test_localVariable() async {
    await assertErrorsInCode(r'''
void f() {
  var a;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(HintCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE, 17, 1),
    ]);
  }

  test_localVariable_withInitializer() async {
    await assertErrorsInCode(r'''
void f() {
  var a = 7;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
    ]);
  }

  test_localVariable_withType() async {
    await assertErrorsInCode(r'''
void f() {
  int a = 0;
  dynamic b;
  Object c = Object();
  Null d;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 34, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 46, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 67, 1),
    ]);
  }

  test_staticField() async {
    await assertErrorsInCode(r'''
class C {
  static var a;
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE, 23, 1),
    ]);
  }

  test_topLevelVariable() async {
    await assertErrorsInCode(r'''
var a;
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE, 4, 1),
    ]);
  }

  test_topLevelVariable_withInitializer() async {
    await assertNoErrorsInCode(r'''
var a = 7;
''');
  }

  test_topLevelVariable_withType() async {
    await assertNoErrorsInCode(r'''
int a = 0;
dynamic b;
Object c = Object();
Null d;
''');
  }
}
