// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnOfInvalidTypeForCatchErrorTest);
    defineReflectiveTests(
        ReturnOfInvalidTypeForCatchErrorWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ReturnOfInvalidTypeForCatchErrorTest extends PubPackageResolutionTest
    with ReturnOfInvalidTypeForCatchErrorTestCases {
  test_nullableType_emptyBody() async {
    await assertNoErrorsInCode('''
void f(Future<int?> future) {
  future.catchError((e, st) {});
}
''');
  }

  test_nullableType_emptyReturn() async {
    await assertErrorsInCode('''
void f(Future<int?> future) {
  future.catchError((e, st) {
    return;
  });
}
''', [
      error(CompileTimeErrorCode.RETURN_WITHOUT_VALUE, 64, 6),
    ]);
  }

  test_nullableType_invalidReturnType() async {
    await assertErrorsInCode('''
void f(Future<int?> future) {
  future.catchError((e, st) => '');
}
''', [
      error(HintCode.RETURN_OF_INVALID_TYPE_FROM_CATCH_ERROR, 61, 2),
    ]);
  }
}

mixin ReturnOfInvalidTypeForCatchErrorTestCases on PubPackageResolutionTest {
  test_async_okReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future) {
  future.catchError((e, st) async => 0);
}
''');
  }

  test_blockFunctionBody_async_emptyReturn_nonVoid() async {
    await assertErrorsInCode('''
void f(Future<int> future) {
  future.catchError((e, st) async {
    return;
  });
}
''', [
      error(CompileTimeErrorCode.RETURN_WITHOUT_VALUE, 69, 6),
    ]);
  }

  test_blockFunctionBody_async_emptyReturn_void() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((e, st) async {
    return;
  });
}
''');
  }

  test_blockFunctionBody_emptyReturn_dynamic() async {
    await assertNoErrorsInCode('''
void f(Future<dynamic> future) {
  future.catchError((e, st) {
    return;
  });
}
''');
  }

  test_blockFunctionBody_emptyReturn_nonVoid() async {
    await assertErrorsInCode('''
void f(Future<int> future) {
  future.catchError((e, st) {
    return;
  });
}
''', [
      error(CompileTimeErrorCode.RETURN_WITHOUT_VALUE, 63, 6),
    ]);
  }

  test_blockFunctionBody_emptyReturn_void() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((e, st) {
    return;
  });
}
''');
  }

  test_blockFunctionBody_invalidReturnType() async {
    await assertErrorsInCode('''
void f(Future<int> future) {
  future.catchError((e, st) {
    if (1 == 2) {
      return 7;
    } else {
      return 0.5;
    }
  });
}
''', [
      error(HintCode.RETURN_OF_INVALID_TYPE_FROM_CATCH_ERROR, 119, 3),
    ]);
  }

  test_blockFunctionBody_withLocalFunction_expression_okReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future) {
  future.catchError((e, st) {
    double g() => 0.5;
    if (g() == 0.5) return 0;
    return 1;
  });
}
''');
  }

  test_blockFunctionBody_withLocalFunction_okReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future) {
  future.catchError((e, st) {
    double g() {
      return 0.5;
    }
    if (g() == 0.5) return 0;
    return 1;
  });
}
''');
  }

  test_expressionFunctionBody_invalidReturnType() async {
    await assertErrorsInCode('''
void f(Future<int> future) {
  future.catchError((e, st) => 'c');
}
''', [
      error(HintCode.RETURN_OF_INVALID_TYPE_FROM_CATCH_ERROR, 60, 3),
    ]);
  }

  test_Null_okReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<Null> future) {
  future.catchError((e, st) => null);
}
''');
  }

  test_okReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future) {
  future.catchError((e, st) => 0);
}
''');
  }

  test_void_okReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((e, st) => 0);
}
''');
  }

  test_voidReturnType() async {
    await assertErrorsInCode('''
void f(Future<int> future, void Function() g) {
  future.catchError((e, st) => g());
}
''', [
      error(HintCode.RETURN_OF_INVALID_TYPE_FROM_CATCH_ERROR, 79, 3),
    ]);
  }
}

@reflectiveTest
class ReturnOfInvalidTypeForCatchErrorWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with ReturnOfInvalidTypeForCatchErrorTestCases, WithoutNullSafetyMixin {}
