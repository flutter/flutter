// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LateFinalFieldWithConstConstructorTest);
  });
}

@reflectiveTest
class LateFinalFieldWithConstConstructorTest extends PubPackageResolutionTest {
  static const _errorCode =
      CompileTimeErrorCode.LATE_FINAL_FIELD_WITH_CONST_CONSTRUCTOR;

  test_class_hasConstConstructor_instance_hasInitializer() async {
    await assertErrorsInCode('''
class A {
  late final f = 0;
  const A();
}
''', [
      error(_errorCode, 12, 4),
    ]);
  }

  test_class_hasConstConstructor_instance_hasNotConst() async {
    await assertErrorsInCode('''
class A {
  late final f = 0;
  const A();
  A.notConst();
}
''', [
      error(_errorCode, 12, 4),
    ]);
  }

  test_class_hasConstConstructor_instance_noInitializer() async {
    await assertErrorsInCode('''
class A {
  late final f;
  const A();
}
''', [
      error(_errorCode, 12, 4),
    ]);
  }

  test_class_hasConstConstructor_static_late_final() async {
    await assertNoErrorsInCode('''
class A {
  static late final f = 0;
  const A();
}
''');
  }

  test_class_hasConstFactoryConstructor() async {
    await assertNoErrorsInCode('''
class Base {
  Base();
  const factory Base.empty() = _Empty;
  late final int property;
}

class _Empty implements Base {
  const _Empty();
  int get property => 0;
  set property(_) {}
}
''');
  }

  test_class_noConstConstructor() async {
    await assertNoErrorsInCode('''
class A {
  late final f = 0;
  A();
}
''');
  }

  test_enum_instance_hasInitializer() async {
    await assertErrorsInCode('''
enum E {
  v;
  late final f = 0;
}
''', [
      error(_errorCode, 16, 4),
    ]);
  }

  test_enum_static() async {
    await assertNoErrorsInCode('''
enum E {
  v;
  static late final f = 0;
}
''');
  }

  test_extension() async {
    // https://github.com/dart-lang/sdk/issues/46952
    // This test is here because the code that tests for
    // LATE_FINAL_FIELD_WITH_CONST_CONSTRUCTOR is where the referenced issue was
    // caused.
    await assertErrorsInCode('''
extension E on int {
  late final int i;
}
''', [
      error(ParserErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD, 38, 1),
    ]);
  }
}
