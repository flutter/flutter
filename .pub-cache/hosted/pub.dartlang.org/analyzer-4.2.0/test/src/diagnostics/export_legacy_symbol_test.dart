// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExportLegacySymbolTest);
  });
}

@reflectiveTest
class ExportLegacySymbolTest extends PubPackageResolutionTest {
  test_exportDartAsync() async {
    await assertNoErrorsInCode(r'''
export 'dart:async';
''');
  }

  test_exportDartCore() async {
    await assertNoErrorsInCode(r'''
export 'dart:core';
''');
  }

  test_exportOptedIn() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');
    await assertNoErrorsInCode(r'''
export 'a.dart';
''');
  }

  test_exportOptedOut_exportOptedIn_hasLegacySymbol() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
// @dart = 2.5
export 'a.dart';
class B {}
''');

    await assertErrorsInCode(r'''
export 'b.dart';
''', [
      error(CompileTimeErrorCode.EXPORT_LEGACY_SYMBOL, 7, 8),
    ]);
  }

  test_exportOptedOut_exportOptedIn_hideLegacySymbol() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
// @dart = 2.5
export 'a.dart';
class B {}
''');

    await assertNoErrorsInCode(r'''
export 'b.dart' hide B;
''');
  }

  test_exportOptedOut_hasLegacySymbol() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.5
class A {}
class B {}
''');

    await assertErrorsInCode(r'''
export 'a.dart';
''', [
      error(CompileTimeErrorCode.EXPORT_LEGACY_SYMBOL, 7, 8),
    ]);
  }
}
