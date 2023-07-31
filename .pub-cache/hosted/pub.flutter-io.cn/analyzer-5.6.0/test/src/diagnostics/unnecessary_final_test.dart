// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryFinalTest);
  });
}

@reflectiveTest
class UnnecessaryFinalTest extends PubPackageResolutionTest {
  test_final() async {
    await assertNoErrorsInCode('''
class C {
  C(final int value);
}
''');
  }

  test_positional() async {
    await assertErrorsInCode('''
class C {
  C([final this.value = 0]);
  int value;
}
''', [
      error(HintCode.UNNECESSARY_FINAL, 15, 5),
    ]);
  }

  test_super() async {
    await assertErrorsInCode('''
class A {
  A(this.value);
  int value;
}

class B extends A {
  B(final super.value);
}
''', [
      error(HintCode.UNNECESSARY_FINAL, 67, 5),
    ]);
  }

  test_this() async {
    await assertErrorsInCode('''
class C {
  C(final this.value);
  int value;
}
''', [
      error(HintCode.UNNECESSARY_FINAL, 14, 5),
    ]);
  }
}
