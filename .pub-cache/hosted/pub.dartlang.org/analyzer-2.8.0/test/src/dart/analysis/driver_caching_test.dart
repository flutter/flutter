// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverCachingTest);
  });
}

@reflectiveTest
class AnalysisDriverCachingTest extends PubPackageResolutionTest {
  String get testFilePathPlatform => convertPath(testFilePath);

  List<Set<String>> get _linkedCycles {
    var driver = driverFor(testFilePath);
    return driver.test.libraryContextTestView.linkedCycles;
  }

  test_change_factoryConstructor_addEqNothing() async {
    await resolveTestCode(r'''
class A {
  factory A();
}
''');

    driverFor(testFilePathPlatform).changeFile(testFilePathPlatform);
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

    driverFor(testFilePathPlatform).changeFile(testFilePathPlatform);
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

    driverFor(testFilePathPlatform).changeFile(testFilePathPlatform);
    await resolveTestCode(r'''
class A {
  const
  static f = Object();
}
''');
  }

  test_change_field_staticFinal_hasConstConstructor_changeInitializer() async {
    useEmptyByteStore();

    newFile(testFilePath, content: r'''
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
    _assertContainsLinkedCycle({testFilePath}, andClear: true);

    // Dispose the collection, with its driver.
    // The next analysis will recreate it.
    // We will reuse the byte store, so can reuse summaries.
    disposeAnalysisContextCollection();

    newFile(testFilePath, content: r'''
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

    newFile(testFilePath, content: r'''
void f() {
  print(0);
}
''');

    await resolveTestFile();
    expect(findNode.integerLiteral('0'), isNotNull);

    // The summary for the library was linked.
    _assertContainsLinkedCycle({testFilePath}, andClear: true);

    // Dispose the collection, with its driver.
    // The next analysis will recreate it.
    // We will reuse the byte store, so can reuse summaries.
    disposeAnalysisContextCollection();

    newFile(testFilePath, content: r'''
void f() {
  print(1);
}
''');

    await resolveTestFile();
    expect(findNode.integerLiteral('1'), isNotNull);

    // We changed only the function body, nothing should be linked.
    _assertNoLinkedCycles();
  }

  test_lint_dependOnReferencedPackage_update_pubspec_addDependency() async {
    useEmptyByteStore();

    var aaaPackageRootPath = '$packagesRootPath/aaa';
    newFile('$aaaPackageRootPath/lib/a.dart', content: '');

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

    newFile(testFilePath, content: r'''
// ignore:unused_import
import 'package:aaa/a.dart';
''');

    // We don't have a dependency on `package:aaa`, so there is a lint.
    _assertHasLintReported(
      await _computeTestFileErrors(),
      'depend_on_referenced_packages',
    );

    // The summary for the library was linked.
    _assertContainsLinkedCycle({testFilePath}, andClear: true);

    // We will recreate it with new pubspec.yaml content.
    // But we will reuse the byte store, so can reuse summaries.
    disposeAnalysisContextCollection();

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

    newFile(testFilePath, content: r'''
void f() {
  ![0].isEmpty;
}
''');

    // We don't have any lints configured, so no errors.
    await resolveTestFile();
    assertErrorsInResult([]);

    // The summary for the library was linked.
    _assertContainsLinkedCycle({testFilePath}, andClear: true);

    // We will recreate it with new analysis options.
    // But we will reuse the byte store, so can reuse summaries.
    disposeAnalysisContextCollection();

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

  void _assertContainsLinkedCycle(Set<String> expectedPosix,
      {bool andClear = false}) {
    var expected = expectedPosix.map(convertPath).toSet();
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
    var testFilePathConverted = convertPath(testFilePath);
    var errorsResult = await contextFor(testFilePathConverted)
        .currentSession
        .getErrors(testFilePathConverted) as ErrorsResult;
    return errorsResult.errors;
  }
}
