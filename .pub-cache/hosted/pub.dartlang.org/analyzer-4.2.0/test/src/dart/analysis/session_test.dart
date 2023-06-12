// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisSessionImplTest);
    defineReflectiveTests(AnalysisSessionImpl_BazelWorkspaceTest);
  });
}

@reflectiveTest
class AnalysisSessionImpl_BazelWorkspaceTest
    extends BazelWorkspaceResolutionTest {
  void test_getErrors_notFileOfUri() async {
    var relPath = 'dart/my/lib/a.dart';
    newFile('$workspaceRootPath/bazel-bin/$relPath', '');

    var path = convertPath('$workspaceRootPath/$relPath');
    var session = contextFor(path).currentSession;
    var result = await session.getErrors(path);
    expect(result, isA<NotPathOfUriResult>());
  }

  void test_getErrors_valid() async {
    var file = newFile(
      '$workspaceRootPath/dart/my/lib/a.dart',
      'var x = 0',
    );

    var session = contextFor(file.path).currentSession;
    var result = await session.getErrorsValid(file.path);
    expect(result.path, file.path);
    expect(result.errors, hasLength(1));
    expect(result.uri.toString(), 'package:dart.my/a.dart');
  }

  void test_getParsedLibrary_notFileOfUri() async {
    var relPath = 'dart/my/lib/a.dart';
    newFile('$workspaceRootPath/bazel-bin/$relPath', '');

    var path = convertPath('$workspaceRootPath/$relPath');
    var session = contextFor(path).currentSession;
    var result = session.getParsedLibrary(path);
    expect(result, isA<NotPathOfUriResult>());
  }

  void test_getResolvedLibrary_notFileOfUri() async {
    var relPath = 'dart/my/lib/a.dart';
    newFile('$workspaceRootPath/bazel-bin/$relPath', '');

    var path = convertPath('$workspaceRootPath/$relPath');
    var session = contextFor(path).currentSession;
    var result = await session.getResolvedLibrary(path);
    expect(result, isA<NotPathOfUriResult>());
  }

  void test_getResolvedUnit_notFileOfUri() async {
    var relPath = 'dart/my/lib/a.dart';
    newFile('$workspaceRootPath/bazel-bin/$relPath', '');

    var path = convertPath('$workspaceRootPath/$relPath');
    var session = contextFor(path).currentSession;
    var result = await session.getResolvedUnit(path);
    expect(result, isA<NotPathOfUriResult>());
  }

  void test_getResolvedUnit_valid() async {
    var file = newFile(
      '$workspaceRootPath/dart/my/lib/a.dart',
      'class A {}',
    );

    var session = contextFor(file.path).currentSession;
    var result = await session.getResolvedUnit(file.path) as ResolvedUnitResult;
    expect(result.path, file.path);
    expect(result.errors, isEmpty);
    expect(result.uri.toString(), 'package:dart.my/a.dart');
  }

  void test_getUnitElement_invalidPath_notAbsolute() async {
    var file = newFile(
      '$workspaceRootPath/dart/my/lib/a.dart',
      'class A {}',
    );

    var session = contextFor(file.path).currentSession;
    var result = await session.getUnitElement('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  void test_getUnitElement_notPathOfUri() async {
    var relPath = 'dart/my/lib/a.dart';
    newFile('$workspaceRootPath/bazel-bin/$relPath', '');

    var path = convertPath('$workspaceRootPath/$relPath');
    var session = contextFor(path).currentSession;
    var result = await session.getUnitElement(path);
    expect(result, isA<NotPathOfUriResult>());
  }

  void test_getUnitElement_valid() async {
    var file = newFile(
      '$workspaceRootPath/dart/my/lib/a.dart',
      'class A {}',
    );

    var session = contextFor(file.path).currentSession;
    var result = await session.getUnitElementValid(file.path);
    expect(result.path, file.path);
    expect(result.element.classes, hasLength(1));
    expect(result.uri.toString(), 'package:dart.my/a.dart');
  }
}

@reflectiveTest
class AnalysisSessionImplTest extends PubPackageResolutionTest {
  test_applyPendingFileChanges_getFile() async {
    final a = newFile('$testPackageLibPath/a.dart', '');
    final analysisContext = contextFor(a.path);

    int lineCount_in_a() {
      final result = analysisContext.currentSession.getFileValid(a.path);
      return result.lineInfo.lineCount;
    }

    expect(lineCount_in_a(), 1);

    newFile(a.path, '\n');
    analysisContext.changeFile(a.path);
    await analysisContext.applyPendingFileChanges();

    // The file must be re-read after `applyPendingFileChanges()`.
    expect(lineCount_in_a(), 2);
  }

  test_applyPendingFileChanges_getParsedLibrary() async {
    final a = newFile('$testPackageLibPath/a.dart', '');
    final analysisContext = contextFor(a.path);

    int lineCount_in_a() {
      final analysisSession = analysisContext.currentSession;
      final result = analysisSession.getParsedLibraryValid(a.path);
      return result.units.first.lineInfo.lineCount;
    }

    expect(lineCount_in_a(), 1);

    newFile(a.path, '\n');
    analysisContext.changeFile(a.path);
    await analysisContext.applyPendingFileChanges();

    // The file must be re-read after `applyPendingFileChanges()`.
    expect(lineCount_in_a(), 2);
  }

  test_applyPendingFileChanges_getParsedUnit() async {
    final a = newFile('$testPackageLibPath/a.dart', '');
    final analysisContext = contextFor(a.path);

    int lineCount_in_a() {
      final result = analysisContext.currentSession.getParsedUnitValid(a.path);
      return result.lineInfo.lineCount;
    }

    expect(lineCount_in_a(), 1);

    newFile(a.path, '\n');
    analysisContext.changeFile(a.path);
    await analysisContext.applyPendingFileChanges();

    // The file must be re-read after `applyPendingFileChanges()`.
    expect(lineCount_in_a(), 2);
  }

  test_getErrors() async {
    var test = newFile(testFilePath, 'class C {');

    var session = contextFor(testFilePath).currentSession;
    var errorsResult = await session.getErrorsValid(test.path);
    expect(errorsResult.session, session);
    expect(errorsResult.path, test.path);
    expect(errorsResult.errors, isNotEmpty);
  }

  test_getErrors_inconsistent() async {
    var test = newFile(testFilePath, '');
    var session = contextFor(test.path).currentSession;
    driverFor(test.path).changeFile(test.path);
    expect(
      () => session.getErrors(test.path),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_getErrors_invalidPath_notAbsolute() async {
    var session = contextFor(testFilePath).currentSession;
    var errorsResult = await session.getErrors('not_absolute.dart');
    expect(errorsResult, isA<InvalidPathResult>());
  }

  test_getFile_inconsistent() async {
    var test = newFile(testFilePath, '');
    var session = contextFor(test.path).currentSession;
    driverFor(test.path).changeFile(test.path);
    expect(
      () => session.getFile(test.path),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_getFile_invalidPath_notAbsolute() async {
    var session = contextFor(testFilePath).currentSession;
    var errorsResult = session.getFile('not_absolute.dart');
    expect(errorsResult, isA<InvalidPathResult>());
  }

  test_getFile_library() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var session = contextFor(testFilePath).currentSession;
    var file = session.getFileValid(a.path);
    expect(file.path, a.path);
    expect(file.uri.toString(), 'package:test/a.dart');
    expect(file.isPart, isFalse);
  }

  test_getFile_part() async {
    var a = newFile('$testPackageLibPath/a.dart', 'part of lib;');

    var session = contextFor(testFilePath).currentSession;
    var file = session.getFileValid(a.path);
    expect(file.path, a.path);
    expect(file.uri.toString(), 'package:test/a.dart');
    expect(file.isPart, isTrue);
  }

  test_getLibraryByUri() async {
    newFile(testFilePath, r'''
class A {}
class B {}
''');

    var session = contextFor(testFilePath).currentSession;
    var result = await session.getLibraryByUriValid('package:test/test.dart');
    var library = result.element;
    expect(library.getType('A'), isNotNull);
    expect(library.getType('B'), isNotNull);
    expect(library.getType('C'), isNull);
  }

  test_getLibraryByUri_inconsistent() async {
    var test = newFile(testFilePath, '');
    var session = contextFor(test.path).currentSession;
    driverFor(test.path).changeFile(test.path);
    expect(
      () => session.getLibraryByUriValid('package:test/test.dart'),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_getLibraryByUri_notLibrary_augmentation() async {
    newFile(testFilePath, r'''
library augment 'a.dart';
''');

    final session = contextFor(testFilePath).currentSession;
    final result = await session.getLibraryByUri('package:test/test.dart');
    expect(result, isA<NotLibraryButAugmentationResult>());
  }

  test_getLibraryByUri_notLibrary_part() async {
    newFile(testFilePath, r'''
part of 'a.dart';
''');

    final session = contextFor(testFilePath).currentSession;
    final result = await session.getLibraryByUri('package:test/test.dart');
    expect(result, isA<NotLibraryButPartResult>());
  }

  test_getLibraryByUri_unresolvedUri() async {
    var session = contextFor(testFilePath).currentSession;
    var result = await session.getLibraryByUri('package:foo/foo.dart');
    expect(result, isA<CannotResolveUriResult>());
  }

  test_getParsedLibrary() async {
    var test = newFile('$testPackageLibPath/a.dart', r'''
class A {}
class B {}
''');

    var session = contextFor(testFilePath).currentSession;
    var parsedLibrary = session.getParsedLibraryValid(test.path);
    expect(parsedLibrary.session, session);

    expect(parsedLibrary.units, hasLength(1));
    {
      var parsedUnit = parsedLibrary.units[0];
      expect(parsedUnit.session, session);
      expect(parsedUnit.path, test.path);
      expect(parsedUnit.uri, Uri.parse('package:test/a.dart'));
      expect(parsedUnit.unit.declarations, hasLength(2));
    }
  }

  test_getParsedLibrary_getElementDeclaration_class() async {
    var test = newFile(testFilePath, r'''
class A {}
class B {}
''');

    var session = contextFor(testFilePath).currentSession;
    var libraryResult = await session.getLibraryByUriValid(
      'package:test/test.dart',
    );
    var parsedLibrary = session.getParsedLibraryValid(test.path);

    var element = libraryResult.element.getType('A')!;
    var declaration = parsedLibrary.getElementDeclaration(element)!;
    var node = declaration.node as ClassDeclaration;
    expect(node.name.name, 'A');
    expect(node.offset, 0);
    expect(node.length, 10);
  }

  test_getParsedLibrary_getElementDeclaration_notThisLibrary() async {
    var test = newFile(testFilePath, '');

    var session = contextFor(testFilePath).currentSession;
    var resolvedUnit =
        await session.getResolvedUnit(test.path) as ResolvedUnitResult;
    var typeProvider = resolvedUnit.typeProvider;
    var intClass = typeProvider.intType.element;

    var parsedLibrary = session.getParsedLibraryValid(test.path);

    expect(() {
      parsedLibrary.getElementDeclaration(intClass);
    }, throwsArgumentError);
  }

  test_getParsedLibrary_getElementDeclaration_synthetic() async {
    var test = newFile(testFilePath, r'''
int foo = 0;
''');

    var session = contextFor(testFilePath).currentSession;
    var parsedLibrary = session.getParsedLibraryValid(test.path);

    var unitResult = await session.getUnitElementValid(test.path);
    var fooElement = unitResult.element.topLevelVariables[0];
    expect(fooElement.name, 'foo');

    // We can get the variable element declaration.
    var fooDeclaration = parsedLibrary.getElementDeclaration(fooElement)!;
    var fooNode = fooDeclaration.node as VariableDeclaration;
    expect(fooNode.name.name, 'foo');
    expect(fooNode.offset, 4);
    expect(fooNode.length, 7);
    expect(fooNode.name.staticElement, isNull);

    // Synthetic elements don't have nodes.
    expect(parsedLibrary.getElementDeclaration(fooElement.getter!), isNull);
    expect(parsedLibrary.getElementDeclaration(fooElement.setter!), isNull);
  }

  test_getParsedLibrary_inconsistent() async {
    var test = newFile(testFilePath, '');
    var session = contextFor(test.path).currentSession;
    driverFor(test.path).changeFile(test.path);
    expect(
      () => session.getParsedLibrary(test.path),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_getParsedLibrary_invalidPartUri() async {
    var test = newFile(testFilePath, r'''
part 'a.dart';
part ':[invalid uri].dart';
part 'c.dart';
''');

    var session = contextFor(testFilePath).currentSession;
    var parsedLibrary = session.getParsedLibraryValid(test.path);

    expect(parsedLibrary.units, hasLength(3));
    expect(
      parsedLibrary.units[0].path,
      convertPath('/home/test/lib/test.dart'),
    );
    expect(
      parsedLibrary.units[1].path,
      convertPath('/home/test/lib/a.dart'),
    );
    expect(
      parsedLibrary.units[2].path,
      convertPath('/home/test/lib/c.dart'),
    );
  }

  test_getParsedLibrary_invalidPath_notAbsolute() async {
    var session = contextFor(testFilePath).currentSession;
    var result = session.getParsedLibrary('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getParsedLibrary_notLibrary() async {
    var test = newFile(testFilePath, 'part of "a.dart";');
    var session = contextFor(testFilePath).currentSession;
    expect(session.getParsedLibrary(test.path), isA<NotLibraryButPartResult>());
  }

  test_getParsedLibrary_notLibrary_augmentation() async {
    newFile(testFilePath, r'''
library augment 'a.dart';
''');

    final session = contextFor(testFilePath).currentSession;
    final result = session.getParsedLibrary(testFile.path);
    expect(result, isA<NotLibraryButAugmentationResult>());
  }

  test_getParsedLibrary_parts() async {
    var aContent = r'''
part 'b.dart';
part 'c.dart';

class A {}
''';

    var bContent = r'''
part of 'a.dart';

class B1 {}
class B2 {}
''';

    var cContent = r'''
part of 'a.dart';

class C1 {}
class C2 {}
class C3 {}
''';

    var a = newFile('$testPackageLibPath/a.dart', aContent);
    var b = newFile('$testPackageLibPath/b.dart', bContent);
    var c = newFile('$testPackageLibPath/c.dart', cContent);

    var session = contextFor(testFilePath).currentSession;
    var parsedLibrary = session.getParsedLibraryValid(a.path);
    expect(parsedLibrary.units, hasLength(3));

    {
      var aUnit = parsedLibrary.units[0];
      expect(aUnit.path, a.path);
      expect(aUnit.uri, Uri.parse('package:test/a.dart'));
      expect(aUnit.unit.declarations, hasLength(1));
    }

    {
      var bUnit = parsedLibrary.units[1];
      expect(bUnit.path, b.path);
      expect(bUnit.uri, Uri.parse('package:test/b.dart'));
      expect(bUnit.unit.declarations, hasLength(2));
    }

    {
      var cUnit = parsedLibrary.units[2];
      expect(cUnit.path, c.path);
      expect(cUnit.uri, Uri.parse('package:test/c.dart'));
      expect(cUnit.unit.declarations, hasLength(3));
    }
  }

  test_getParsedLibraryByElement() async {
    var test = newFile(testFilePath, '');

    var session = contextFor(testFilePath).currentSession;
    var libraryResult = await session.getLibraryByUriValid(
      'package:test/test.dart',
    );
    var element = libraryResult.element;

    var parsedLibrary = session.getParsedLibraryByElementValid(element);
    expect(parsedLibrary.session, session);
    expect(parsedLibrary.units, hasLength(1));

    {
      var unit = parsedLibrary.units[0];
      expect(unit.path, test.path);
      expect(unit.uri, Uri.parse('package:test/test.dart'));
      expect(unit.unit, isNotNull);
    }
  }

  test_getParsedLibraryByElement_differentSession() async {
    newFile(testFilePath, '');

    var session = contextFor(testFilePath).currentSession;
    var libraryResult = await session.getLibraryByUriValid(
      'package:test/test.dart',
    );
    var element = libraryResult.element;

    var aaaSession = contextFor('$workspaceRootPath/aaa').currentSession;

    var result = aaaSession.getParsedLibraryByElement(element);
    expect(result, isA<NotElementOfThisSessionResult>());
  }

  test_getParsedUnit() async {
    var test = newFile(testFilePath, r'''
class A {}
class B {}
''');

    var session = contextFor(testFilePath).currentSession;
    var unitResult = session.getParsedUnitValid(test.path);
    expect(unitResult.session, session);
    expect(unitResult.path, test.path);
    expect(unitResult.uri, Uri.parse('package:test/test.dart'));
    expect(unitResult.unit.declarations, hasLength(2));
  }

  test_getParsedUnit_inconsistent() async {
    var test = newFile(testFilePath, '');
    var session = contextFor(test.path).currentSession;
    driverFor(test.path).changeFile(test.path);
    expect(
      () => session.getParsedUnit(test.path),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_getParsedUnit_invalidPath_notAbsolute() async {
    var session = contextFor(testFilePath).currentSession;
    var result = session.getParsedUnit('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getResolvedLibrary() async {
    var aContent = r'''
part 'b.dart';

class A /*a*/ {}
''';
    var a = newFile('$testPackageLibPath/a.dart', aContent);

    var bContent = r'''
part of 'a.dart';

class B /*b*/ {}
class B2 extends X {}
''';
    var b = newFile('$testPackageLibPath/b.dart', bContent);

    var session = contextFor(testFilePath).currentSession;
    var resolvedLibrary = await session.getResolvedLibraryValid(a.path);
    expect(resolvedLibrary.session, session);

    var typeProvider = resolvedLibrary.typeProvider;
    expect(typeProvider.intType.element.name, 'int');

    var libraryElement = resolvedLibrary.element;

    var aClass = libraryElement.getType('A')!;

    var bClass = libraryElement.getType('B')!;

    var aUnitResult = resolvedLibrary.units[0];
    expect(aUnitResult.path, a.path);
    expect(aUnitResult.uri, Uri.parse('package:test/a.dart'));
    expect(aUnitResult.content, aContent);
    expect(aUnitResult.unit, isNotNull);
    expect(aUnitResult.unit.directives, hasLength(1));
    expect(aUnitResult.unit.declarations, hasLength(1));
    expect(aUnitResult.errors, isEmpty);

    var bUnitResult = resolvedLibrary.units[1];
    expect(bUnitResult.path, b.path);
    expect(bUnitResult.uri, Uri.parse('package:test/b.dart'));
    expect(bUnitResult.content, bContent);
    expect(bUnitResult.unit, isNotNull);
    expect(bUnitResult.unit.directives, hasLength(1));
    expect(bUnitResult.unit.declarations, hasLength(2));
    expect(bUnitResult.errors, isNotEmpty);

    var aDeclaration = resolvedLibrary.getElementDeclaration(aClass)!;
    var aNode = aDeclaration.node as ClassDeclaration;
    expect(aNode.name.name, 'A');
    expect(aNode.offset, 16);
    expect(aNode.length, 16);
    expect(aNode.declaredElement!.name, 'A');

    var bDeclaration = resolvedLibrary.getElementDeclaration(bClass)!;
    var bNode = bDeclaration.node as ClassDeclaration;
    expect(bNode.name.name, 'B');
    expect(bNode.offset, 19);
    expect(bNode.length, 16);
    expect(bNode.declaredElement!.name, 'B');
  }

  test_getResolvedLibrary_getElementDeclaration_notThisLibrary() async {
    var test = newFile(testFilePath, '');

    var session = contextFor(testFilePath).currentSession;
    var resolvedLibrary = await session.getResolvedLibraryValid(test.path);

    expect(() {
      var intClass = resolvedLibrary.typeProvider.intType.element;
      resolvedLibrary.getElementDeclaration(intClass);
    }, throwsArgumentError);
  }

  test_getResolvedLibrary_getElementDeclaration_synthetic() async {
    var test = newFile(testFilePath, r'''
int foo = 0;
''');

    var session = contextFor(testFilePath).currentSession;
    var resolvedLibrary = await session.getResolvedLibraryValid(test.path);
    var unitElement = resolvedLibrary.element.definingCompilationUnit;

    var fooElement = unitElement.topLevelVariables[0];
    expect(fooElement.name, 'foo');

    // We can get the variable element declaration.
    var fooDeclaration = resolvedLibrary.getElementDeclaration(fooElement)!;
    var fooNode = fooDeclaration.node as VariableDeclaration;
    expect(fooNode.name.name, 'foo');
    expect(fooNode.offset, 4);
    expect(fooNode.length, 7);
    expect(fooNode.declaredElement!.name, 'foo');

    // Synthetic elements don't have nodes.
    expect(resolvedLibrary.getElementDeclaration(fooElement.getter!), isNull);
    expect(resolvedLibrary.getElementDeclaration(fooElement.setter!), isNull);
  }

  test_getResolvedLibrary_inconsistent() async {
    var test = newFile(testFilePath, '');
    var session = contextFor(test.path).currentSession;
    driverFor(test.path).changeFile(test.path);
    expect(
      () => session.getResolvedLibrary(test.path),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_getResolvedLibrary_invalidPartUri() async {
    var test = newFile(testFilePath, r'''
part 'a.dart';
part ':[invalid uri].dart';
part 'c.dart';
''');

    var session = contextFor(testFilePath).currentSession;
    var resolvedLibrary = await session.getResolvedLibraryValid(test.path);

    expect(resolvedLibrary.units, hasLength(3));
    expect(
      resolvedLibrary.units[0].path,
      convertPath('/home/test/lib/test.dart'),
    );
    expect(
      resolvedLibrary.units[1].path,
      convertPath('/home/test/lib/a.dart'),
    );
    expect(
      resolvedLibrary.units[2].path,
      convertPath('/home/test/lib/c.dart'),
    );
  }

  test_getResolvedLibrary_invalidPath_notAbsolute() async {
    var session = contextFor(testFilePath).currentSession;
    var result = await session.getResolvedLibrary('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getResolvedLibrary_notLibrary_augmentation() async {
    newFile(testFilePath, r'''
library augment of 'a.dart';
''');

    final session = contextFor(testFilePath).currentSession;
    final result = await session.getResolvedLibrary(testFile.path);
    expect(result, isA<NotLibraryButAugmentationResult>());
  }

  test_getResolvedLibrary_notLibrary_part() async {
    var test = newFile(testFilePath, 'part of "a.dart";');

    var session = contextFor(testFilePath).currentSession;
    var result = await session.getResolvedLibrary(test.path);
    expect(result, isA<NotLibraryButPartResult>());
  }

  test_getResolvedLibraryByElement() async {
    var test = newFile(testFilePath, '');

    var session = contextFor(testFilePath).currentSession;
    var libraryResult = await session.getLibraryByUriValid(
      'package:test/test.dart',
    );
    var element = libraryResult.element;

    var result = await session.getResolvedLibraryByElementValid(element);
    expect(result.session, session);
    expect(result.units, hasLength(1));
    expect(result.units[0].path, test.path);
    expect(result.units[0].uri, Uri.parse('package:test/test.dart'));
    expect(result.units[0].unit.declaredElement, isNotNull);
  }

  test_getResolvedLibraryByElement_differentSession() async {
    newFile(testFilePath, '');

    var session = contextFor(testFilePath).currentSession;
    var libraryResult = await session.getLibraryByUriValid(
      'package:test/test.dart',
    );
    var element = libraryResult.element;

    var aaaSession = contextFor('$workspaceRootPath/aaa').currentSession;

    var result = await aaaSession.getResolvedLibraryByElement(element);
    expect(result, isA<NotElementOfThisSessionResult>());
  }

  test_getResolvedUnit() async {
    var test = newFile(testFilePath, r'''
class A {}
class B {}
''');

    var session = contextFor(testFilePath).currentSession;
    var unitResult =
        await session.getResolvedUnit(test.path) as ResolvedUnitResult;
    expect(unitResult.session, session);
    expect(unitResult.path, test.path);
    expect(unitResult.uri, Uri.parse('package:test/test.dart'));
    expect(unitResult.unit.declarations, hasLength(2));
    expect(unitResult.typeProvider, isNotNull);
    expect(unitResult.libraryElement, isNotNull);
  }

  test_getResolvedUnit_inconsistent() async {
    var test = newFile(testFilePath, '');
    var session = contextFor(test.path).currentSession;
    driverFor(test.path).changeFile(test.path);
    expect(
      () => session.getResolvedUnit(test.path),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_getUnitElement() async {
    var test = newFile(testFilePath, r'''
class A {}
class B {}
''');

    var session = contextFor(testFilePath).currentSession;
    var unitResult = await session.getUnitElementValid(test.path);
    expect(unitResult.session, session);
    expect(unitResult.path, test.path);
    expect(unitResult.uri, Uri.parse('package:test/test.dart'));
    expect(unitResult.element.classes, hasLength(2));
  }

  test_getUnitElement_inconsistent() async {
    var test = newFile(testFilePath, '');
    var session = contextFor(test.path).currentSession;
    driverFor(test.path).changeFile(test.path);
    expect(
      () => session.getUnitElement(test.path),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_resourceProvider() async {
    var session = contextFor(testFilePath).currentSession;
    expect(session.resourceProvider, resourceProvider);
  }
}

extension on AnalysisSession {
  Future<ErrorsResult> getErrorsValid(String path) async {
    return await getErrors(path) as ErrorsResult;
  }

  FileResult getFileValid(String path) {
    return getFile(path) as FileResult;
  }

  Future<LibraryElementResult> getLibraryByUriValid(String path) async {
    return await getLibraryByUri(path) as LibraryElementResult;
  }

  ParsedLibraryResult getParsedLibraryByElementValid(LibraryElement element) {
    return getParsedLibraryByElement(element) as ParsedLibraryResult;
  }

  ParsedLibraryResult getParsedLibraryValid(String path) {
    return getParsedLibrary(path) as ParsedLibraryResult;
  }

  ParsedUnitResult getParsedUnitValid(String path) {
    return getParsedUnit(path) as ParsedUnitResult;
  }

  Future<ResolvedLibraryResult> getResolvedLibraryByElementValid(
      LibraryElement element) async {
    return await getResolvedLibraryByElement(element) as ResolvedLibraryResult;
  }

  Future<ResolvedLibraryResult> getResolvedLibraryValid(String path) async {
    return await getResolvedLibrary(path) as ResolvedLibraryResult;
  }

  Future<UnitElementResult> getUnitElementValid(String path) async {
    return await getUnitElement(path) as UnitElementResult;
  }
}
