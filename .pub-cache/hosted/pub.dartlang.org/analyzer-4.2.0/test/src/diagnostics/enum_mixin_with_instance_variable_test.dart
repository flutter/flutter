// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumMixinWithInstanceVariableTest);
  });
}

@reflectiveTest
class EnumMixinWithInstanceVariableTest extends PubPackageResolutionTest {
  test_field_instance() async {
    await assertErrorsInCode(r'''
mixin M {
  var foo = 0;
}

enum E with M {
  v
}
''', [
      error(CompileTimeErrorCode.ENUM_MIXIN_WITH_INSTANCE_VARIABLE, 40, 1),
    ]);
  }

  test_field_instance_final() async {
    await assertErrorsInCode(r'''
mixin M {
  final foo = 0;
}

enum E with M {
  v
}
''', [
      error(CompileTimeErrorCode.ENUM_MIXIN_WITH_INSTANCE_VARIABLE, 42, 1),
    ]);
  }

  test_field_static() async {
    await assertNoErrorsInCode(r'''
mixin M {
  static var foo = 0;
}

enum E with M {
  v
}
''');
  }

  test_getter_instance() async {
    await assertNoErrorsInCode(r'''
mixin M {
  int get foo => 0;
}

enum E with M {
  v
}
''');
  }

  test_setter_instance() async {
    await assertNoErrorsInCode(r'''
mixin M {
  set foo(int _) {}
}

enum E with M {
  v
}
''');
  }
}
