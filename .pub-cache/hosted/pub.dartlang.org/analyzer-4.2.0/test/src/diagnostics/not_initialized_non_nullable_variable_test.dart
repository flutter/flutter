// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotInitializedNonNullableVariableTest);
  });
}

@reflectiveTest
class NotInitializedNonNullableVariableTest extends PubPackageResolutionTest {
  test_external_static_field_non_nullable() async {
    await assertNoErrorsInCode('''
class A {
  external static int x;
}
''');
  }

  test_external_variable_non_nullable() async {
    await assertNoErrorsInCode('''
external int x;
''');
  }

  test_staticField_futureOr_questionArgument_none() async {
    await assertNoErrorsInCode('''
import 'dart:async';

class A {
  static FutureOr<int?> v;
}
''');
  }

  test_staticField_hasInitializer() async {
    await assertNoErrorsInCode('''
class A {
  static int v = 0;
}
''');
  }

  test_staticField_late() async {
    await assertNoErrorsInCode('''
class A {
  static late int v;
}
''');
  }

  test_staticField_noInitializer() async {
    await assertErrorsInCode('''
class A {
  static int x = 0, y, z = 2;
}
''', [
      error(CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_VARIABLE, 30, 1),
    ]);
  }

  test_staticField_noInitializer_constructor() async {
    await assertErrorsInCode('''
class A {
  static int x = 0, y, z = 2;
  A();
}
''', [
      error(CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_VARIABLE, 30, 1),
    ]);
  }

  test_staticField_noInitializer_final_constructor() async {
    await assertErrorsInCode('''
class A {
  static final int x = 0, y, z = 2;
  A();
}
''', [
      error(CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_VARIABLE, 36, 1),
    ]);
  }

  test_staticField_nullable() async {
    await assertNoErrorsInCode('''
class A {
  static int? v;
}
''');
  }

  test_staticField_type_dynamic() async {
    await assertNoErrorsInCode('''
class A {
  static dynamic v;
}
''');
  }

  test_staticField_type_dynamic_implicit() async {
    await assertNoErrorsInCode('''
class A {
  static var v;
}
''');
  }

  test_staticField_type_never() async {
    await assertErrorsInCode('''
class A {
  static Never v;
}
''', [
      error(CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_VARIABLE, 25, 1),
    ]);
  }

  test_staticField_type_void() async {
    await assertNoErrorsInCode('''
class A {
  static void v;
}
''');
  }

  test_topLevelVariable_futureOr_questionArgument_none() async {
    await assertNoErrorsInCode('''
import 'dart:async';

FutureOr<int?> v;
''');
  }

  test_topLevelVariable_hasInitializer() async {
    await assertNoErrorsInCode('''
int v = 0;
''');
  }

  test_topLevelVariable_noInitializer() async {
    await assertErrorsInCode('''
int x = 0, y, z = 2;
''', [
      error(CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_VARIABLE, 11, 1),
    ]);
  }

  test_topLevelVariable_nullable() async {
    await assertNoErrorsInCode('''
int? v;
''');
  }

  test_topLevelVariable_type_dynamic() async {
    await assertNoErrorsInCode('''
dynamic v;
''');
  }

  test_topLevelVariable_type_dynamic_implicit() async {
    await assertNoErrorsInCode('''
var v;
''');
  }

  test_topLevelVariable_type_never() async {
    await assertErrorsInCode('''
Never v;
''', [
      error(CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_VARIABLE, 6, 1),
    ]);
  }

  test_topLevelVariable_type_void() async {
    await assertNoErrorsInCode('''
void v;
''');
  }
}
