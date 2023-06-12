// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForElementTest);
    defineReflectiveTests(IfElementTest);
    defineReflectiveTests(SpreadElementTest);
  });
}

@reflectiveTest
class ForElementTest extends PubPackageResolutionTest {
  test_list_awaitForIn_dynamic_downward() async {
    await resolveTestCode('''
void f() async {
  var b = <int>[await for (var e in a()) e];
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Stream<Object?> Function()');
  }

  test_list_awaitForIn_int_downward() async {
    await resolveTestCode('''
void f() async {
  var b = <int>[await for (int e in a()) e];
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'Stream<int> Function()');
  }

  test_list_for_downward() async {
    await resolveTestCode('''
void f() {
  var b = <int>[for (int i = 0; a(); i++) i];
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }

  test_list_forIn_dynamic_downward() async {
    await resolveTestCode('''
void f() {
  var b = <int>[for (var e in a()) e];
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Iterable<Object?> Function()');
  }

  test_list_forIn_int_downward() async {
    await resolveTestCode('''
void f() {
  var b = <int>[for (int e in a()) e];
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Iterable<int> Function()');
  }

  test_map_awaitForIn_dynamic_downward() async {
    await resolveTestCode('''
void f() async {
  var b = <int, int>{await for (var e in a()) e : e};
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Stream<Object?> Function()');
  }

  test_map_awaitForIn_int_downward() async {
    await resolveTestCode('''
void f() async {
  var b = <int, int>{await for (int e in a()) e : e};
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'Stream<int> Function()');
  }

  test_map_for_downward() async {
    await resolveTestCode('''
void f() {
  var b = <int, int>{for (int i = 0; a(); i++) i : i};
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }

  test_map_forIn_dynamic_downward() async {
    await resolveTestCode('''
void f() {
  var b = <int, int>{for (var e in a()) e : e};
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Iterable<Object?> Function()');
  }

  test_map_forIn_int_downward() async {
    await resolveTestCode('''
void f() {
  var b = <int, int>{for (int e in a()) e : e};
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Iterable<int> Function()');
  }

  test_set_awaitForIn_dynamic_downward() async {
    await resolveTestCode('''
void f() async {
  var b = <int>{await for (var e in a()) e};
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Stream<Object?> Function()');
  }

  test_set_awaitForIn_int_downward() async {
    await resolveTestCode('''
void f() async {
  var b = <int>{await for (int e in a()) e};
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'Stream<int> Function()');
  }

  test_set_for_downward() async {
    await resolveTestCode('''
void f() {
  var b = <int>{for (int i = 0; a(); i++) i};
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }

  test_set_forIn_dynamic_downward() async {
    await resolveTestCode('''
void f() {
  var b = <int>{for (var e in a()) e};
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Iterable<Object?> Function()');
  }

  test_set_forIn_int_downward() async {
    await resolveTestCode('''
void f() {
  var b = <int>{for (int e in a()) e};
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Iterable<int> Function()');
  }
}

@reflectiveTest
class IfElementTest extends PubPackageResolutionTest {
  test_list_downward() async {
    await resolveTestCode('''
void f() {
  var b = <int>[if (a()) 1];
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }

  test_map_downward() async {
    await resolveTestCode('''
void f() {
  var b = <String, int>{if (a()) 'a' : 1};
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }

  test_set_downward() async {
    await resolveTestCode('''
void f() {
  var b = <int>{if (a()) 1};
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }
}

@reflectiveTest
class SpreadElementTest extends PubPackageResolutionTest {
  test_list_downward() async {
    await resolveTestCode('''
void f() {
  var b = <int>[...a()];
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Iterable<int> Function()');
  }

  test_map_downward() async {
    await resolveTestCode('''
void f() {
  var b = <String, int>{...a()};
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Map<String, int> Function()');
  }

  test_set_downward() async {
    await resolveTestCode('''
void f() {
  var b = <int>{...a()};
  print(b);
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Iterable<int> Function()');
  }
}
