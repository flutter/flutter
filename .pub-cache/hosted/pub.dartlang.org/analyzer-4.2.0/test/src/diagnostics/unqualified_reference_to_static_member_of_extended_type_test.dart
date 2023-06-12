// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnqualifiedReferenceToStaticMemberOfExtendedTypeTest);
  });
}

@reflectiveTest
class UnqualifiedReferenceToStaticMemberOfExtendedTypeTest
    extends PubPackageResolutionTest {
  CompileTimeErrorCode get _errorCode {
    return CompileTimeErrorCode
        .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE;
  }

  test_getter() async {
    await assertErrorsInCode('''
class MyClass {
  static int get zero => 0;
}
extension MyExtension on MyClass {
  void m() {
    zero;
  }
}
''', [
      error(_errorCode, 98, 4),
    ]);
  }

  test_method() async {
    await assertErrorsInCode('''
class MyClass {
  static void sm() {}
}
extension MyExtension on MyClass {
  void m() {
    sm();
  }
}
''', [
      error(_errorCode, 92, 2),
    ]);
  }

  test_methodTearoff() async {
    await assertErrorsInCode('''
class MyClass {
  static void sm<T>() {}
}
extension MyExtension on MyClass {
  void m() {
    sm<int>;
  }
}
''', [
      error(_errorCode, 95, 2),
    ]);
  }

  test_readWrite() async {
    await assertErrorsInCode('''
class MyClass {
  static int get x => 0;
  static set x(int _) {}
}

extension MyExtension on MyClass {
  void f() {
    x = 0;
    x += 1;
    ++x;
    x++;
  }
}
''', [
      error(_errorCode, 121, 1),
      error(_errorCode, 132, 1),
      error(_errorCode, 146, 1),
      error(_errorCode, 153, 1),
    ]);
  }
}
