// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResolveForCompletionTest);
  });
}

@reflectiveTest
class ResolveForCompletionTest extends PubPackageResolutionTest {
  AnalysisDriver get testDriver {
    return driverFor(testFilePathPlatform);
  }

  String get testFilePathPlatform => convertPath(testFilePath);

  test_class__fieldDeclaration_type_namedType_name() async {
    var result = _resolveTestCode(r'''
class A {
  var f1 = 0;
  doub^ f2 = null;
  var f3 = 1;
}
''');

    result.assertResolvedNodes([]);
  }

  test_class__fieldDeclaration_type_namedType_typeArgument_name() async {
    var result = _resolveTestCode(r'''
class A {
  var f1 = 0;
  List<doub^>? f2 = null;
  var f3 = 1;
}
''');

    result.assertResolvedNodes([]);
  }

  test_class_extends_name() async {
    var result = _resolveTestCode(r'''
class A extends foo^ {}
''');

    result.assertResolvedNodes([]);
  }

  test_class_fieldDeclaration_initializer() async {
    var result = _resolveTestCode(r'''
class A {
  var f1 = 0;
  var f2 = foo^;
  var f3 = 1;
}
''');

    result.assertResolvedNodes([
      'var f2 = foo;',
    ]);
  }

  test_class_implements_name() async {
    var result = _resolveTestCode(r'''
class A implements foo^ {}
''');

    result.assertResolvedNodes([]);
  }

  test_class_methodDeclaration_body() async {
    var result = _resolveTestCode(r'''
class A {}

class B {
  void foo1() {}

  void foo2() {
    print(0);
    bar^;
    print(1);
  }

  void foo3() {}
}
''');

    result.assertResolvedNodes([
      'void foo2() {print(0); bar; print(1);}',
    ]);
  }

  test_class_methodDeclaration_name() async {
    var result = _resolveTestCode(r'''
class A {
  void foo^() {
    print(0);
  }
}
''');

    result.assertResolvedNodes([]);
  }

  test_class_methodDeclaration_returnType_name() async {
    var result = _resolveTestCode(r'''
class A {
  doub^ foo() {}
}
''');

    result.assertResolvedNodes([]);
  }

  test_class_with_name() async {
    var result = _resolveTestCode(r'''
class A with foo^ {}
''');

    result.assertResolvedNodes([]);
  }

  test_constructorDeclaration_body() async {
    var result = _resolveTestCode(r'''
class A {}

class B {
  void foo1() {}

  B() {
    print(0);
    bar^;
    print(1);
  }

  void foo2() {}
}
''');

    result.assertResolvedNodes([
      'B() {print(0); bar; print(1);}',
    ]);
  }

  test_constructorDeclaration_fieldInitializer_name() async {
    var result = _resolveTestCode(r'''
class A {}

class B {
  var f;

  void foo1() {}

  B(int a) : bar^ = 0 {
    print(0);
  }

  void foo2() {}
}
''');

    result.assertResolvedNodes([]);
  }

  test_constructorDeclaration_fieldInitializer_value() async {
    var result = _resolveTestCode(r'''
class A {
  var f;

  A(int a) : f = a + bar^ {
    print(0);
  }
}
''');

    // TODO(scheglov) Resolve only the initializer.
    result.assertResolvedNodes([
      'A(int a) : f = a + bar {print(0);}',
    ]);
  }

  test_constructorDeclaration_name() async {
    var result = _resolveTestCode(r'''
class A {
  A.foo^() {
    print(0);
  }
}
''');

    result.assertResolvedNodes([]);
  }

  test_doubleLiteral() async {
    var result = _resolveTestCode(r'''
var v = 1.2^;
''');

    result.assertResolvedNodes([]);
  }

  test_extension_methodDeclaration_body() async {
    var result = _resolveTestCode(r'''
extension E on int {
  void foo1() {}

  void foo2() {
    print(0);
    bar^;
    print(1);
  }

  void foo3() {}
}
''');

    result.assertResolvedNodes([
      'void foo2() {print(0); bar; print(1);}',
    ]);
  }

  test_extension_methodDeclaration_name() async {
    var result = _resolveTestCode(r'''
extension E on int {
  void foo^() {
    print(0);
  }
}
''');

    result.assertResolvedNodes([]);
  }

  test_extension_methodDeclaration_returnType_name() async {
    var result = _resolveTestCode(r'''
extension E on int {
  doub^ foo() {}
}
''');

    result.assertResolvedNodes([]);
  }

  test_extension_on_name() async {
    var result = _resolveTestCode(r'''
extension E on int^ {
  void foo() {}
}
''');

    result.assertResolvedNodes([]);
  }

  test_functionDeclaration_body() async {
    var result = _resolveTestCode(r'''
void foo1() {}

void foo2() {
  print(0);
  bar^;
  print(1);
}

void foo3() {}
''');

    result.assertResolvedNodes([
      'void foo2() {print(0); bar; print(1);}',
    ]);
  }

  test_functionDeclaration_name() async {
    var result = _resolveTestCode(r'''
void foo^() {
  print(0);
}
''');

    result.assertResolvedNodes([]);
  }

  test_functionDeclaration_returnType_name() async {
    var result = _resolveTestCode(r'''
doub^ f() {}
''');

    result.assertResolvedNodes([]);
  }

  test_importDirective_show_name() async {
    var result = _resolveTestCode(r'''
import 'dart:async';
import 'dart:math' show ^;
import 'dart:io';
''');

    result.assertResolvedNodes([
      "import 'dart:math' show ;",
    ]);
  }

  test_importDirective_uri() async {
    var result = _resolveTestCode(r'''
import 'dart:async';
import 'dart:ma^'
import 'dart:io';
''');

    result.assertResolvedNodes([
      "import 'dart:ma';",
    ]);
  }

  test_integerLiteral() async {
    var result = _resolveTestCode(r'''
var v = 0^;
''');

    result.assertResolvedNodes([]);
  }

  test_localVariableDeclaration_name() async {
    var result = _resolveTestCode(r'''
void f() {
  var foo^
}
''');

    result.assertResolvedNodes([]);
  }

  test_localVariableDeclaration_type_name() async {
    var result = _resolveTestCode(r'''
void f() {
  doub^ a;
}
''');

    result.assertResolvedNodes([]);
  }

  test_mixin_implements_name() async {
    var result = _resolveTestCode(r'''
mixin M implements foo^ {}
''');

    result.assertResolvedNodes([]);
  }

  test_mixin_methodDeclaration_body() async {
    var result = _resolveTestCode(r'''
class A {}

mixin M {
  void foo1() {}

  void foo2() {
    print(0);
    bar^;
    print(1);
  }

  void foo3() {}
}
''');

    result.assertResolvedNodes([
      'void foo2() {print(0); bar; print(1);}',
    ]);
  }

  test_mixin_methodDeclaration_name() async {
    var result = _resolveTestCode(r'''
mixin M {
  void foo^() {
    print(0);
  }
}
''');

    result.assertResolvedNodes([]);
  }

  test_mixin_methodDeclaration_returnType_name() async {
    var result = _resolveTestCode(r'''
mixin M {
  doub^ foo() {}
}
''');

    result.assertResolvedNodes([]);
  }

  test_mixin_on_name() async {
    var result = _resolveTestCode(r'''
mixin M on foo^ {}
''');

    result.assertResolvedNodes([]);
  }

  test_processPendingChanges() async {
    newFile(testFilePath, content: 'class A {}');

    // Read the file.
    testDriver.getFileSync(testFilePathPlatform);

    // Should call `changeFile()`, and the driver must re-read the file.
    var result = _resolveTestCode(r'''
var v1 = 0;
var v2 = v1.^;
''');

    result.assertResolvedNodes([
      'var v2 = v1.;',
    ]);
  }

  test_simpleFormalParameter_name() async {
    var result = _resolveTestCode(r'''
void f(doub^) {}
''');

    result.assertResolvedNodes([]);
  }

  test_simpleFormalParameter_type_name() async {
    var result = _resolveTestCode(r'''
void f(doub^ a) {}
''');

    result.assertResolvedNodes([]);
  }

  test_topLevelVariable_initializer() async {
    var result = _resolveTestCode(r'''
var v1 = 0;
var v2 = foo^;
var v3 = 1;
''');

    result.assertResolvedNodes([
      'var v2 = foo;',
    ]);
  }

  test_topLevelVariable_name() async {
    var result = _resolveTestCode(r'''
var v1 = 0;
var v2^
var v3 = 0;
''');

    result.assertResolvedNodes([]);
  }

  test_topLevelVariable_type_namedType_name() async {
    var result = _resolveTestCode(r'''
var v1 = 0;
doub^ v2 = null;
var v3 = 1;
''');

    result.assertResolvedNodes([]);
  }

  test_topLevelVariable_type_namedType_typeArgument_name() async {
    var result = _resolveTestCode(r'''
var v1 = 0;
List<doub^>? v2 = null;
var v3 = 1;
''');

    result.assertResolvedNodes([]);
  }

  test_typedef_name_nothing() async {
    var result = _resolveTestCode(r'''
typedef F^
''');

    _assertWholeUnitResolved(result);
  }

  test_typeParameter_name() async {
    var result = _resolveTestCode(r'''
void f<T^>() {
  print(0);
}
''');

    result.assertResolvedNodes([]);
  }

  int _newFileWithOffset(String path, String content) {
    var offset = content.indexOf('^');
    expect(offset, isNot(equals(-1)), reason: 'missing ^');

    var nextOffset = content.indexOf('^', offset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');

    var before = content.substring(0, offset);
    var after = content.substring(offset + 1);
    newFile(path, content: before + after);

    return offset;
  }

  ResolvedForCompletionResultImpl _resolveTestCode(String content) {
    var path = testFilePathPlatform;
    var offset = _newFileWithOffset(path, content);
    testDriver.changeFile(path);

    var performance = OperationPerformanceImpl('<root>');
    var result = testDriver.resolveForCompletion(
      path: path,
      offset: offset,
      performance: performance,
    );
    return result!;
  }

  static void _assertWholeUnitResolved(
    ResolvedForCompletionResultImpl result,
  ) {
    expect(result.resolvedNodes, [result.parsedUnit]);
  }
}

extension ResolvedForCompletionResultImplExtension
    on ResolvedForCompletionResultImpl {
  void assertResolvedNodes(List<String> expected) {
    var actual = resolvedNodes.map((e) => '$e').toList();
    expect(actual, expected);
  }
}
