// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LabelInOuterScopeTest);
  });
}

@reflectiveTest
class LabelInOuterScopeTest extends PubPackageResolutionTest {
  test_label_in_outer_scope() async {
    await assertErrorsInCode(r'''
class A {
  void m(int i) {
    l: while (i > 0) {
      void f() {
        break l;
      };
    }
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 62, 1),
      error(CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE, 82, 1),
    ]);
  }
}
