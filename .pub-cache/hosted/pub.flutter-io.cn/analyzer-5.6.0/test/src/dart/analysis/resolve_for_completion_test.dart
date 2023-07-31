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
    return driverFor(testFile);
  }

  test_class_body_identifier_beforeFieldDeclaration() async {
    var result = await _resolveTestCode(r'''
class A {
  foo^
  int bar = 0;
}
''');

    result.assertResolvedNodes([
      'foo int;',
    ]);
  }

  test_class_fieldDeclaration_initializer() async {
    var result = await _resolveTestCode(r'''
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

  test_class_fieldDeclaration_type_namedType_name() async {
    var result = await _resolveTestCode(r'''
class A {
  var f1 = 0;
  dou^ f2 = null;
  var f3 = 1;
}
''');

    result.assertResolvedNodes([
      'dou f2 = null;',
    ]);
  }

  test_class_methodDeclaration_body() async {
    var result = await _resolveTestCode(r'''
class A {}

class B {
  void foo1() {}

  void foo2() {
    print(0);
    bar^
    print(1);
  }

  void foo3() {}
}
''');

    result.assertResolvedNodes([
      'void foo2() {print(0); bar print; (1);}',
    ]);
  }

  test_classDeclaration_body_identifier() async {
    var result = await _resolveTestCode(r'''
class A {}

class B {
  void foo() {}

  bar^
}
''');

    result.assertResolvedNodes([
      'bar;',
    ]);
  }

  test_constructorDeclaration_body() async {
    var result = await _resolveTestCode(r'''
class A {}

class B {
  void foo1() {}

  B() {
    print(0);
    bar^
    print(1);
  }

  void foo2() {}
}
''');

    result.assertResolvedNodes([
      'B() {print(0); bar print; (1);}',
    ]);
  }

  test_constructorDeclaration_fieldFormalParameter_name() async {
    var result = await _resolveTestCode(r'''
class A {
  final int f;
  A(this.^);
}
''');

    result.assertResolvedNodes([
      'A(this.);',
    ]);
  }

  test_constructorDeclaration_fieldInitializer_value() async {
    var result = await _resolveTestCode(r'''
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

  test_constructorDeclaration_superFormalParameter_name() async {
    var result = await _resolveTestCode(r'''
class A {
  A(int first, double second);
  A.named(int third);
}

class B extends A {
  B(super.^);
}
''');

    result.assertResolvedNodes([
      'B(super.);',
    ]);
  }

  test_extension_methodDeclaration_body() async {
    var result = await _resolveTestCode(r'''
extension E on int {
  void foo1() {}

  void foo2() {
    print(0);
    bar^
    print(1);
  }

  void foo3() {}
}
''');

    result.assertResolvedNodes([
      'void foo2() {print(0); bar print; (1);}',
    ]);
  }

  test_functionDeclaration_body() async {
    var result = await _resolveTestCode(r'''
void foo1() {}

void foo2() {
  print(0);
  bar^
  print(1);
}

void foo3() {}
''');

    result.assertResolvedNodes([
      'void foo2() {print(0); bar print; (1);}',
    ]);
  }

  test_functionDeclaration_body_withSemicolon() async {
    var result = await _resolveTestCode(r'''
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

  test_importDirective_show_name() async {
    var result = await _resolveTestCode(r'''
import 'dart:async';
import 'dart:math' show ^;
import 'dart:io';
''');

    result.assertResolvedNodes([
      "import 'dart:math' show ;",
    ]);
  }

  test_importDirective_uri() async {
    var result = await _resolveTestCode(r'''
import 'dart:async';
import 'dart:ma^'
import 'dart:io';
''');

    result.assertResolvedNodes([
      "import 'dart:ma';",
    ]);
  }

  test_mixin_methodDeclaration_body() async {
    var result = await _resolveTestCode(r'''
class A {}

mixin M {
  void foo1() {}

  void foo2() {
    print(0);
    bar^
    print(1);
  }

  void foo3() {}
}
''');

    result.assertResolvedNodes([
      'void foo2() {print(0); bar print; (1);}',
    ]);
  }

  test_processPendingChanges() async {
    addTestFile('class A {}');

    // Read the file.
    testDriver.getFileSync(testFile.path);

    // Should call `changeFile()`, and the driver must re-read the file.
    var result = await _resolveTestCode(r'''
var v1 = 0;
var v2 = v1.^;
''');

    result.assertResolvedNodes([
      'var v2 = v1.;',
    ]);
  }

  test_topLevelVariable_initializer() async {
    var result = await _resolveTestCode(r'''
var v1 = 0;
var v2 = foo^;
var v3 = 1;
''');

    result.assertResolvedNodes([
      'var v2 = foo;',
    ]);
  }

  test_typedef_name_nothing() async {
    var result = await _resolveTestCode(r'''
typedef F^
''');

    _assertWholeUnitResolved(result);
  }

  int _newFileWithOffset(String path, String content) {
    var offset = content.indexOf('^');
    expect(offset, isNot(equals(-1)), reason: 'missing ^');

    var nextOffset = content.indexOf('^', offset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');

    var before = content.substring(0, offset);
    var after = content.substring(offset + 1);
    newFile(path, before + after);

    return offset;
  }

  Future<ResolvedForCompletionResultImpl> _resolveTestCode(
    String content,
  ) async {
    var path = testFile.path;
    var offset = _newFileWithOffset(path, content);

    testDriver.changeFile(path);
    await testDriver.applyPendingFileChanges();

    var performance = OperationPerformanceImpl('<root>');
    var result = await testDriver.resolveForCompletion(
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
