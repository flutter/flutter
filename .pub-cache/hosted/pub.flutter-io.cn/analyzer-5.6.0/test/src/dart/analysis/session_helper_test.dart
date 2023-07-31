// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisSessionHelperTest);
  });
}

@reflectiveTest
class AnalysisSessionHelperTest extends PubPackageResolutionTest {
  late final AnalysisSessionHelper helper;

  @override
  void setUp() {
    super.setUp();
    var session = contextFor(testFile).currentSession;
    helper = AnalysisSessionHelper(session);
  }

  test_getClass_defined() async {
    var file = newFile('$testPackageLibPath/c.dart', r'''
class C {}
int v = 0;
''');
    String uri = file.toUri().toString();

    var element = (await helper.getClass(uri, 'C'))!;
    expect(element.displayName, 'C');
  }

  test_getClass_defined_notClass() async {
    var file = newFile('$testPackageLibPath/c.dart', r'''
int v = 0;
''');
    String uri = file.toUri().toString();

    var element = await helper.getClass(uri, 'v');
    expect(element, isNull);
  }

  test_getClass_exported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');
    var bFile = newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');
    String bUri = bFile.toUri().toString();

    var element = (await helper.getClass(bUri, 'A'))!;
    expect(element.displayName, 'A');
  }

  test_getClass_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');
    var bFile = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
''');
    String bUri = bFile.toUri().toString();

    var element = await helper.getClass(bUri, 'A');
    expect(element, isNull);
  }

  test_getElementDeclaration_class() async {
    await resolveTestCode(r'''
class A {}
''');
    var element = findElement.class_('A');
    var result = (await helper.getElementDeclaration(element))!;
    var node = result.node as ClassDeclaration;
    expect(node.name.lexeme, 'A');
  }

  test_getResolvedUnitByElement() async {
    await resolveTestCode(r'''
class A {}
class B {}
''');
    var element = findNode.classDeclaration('A').declaredElement!;
    var resolvedUnit = (await helper.getResolvedUnitByElement(element))!;
    expect(resolvedUnit.unit.declarations, hasLength(2));
  }

  test_getTopLevelPropertyAccessor_defined_getter() async {
    var file = newFile('$testPackageLibPath/test.dart', r'''
int get a => 0;
''');
    String uri = file.toUri().toString();

    var element = (await helper.getTopLevelPropertyAccessor(uri, 'a'))!;
    expect(element.kind, ElementKind.GETTER);
    expect(element.displayName, 'a');
  }

  test_getTopLevelPropertyAccessor_defined_setter() async {
    var file = newFile('$testPackageLibPath/test.dart', r'''
set a(_) {}
''');
    String uri = file.toUri().toString();

    var element = (await helper.getTopLevelPropertyAccessor(uri, 'a='))!;
    expect(element.kind, ElementKind.SETTER);
    expect(element.displayName, 'a');
  }

  test_getTopLevelPropertyAccessor_defined_variable() async {
    var file = newFile('$testPackageLibPath/test.dart', r'''
int a;
''');
    String uri = file.toUri().toString();

    var element = (await helper.getTopLevelPropertyAccessor(uri, 'a'))!;
    expect(element.kind, ElementKind.GETTER);
    expect(element.displayName, 'a');
  }

  test_getTopLevelPropertyAccessor_exported() async {
    newFile('$testPackageLibPath/a.dart', r'''
int a;
''');
    var bFile = newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');
    String bUri = bFile.toUri().toString();

    var element = (await helper.getTopLevelPropertyAccessor(bUri, 'a'))!;
    expect(element.kind, ElementKind.GETTER);
    expect(element.displayName, 'a');
  }

  test_getTopLevelPropertyAccessor_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
int a;
''');
    var bFile = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
''');
    String bUri = bFile.toUri().toString();

    var element = await helper.getTopLevelPropertyAccessor(bUri, 'a');
    expect(element, isNull);
  }

  test_getTopLevelPropertyAccessor_notDefined() async {
    var file = newFile('$testPackageLibPath/test.dart', r'''
int a;
''');
    String uri = file.toUri().toString();

    var element = await helper.getTopLevelPropertyAccessor(uri, 'b');
    expect(element, isNull);
  }

  test_getTopLevelPropertyAccessor_notPropertyAccessor() async {
    var file = newFile('$testPackageLibPath/test.dart', r'''
int a() {}
''');
    String uri = file.toUri().toString();

    var element = await helper.getTopLevelPropertyAccessor(uri, 'a');
    expect(element, isNull);
  }
}
