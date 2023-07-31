// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclaresMemberOfObjectTest);
  });
}

@reflectiveTest
class ExtensionDeclaresMemberOfObjectTest extends PubPackageResolutionTest {
  test_instance_differentKind() async {
    await assertErrorsInCode('''
extension E on String {
  void hashCode() {}
}
''', [
      error(CompileTimeErrorCode.EXTENSION_DECLARES_MEMBER_OF_OBJECT, 31, 8),
    ]);
  }

  test_instance_sameKind() async {
    await assertErrorsInCode('''
extension E on String {
  bool operator==(_) => false;
  int get hashCode => 0;
  String toString() => '';
  dynamic get runtimeType => null;
  dynamic noSuchMethod(_) => null;
}
''', [
      error(CompileTimeErrorCode.EXTENSION_DECLARES_MEMBER_OF_OBJECT, 39, 2),
      error(CompileTimeErrorCode.EXTENSION_DECLARES_MEMBER_OF_OBJECT, 65, 8),
      error(CompileTimeErrorCode.EXTENSION_DECLARES_MEMBER_OF_OBJECT, 89, 8),
      error(CompileTimeErrorCode.EXTENSION_DECLARES_MEMBER_OF_OBJECT, 121, 11),
      error(CompileTimeErrorCode.EXTENSION_DECLARES_MEMBER_OF_OBJECT, 152, 12),
    ]);
  }

  test_static() async {
    await assertErrorsInCode('''
extension E on String {
  static void hashCode() {}
}
''', [
      error(CompileTimeErrorCode.EXTENSION_DECLARES_MEMBER_OF_OBJECT, 38, 8),
    ]);
  }
}
