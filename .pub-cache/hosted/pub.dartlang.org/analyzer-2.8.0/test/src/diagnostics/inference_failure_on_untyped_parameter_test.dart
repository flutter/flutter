// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnUntypedParameterTest);
  });
}

/// Tests of HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER with the
/// "strict-inference" static analysis option.
@reflectiveTest
class InferenceFailureOnUntypedParameterTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        strictInference: true,
      ),
    );
  }

  test_fieldParameter() async {
    await assertNoErrorsInCode(r'''
class C {
  int a;
  C(this.a) {}
}
''');
  }

  test_functionTypedFormalParameter_withType() async {
    await assertNoErrorsInCode(r'''
void fn(String cb(int x)) => print(cb(7));
''');
  }

  test_functionTypedFormalParameter_withVar() async {
    await assertErrorsInCode(r'''
void fn(String cb(var x)) => print(cb(7));
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER, 18, 5),
    ]);
  }

  test_namedParameter_withType() async {
    await assertNoErrorsInCode(r'''
void fn({int a = 0}) => print(a);
''');
  }

  test_namedParameter_withVar() async {
    await assertErrorsInCode(r'''
void fn({var a}) => print(a);
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER, 9, 5),
    ]);
  }

  test_namedParameter_withVar_unreferenced() async {
    await assertNoErrorsInCode(r'''
void fn({var a}) {}
''');
  }

  test_parameter() async {
    await assertErrorsInCode(r'''
void fn(a) => print(a);
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER, 8, 1),
    ]);
  }

  test_parameter_inConstructor() async {
    await assertErrorsInCode(r'''
class C {
  C(var a) {
    a;
  }
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER, 14, 5),
    ]);
  }

  test_parameter_inConstructor_fieldFormal() async {
    await assertNoErrorsInCode(r'''
class C {
  int a;
  C(this.a) {
    a;
  }
}
''');
  }

  test_parameter_inConstructor_fieldFormal_withVar() async {
    await assertNoErrorsInCode(r'''
class C {
  int a;
  C(var this.a) {
    a;
  }
}
''');
  }

  test_parameter_inConstructor_referencedInInitializer() async {
    await assertErrorsInCode(r'''
class C {
  C(var a) : assert(a != null);
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER, 14, 5),
    ]);
  }

  test_parameter_inConstructor_unreferenced() async {
    await assertNoErrorsInCode(r'''
class C {
  C(var a);
}
''');
  }

  test_parameter_inConstructor_withType() async {
    await assertNoErrorsInCode(r'''
class C {
  C(int a) {}
}
''');
  }

  test_parameter_inFunctionLiteral() async {
    await assertErrorsInCode(r'''
void fn() {
  var f = (var a) => a;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 1),
      error(HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER, 23, 5),
    ]);
  }

  test_parameter_inFunctionLiteral_inferredType() async {
    await assertNoErrorsInCode(r'''
void fn() {
  g((a, b) => print('$a$b'));
}

void g(void cb(int a, dynamic b)) => cb(7, "x");
''');
  }

  test_parameter_inFunctionLiteral_inferredType_viaReturn() async {
    await assertNoErrorsInCode(r'''
void Function(int, dynamic) fn() {
  return (a, b) => print('$a$b');
}
''');
  }

  test_parameter_inFunctionLiteral_withType() async {
    await assertNoErrorsInCode(r'''
var f = (int a) => false;
''');
  }

  test_parameter_inGenericFunction_withType() async {
    await assertNoErrorsInCode(r'''
void fn<T>(T a) => print(a);
''');
  }

  test_parameter_inMethod() async {
    await assertErrorsInCode(r'''
class C {
  void fn(var a) => print(a);
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER, 20, 5),
    ]);
  }

  test_parameter_inMethod_abstract() async {
    await assertErrorsInCode(r'''
abstract class C {
  void fn(var a);
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER, 29, 5),
    ]);
  }

  test_parameter_inMethod_withType() async {
    await assertNoErrorsInCode(r'''
class C {
  void fn(String a) => print(a);
}
''');
  }

  test_parameter_inOverridingMethod() async {
    await assertNoErrorsInCode(r'''
class C {
  void fn(int a) => print(a);
}

class D extends C {
  @override
  void fn(a) => print(a);
}
''');
  }

  test_parameter_inOverridingMethod_withDefault() async {
    await assertNoErrorsInCode(r'''
class C {
  void fn([int a = 7]) => print(a);
}

class D extends C {
  @override
  void fn([var a = 7]) => print(a);
}
''');
  }

  test_parameter_inOverridingMethod_withDefaultAndType() async {
    await assertNoErrorsInCode(r'''
class C {
  void fn([int a = 7]) => print(a);
}

class D extends C {
  @override
  void fn([num a = 7]) => print(a);
}
''');
  }

  test_parameter_inOverridingMethod_withType() async {
    await assertNoErrorsInCode(r'''
class C {
  void fn(int a) => print(a);
}

class D extends C {
  @override
  void fn(num a) => print(a);
}
''');
  }

  test_parameter_inOverridingMethod_withVar() async {
    await assertNoErrorsInCode(r'''
class C {
  void fn(int a) => print(a);
}

class D extends C {
  @override
  void fn(var a) => print(a);
}
''');
  }

  test_parameter_inTypedef_withoutType() async {
    await assertErrorsInCode(r'''
typedef void cb(a);
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER, 16, 1),
    ]);
  }

  test_parameter_inTypedef_withType() async {
    await assertNoErrorsInCode(r'''
typedef cb = void Function(int a);
''');
  }

  test_parameter_withoutKeyword() async {
    await assertErrorsInCode(r'''
void fn(a) => print(a);
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER, 8, 1),
    ]);
  }

  test_parameter_withType() async {
    await assertNoErrorsInCode(r'''
void fn(int a) => print(a);
''');
  }

  test_parameter_withTypeAndDefault() async {
    await assertNoErrorsInCode(r'''
void fn([int a = 7]) => print(a);
''');
  }

  test_parameter_withVar() async {
    await assertErrorsInCode(r'''
void fn(var a) => print(a);
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER, 8, 5),
    ]);
  }

  test_parameter_withVarAndDefault() async {
    await assertErrorsInCode(r'''
void fn([var a = 7]) => print(a);
''', [
      error(HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER, 9, 5),
    ]);
  }
}
