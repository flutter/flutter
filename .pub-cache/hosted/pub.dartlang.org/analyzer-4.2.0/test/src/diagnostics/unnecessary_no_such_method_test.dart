// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNoSuchMethodTest);
  });
}

@reflectiveTest
class UnnecessaryNoSuchMethodTest extends PubPackageResolutionTest {
  test_blockBody() async {
    await assertErrorsInCode(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) {
    return super.noSuchMethod(y);
  }
}
''', [
      error(HintCode.UNNECESSARY_NO_SUCH_METHOD, 87, 12),
    ]);
  }

  test_blockBody_notReturnStatement() async {
    await assertNoErrorsInCode(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) {
    print(y);
  }
}
''');
  }

  test_blockBody_notSingleStatement() async {
    await assertNoErrorsInCode(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) {
    print(y);
    return super.noSuchMethod(y);
  }
}
''');
  }

  test_expressionBody() async {
    await assertErrorsInCode(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) => super.noSuchMethod(y);
}
''', [
      error(HintCode.UNNECESSARY_NO_SUCH_METHOD, 87, 12),
    ]);
  }

  test_expressionBody_notNoSuchMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) => super.hashCode;
}
''');
  }

  test_expressionBody_notSuper() async {
    await assertNoErrorsInCode(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) => 42;
}
''');
  }
}
