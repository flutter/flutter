// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumWithAbstractMemberTest);
  });
}

@reflectiveTest
class EnumWithAbstractMemberTest extends PubPackageResolutionTest {
  test_getter() async {
    await assertErrorsInCode('''
enum E {
  v;
  int get foo;
}
''', [
      error(CompileTimeErrorCode.ENUM_WITH_ABSTRACT_MEMBER, 16, 12),
    ]);
  }

  test_method() async {
    await assertErrorsInCode('''
enum E {
  v;
  void foo();
}
''', [
      error(CompileTimeErrorCode.ENUM_WITH_ABSTRACT_MEMBER, 16, 11),
    ]);
  }

  test_setter() async {
    await assertErrorsInCode('''
enum E {
  v;
  set foo(int _);
}
''', [
      error(CompileTimeErrorCode.ENUM_WITH_ABSTRACT_MEMBER, 16, 15),
    ]);
  }
}
