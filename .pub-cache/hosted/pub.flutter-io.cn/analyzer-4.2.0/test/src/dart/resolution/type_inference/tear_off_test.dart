// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TearOffTest);
  });
}

@reflectiveTest
class TearOffTest extends PubPackageResolutionTest {
  test_empty_contextNotInstantiated() async {
    await assertErrorsInCode('''
T f<T>(T x) => x;

void test() {
  U Function<U>(U) context;
  context = f; // 1
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 52, 7),
    ]);
    _assertTearOff(
      'f; // 1',
      findElement.topFunction('f'),
      'T Function<T>(T)',
    );
  }

  test_empty_notGeneric() async {
    await assertErrorsInCode('''
int f(int x) => x;

void test() {
  int Function(int) context;
  context = f; // 1
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 54, 7),
    ]);
    _assertTearOff(
      'f; // 1',
      findElement.topFunction('f'),
      'int Function(int)',
    );
  }

  test_notEmpty_instanceMethod() async {
    await assertNoErrorsInCode('''
class C {
  T f<T>(T x) => x;
}

int Function(int) test() {
  return new C().f;
}
''');
    _assertGenericFunctionInstantiation(
      'f;',
      findElement.method('f', of: 'C'),
      'int Function(int)',
      ['int'],
    );
  }

  test_notEmpty_localFunction() async {
    await assertNoErrorsInCode('''
int Function(int) test() {
  T f<T>(T x) => x;
  return f;
}
''');
    _assertGenericFunctionInstantiation(
      'f;',
      findElement.localFunction('f'),
      'int Function(int)',
      ['int'],
    );
  }

  test_notEmpty_staticMethod() async {
    await assertNoErrorsInCode('''
class C {
  static T f<T>(T x) => x;
}

int Function(int) test() {
  return C.f;
}
''');
    _assertGenericFunctionInstantiation(
      'f;',
      findElement.method('f', of: 'C'),
      'int Function(int)',
      ['int'],
    );
  }

  test_notEmpty_superMethod() async {
    await assertNoErrorsInCode('''
class C {
  T f<T>(T x) => x;
}

class D extends C {
  int Function(int) test() {
    return super.f;
  }
}
''');
    _assertGenericFunctionInstantiation(
      'f;',
      findElement.method('f', of: 'C'),
      'int Function(int)',
      ['int'],
    );
  }

  test_notEmpty_topLevelFunction() async {
    await assertNoErrorsInCode('''
T f<T>(T x) => x;

int Function(int) test() {
  return f;
}
''');
    _assertGenericFunctionInstantiation(
      'f;',
      findElement.topFunction('f'),
      'int Function(int)',
      ['int'],
    );
  }

  test_null_notTearOff() async {
    await assertNoErrorsInCode('''
T f<T>(T x) => x;

void test() {
  f(0);
}
''');
    _assertTearOff(
      'f(0);',
      findElement.topFunction('f'),
      'T Function<T>(T)',
    );
    assertInvokeType(
      findNode.methodInvocation('f(0)'),
      'int Function(int)',
    );
  }

  void _assertGenericFunctionInstantiation(
    String search,
    ExecutableElement element,
    String type,
    List<String>? typeArguments,
  ) {
    var id = findNode.functionReference(search);
    assertElement(id, element);
    assertType(id, type);
    if (typeArguments != null) {
      assertElementTypes(id.typeArgumentTypes, typeArguments);
    } else {
      expect(id.typeArgumentTypes, isNull);
    }
  }

  void _assertTearOff(
    String search,
    ExecutableElement element,
    String type,
  ) {
    var id = findNode.simple(search);
    assertElement(id, element);
    assertType(id, type);
    expect(id.tearOffTypeArgumentTypes, isNull);
  }
}
