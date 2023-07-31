// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UriWithInterpolationTest);
  });
}

@reflectiveTest
class UriWithInterpolationTest extends PubPackageResolutionTest {
  test_constant() async {
    await assertErrorsInCode('''
import 'stuff_\$platform.dart';
''', [
      error(CompileTimeErrorCode.URI_WITH_INTERPOLATION, 7, 22),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 15, 8),
    ]);
  }

  test_nonConstant() async {
    await assertErrorsInCode(r'''
library lib;
part '${'a'}.dart';
''', [
      error(CompileTimeErrorCode.URI_WITH_INTERPOLATION, 18, 13),
    ]);
  }
}
