// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvocationOfExtensionWithoutCallTest);
  });
}

@reflectiveTest
class InvocationOfExtensionWithoutCallTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_instance_differentKind() async {
    await assertErrorsInCode('''
extension E on Object {}
f() {
  E(null)();
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_EXTENSION_WITHOUT_CALL, 33, 7),
    ]);
  }
}
