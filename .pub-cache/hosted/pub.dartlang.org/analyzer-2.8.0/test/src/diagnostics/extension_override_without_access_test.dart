// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionOverrideWithoutAccessTest);
  });
}

@reflectiveTest
class ExtensionOverrideWithoutAccessTest extends PubPackageResolutionTest {
  test_binaryExpression() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  int operator +(int x) => x;
}
f(C c) {
  E(c) + 2;
}
''');
  }

  test_call() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  int call(int x) => 0;
}

f(C c) {
  E(c)(2);
}
''');
  }

  test_expressionStatement() async {
    await assertErrorsInCode('''
class C {}
extension E on C {
  void m() {}
}
f(C c) {
  E(c);
}
''', [error(CompileTimeErrorCode.EXTENSION_OVERRIDE_WITHOUT_ACCESS, 57, 4)]);
    assertTypeDynamic(findNode.extensionOverride('E(c)'));
  }

  test_getter() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  int get g => 0;
}
f(C c) {
  E(c).g;
}
''');
  }

  test_indexExpression_get() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  int operator [](int i) => 4;
}
f(C c) {
  E(c)[2];
}
''');
  }

  test_indexExpression_set() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator []=(int i, int v) {}
}
f(C c) {
  E(c)[2] = 5;
}
''');
  }

  test_methodInvocation() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void m() {}
}
f(C c) {
  E(c).m();
}
''');
  }

  test_prefixExpression() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  int operator -() => 7;
}
f(C c) {
  -E(c);
}
''');
  }

  test_setter() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  set s(int x) {}
}
f(C c) {
  E(c).s = 3;
}
''');
  }
}
