// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/dart/micro/utils.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/node_text_expectations.dart';
import 'file_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileResolver_changeFiles_Test);
    defineReflectiveTests(FileResolverTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FileResolver_changeFiles_Test extends FileResolutionTest {
  test_changeFile_refreshedFiles() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
class B {}
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
import 'a.dart';
import 'b.dart';
''');

    // First time we refresh everything.
    await resolveFile(c.path);

    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_3 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /workspace/dart/test/lib/b.dart
    uri: package:dart.test/b.dart
    current
      id: file_1
      kind: library_1
        imports
          library_3 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /workspace/dart/test/lib/c.dart
    uri: package:dart.test/c.dart
    current
      id: file_2
      kind: library_2
        imports
          library_0
          library_1
          library_3 dart:core synthetic
        cycle_2
          dependencies: cycle_0 cycle_1 dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
libraryCycles
  /workspace/dart/test/lib/a.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /workspace/dart/test/lib/b.dart
    current: cycle_1
      key: k04
    get: []
    put: [k04]
  /workspace/dart/test/lib/c.dart
    current: cycle_2
      key: k05
    get: []
    put: [k05]
elementFactory
  hasElement
    package:dart.test/a.dart
    package:dart.test/b.dart
    package:dart.test/c.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08, k09, k10, k11]
''');

    // Without changes we refresh nothing.
    await resolveFile(c.path);
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_3 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /workspace/dart/test/lib/b.dart
    uri: package:dart.test/b.dart
    current
      id: file_1
      kind: library_1
        imports
          library_3 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /workspace/dart/test/lib/c.dart
    uri: package:dart.test/c.dart
    current
      id: file_2
      kind: library_2
        imports
          library_0
          library_1
          library_3 dart:core synthetic
        cycle_2
          dependencies: cycle_0 cycle_1 dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
libraryCycles
  /workspace/dart/test/lib/a.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /workspace/dart/test/lib/b.dart
    current: cycle_1
      key: k04
    get: []
    put: [k04]
  /workspace/dart/test/lib/c.dart
    current: cycle_2
      key: k05
    get: []
    put: [k05]
elementFactory
  hasElement
    package:dart.test/a.dart
    package:dart.test/b.dart
    package:dart.test/c.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08, k09, k10, k11]
''');

    // We already know a.dart, refresh nothing.
    await resolveFile(a.path);
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_3 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /workspace/dart/test/lib/b.dart
    uri: package:dart.test/b.dart
    current
      id: file_1
      kind: library_1
        imports
          library_3 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /workspace/dart/test/lib/c.dart
    uri: package:dart.test/c.dart
    current
      id: file_2
      kind: library_2
        imports
          library_0
          library_1
          library_3 dart:core synthetic
        cycle_2
          dependencies: cycle_0 cycle_1 dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
libraryCycles
  /workspace/dart/test/lib/a.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /workspace/dart/test/lib/b.dart
    current: cycle_1
      key: k04
    get: []
    put: [k04]
  /workspace/dart/test/lib/c.dart
    current: cycle_2
      key: k05
    get: []
    put: [k05]
elementFactory
  hasElement
    package:dart.test/a.dart
    package:dart.test/b.dart
    package:dart.test/c.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08, k09, k10, k11]
''');

    // Change a.dart, discard data for a.dart and c.dart, but not b.dart
    fileResolver.changeFiles([a.path]);
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    unlinkedGet: []
    unlinkedPut: [k00]
  /workspace/dart/test/lib/b.dart
    uri: package:dart.test/b.dart
    current
      id: file_1
      kind: library_1
        imports
          library_3 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /workspace/dart/test/lib/c.dart
    uri: package:dart.test/c.dart
    unlinkedGet: []
    unlinkedPut: [k02]
libraryCycles
  /workspace/dart/test/lib/a.dart
    get: []
    put: [k03]
  /workspace/dart/test/lib/b.dart
    current: cycle_1
      key: k04
    get: []
    put: [k04]
  /workspace/dart/test/lib/c.dart
    get: []
    put: [k05]
elementFactory
  hasElement
    package:dart.test/b.dart
byteStore
  1: [k01, k04, k06, k07, k08, k09, k10, k11]
''');

    // Resolve, read again a.dart and c.dart
    await resolveFile(c.path);
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    current
      id: file_8
      kind: library_8
        imports
          library_3 dart:core synthetic
        cycle_4
          dependencies: dart:core
          libraries: library_8
          apiSignature_0
          users: cycle_5
      referencingFiles: file_9
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00, k00]
  /workspace/dart/test/lib/b.dart
    uri: package:dart.test/b.dart
    current
      id: file_1
      kind: library_1
        imports
          library_3 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
          users: cycle_5
      referencingFiles: file_9
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /workspace/dart/test/lib/c.dart
    uri: package:dart.test/c.dart
    current
      id: file_9
      kind: library_9
        imports
          library_8
          library_1
          library_3 dart:core synthetic
        cycle_5
          dependencies: cycle_1 cycle_4 dart:core
          libraries: library_9
          apiSignature_2
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02, k02]
libraryCycles
  /workspace/dart/test/lib/a.dart
    current: cycle_4
      key: k03
    get: []
    put: [k03, k03]
  /workspace/dart/test/lib/b.dart
    current: cycle_1
      key: k04
    get: []
    put: [k04]
  /workspace/dart/test/lib/c.dart
    current: cycle_5
      key: k05
    get: []
    put: [k05, k05]
elementFactory
  hasElement
    package:dart.test/a.dart
    package:dart.test/b.dart
    package:dart.test/c.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08, k09, k10, k11]
''');
  }

  test_changeFile_resolution() async {
    final a = newFile('/workspace/dart/test/lib/a.dart', r'''
class A {}
''');

    final b = newFile('/workspace/dart/test/lib/b.dart', r'''
import 'a.dart';
void f(A a, B b) {}
''');

    result = await resolveFile(b.path);
    assertErrorsInResolvedUnit(result, [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 29, 1),
    ]);

    newFile(a.path, r'''
class A {}
class B {}
''');
    fileResolver.changeFiles([a.path]);

    result = await resolveFile(b.path);
    assertErrorsInResolvedUnit(result, []);
  }

  test_changeFile_resolution_flushInheritanceManager() async {
    final a = newFile('/workspace/dart/test/lib/a.dart', r'''
class A {
  final int foo = 0;
}
''');

    final b = newFile('/workspace/dart/test/lib/b.dart', r'''
import 'a.dart';

void f(A a) {
  a.foo = 1;
}
''');

    result = await resolveFile(b.path);
    assertErrorsInResolvedUnit(result, [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 36, 3),
    ]);

    newFile(a.path, r'''
class A {
  int foo = 0;
}
''');
    fileResolver.changeFiles([a.path]);

    result = await resolveFile(b.path);
    assertErrorsInResolvedUnit(result, []);
  }

  test_changeFile_resolution_missingChangeFileForPart() async {
    final a = newFile('/workspace/dart/test/lib/a.dart', r'''
part 'b.dart';

var b = B(0);
''');

    result = await resolveFile(a.path);
    assertErrorsInResolvedUnit(result, [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 5, 8),
      error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 24, 1),
    ]);

    // Update a.dart, and notify the resolver. We need this to have at least
    // one change, so that we decided to rebuild the library summary.
    newFile(a.path, r'''
part 'b.dart';

var b = B(1);
''');
    fileResolver.changeFiles([a.path]);

    // Update b.dart, but do not notify the resolver.
    // If we try to read it now, it will throw.
    final b = newFile('/workspace/dart/test/lib/b.dart', r'''
part of 'a.dart';

class B {
  B(int _);
}
''');

    try {
      await resolveFile(a.path);
      fail('Expected StateError');
    } on StateError {
      // OK
    }

    // Notify the resolver about b.dart, it is OK now.
    fileResolver.changeFiles([b.path]);
    result = await resolveFile(a.path);
    assertErrorsInResolvedUnit(result, []);
  }

  test_changePartFile_refreshedFiles() async {
    newFile('/workspace/dart/test/lib/a.dart', r'''
part 'b.dart';

class A {}
''');

    final b = newFile('/workspace/dart/test/lib/b.dart', r'''
part of 'a.dart';

class B extends A {}
''');

    // First time we refresh everything.
    await resolveFile(b.path);
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /workspace/dart/test/lib/b.dart
    uri: package:dart.test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
libraryCycles
  /workspace/dart/test/lib/a.dart
    current: cycle_0
      key: k02
    get: []
    put: [k02]
elementFactory
  hasElement
    package:dart.test/a.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08]
''');

    // Change b.dart, discard both b.dart and a.dart
    fileResolver.changeFiles([b.path]);
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    unlinkedGet: []
    unlinkedPut: [k00]
  /workspace/dart/test/lib/b.dart
    uri: package:dart.test/b.dart
    unlinkedGet: []
    unlinkedPut: [k01]
libraryCycles
  /workspace/dart/test/lib/a.dart
    get: []
    put: [k02]
elementFactory
byteStore
  1: [k03, k04, k05, k06, k07, k08]
''');

    // Resolve, read a.dart and b.dart
    await resolveFile(b.path);
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    current
      id: file_7
      kind: library_7
        imports
          library_2 dart:core synthetic
        parts
          partOfUriKnown_8
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_0
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00, k00]
  /workspace/dart/test/lib/b.dart
    uri: package:dart.test/b.dart
    current
      id: file_8
      kind: partOfUriKnown_8
        library: library_7
      referencingFiles: file_7
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01, k01]
libraryCycles
  /workspace/dart/test/lib/a.dart
    current: cycle_2
      key: k02
    get: []
    put: [k02, k02]
elementFactory
  hasElement
    package:dart.test/a.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08]
''');
  }

  test_changePartFile_refreshedFiles_transitive() async {
    newFile('/workspace/dart/test/lib/a.dart', r'''
part 'b.dart';

class A {}
''');

    final b = newFile('/workspace/dart/test/lib/b.dart', r'''
part of 'a.dart';

class B extends A {}
''');

    final c = newFile('/workspace/dart/test/lib/c.dart', r'''
import 'a.dart';
''');

    await resolveFile(c.path);
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_3 dart:core synthetic
        parts
          partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_2
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /workspace/dart/test/lib/b.dart
    uri: package:dart.test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /workspace/dart/test/lib/c.dart
    uri: package:dart.test/c.dart
    current
      id: file_2
      kind: library_2
        imports
          library_0
          library_3 dart:core synthetic
        cycle_1
          dependencies: cycle_0 dart:core
          libraries: library_2
          apiSignature_1
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
libraryCycles
  /workspace/dart/test/lib/a.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /workspace/dart/test/lib/c.dart
    current: cycle_1
      key: k04
    get: []
    put: [k04]
elementFactory
  hasElement
    package:dart.test/a.dart
    package:dart.test/c.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08, k09, k10]
''');

    // Should invalidate a.dart, b.dart, c.dart
    fileResolver.changeFiles([b.path]);
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    unlinkedGet: []
    unlinkedPut: [k00]
  /workspace/dart/test/lib/b.dart
    uri: package:dart.test/b.dart
    unlinkedGet: []
    unlinkedPut: [k01]
  /workspace/dart/test/lib/c.dart
    uri: package:dart.test/c.dart
    unlinkedGet: []
    unlinkedPut: [k02]
libraryCycles
  /workspace/dart/test/lib/a.dart
    get: []
    put: [k03]
  /workspace/dart/test/lib/c.dart
    get: []
    put: [k04]
elementFactory
byteStore
  1: [k05, k06, k07, k08, k09, k10]
''');

    // Read again a.dart, b.dart, c.dart
    await resolveFile(c.path);
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    current
      id: file_8
      kind: library_8
        imports
          library_3 dart:core synthetic
        parts
          partOfUriKnown_9
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_0
          users: cycle_4
      referencingFiles: file_10
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00, k00]
  /workspace/dart/test/lib/b.dart
    uri: package:dart.test/b.dart
    current
      id: file_9
      kind: partOfUriKnown_9
        library: library_8
      referencingFiles: file_8
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01, k01]
  /workspace/dart/test/lib/c.dart
    uri: package:dart.test/c.dart
    current
      id: file_10
      kind: library_10
        imports
          library_8
          library_3 dart:core synthetic
        cycle_4
          dependencies: cycle_3 dart:core
          libraries: library_10
          apiSignature_1
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02, k02]
libraryCycles
  /workspace/dart/test/lib/a.dart
    current: cycle_3
      key: k03
    get: []
    put: [k03, k03]
  /workspace/dart/test/lib/c.dart
    current: cycle_4
      key: k04
    get: []
    put: [k04, k04]
elementFactory
  hasElement
    package:dart.test/a.dart
    package:dart.test/c.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08, k09, k10]
''');
  }
}

@reflectiveTest
class FileResolverTest extends FileResolutionTest {
  @override
  bool get isNullSafetyEnabled => true;

  test_analysisOptions_default_fromPackageUri() async {
    newFile('/workspace/dart/analysis_options/lib/default.yaml', r'''
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
    newAnalysisOptionsYamlFile('/workspace/dart/test', r'''
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
    newFile('/workspace/dart/analysis_options/lib/third_party.yaml', r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    newAnalysisOptionsYamlFile('/workspace/third_party/dart/aaa', r'''
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
    newFile('/workspace/dart/analysis_options/lib/third_party.yaml', r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    newAnalysisOptionsYamlFile('/workspace/third_party/dart_lang/aaa', r'''
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
    newFile('/workspace/dart/analysis_options/lib/default.yaml', r'''
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

  test_basic() async {
    await assertNoErrorsInCode(r'''
int a = 0;
var b = 1 + 2;
''');
    assertType(findElement.topVar('a').type, 'int');
    assertElement(findNode.simple('int a'), intElement);

    assertType(findElement.topVar('b').type, 'int');
  }

  test_dispose() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    // After resolution the byte store contains unlinked data for files,
    // and linked data for loaded bundles.
    await resolveFile(a.path);
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
libraryCycles
  /workspace/dart/test/lib/a.dart
    current: cycle_0
      key: k01
    get: []
    put: [k01]
elementFactory
  hasElement
    package:dart.test/a.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07]
''');

    fileResolver.dispose();

    // After dispose() we don't have any loaded libraries or files.
    // The byte store is empty - no unlinked or linked data.
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    unlinkedGet: []
    unlinkedPut: [k00]
libraryCycles
  /workspace/dart/test/lib/a.dart
    get: []
    put: [k01]
elementFactory
byteStore
''');
  }

  test_elements_export_dartCoreDynamic() async {
    var a_path = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(a_path, r'''
export 'dart:core' show dynamic;
''');

    // Analyze so that `dart:core` is linked.
    var a_result = await resolveFile(a_path);

    // Touch `dart:core` so that its element model is discarded.
    var dartCorePath = a_result.session.uriConverter.uriToPath(
      Uri.parse('dart:core'),
    )!;
    fileResolver.changeFiles([dartCorePath]);

    // Analyze, this will read the element model for `dart:core`.
    // There was a bug that `root::dart:core::dynamic` had no element set.
    await assertNoErrorsInCode(r'''
import 'a.dart' as p;
p.dynamic f() {}
''');
  }

  test_errors_hasNullSuffix() {
    assertErrorsInCode(r'''
String f(Map<int, String> a) {
  return a[0];
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 40, 4,
          messageContains: ["'String'", 'String?']),
    ]);
  }

  test_findReferences_class() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
class A {
  int foo;
}
''');

    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, r'''
import 'a.dart';

void func() {
  var a = A();
  print(a.foo);
}
''');

    await resolveFile(bPath);
    var element = await _findElement(6, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath,
          [CiderSearchInfo(CharacterLocation(4, 11), 1, MatchKind.REFERENCE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_field() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
class A {
  int foo = 0;

  void func(int bar) {
    foo = bar;
 }
}
''');

    await resolveFile(aPath);
    var element = await _findElement(16, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(
          aPath, [CiderSearchInfo(CharacterLocation(5, 5), 3, MatchKind.WRITE)])
    ];
    expect(result, expected);
  }

  test_findReferences_function() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
main() {
  foo('Hello');
}

foo(String str) {}
''');

    await resolveFile(aPath);
    var element = await _findElement(11, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(aPath,
          [CiderSearchInfo(CharacterLocation(2, 3), 3, MatchKind.REFERENCE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_getter() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
class A {
  int get foo => 6;
}
''');
    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, r'''
import 'a.dart';

main() {
  var a = A();
  var bar = a.foo;
}
''');

    await resolveFile(bPath);
    var element = await _findElement(20, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath,
          [CiderSearchInfo(CharacterLocation(5, 15), 3, MatchKind.REFERENCE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_local_variable() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
class A {
  void func(int n) {
    var foo = bar+1;
    print(foo);
 }
}
''');
    await resolveFile(aPath);
    var element = await _findElement(39, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(aPath,
          [CiderSearchInfo(CharacterLocation(4, 11), 3, MatchKind.REFERENCE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_method() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
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
    newFile(bPath, r'''
import 'a.dart';

main() {
  var a = A();
  a.func();
}
''');

    await resolveFile(bPath);
    var element = await _findElement(17, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath,
          [CiderSearchInfo(CharacterLocation(5, 5), 4, MatchKind.REFERENCE)]),
      CiderSearchMatch(aPath,
          [CiderSearchInfo(CharacterLocation(7, 4), 4, MatchKind.REFERENCE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_setter() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
class A {
  void set value(int m){ };
}
''');
    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, r'''
import 'a.dart';

main() {
  var a = A();
  a.value = 6;
}
''');

    await resolveFile(bPath);
    var element = await _findElement(21, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(
          bPath, [CiderSearchInfo(CharacterLocation(5, 5), 5, MatchKind.WRITE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_top_level_getter() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');

    newFile(aPath, r'''
int _foo;

int get foo => _foo;
''');

    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, r'''
import 'a.dart';

main() {
  var bar = foo;
}
''');

    await resolveFile(bPath);
    var element = await _findElement(19, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath,
          [CiderSearchInfo(CharacterLocation(4, 13), 3, MatchKind.REFERENCE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_top_level_setter() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');

    newFile(aPath, r'''
int _foo;

void set foo(int bar) { _foo = bar; }
''');

    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, r'''
import 'a.dart';

main() {
  foo = 6;
}
''');

    await resolveFile(bPath);
    var element = await _findElement(20, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath,
          [CiderSearchInfo(CharacterLocation(4, 3), 3, MatchKind.WRITE)]),
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_top_level_variable() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');

    newFile(aPath, r'''
const int C = 42;

void func() {
    print(C);
}
''');

    await resolveFile(aPath);
    var element = await _findElement(10, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(
          aPath, [CiderSearchInfo(CharacterLocation(4, 11), 1, MatchKind.READ)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_type_parameter() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
class Foo<T> {
  List<T> l;

  void bar(T t) {}
}
''');
    await resolveFile(aPath);
    var element = await _findElement(10, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(aPath, [
        CiderSearchInfo(CharacterLocation(2, 8), 1, MatchKind.REFERENCE),
        CiderSearchInfo(CharacterLocation(4, 12), 1, MatchKind.REFERENCE)
      ])
    ];
    expect(result, expected);
  }

  test_findReferences_typedef() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
typedef func = int Function(int);

''');
    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, r'''
import 'a.dart';

void f(func o) {}
''');

    await resolveFile(bPath);
    var element = await _findElement(8, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath,
          [CiderSearchInfo(CharacterLocation(3, 8), 4, MatchKind.REFERENCE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_getErrors() async {
    addTestFile(r'''
var a = b;
var foo = 0;
''');

    var result = await getTestErrors();
    expect(result.path, convertPath('/workspace/dart/test/lib/test.dart'));
    expect(result.uri.toString(), 'package:dart.test/test.dart');
    assertErrorsInList(result.errors, [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 8, 1),
    ]);
    expect(result.lineInfo.lineStarts, [0, 11, 24]);
  }

  test_getErrors_reuse() async {
    newFile(testFilePath, 'var a = b;');

    // No resolved files yet.
    _assertResolvedFiles([]);

    // No cached, will resolve once.
    expect((await getTestErrors()).errors, hasLength(1));
    _assertResolvedFiles([testFile]);

    // Has cached, will be not resolved again.
    expect((await getTestErrors()).errors, hasLength(1));
    _assertResolvedFiles([]);

    // Change the file, will be resolved again.
    newFile(testFilePath, 'var a = c;');
    fileResolver.changeFiles([testFile.path]);
    expect((await getTestErrors()).errors, hasLength(1));
    _assertResolvedFiles([testFile]);
  }

  test_getErrors_reuse_changeDependency() async {
    final a = newFile('/workspace/dart/test/lib/a.dart', r'''
var a = 0;
''');

    newFile(testFilePath, r'''
import 'a.dart';
var b = a.foo;
''');

    // No resolved files yet.
    _assertResolvedFiles([]);

    // No cached, will resolve once.
    expect((await getTestErrors()).errors, hasLength(1));
    _assertResolvedFiles([testFile]);

    // Has cached, will be not resolved again.
    expect((await getTestErrors()).errors, hasLength(1));
    _assertResolvedFiles([]);

    // Change the dependency.
    // The signature of the result is different.
    // The previously cached result cannot be used.
    newFile(a.path, r'''
var a = 4.2;
''');
    fileResolver.changeFiles([a.path]);
    expect((await getTestErrors()).errors, hasLength(1));
    _assertResolvedFiles([testFile]);
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
      expect(file.path, result.path);
    }

    // Ask to check that it works when parsed.
    assertHasOneVariable();

    // Create a new resolved, but reuse the cache.
    createFileResolver();

    await resolveTestFile();

    // Ask again, when unlinked information is read from the cache.
    assertHasOneVariable();
  }

  test_getLibraryByUri() async {
    newFile('/workspace/dart/my/lib/a.dart', r'''
class A {}
''');

    var element = await fileResolver.getLibraryByUri2(
      uriStr: 'package:dart.my/a.dart',
    );
    expect(element.definingCompilationUnit.classes, hasLength(1));
  }

  test_getLibraryByUri_notExistingFile() async {
    var element = await fileResolver.getLibraryByUri2(
      uriStr: 'package:dart.my/a.dart',
    );
    expect(element.definingCompilationUnit.classes, isEmpty);
  }

  test_getLibraryByUri_partOf() async {
    newFile('/workspace/dart/my/lib/a.dart', r'''
part of 'b.dart';
''');

    expect(() async {
      await fileResolver.getLibraryByUri2(
        uriStr: 'package:dart.my/a.dart',
      );
    }, throwsArgumentError);
  }

  test_getLibraryByUri_unresolvedUri() async {
    expect(() async {
      await fileResolver.getLibraryByUri2(
        uriStr: 'my:unresolved',
      );
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
    newFile(aPath, r'''
import 'dart:math';
''');
    await resolveFile(aPath);
    assertNoErrorsInResult();
  }

  test_linkLibraries() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
final b = a;
''');

    await fileResolver.linkLibraries2(path: a.path);
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
libraryCycles
  /workspace/dart/test/lib/a.dart
    current: cycle_0
      key: k01
    get: [k01]
    put: [k01]
elementFactory
  hasReader
    package:dart.test/a.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07]
''');

    await fileResolver.getLibraryByUri2(
      uriStr: 'package:dart.test/a.dart',
    );
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
libraryCycles
  /workspace/dart/test/lib/a.dart
    current: cycle_0
      key: k01
    get: [k01]
    put: [k01]
elementFactory
  hasElement
    package:dart.test/a.dart
  hasReader
    package:dart.test/a.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07]
''');

    await fileResolver.linkLibraries2(path: b.path);

    // We discarded all libraries, so each one has `get` and `put`.
    // We did not discard files, so only `unlinkedPut`.
    // The reference count for each data is exactly `1`.
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_2
      referencingFiles: file_6
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /workspace/dart/test/lib/b.dart
    uri: package:dart.test/b.dart
    current
      id: file_6
      kind: library_6
        imports
          library_0
          library_1 dart:core synthetic
        cycle_2
          dependencies: cycle_0 dart:core
          libraries: library_6
          apiSignature_1
      unlinkedKey: k08
    unlinkedGet: []
    unlinkedPut: [k08]
libraryCycles
  /workspace/dart/test/lib/a.dart
    current: cycle_0
      key: k01
    get: [k01, k01]
    put: [k01]
  /workspace/dart/test/lib/b.dart
    current: cycle_2
      key: k09
    get: [k09]
    put: [k09]
elementFactory
  hasReader
    package:dart.test/a.dart
    package:dart.test/b.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08, k09]
''');

    final b_library = await fileResolver.getLibraryByUri2(
      uriStr: 'package:dart.test/b.dart',
    );

    // Ask types for top-level variables.
    final b_unit = b_library.definingCompilationUnit;
    for (final topLevelVariable in b_unit.topLevelVariables) {
      topLevelVariable.type;
    }

    // All types are stored in the bundle for b.dart itself, we don't need to
    // read a.dart to access them, so we keep it as a reader.
    assertStateString(r'''
files
  /workspace/dart/test/lib/a.dart
    uri: package:dart.test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_2
      referencingFiles: file_6
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /workspace/dart/test/lib/b.dart
    uri: package:dart.test/b.dart
    current
      id: file_6
      kind: library_6
        imports
          library_0
          library_1 dart:core synthetic
        cycle_2
          dependencies: cycle_0 dart:core
          libraries: library_6
          apiSignature_1
      unlinkedKey: k08
    unlinkedGet: []
    unlinkedPut: [k08]
libraryCycles
  /workspace/dart/test/lib/a.dart
    current: cycle_0
      key: k01
    get: [k01, k01]
    put: [k01]
  /workspace/dart/test/lib/b.dart
    current: cycle_2
      key: k09
    get: [k09]
    put: [k09]
elementFactory
  hasElement
    package:dart.test/b.dart
  hasReader
    package:dart.test/a.dart
    package:dart.test/b.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08, k09]
''');
  }

  test_linkLibraries_getErrors() async {
    addTestFile(r'''
var a = b;
var foo = 0;
''');

    await fileResolver.linkLibraries2(path: testFile.path);

    // We discarded all libraries, so each one has `get` and `put`.
    // We did not discard files, so only `unlinkedPut`.
    // The library for the test file has reader, but not the element yet.
    // `dart:core` and `dart` have element because of `TypeProvider`.
    // The reference count for each data is exactly `1`.
    assertStateString(r'''
files
  /workspace/dart/test/lib/test.dart
    uri: package:dart.test/test.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
libraryCycles
  /workspace/dart/test/lib/test.dart
    current: cycle_0
      key: k01
    get: [k01]
    put: [k01]
elementFactory
  hasReader
    package:dart.test/test.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07]
''');

    var result = await getTestErrors();
    expect(result.path, testFile.path);
    expect(result.uri.toString(), 'package:dart.test/test.dart');
    assertErrorsInList(result.errors, [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 8, 1),
    ]);
    expect(result.lineInfo.lineStarts, [0, 11, 24]);

    // We created the library element for the test file, using the reader.
    assertStateString(r'''
files
  /workspace/dart/test/lib/test.dart
    uri: package:dart.test/test.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
libraryCycles
  /workspace/dart/test/lib/test.dart
    current: cycle_0
      key: k01
    get: [k01]
    put: [k01]
elementFactory
  hasElement
    package:dart.test/test.dart
  hasReader
    package:dart.test/test.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07]
''');
  }

  test_nameOffset_class_method_fromBytes() async {
    newFile('/workspace/dart/test/lib/a.dart', r'''
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
    newFile('/workspace/dart/test/lib/a.dart', r'''
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
    newFile('/workspace/dart/test/BUILD', '');

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
    newFile('/workspace/dart/aaa/lib/a.dart', r'''
class A {}
''');

    final b = newFile('/workspace/dart/aaa/lib/b.dart', r'''
import 'a.dart';
class B {}
''');

    final c = newFile('/workspace/dart/aaa/lib/c.dart', r'''
import 'a.dart';
class C {}
''');

    await resolveFile(b.path);
    await resolveFile(c.path);
    assertStateString(r'''
files
  /workspace/dart/aaa/lib/a.dart
    uri: package:dart.aaa/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_3 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_1 cycle_2
      referencingFiles: file_1 file_2
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /workspace/dart/aaa/lib/b.dart
    uri: package:dart.aaa/b.dart
    current
      id: file_1
      kind: library_1
        imports
          library_0
          library_3 dart:core synthetic
        cycle_1
          dependencies: cycle_0 dart:core
          libraries: library_1
          apiSignature_1
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /workspace/dart/aaa/lib/c.dart
    uri: package:dart.aaa/c.dart
    current
      id: file_2
      kind: library_2
        imports
          library_0
          library_3 dart:core synthetic
        cycle_2
          dependencies: cycle_0 dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
libraryCycles
  /workspace/dart/aaa/lib/a.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /workspace/dart/aaa/lib/b.dart
    current: cycle_1
      key: k04
    get: []
    put: [k04]
  /workspace/dart/aaa/lib/c.dart
    current: cycle_2
      key: k05
    get: []
    put: [k05]
elementFactory
  hasElement
    package:dart.aaa/a.dart
    package:dart.aaa/b.dart
    package:dart.aaa/c.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08, k09, k10, k11]
''');

    fileResolver.removeFilesNotNecessaryForAnalysisOf([c.path]);

    // No data for b.dart anymore.
    assertStateString(r'''
files
  /workspace/dart/aaa/lib/a.dart
    uri: package:dart.aaa/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_3 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /workspace/dart/aaa/lib/b.dart
    uri: package:dart.aaa/b.dart
    unlinkedGet: []
    unlinkedPut: [k01]
  /workspace/dart/aaa/lib/c.dart
    uri: package:dart.aaa/c.dart
    current
      id: file_2
      kind: library_2
        imports
          library_0
          library_3 dart:core synthetic
        cycle_2
          dependencies: cycle_0 dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
libraryCycles
  /workspace/dart/aaa/lib/a.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /workspace/dart/aaa/lib/b.dart
    get: []
    put: [k04]
  /workspace/dart/aaa/lib/c.dart
    current: cycle_2
      key: k05
    get: []
    put: [k05]
elementFactory
  hasElement
    package:dart.aaa/a.dart
    package:dart.aaa/c.dart
byteStore
  1: [k00, k02, k03, k05, k06, k07, k08, k09, k10, k11]
''');
  }

  test_removeFilesNotNecessaryForAnalysisOf_multiple() async {
    newFile('/workspace/dart/aaa/lib/a.dart', r'''
class A {}
''');

    newFile('/workspace/dart/aaa/lib/b.dart', r'''
class B {}
''');

    newFile('/workspace/dart/aaa/lib/c.dart', r'''
class C {}
''');

    final d = newFile('/workspace/dart/aaa/lib/d.dart', r'''
import 'a.dart';
''');

    final e = newFile('/workspace/dart/aaa/lib/e.dart', r'''
import 'a.dart';
import 'b.dart';
''');

    final f = newFile('/workspace/dart/aaa/lib/f.dart', r'''
import 'c.dart';
 ''');

    await resolveFile(d.path);
    await resolveFile(e.path);
    await resolveFile(f.path);
    assertStateString(r'''
files
  /workspace/dart/aaa/lib/a.dart
    uri: package:dart.aaa/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_6 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_3 cycle_4
      referencingFiles: file_3 file_4
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /workspace/dart/aaa/lib/b.dart
    uri: package:dart.aaa/b.dart
    current
      id: file_1
      kind: library_1
        imports
          library_6 dart:core synthetic
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
          users: cycle_4
      referencingFiles: file_4
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /workspace/dart/aaa/lib/c.dart
    uri: package:dart.aaa/c.dart
    current
      id: file_2
      kind: library_2
        imports
          library_6 dart:core synthetic
        cycle_2
          dependencies: dart:core
          libraries: library_2
          apiSignature_2
          users: cycle_5
      referencingFiles: file_5
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
  /workspace/dart/aaa/lib/d.dart
    uri: package:dart.aaa/d.dart
    current
      id: file_3
      kind: library_3
        imports
          library_0
          library_6 dart:core synthetic
        cycle_3
          dependencies: cycle_0 dart:core
          libraries: library_3
          apiSignature_3
      unlinkedKey: k03
    unlinkedGet: []
    unlinkedPut: [k03]
  /workspace/dart/aaa/lib/e.dart
    uri: package:dart.aaa/e.dart
    current
      id: file_4
      kind: library_4
        imports
          library_0
          library_1
          library_6 dart:core synthetic
        cycle_4
          dependencies: cycle_0 cycle_1 dart:core
          libraries: library_4
          apiSignature_4
      unlinkedKey: k04
    unlinkedGet: []
    unlinkedPut: [k04]
  /workspace/dart/aaa/lib/f.dart
    uri: package:dart.aaa/f.dart
    current
      id: file_5
      kind: library_5
        imports
          library_2
          library_6 dart:core synthetic
        cycle_5
          dependencies: cycle_2 dart:core
          libraries: library_5
          apiSignature_5
      unlinkedKey: k05
    unlinkedGet: []
    unlinkedPut: [k05]
libraryCycles
  /workspace/dart/aaa/lib/a.dart
    current: cycle_0
      key: k06
    get: []
    put: [k06]
  /workspace/dart/aaa/lib/b.dart
    current: cycle_1
      key: k07
    get: []
    put: [k07]
  /workspace/dart/aaa/lib/c.dart
    current: cycle_2
      key: k08
    get: []
    put: [k08]
  /workspace/dart/aaa/lib/d.dart
    current: cycle_3
      key: k09
    get: []
    put: [k09]
  /workspace/dart/aaa/lib/e.dart
    current: cycle_4
      key: k10
    get: []
    put: [k10]
  /workspace/dart/aaa/lib/f.dart
    current: cycle_5
      key: k11
    get: []
    put: [k11]
elementFactory
  hasElement
    package:dart.aaa/a.dart
    package:dart.aaa/b.dart
    package:dart.aaa/c.dart
    package:dart.aaa/d.dart
    package:dart.aaa/e.dart
    package:dart.aaa/f.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08, k09, k10, k11, k12, k13, k14, k15, k16, k17]
''');

    fileResolver.removeFilesNotNecessaryForAnalysisOf([d.path, f.path]);
    // No data for b.dart and e.dart anymore.
    assertStateString(r'''
files
  /workspace/dart/aaa/lib/a.dart
    uri: package:dart.aaa/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_6 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_3
      referencingFiles: file_3
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /workspace/dart/aaa/lib/b.dart
    uri: package:dart.aaa/b.dart
    unlinkedGet: []
    unlinkedPut: [k01]
  /workspace/dart/aaa/lib/c.dart
    uri: package:dart.aaa/c.dart
    current
      id: file_2
      kind: library_2
        imports
          library_6 dart:core synthetic
        cycle_2
          dependencies: dart:core
          libraries: library_2
          apiSignature_2
          users: cycle_5
      referencingFiles: file_5
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
  /workspace/dart/aaa/lib/d.dart
    uri: package:dart.aaa/d.dart
    current
      id: file_3
      kind: library_3
        imports
          library_0
          library_6 dart:core synthetic
        cycle_3
          dependencies: cycle_0 dart:core
          libraries: library_3
          apiSignature_3
      unlinkedKey: k03
    unlinkedGet: []
    unlinkedPut: [k03]
  /workspace/dart/aaa/lib/e.dart
    uri: package:dart.aaa/e.dart
    unlinkedGet: []
    unlinkedPut: [k04]
  /workspace/dart/aaa/lib/f.dart
    uri: package:dart.aaa/f.dart
    current
      id: file_5
      kind: library_5
        imports
          library_2
          library_6 dart:core synthetic
        cycle_5
          dependencies: cycle_2 dart:core
          libraries: library_5
          apiSignature_5
      unlinkedKey: k05
    unlinkedGet: []
    unlinkedPut: [k05]
libraryCycles
  /workspace/dart/aaa/lib/a.dart
    current: cycle_0
      key: k06
    get: []
    put: [k06]
  /workspace/dart/aaa/lib/b.dart
    get: []
    put: [k07]
  /workspace/dart/aaa/lib/c.dart
    current: cycle_2
      key: k08
    get: []
    put: [k08]
  /workspace/dart/aaa/lib/d.dart
    current: cycle_3
      key: k09
    get: []
    put: [k09]
  /workspace/dart/aaa/lib/e.dart
    get: []
    put: [k10]
  /workspace/dart/aaa/lib/f.dart
    current: cycle_5
      key: k11
    get: []
    put: [k11]
elementFactory
  hasElement
    package:dart.aaa/a.dart
    package:dart.aaa/c.dart
    package:dart.aaa/d.dart
    package:dart.aaa/f.dart
byteStore
  1: [k00, k02, k03, k05, k06, k08, k09, k11, k12, k13, k14, k15, k16, k17]
''');
  }

  test_removeFilesNotNecessaryForAnalysisOf_unknown() async {
    final a = newFile('/workspace/dart/aaa/lib/a.dart', r'''
class A {}
''');

    final b = getFile('/workspace/dart/aaa/lib/b.dart');

    await resolveFile(a.path);
    fileResolver.removeFilesNotNecessaryForAnalysisOf([a.path, b.path]);

    // No b.dart anywhere.
    assertStateString(r'''
files
  /workspace/dart/aaa/lib/a.dart
    uri: package:dart.aaa/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
libraryCycles
  /workspace/dart/aaa/lib/a.dart
    current: cycle_0
      key: k01
    get: []
    put: [k01]
elementFactory
  hasElement
    package:dart.aaa/a.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07]
''');
  }

  test_resolve_libraryWithPart_noLibraryDiscovery() async {
    newFile('/workspace/dart/test/lib/a.dart', r'''
part of 'test.dart';

class A {}
''');

    await assertNoErrorsInCode(r'''
part 'a.dart';

void f(A a) {}
''');

    // We started resolution from the library, and then followed to the part.
    // So, the part knows its library, there is no need to discover it.
    // TODO(scheglov) Use textual dump
    // _assertDiscoveredLibraryForParts([]);
  }

  test_resolve_part_of_name() async {
    final a = newFile('/workspace/dart/test/lib/a.dart', r'''
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

    // TODO(scheglov) Use textual dump
    final fsState = fileResolver.fsState!;
    final testState = fsState.getExisting(testFile)!;
    final testKind = testState.kind as PartFileStateKind;
    expect(testKind.library?.file, fsState.getExisting(a));
  }

  test_resolve_part_of_uri() async {
    final a = newFile('/workspace/dart/test/lib/a.dart', r'''
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

    // TODO(scheglov) Use textual dump
    final fsState = fileResolver.fsState!;
    final testState = fsState.getExisting(testFile)!;
    final testKind = testState.kind as PartFileStateKind;
    expect(testKind.library?.file, fsState.getExisting(a));
  }

  test_resolveFile_cache() async {
    newFile(testFilePath, 'var a = 0;');

    // No resolved files yet.
    _assertResolvedFiles([]);

    await resolveFile2(testFile.path);
    var result1 = result;

    // The file was resolved.
    _assertResolvedFiles([testFile]);

    // The result is cached.
    expect(fileResolver.cachedResults, contains(testFile.path));

    // Ask again, no changes, not resolved.
    await resolveFile2(testFile.path);
    _assertResolvedFiles([]);

    // The same result was returned.
    expect(result, same(result1));

    // Change a file.
    var a_path = convertPath('/workspace/dart/test/lib/a.dart');
    fileResolver.changeFiles([a_path]);

    // The was a change to a file, no matter which, resolve again.
    await resolveFile2(testFile.path);
    _assertResolvedFiles([testFile]);

    // Get should get a new result.
    expect(result, isNot(same(result1)));
  }

  test_resolveLibrary() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
part 'test.dart';

class A {
  int m;
}
''');

    newFile('/workspace/dart/test/lib/test.dart', r'''
part of 'a.dart';

void func() {
  var a = A();
  print(a.m);
}
''');

    var result = await fileResolver.resolveLibrary2(path: aPath);
    expect(result.units.length, 2);
    expect(result.units[0].path, aPath);
    expect(result.units[0].uri, Uri.parse('package:dart.test/a.dart'));
  }

  test_reuse_compatibleOptions() async {
    newFile('/workspace/dart/aaa/BUILD', '');
    newFile('/workspace/dart/bbb/BUILD', '');

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
    newFile('/workspace/dart/aaa/BUILD', '');
    newAnalysisOptionsYamlFile('/workspace/dart/aaa', r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    newFile('/workspace/dart/bbb/BUILD', '');
    newAnalysisOptionsYamlFile('/workspace/dart/bbb', r'''
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

  void _assertResolvedFiles(
    List<File> expected, {
    bool andClear = true,
  }) {
    final actual = fileResolver.testData!.resolvedLibraries;
    expect(actual, expected.map((e) => e.path).toList());
    if (andClear) {
      actual.clear();
    }
  }

  Future<Element> _findElement(int offset, String filePath) async {
    var resolvedUnit = await fileResolver.resolve2(path: filePath);
    var node = NodeLocator(offset).searchWithin(resolvedUnit.unit);
    var element = getElementOfNode(node);
    return element!;
  }
}
