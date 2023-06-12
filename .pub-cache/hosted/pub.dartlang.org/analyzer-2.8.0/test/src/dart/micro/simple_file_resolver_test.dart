// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/dart/micro/cider_byte_store.dart';
import 'package:analyzer/src/dart/micro/library_graph.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/dart/micro/utils.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'file_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileResolver_changeFile_Test);
    defineReflectiveTests(FileResolverTest);
  });
}

@reflectiveTest
class FileResolver_changeFile_Test extends FileResolutionTest {
  late final String aPath;
  late final String bPath;
  late final String cPath;

  @override
  void setUp() {
    super.setUp();
    aPath = convertPath('/workspace/dart/test/lib/a.dart');
    bPath = convertPath('/workspace/dart/test/lib/b.dart');
    cPath = convertPath('/workspace/dart/test/lib/c.dart');
  }

  test_changeFile_refreshedFiles() async {
    newFile(aPath, content: r'''
class A {}
''');

    newFile(bPath, content: r'''
class B {}
''');

    newFile(cPath, content: r'''
import 'a.dart';
import 'b.dart';
''');

    // First time we refresh everything.
    await resolveFile(cPath);
    _assertRefreshedFiles([aPath, bPath, cPath], withSdk: true);

    // Without changes we refresh nothing.
    await resolveFile(cPath);
    _assertRefreshedFiles([]);

    // We already know a.dart, refresh nothing.
    await resolveFile(aPath);
    _assertRefreshedFiles([]);

    // Change a.dart, refresh a.dart and c.dart, but not b.dart
    fileResolver.changeFile(aPath);
    await resolveFile(cPath);
    _assertRefreshedFiles([aPath, cPath]);
  }

  test_changeFile_resolution() async {
    newFile(aPath, content: r'''
class A {}
''');

    newFile(bPath, content: r'''
import 'a.dart';
A a;
B b;
''');

    result = await resolveFile(bPath);
    assertErrorsInResolvedUnit(result, [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 22, 1),
    ]);

    newFile(aPath, content: r'''
class A {}
class B {}
''');
    fileResolver.changeFile(aPath);

    result = await resolveFile(bPath);
    assertErrorsInResolvedUnit(result, []);
  }

  test_changeFile_resolution_flushInheritanceManager() async {
    newFile(aPath, content: r'''
class A {
  final int foo = 0;
}
''');

    newFile(bPath, content: r'''
import 'a.dart';

void f(A a) {
  a.foo = 1;
}
''');

    result = await resolveFile(bPath);
    assertErrorsInResolvedUnit(result, [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 36, 3),
    ]);

    newFile(aPath, content: r'''
class A {
  int foo = 0;
}
''');
    fileResolver.changeFile(aPath);

    result = await resolveFile(bPath);
    assertErrorsInResolvedUnit(result, []);
  }

  test_changeFile_resolution_missingChangeFileForPart() async {
    newFile(aPath, content: r'''
part 'b.dart';

var b = B(0);
''');

    result = await resolveFile(aPath);
    assertErrorsInResolvedUnit(result, [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 5, 8),
      error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 24, 1),
    ]);

    // Update a.dart, and notify the resolver. We need this to have at least
    // one change, so that we decided to rebuild the library summary.
    newFile(aPath, content: r'''
part 'b.dart';

var b = B(1);
''');
    fileResolver.changeFile(aPath);

    // Update b.dart, but do not notify the resolver.
    // If we try to read it now, it will throw.
    newFile(bPath, content: r'''
part of 'a.dart';

class B {
  B(int _);
}
''');

    expect(() async {
      await resolveFile(aPath);
    }, throwsStateError);

    // Notify the resolver about b.dart, it is OK now.
    fileResolver.changeFile(bPath);
    result = await resolveFile(aPath);
    assertErrorsInResolvedUnit(result, []);
  }

  test_changePartFile_refreshedFiles() async {
    newFile(aPath, content: r'''
part 'b.dart';

class A {}
''');

    newFile(bPath, content: r'''
part of 'a.dart';

class B extends A {}
''');

    newFile(cPath, content: r'''
import 'a.dart';
''');

    // First time we refresh everything.
    await resolveFile(bPath);
    _assertRefreshedFiles([aPath, bPath], withSdk: true);
    // Change b.dart, refresh a.dart
    fileResolver.changeFile(bPath);
    await resolveFile(bPath);
    _assertRefreshedFiles([aPath, bPath]);
    // now with c.dart
    await resolveFile(cPath);
    _assertRefreshedFiles([cPath]);
    fileResolver.changeFile(bPath);
    await resolveFile(cPath);
    _assertRefreshedFiles([aPath, bPath, cPath]);
  }

  void _assertRefreshedFiles(List<String> expected, {bool withSdk = false}) {
    var expectedPlusSdk = expected.toSet();

    if (withSdk) {
      expectedPlusSdk
        ..add(convertPath('/sdk/lib/_internal/internal.dart'))
        ..add(convertPath('/sdk/lib/async/async.dart'))
        ..add(convertPath('/sdk/lib/async/stream.dart'))
        ..add(convertPath('/sdk/lib/core/core.dart'))
        ..add(convertPath('/sdk/lib/math/math.dart'));
    }

    var refreshedFiles = fileResolver.fsState!.testView.refreshedFiles;
    expect(refreshedFiles, unorderedEquals(expectedPlusSdk));

    refreshedFiles.clear();
  }
}

@reflectiveTest
class FileResolverTest extends FileResolutionTest {
  @override
  bool typeToStringWithNullability = false;

  test_analysisOptions_default_fromPackageUri() async {
    newFile('/workspace/dart/analysis_options/lib/default.yaml', content: r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    await assertErrorsInCode(r'''
num a = 0;
int b = a;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_analysisOptions_file_inPackage() async {
    newAnalysisOptionsYamlFile('/workspace/dart/test', content: r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    await assertErrorsInCode(r'''
num a = 0;
int b = a;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_analysisOptions_file_inThirdParty() async {
    newFile('/workspace/dart/analysis_options/lib/third_party.yaml',
        content: r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    newAnalysisOptionsYamlFile('/workspace/third_party/dart/aaa', content: r'''
analyzer:
  strong-mode:
    implicit-casts: true
''');

    var aPath = convertPath('/workspace/third_party/dart/aaa/lib/a.dart');
    await assertErrorsInFile(aPath, r'''
num a = 0;
int b = a;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_analysisOptions_file_inThirdPartyDartLang() async {
    newFile('/workspace/dart/analysis_options/lib/third_party.yaml',
        content: r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    newAnalysisOptionsYamlFile('/workspace/third_party/dart_lang/aaa',
        content: r'''
analyzer:
  strong-mode:
    implicit-casts: true
''');

    var aPath = convertPath('/workspace/third_party/dart_lang/aaa/lib/a.dart');
    await assertErrorsInFile(aPath, r'''
num a = 0;
int b = a;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_analysisOptions_lints() async {
    newFile('/workspace/dart/analysis_options/lib/default.yaml', content: r'''
linter:
  rules:
    - omit_local_variable_types
''');

    var rule = Registry.ruleRegistry.getRule('omit_local_variable_types')!;

    await assertErrorsInCode(r'''
main() {
  int a = 0;
  a;
}
''', [
      error(rule.lintCode, 11, 9),
    ]);
  }

  test_analysisOptions_no() async {
    await assertNoErrorsInCode(r'''
num a = 0;
int b = a;
''');
  }

  test_basic() async {
    await assertNoErrorsInCode(r'''
int a = 0;
var b = 1 + 2;
''');
    assertType(findElement.topVar('a').type, 'int');
    assertElement(findNode.simple('int a'), intElement);

    assertType(findElement.topVar('b').type, 'int');
  }

  test_collectSharedDataIdentifiers() async {
    var aPath = convertPath('/workspace/third_party/dart/aaa/lib/a.dart');

    newFile(aPath, content: r'''
class A {}
''');

    await resolveFile(aPath);
    fileResolver.collectSharedDataIdentifiers();
    expect(fileResolver.removedCacheIds.length,
        (fileResolver.byteStore as CiderCachedByteStore).testView!.length);
  }

  test_elements_export_dartCoreDynamic() async {
    var a_path = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(a_path, content: r'''
export 'dart:core' show dynamic;
''');

    // Analyze so that `dart:core` is linked.
    var a_result = await resolveFile(a_path);

    // Touch `dart:core` so that its element model is discarded.
    var dartCorePath = a_result.session.uriConverter.uriToPath(
      Uri.parse('dart:core'),
    )!;
    fileResolver.changeFile(dartCorePath);

    // Analyze, this will read the element model for `dart:core`.
    // There was a bug that `root::dart:core::dynamic` had no element set.
    await assertNoErrorsInCode(r'''
import 'a.dart' as p;
p.dynamic f() {}
''');
  }

  test_findReferences_class() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, content: r'''
class A {
  int foo;
}
''');

    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, content: r'''
import 'a.dart';

void func() {
  var a = A();
  print(a.foo);
}
''');

    await resolveFile(bPath);
    var result = fileResolver.findReferences(_findElement(6, aPath));
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath, [CharacterLocation(4, 11)]),
      CiderSearchMatch(aPath, [CharacterLocation(1, 7)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_field() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, content: r'''
class A {
  int foo = 0;

  void func(int bar) {
    foo = bar;
 }
}
''');

    await resolveFile(aPath);
    var result = fileResolver.findReferences(_findElement(16, aPath));
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(
          aPath, [CharacterLocation(2, 7), CharacterLocation(5, 5)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_function() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, content: r'''
main() {
  foo('Hello');
}

foo(String str) {}
''');

    await resolveFile(aPath);
    var result = fileResolver.findReferences(_findElement(11, aPath));
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(
          aPath, [CharacterLocation(2, 3), CharacterLocation(5, 1)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_getter() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, content: r'''
class A {
  int get foo => 6;
}
''');
    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, content: r'''
import 'a.dart';

main() {
  var a = A();
  var bar = a.foo;
}
''');

    await resolveFile(bPath);
    var result = fileResolver.findReferences(_findElement(20, aPath));
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath, [CharacterLocation(5, 15)]),
      CiderSearchMatch(aPath, [CharacterLocation(2, 11)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_local_variable() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, content: r'''
class A {
  void func(int n) {
    var foo = bar+1;
    print(foo);
 }
}
''');
    await resolveFile(aPath);
    var result = fileResolver.findReferences(_findElement(39, aPath));
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(
          aPath, [CharacterLocation(3, 9), CharacterLocation(4, 11)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_method() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, content: r'''
class A {
  void func() {
   print('hello');
 }

 void func2() {
   func();
 }
}
''');

    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, content: r'''
import 'a.dart';

main() {
  var a = A();
  a.func();
}
''');

    await resolveFile(bPath);
    var result = fileResolver.findReferences(_findElement(17, aPath));
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath, [CharacterLocation(5, 5)]),
      CiderSearchMatch(
          aPath, [CharacterLocation(2, 8), CharacterLocation(7, 4)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_setter() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, content: r'''
class A {
  void set value(int m){ };
}
''');
    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, content: r'''
import 'a.dart';

main() {
  var a = A();
  a.value = 6;
}
''');

    await resolveFile(bPath);
    var result = fileResolver.findReferences(_findElement(21, aPath));
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath, [CharacterLocation(5, 5)]),
      CiderSearchMatch(aPath, [CharacterLocation(2, 12)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_top_level_getter() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');

    newFile(aPath, content: r'''
int _foo;

int get foo => _foo;
''');

    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, content: r'''
import 'a.dart';

main() {
  var bar = foo;
}
''');

    await resolveFile(bPath);
    var result = fileResolver.findReferences(_findElement(19, aPath));
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath, [CharacterLocation(4, 13)]),
      CiderSearchMatch(aPath, [CharacterLocation(3, 9)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_top_level_setter() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');

    newFile(aPath, content: r'''
int _foo;

void set foo(int bar) { _foo = bar; }
''');

    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, content: r'''
import 'a.dart';

main() {
  foo = 6;
}
''');

    await resolveFile(bPath);
    var result = fileResolver.findReferences(_findElement(20, aPath));
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath, [CharacterLocation(4, 3)]),
      CiderSearchMatch(aPath, [CharacterLocation(3, 10)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_top_level_variable() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');

    newFile(aPath, content: r'''
const int C = 42;

void func() {
    print(C);
}
''');

    await resolveFile(aPath);
    var result = fileResolver.findReferences(_findElement(10, aPath));
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(
          aPath, [CharacterLocation(1, 11), CharacterLocation(4, 11)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_type_parameter() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, content: r'''
class Foo<T> {
  List<T> l;

  void bar(T t) {}
}
''');
    await resolveFile(aPath);
    var result = fileResolver.findReferences(_findElement(10, aPath));
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(aPath, [
        CharacterLocation(1, 11),
        CharacterLocation(2, 8),
        CharacterLocation(4, 12)
      ])
    ];
    expect(result.map((e) => e.path),
        unorderedEquals(expected.map((e) => e.path)));
    expect(result.map((e) => e.startPositions),
        unorderedEquals(expected.map((e) => e.startPositions)));
  }

  test_findReferences_typedef() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, content: r'''
typedef func = int Function(int);

''');
    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, content: r'''
import 'a.dart';

void f(func o) {}
''');

    await resolveFile(bPath);
    var result = fileResolver.findReferences(_findElement(8, aPath));
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath, [CharacterLocation(3, 8)]),
      CiderSearchMatch(aPath, [CharacterLocation(1, 9)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_getErrors() {
    addTestFile(r'''
var a = b;
var foo = 0;
''');

    var result = getTestErrors();
    expect(result.path, convertPath('/workspace/dart/test/lib/test.dart'));
    expect(result.uri.toString(), 'package:dart.test/test.dart');
    assertErrorsInList(result.errors, [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 8, 1),
    ]);
    expect(result.lineInfo.lineStarts, [0, 11, 24]);
  }

  test_getErrors_reuse() {
    addTestFile('var a = b;');

    var path = convertPath('/workspace/dart/test/lib/test.dart');

    // No resolved files yet.
    expect(fileResolver.testView!.resolvedLibraries, isEmpty);

    // No cached, will resolve once.
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView!.resolvedLibraries, [path]);

    // Has cached, will be not resolved again.
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView!.resolvedLibraries, [path]);

    // New resolver.
    // Still has cached, will be not resolved.
    createFileResolver();
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView!.resolvedLibraries, <Object>[]);

    // Change the file, new resolver.
    // With changed file the previously cached result cannot be used.
    addTestFile('var a = c;');
    createFileResolver();
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView!.resolvedLibraries, [path]);

    // New resolver.
    // Still has cached, will be not resolved.
    createFileResolver();
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView!.resolvedLibraries, <Object>[]);
  }

  test_getErrors_reuse_changeDependency() {
    newFile('/workspace/dart/test/lib/a.dart', content: r'''
var a = 0;
''');

    addTestFile(r'''
import 'a.dart';
var b = a.foo;
''');

    var path = convertPath('/workspace/dart/test/lib/test.dart');

    // No resolved files yet.
    expect(fileResolver.testView!.resolvedLibraries, isEmpty);

    // No cached, will resolve once.
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView!.resolvedLibraries, [path]);

    // Has cached, will be not resolved again.
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView!.resolvedLibraries, [path]);

    // Change the dependency, new resolver.
    // The signature of the result is different.
    // The previously cached result cannot be used.
    newFile('/workspace/dart/test/lib/a.dart', content: r'''
var a = 4.2;
''');
    createFileResolver();
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView!.resolvedLibraries, [path]);

    // New resolver.
    // Still has cached, will be not resolved.
    createFileResolver();
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView!.resolvedLibraries, <Object>[]);
  }

  test_getFilesWithTopLevelDeclarations_cached() async {
    await assertNoErrorsInCode(r'''
int a = 0;
var b = 1 + 2;
''');

    void assertHasOneVariable() {
      var files = fileResolver.getFilesWithTopLevelDeclarations('a');
      expect(files, hasLength(1));
      var file = files.single;
      expect(file.file.path, result.path);
      expect(file.kind, FileTopLevelDeclarationKind.variable);
    }

    // Ask to check that it works when parsed.
    assertHasOneVariable();

    // Create a new resolved, but reuse the cache.
    createFileResolver();

    await resolveTestFile();

    // Ask again, when unlinked information is read from the cache.
    assertHasOneVariable();
  }

  test_getLibraryByUri() {
    newFile('/workspace/dart/my/lib/a.dart', content: r'''
class A {}
''');

    var element = fileResolver.getLibraryByUri(
      uriStr: 'package:dart.my/a.dart',
    );
    expect(element.definingCompilationUnit.classes, hasLength(1));
  }

  test_getLibraryByUri_notExistingFile() {
    var element = fileResolver.getLibraryByUri(
      uriStr: 'package:dart.my/a.dart',
    );
    expect(element.definingCompilationUnit.classes, isEmpty);
  }

  test_getLibraryByUri_partOf() {
    newFile('/workspace/dart/my/lib/a.dart', content: r'''
part of 'b.dart';
''');

    expect(() {
      fileResolver.getLibraryByUri(
        uriStr: 'package:dart.my/a.dart',
      );
    }, throwsArgumentError);
  }

  test_getLibraryByUri_unresolvedUri() {
    expect(() {
      fileResolver.getLibraryByUri(uriStr: 'my:unresolved');
    }, throwsArgumentError);
  }

  test_hint() async {
    await assertErrorsInCode(r'''
import 'dart:math';
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
    ]);
  }

  test_hint_in_third_party() async {
    var aPath = convertPath('/workspace/third_party/dart/aaa/lib/a.dart');
    newFile(aPath, content: r'''
import 'dart:math';
''');
    await resolveFile(aPath);
    assertNoErrorsInResult();
  }

  test_linkLibraries_getErrors() {
    addTestFile(r'''
var a = b;
var foo = 0;
''');

    var path = convertPath('/workspace/dart/test/lib/test.dart');
    fileResolver.linkLibraries(path: path);

    var result = getTestErrors();
    expect(result.path, path);
    expect(result.uri.toString(), 'package:dart.test/test.dart');
    assertErrorsInList(result.errors, [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 8, 1),
    ]);
    expect(result.lineInfo.lineStarts, [0, 11, 24]);
  }

  test_nameOffset_class_method_fromBytes() async {
    newFile('/workspace/dart/test/lib/a.dart', content: r'''
class A {
  void foo() {}
}
''');

    addTestFile(r'''
import 'a.dart';

void f(A a) {
  a.foo();
}
''');

    await resolveTestFile();
    {
      var element = findNode.simple('foo();').staticElement!;
      expect(element.nameOffset, 17);
    }

    // New resolver.
    // Element models will be loaded from the cache.
    createFileResolver();
    await resolveTestFile();
    {
      var element = findNode.simple('foo();').staticElement!;
      expect(element.nameOffset, 17);
    }
  }

  test_nameOffset_unit_variable_fromBytes() async {
    newFile('/workspace/dart/test/lib/a.dart', content: r'''
var a = 0;
''');

    addTestFile(r'''
import 'a.dart';
var b = a;
''');

    await resolveTestFile();
    {
      var element = findNode.simple('a;').staticElement!;
      expect(element.nonSynthetic.nameOffset, 4);
    }

    // New resolver.
    // Element models will be loaded from the cache.
    createFileResolver();
    await resolveTestFile();
    {
      var element = findNode.simple('a;').staticElement!;
      expect(element.nonSynthetic.nameOffset, 4);
    }
  }

  test_nullSafety_enabled() async {
    typeToStringWithNullability = true;

    newFile('/workspace/dart/test/BUILD', content: r'''
dart_package(
  null_safety = True,
)
''');

    await assertNoErrorsInCode(r'''
void f(int? a) {
  if (a != null) {
    a.isEven;
  }
}
''');

    assertType(
      findElement.parameter('a').type,
      'int?',
    );
  }

  test_nullSafety_notEnabled() async {
    typeToStringWithNullability = true;

    await assertErrorsInCode(r'''
void f(int? a) {}
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 10, 1),
    ]);

    assertType(
      findElement.parameter('a').type,
      'int*',
    );
  }

  test_part_notInLibrary_libraryDoesNotExist() async {
    // TODO(scheglov) Should report CompileTimeErrorCode.URI_DOES_NOT_EXIST
    await assertNoErrorsInCode(r'''
part of 'a.dart';
''');
  }

  test_removeFilesNotNecessaryForAnalysisOf() async {
    var aPath = convertPath('/workspace/dart/aaa/lib/a.dart');
    var bPath = convertPath('/workspace/dart/aaa/lib/b.dart');
    var cPath = convertPath('/workspace/dart/aaa/lib/c.dart');

    newFile(aPath, content: r'''
class A {}
''');

    newFile(bPath, content: r'''
import 'a.dart';
''');

    newFile(cPath, content: r'''
import 'a.dart';
''');

    await resolveFile(bPath);
    await resolveFile(cPath);
    fileResolver.removeFilesNotNecessaryForAnalysisOf([cPath]);
    _assertRemovedPaths(unorderedEquals([bPath]));
  }

  test_removeFilesNotNecessaryForAnalysisOf_multiple() async {
    var bPath = convertPath('/workspace/dart/aaa/lib/b.dart');
    var dPath = convertPath('/workspace/dart/aaa/lib/d.dart');
    var ePath = convertPath('/workspace/dart/aaa/lib/e.dart');
    var fPath = convertPath('/workspace/dart/aaa/lib/f.dart');

    newFile('/workspace/dart/aaa/lib/a.dart', content: r'''
class A {}
''');

    newFile(bPath, content: r'''
class B {}
''');

    newFile('/workspace/dart/aaa/lib/c.dart', content: r'''
class C {}
''');

    newFile(dPath, content: r'''
import 'a.dart';
''');

    newFile(ePath, content: r'''
import 'a.dart';
import 'b.dart';
''');

    newFile(fPath, content: r'''
import 'c.dart';
 ''');

    await resolveFile(dPath);
    await resolveFile(ePath);
    await resolveFile(fPath);
    fileResolver.removeFilesNotNecessaryForAnalysisOf([dPath, fPath]);
    _assertRemovedPaths(unorderedEquals([bPath, ePath]));
  }

  test_removeFilesNotNecessaryForAnalysisOf_unknown() async {
    var aPath = convertPath('/workspace/dart/aaa/lib/a.dart');
    var bPath = convertPath('/workspace/dart/aaa/lib/b.dart');

    newFile(aPath, content: r'''
class A {}
''');

    await resolveFile(aPath);

    fileResolver.removeFilesNotNecessaryForAnalysisOf([aPath, bPath]);
    _assertRemovedPaths(isEmpty);
  }

  test_resolve_libraryWithPart_noLibraryDiscovery() async {
    var partPath = '/workspace/dart/test/lib/a.dart';
    newFile(partPath, content: r'''
part of 'test.dart';

class A {}
''');

    await assertNoErrorsInCode(r'''
part 'a.dart';

void f(A a) {}
''');

    // We started resolution from the library, and then followed to the part.
    // So, the part knows its library, there is no need to discover it.
    _assertDiscoveredLibraryForParts([]);
  }

  test_resolve_part_of_name() async {
    newFile('/workspace/dart/test/lib/a.dart', content: r'''
library my.lib;

part 'test.dart';

class A {
  int m;
}
''');

    await assertNoErrorsInCode(r'''
part of my.lib;

void func() {
  var a = A();
  print(a.m);
}
''');

    _assertDiscoveredLibraryForParts([result.path]);
  }

  test_resolve_part_of_uri() async {
    newFile('/workspace/dart/test/lib/a.dart', content: r'''
part 'test.dart';

class A {
  int m;
}
''');

    await assertNoErrorsInCode(r'''
part of 'a.dart';

void func() {
  var a = A();
  print(a.m);
}
''');

    _assertDiscoveredLibraryForParts([result.path]);
  }

  test_resolveFile_cache() async {
    var path = convertPath('/workspace/dart/test/lib/test.dart');
    newFile(path, content: 'var a = 0;');

    // No resolved files yet.
    var testView = fileResolver.testView!;
    expect(testView.resolvedLibraries, isEmpty);

    await resolveFile2(path);
    var result1 = result;

    // The file was resolved.
    expect(testView.resolvedLibraries, [path]);

    // The result is cached.
    expect(fileResolver.cachedResults, contains(path));

    // Ask again, no changes, not resolved.
    await resolveFile2(path);
    expect(testView.resolvedLibraries, [path]);

    // The same result was returned.
    expect(result, same(result1));

    // Change a file.
    var a_path = convertPath('/workspace/dart/test/lib/a.dart');
    fileResolver.changeFile(a_path);

    // The was a change to a file, no matter which, resolve again.
    await resolveFile2(path);
    expect(testView.resolvedLibraries, [path, path]);

    // Get should get a new result.
    expect(result, isNot(same(result1)));
  }

  test_resolveFile_dontCache_whenForCompletion() async {
    var a_path = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(a_path, content: r'''
part 'b.dart';
''');

    var b_path = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(b_path, content: r'''
part of 'a.dart';
''');

    // No resolved files yet.
    var testView = fileResolver.testView!;
    expect(testView.resolvedLibraries, isEmpty);

    fileResolver.resolve(
      path: b_path,
      completionLine: 0,
      completionColumn: 0,
    );

    // The file was resolved.
    expect(testView.resolvedLibraries, [a_path]);

    // The completion location was set, so not units are resolved.
    // So, the result should not be cached.
    expect(fileResolver.cachedResults, isEmpty);
  }

  test_resolveLibrary() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, content: r'''
part 'test.dart';

class A {
  int m;
}
''');

    newFile('/workspace/dart/test/lib/test.dart', content: r'''
part of 'a.dart';

void func() {
  var a = A();
  print(a.m);
}
''');

    var result = fileResolver.resolveLibrary(path: aPath);
    expect(result.units.length, 2);
    expect(result.units[0].path, aPath);
    expect(result.units[0].uri, Uri.parse('package:dart.test/a.dart'));
  }

  test_reuse_compatibleOptions() async {
    newFile('/workspace/dart/aaa/BUILD', content: '');
    newFile('/workspace/dart/bbb/BUILD', content: '');

    var aPath = '/workspace/dart/aaa/lib/a.dart';
    var aResult = await assertErrorsInFile(aPath, r'''
num a = 0;
int b = a;
''', []);

    var bPath = '/workspace/dart/bbb/lib/a.dart';
    var bResult = await assertErrorsInFile(bPath, r'''
num a = 0;
int b = a;
''', []);

    // Both files use the same (default) analysis options.
    // So, when we resolve 'bbb', we can reuse the context after 'aaa'.
    expect(
      aResult.libraryElement.context,
      same(bResult.libraryElement.context),
    );
  }

  test_reuse_incompatibleOptions_implicitCasts() async {
    newFile('/workspace/dart/aaa/BUILD', content: '');
    newAnalysisOptionsYamlFile('/workspace/dart/aaa', content: r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    newFile('/workspace/dart/bbb/BUILD', content: '');
    newAnalysisOptionsYamlFile('/workspace/dart/bbb', content: r'''
analyzer:
  strong-mode:
    implicit-casts: true
''');

    // Implicit casts are disabled in 'aaa'.
    var aPath = '/workspace/dart/aaa/lib/a.dart';
    await assertErrorsInFile(aPath, r'''
num a = 0;
int b = a;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 1),
    ]);

    // Implicit casts are enabled in 'bbb'.
    var bPath = '/workspace/dart/bbb/lib/a.dart';
    await assertErrorsInFile(bPath, r'''
num a = 0;
int b = a;
''', []);

    // Implicit casts are still disabled in 'aaa'.
    await assertErrorsInFile(aPath, r'''
num a = 0;
int b = a;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_switchCase_implementsEquals_enum() async {
    await assertNoErrorsInCode(r'''
enum MyEnum {a, b, c}

void f(MyEnum myEnum) {
  switch (myEnum) {
    case MyEnum.a:
      break;
    default:
      break;
  }
}
''');
  }

  test_unknown_uri() async {
    await assertErrorsInCode(r'''
import 'foo:bar';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 9),
    ]);
  }

  void _assertDiscoveredLibraryForParts(List<String> expected) {
    expect(fileResolver.fsState!.testView.partsDiscoveredLibraries, expected);
  }

  void _assertRemovedPaths(Matcher matcher) {
    expect(fileResolver.fsState!.testView.removedPaths, matcher);
  }

  Element _findElement(int offset, String filePath) {
    var resolvedUnit = fileResolver.resolve(path: filePath);
    var node = NodeLocator(offset).searchWithin(resolvedUnit.unit);
    var element = getElementOfNode(node);
    return element!;
  }
}
