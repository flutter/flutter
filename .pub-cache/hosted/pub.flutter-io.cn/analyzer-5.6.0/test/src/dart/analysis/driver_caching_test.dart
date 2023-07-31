// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/extensions/stream.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../summary/macros_environment.dart';
import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverCachingTest);
  });
}

@reflectiveTest
class AnalysisDriverCachingTest extends PubPackageResolutionTest {
  @override
  bool get retainDataForTesting => true;

  List<Set<String>> get _linkedCycles {
    var driver = driverFor(testFile);
    return driver.testView!.libraryContext.linkedCycles;
  }

  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      macrosEnvironment: MacrosEnvironment.instance,
    );
  }

  test_analysisOptions_strictCasts() async {
    useEmptyByteStore();

    // Configure `strict-casts: false`.
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        strictCasts: false,
      ),
    );

    addTestFile(r'''
dynamic a = 0;
int b = a;
''');

    // `strict-cast: false`, so no errors.
    assertErrorsInList(await _computeTestFileErrors(), []);

    // Configure `strict-casts: true`.
    await disposeAnalysisContextCollection();
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        strictCasts: true,
      ),
    );

    // `strict-cast: true`, so has errors.
    assertErrorsInList(await _computeTestFileErrors(), [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 23, 1),
    ]);
  }

  test_change_factoryConstructor_addEqNothing() async {
    await resolveTestCode(r'''
class A {
  factory A();
}
''');

    var analysisDriver = driverFor(testFile);
    analysisDriver.changeFile(testFile.path);
    await analysisDriver.applyPendingFileChanges();

    await resolveTestCode(r'''
class A {
  factory A() =;
}
''');
  }

  test_change_factoryConstructor_moveStaticToken() async {
    await resolveTestCode(r'''
class A {
  factory A();
  static void foo<U>() {}
}
''');

    var analysisDriver = driverFor(testFile);
    analysisDriver.changeFile(testFile.path);
    await analysisDriver.applyPendingFileChanges();

    await resolveTestCode(r'''
class A {
  factory A() =
  static void foo<U>() {}
}
''');
  }

  test_change_field_outOfOrderStaticConst() async {
    await resolveTestCode(r'''
class A {
  static f = Object();
}
''');

    var analysisDriver = driverFor(testFile);
    analysisDriver.changeFile(testFile.path);
    await analysisDriver.applyPendingFileChanges();

    await resolveTestCode(r'''
class A {
  const
  static f = Object();
}
''');
  }

  test_change_field_staticFinal_hasConstConstructor_changeInitializer() async {
    useEmptyByteStore();

    addTestFile(r'''
class A {
  static const a = 0;
  static const b = 1;
  static final Set<int> f = {a};
  const A {}
}
''');

    await resolveTestFile();
    assertType(findElement.field('f').type, 'Set<int>');

    // The summary for the library was linked.
    _assertContainsLinkedCycle({testFile}, andClear: true);

    // Dispose the collection, with its driver.
    // The next analysis will recreate it.
    // We will reuse the byte store, so can reuse summaries.
    await disposeAnalysisContextCollection();

    addTestFile(r'''
class A {
  static const a = 0;
  static const b = 1;
  static final Set<int> f = <int>{a, b, 2};
  const A {}
}
''');

    await resolveTestFile();
    assertType(findElement.field('f').type, 'Set<int>');

    // We changed the initializer of the final field. But it is static, so
    // even though the class hsa a constant constructor, we don't need its
    // initializer, so nothing should be linked.
    _assertNoLinkedCycles();
  }

  test_change_functionBody() async {
    useEmptyByteStore();

    addTestFile(r'''
void f() {
  print(0);
}
''');

    await resolveTestFile();
    expect(findNode.integerLiteral('0'), isNotNull);

    // The summary for the library was linked.
    _assertContainsLinkedCycle({testFile}, andClear: true);

    // Dispose the collection, with its driver.
    // The next analysis will recreate it.
    // We will reuse the byte store, so can reuse summaries.
    await disposeAnalysisContextCollection();

    addTestFile(r'''
void f() {
  print(1);
}
''');

    await resolveTestFile();
    expect(findNode.integerLiteral('1'), isNotNull);

    // We changed only the function body, nothing should be linked.
    _assertNoLinkedCycles();
  }

  test_getLibraryByUri_invalidated_exportNamespace() async {
    useEmptyByteStore();

    var a = newFile('$testPackageLibPath/a.dart', 'const a1 = 0;');
    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
''');

    var driver = driverFor(testFile);

    // Link both libraries, keep them.
    await driver.getLibraryByUri('package:test/a.dart');
    await driver.getLibraryByUri('package:test/b.dart');

    // Discard both libraries.
    driver.changeFile(a.path);

    // Read `package:test/a.dart` from bytes.
    // Don't ask for `exportNamespace`, this used to keep it in the state
    // "should be asked from LinkedElementLibrary", which will ask it
    // from the `LibraryReader` current at the moment of `exportNamespace`
    // access, not necessary the same that created this instance.
    final aResult = await driver.getLibraryByUri('package:test/a.dart');
    final aElement = (aResult as LibraryElementResult).element;

    // The element is valid at this point.
    expect(driver.isValidLibraryElement(aElement), isTrue);

    // Discard both libraries.
    driver.changeFile(a.path);

    // Read `package:test/b.dart`, actually create `LibraryElement` for it.
    // We used to create only `LibraryReader` for `package:test/a.dart`.
    await driver.getLibraryByUri('package:test/b.dart');

    // The element is not valid anymore.
    expect(driver.isValidLibraryElement(aElement), isFalse);

    // But its `exportNamespace` can be accessed.
    expect(aElement.exportNamespace.definedNames, isNotEmpty);

    // TODO(scheglov) This is not quite right.
    // When we return `LibraryElement` that is not fully read, and read
    // anything lazily, we can be in a situation when there was a change,
    // and an imported library does not define a referenced element anymore.
    // But there is still a client that holds this `LibraryElement`, and
    // its summary information says "get element X from `package:Y"; and when
    // we attempt to get it, the might be no `X` in `Y`.
  }

  test_lint_dependOnReferencedPackage_update_pubspec_addDependency() async {
    useEmptyByteStore();

    var aaaPackageRootPath = '$packagesRootPath/aaa';
    newFile('$aaaPackageRootPath/lib/a.dart', '');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaPackageRootPath),
    );

    // Configure with the lint.
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(lints: ['depend_on_referenced_packages']),
    );

    // Configure without dependencies, but with a (required) name.
    // So, the lint rule will be activated.
    writeTestPackagePubspecYamlFile(
      PubspecYamlFileConfig(
        name: 'my_test',
        dependencies: [],
      ),
    );

    addTestFile(r'''
// ignore:unused_import
import 'package:aaa/a.dart';
''');

    // We don't have a dependency on `package:aaa`, so there is a lint.
    _assertHasLintReported(
      await _computeTestFileErrors(),
      'depend_on_referenced_packages',
    );

    // The summary for the library was linked.
    _assertContainsLinkedCycle({testFile}, andClear: true);

    // We will recreate it with new pubspec.yaml content.
    // But we will reuse the byte store, so can reuse summaries.
    await disposeAnalysisContextCollection();

    // Add dependency on `package:aaa`.
    writeTestPackagePubspecYamlFile(
      PubspecYamlFileConfig(
        name: 'my_test',
        dependencies: [
          PubspecYamlFileDependency(name: 'aaa'),
        ],
      ),
    );

    // With dependency on `package:aaa` added, no lint is reported.
    expect(await _computeTestFileErrors(), isEmpty);

    // Lints don't affect summaries, nothing should be linked.
    _assertNoLinkedCycles();
  }

  test_lints() async {
    useEmptyByteStore();

    // Configure without any lint, but without experiments as well.
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(lints: []),
    );

    addTestFile(r'''
void f() {
  ![0].isEmpty;
}
''');

    // We don't have any lints configured, so no errors.
    await resolveTestFile();
    assertErrorsInResult([]);

    // The summary for the library was linked.
    _assertContainsLinkedCycle({testFile}, andClear: true);

    // We will recreate it with new analysis options.
    // But we will reuse the byte store, so can reuse summaries.
    await disposeAnalysisContextCollection();

    // Configure to run a lint.
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        lints: ['prefer_is_not_empty'],
      ),
    );

    // Check that the lint was run, and reported.
    await resolveTestFile();
    _assertHasLintReported(result.errors, 'prefer_is_not_empty');

    // Lints don't affect summaries, nothing should be linked.
    _assertNoLinkedCycles();
  }

  test_macro_libraryElement_changeMacroCode() async {
    final macroFile = _newFileWithFixedNameMacro('MacroA');

    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'my_macro.dart';

@MyMacro()
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    final analysisContext = contextFor(macroFile);

    Future<LibraryElement> getLibrary(String uriStr) async {
      final result = await analysisContext.currentSession
          .getLibraryByUri(uriStr) as LibraryElementResult;
      return result.element;
    }

    // This macro generates `MacroA`, but not `MacroB`.
    {
      final libraryA = await getLibrary('package:test/a.dart');
      expect(libraryA.getClass('MacroA'), isNotNull);
      expect(libraryA.getClass('MacroB'), isNull);
      // This propagates transitively.
      final libraryB = await getLibrary('package:test/b.dart');
      expect(libraryB.exportNamespace.get('MacroA'), isNotNull);
      expect(libraryB.exportNamespace.get('MacroB'), isNull);
    }

    _assertContainsLinkedCycle({a});
    _assertContainsLinkedCycle({b}, andClear: true);

    // The macro will generate `MacroB`.
    _newFileWithFixedNameMacro('MacroB');

    // Notify about changes.
    analysisContext.changeFile(macroFile.path);
    await analysisContext.applyPendingFileChanges();

    // This macro generates `MacroB`, but not `MacroA`.
    {
      final libraryA = await getLibrary('package:test/a.dart');
      expect(libraryA.getClass('MacroA'), isNull);
      expect(libraryA.getClass('MacroB'), isNotNull);
      // This propagates transitively.
      final libraryB = await getLibrary('package:test/b.dart');
      expect(libraryB.exportNamespace.get('MacroA'), isNull);
      expect(libraryB.exportNamespace.get('MacroB'), isNotNull);
    }

    _assertContainsLinkedCycle({a});
    _assertContainsLinkedCycle({b}, andClear: true);
  }

  test_macro_reanalyze_errors_changeCodeUsedByMacro_importedLibrary() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
String getClassName() => 'MacroA';
''');

    newFile('$testPackageLibPath/my_macro.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'a.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    final className = getClassName();
    builder.declareType(
      '$className',
      DeclarationCode.fromString('class $className {}'),
    );
  }
}
''');

    var user = newFile('$testPackageLibPath/user.dart', r'''
import 'my_macro.dart';

@MyMacro()
class A {}

void f(MacroA a) {}
''');

    var analysisContext = contextFor(a);
    var analysisDriver = driverFor(a);

    var userErrors = analysisDriver.results
        .whereType<ErrorsResult>()
        .where((event) => event.path == user.path);

    // We get errors when the file is added.
    analysisDriver.addFile(user.path);
    assertErrorsInList((await userErrors.first).errors, []);

    // The macro will generate `MacroB`.
    newFile('$testPackageLibPath/a.dart', r'''
String getClassName() => 'MacroB';
''');

    // Notify about changes.
    analysisContext.changeFile(a.path);
    await analysisContext.applyPendingFileChanges();

    // The change to the macro cause re-analysis of the user file.
    assertErrorsInList((await userErrors.first).errors, [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 55, 6),
    ]);
  }

  test_macro_reanalyze_errors_changeCodeUsedByMacro_part() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part of 'my_macro.dart';
String getClassName() => 'MacroA';
''');

    newFile('$testPackageLibPath/my_macro.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';
part 'a.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    final className = getClassName();
    builder.declareType(
      '$className',
      DeclarationCode.fromString('class $className {}'),
    );
  }
}
''');

    var user = newFile('$testPackageLibPath/user.dart', r'''
import 'my_macro.dart';

@MyMacro()
class A {}

void f(MacroA a) {}
''');

    var analysisContext = contextFor(a);
    var analysisDriver = driverFor(a);

    var userErrors = analysisDriver.results
        .whereType<ErrorsResult>()
        .where((event) => event.path == user.path);

    // We get errors when the file is added.
    analysisDriver.addFile(user.path);
    assertErrorsInList((await userErrors.first).errors, []);

    // The macro will generate `MacroB`.
    newFile('$testPackageLibPath/a.dart', r'''
part of 'my_macro.dart';
String getClassName() => 'MacroB';
''');

    // Notify about changes.
    analysisContext.changeFile(a.path);
    await analysisContext.applyPendingFileChanges();

    // The change to the macro cause re-analysis of the user file.
    assertErrorsInList((await userErrors.first).errors, [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 55, 6),
    ]);
  }

  test_macro_reanalyze_errors_changeMacroCode() async {
    var macroFile = _newFileWithFixedNameMacro('MacroA');

    var user = newFile('$testPackageLibPath/user.dart', r'''
import 'my_macro.dart';

@MyMacro()
class A {}

void f(MacroA a) {}
''');

    var analysisContext = contextFor(user);
    var analysisDriver = driverFor(user);

    var userErrors = analysisDriver.results
        .whereType<ErrorsResult>()
        .where((event) => event.path == user.path);

    // We get errors when the file is added.
    analysisDriver.addFile(user.path);
    assertErrorsInList((await userErrors.first).errors, []);

    // The macro will generate `MacroB`.
    _newFileWithFixedNameMacro('MacroB');

    // Notify about changes.
    analysisContext.changeFile(macroFile.path);
    await analysisContext.applyPendingFileChanges();

    // The change to the macro cause re-analysis of the user file.
    assertErrorsInList((await userErrors.first).errors, [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 55, 6),
    ]);
  }

  test_macro_resolvedUnit_changeCodeUsedByMacro() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
String getClassName() => 'MacroA';
''');

    newFile('$testPackageLibPath/my_macro.dart', r'''
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'a.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  FutureOr<void> buildTypesForClass(clazz, builder) {
    final className = getClassName();
    builder.declareType(
      '$className',
      DeclarationCode.fromString('class $className {}'),
    );
  }
}
''');

    // The macro will generate `MacroA`, so no errors.
    await assertNoErrorsInCode('''
import 'my_macro.dart';

@MyMacro()
class A {}

void f(MacroA a) {}
''');

    // The macro will generate `MacroB`.
    newFile(a.path, r'''
String getClassName() => 'MacroB';
''');

    // Notify about changes.
    var analysisContext = contextFor(a);
    analysisContext.changeFile(a.path);
    await analysisContext.applyPendingFileChanges();

    // Resolve the test file, it still references `MacroA`, but the macro
    // generates `MacroB` now, so we have an error.
    await resolveTestFile();
    assertErrorsInResult([
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 55, 6),
    ]);
  }

  void _assertContainsLinkedCycle(Set<File> expectedFiles,
      {bool andClear = false}) {
    var expected = expectedFiles.map((file) => file.path).toSet();
    expect(_linkedCycles, contains(unorderedEquals(expected)));
    if (andClear) {
      _linkedCycles.clear();
    }
  }

  void _assertHasLintReported(List<AnalysisError> errors, String name) {
    var matching = errors.where((element) {
      var errorCode = element.errorCode;
      return errorCode is LintCode && errorCode.name == name;
    }).toList();
    expect(matching, hasLength(1));
  }

  void _assertNoLinkedCycles() {
    expect(_linkedCycles, isEmpty);
  }

  /// Note that we intentionally use this method, we don't want to use
  /// [resolveFile] instead. Resolving a file will force to produce its
  /// resolved AST, and as a result to recompute the errors.
  ///
  /// But this method is used to check returning errors from the cache, or
  /// recomputing when the cache key is expected to be different.
  Future<List<AnalysisError>> _computeTestFileErrors() async {
    var errorsResult = await contextFor(testFile)
        .currentSession
        .getErrors(testFile.path) as ErrorsResult;
    return errorsResult.errors;
  }

  File _newFileWithFixedNameMacro(String className) {
    return newFile('$testPackageLibPath/my_macro.dart', '''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    builder.declareType(
      '$className',
      DeclarationCode.fromString('class $className {}'),
    );
  }
}
''');
  }
}

extension on AnalysisDriver {
  bool isValidLibraryElement(LibraryElement element) {
    return identical(element.session, currentSession);
  }
}
