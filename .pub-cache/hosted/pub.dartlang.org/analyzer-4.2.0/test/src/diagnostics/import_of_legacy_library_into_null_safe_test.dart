// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportOfLegacyLibraryInoNullSafeTest);
  });
}

@reflectiveTest
class ImportOfLegacyLibraryInoNullSafeTest extends PubPackageResolutionTest {
  test_legacy_into_legacy() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.9
class A {}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.9
import 'a.dart';

void f(A a) {}
''');
  }

  test_legacy_into_nullSafe() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.9
class A {}
''');
    await assertErrorsInCode(r'''
import 'a.dart';

void f(A a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);
  }

  test_nullSafe_into_legacy() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.9
import 'a.dart';

void f(A a) {}
''');
  }

  test_nullSafe_into_nullSafe() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart';

void f(A a) {}
''');
  }

  test_nullSafe_into_nullSafe_part() async {
    newFile('$testPackageLibPath/a.dart', '');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
import 'a.dart';
''');

    await assertNoErrorsInCode(r'''
part 'b.dart';
''');
  }
}
