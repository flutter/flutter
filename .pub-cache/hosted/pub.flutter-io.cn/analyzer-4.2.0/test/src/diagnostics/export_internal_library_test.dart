// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExportInternalLibraryTest);
  });
}

@reflectiveTest
class ExportInternalLibraryTest extends PubPackageResolutionTest {
  test_export_internal_library() async {
    await assertErrorsInCode('''
export 'dart:_internal';
''', [
      error(CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY, 0, 24,
          messageContains: ["library 'dart:_internal' "]),
    ]);
  }
}
