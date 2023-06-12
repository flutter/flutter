// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnFunctionReturnTypeTest);
  });
}

/// Tests of HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE with the
/// "strict-inference" static analysis option.
@reflectiveTest
class InferenceFailureOnFunctionReturnTypeTest
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

  test_classInstanceGetter() async {
    await assertErrorsInCode(r'''
class C {
  get f => 7;
}
''', [error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE, 12, 11)]);
  }

  test_classInstanceMethod() async {
    await assertErrorsInCode(r'''
class C {
  f() => 7;
}
''', [error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE, 12, 9)]);
  }

  test_classInstanceMethod_overriding() async {
    await assertNoErrorsInCode(r'''
class C {
  int f() => 7;
}

class D extends C {
  f() => 9;
}

class E implements C {
  f() => 9;
}

class F with C {
  f() => 9;
}

mixin M on C {
  f() => 9;
}

mixin N {
  int g() => 7;
}

class G with N {
  g() => 9;
}
''');
  }

  test_classInstanceMethod_withReturnType() async {
    await assertNoErrorsInCode(r'''
class C {
  Object f() => 7;
}
''');
  }

  test_classInstanceOperator() async {
    await assertErrorsInCode(r'''
class C {
  operator +(int x) => print(x);
}
''', [error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE, 12, 30)]);
  }

  test_classInstanceSetter() async {
    await assertNoErrorsInCode(r'''
class C {
  set f(int x) => print(x);
}
''');
  }

  test_classStaticMethod() async {
    await assertErrorsInCode(r'''
class C {
  static f() => 7;
}
''', [error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE, 12, 16)]);
  }

  test_classStaticMethod_withType() async {
    await assertNoErrorsInCode(r'''
class C {
  static int f() => 7;
}
''');
  }

  test_extensionMethod() async {
    await assertErrorsInCode(r'''
extension E on List {
  e() {
    return 7;
  }
}
''', [error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE, 24, 23)]);
  }

  test_functionTypedParameter() async {
    await assertErrorsInCode(r'''
void f(callback()) {
  callback();
}
''', [error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE, 7, 10)]);
  }

  test_functionTypedParameter_nested() async {
    await assertErrorsInCode(r'''
void f(void callback(callback2())) {
  callback(() => print('hey'));
}
''', [error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE, 21, 11)]);
  }

  test_functionTypedParameter_withReturnType() async {
    await assertNoErrorsInCode(r'''
void f(int callback()) {
  callback();
}
''');
  }

  test_genericFunctionType() async {
    await assertErrorsInCode(r'''
Function(int) f = (int n) {
  print(n);
};
''', [error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE, 0, 13)]);
  }

  test_genericFunctionType_withReturnType() async {
    await assertNoErrorsInCode(r'''
void Function(int) f = (int n) {
  print(n);
};
''');
  }

  test_localFunction() async {
    await assertErrorsInCode(r'''
class C {
  void f() {
    g() => 7;
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 27, 1),
    ]);
  }

  test_mixinInstanceMethod() async {
    await assertErrorsInCode(r'''
mixin C {
  f() => 7;
}
''', [error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE, 12, 9)]);
  }

  test_setter_topLevel() async {
    await assertNoErrorsInCode(r'''
set f(int x) => print(x);
''');
  }

  test_topLevelArrowFunction() async {
    await assertErrorsInCode(r'''
f() => 7;
''', [error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE, 0, 9)]);
  }

  test_topLevelFunction() async {
    await assertErrorsInCode(r'''
f() {
  return 7;
}
''', [error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE, 0, 19)]);
  }

  test_topLevelFunction_async() async {
    await assertErrorsInCode(r'''
f() {
  return 7;
}
''', [error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE, 0, 19)]);
  }

  test_topLevelFunction_withReturnType() async {
    await assertNoErrorsInCode(r'''
dynamic f() => 7;
''');
  }

  test_typedef_classic() async {
    await assertErrorsInCode(r'''
typedef Callback(int i);
''', [error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE, 0, 24)]);
  }

  test_typedef_classic_withReturnType() async {
    await assertNoErrorsInCode(r'''
typedef void Callback(int i);
''');
  }

  test_typedef_modern() async {
    await assertErrorsInCode(r'''
typedef Callback = Function(int i);
''', [error(HintCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE, 0, 35)]);
  }

  test_typedef_modern_withReturnType() async {
    await assertNoErrorsInCode(r'''
typedef Callback = void Function(int i);
''');
  }
}
