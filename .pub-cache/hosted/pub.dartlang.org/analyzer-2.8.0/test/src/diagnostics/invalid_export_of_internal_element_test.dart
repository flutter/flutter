// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/mock_packages.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidExportOfInternalElement_BazelPackageTest);
    defineReflectiveTests(
        InvalidExportOfInternalElement_PackageBuildPackageTest);
    defineReflectiveTests(InvalidExportOfInternalElement_PubPackageTest);
  });
}

@reflectiveTest
class InvalidExportOfInternalElement_BazelPackageTest
    extends BazelWorkspaceResolutionTest
    with InvalidExportOfInternalElementTest {
  String get testPackageBazelBinPath => '$workspaceRootPath/bazel-bin/dart/my';

  String get testPackageGenfilesPath =>
      '$workspaceRootPath/bazel-genfiles/dart/my';

  @override
  String get testPackageLibPath => myPackageLibPath;

  @override
  void setUp() async {
    super.setUp();
    var metaPath = '$workspaceThirdPartyDartPath/meta';
    MockPackages.addMetaPackageFiles(
      getFolder(metaPath),
    );
    newFile('$testPackageBazelBinPath/my.packages');
    newFolder('$workspaceRootPath/bazel-out');
  }

  void test_exporterIsInBazelBinLib() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveFileCode('$testPackageBazelBinPath/lib/bar.dart', r'''
export 'src/foo.dart';
''');

    assertErrorsInResult([
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 22),
    ]);
  }

  void test_exporterIsInBazelBinLibSrc() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveFileCode('$testPackageBazelBinPath/lib/src/bar.dart', r'''
export 'foo.dart';
''');

    assertNoErrorsInResult();
  }

  void test_exporterIsInGenfilesLib() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveFileCode('$testPackageGenfilesPath/lib/bar.dart', r'''
export 'src/foo.dart';
''');

    assertErrorsInResult([
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 22),
    ]);
  }

  void test_exporterIsInGenfilesLibSrc() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveFileCode('$testPackageGenfilesPath/lib/src/bar.dart', r'''
export 'foo.dart';
''');

    assertNoErrorsInResult();
  }

  void test_exporterIsInLib() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveFileCode('$testPackageLibPath/bar.dart', r'''
export 'src/foo.dart';
''');

    assertErrorsInResult([
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 22),
    ]);
  }

  void test_exporterIsInLibSrc() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveFileCode('$testPackageLibPath/src/bar.dart', r'''
export 'foo.dart';
''');

    assertNoErrorsInResult();
  }

  void test_exporterIsInTest() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveFileCode('$myPackageRootPath/test/foo_test.dart', r'''
export 'package:dart.my/src/foo.dart';
''');

    assertNoErrorsInResult();
  }

  void test_internalIsInBazelBin() async {
    newFile('$testPackageBazelBinPath/lib/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'package:dart.my/src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 38),
    ]);
  }

  void test_internalIsInGenfiles() async {
    newFile('$testPackageGenfilesPath/lib/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'package:dart.my/src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 38),
    ]);
  }

  void test_internalIsInLibSrc() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'package:dart.my/src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 38),
    ]);
  }
}

@reflectiveTest
class InvalidExportOfInternalElement_PackageBuildPackageTest
    extends InvalidExportOfInternalElement_PubPackageTest {
  String get testPackageDartToolPath =>
      '$testPackageRootPath/.dart_tool/build/generated/test';

  @FailingTest(reason: r'''
We try to analyze a file in .dart_tool, which is implicitly excluded from
analysis. So, there is no context to analyze it.
''')
  void test_exporterInGeneratedLib() async {
    newFile('$testPackageRootPath/lib/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveFileCode('$testPackageDartToolPath/lib/bar.dart', r'''
export 'package:test/src/foo.dart';
''');

    assertErrorsInResult([
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 35),
    ]);
  }

  @FailingTest(reason: r'''
We try to analyze a file in .dart_tool, which is implicitly excluded from
analysis. So, there is no context to analyze it.
''')
  void test_exporterInGeneratedLibSrc() async {
    newFile('$testPackageRootPath/lib/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveFileCode('$testPackageDartToolPath/lib/src/bar.dart', r'''
export 'package:test/src/foo.dart';
''');

    assertNoErrorsInResult();
  }

  void test_exporterInLib() async {
    newFile('$testPackageRootPath/lib/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveFileCode('$testPackageRootPath/lib/bar.dart', r'''
export 'package:test/src/foo.dart';
''');

    assertErrorsInResult([
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 35),
    ]);
  }

  void test_exporterInLibSrc() async {
    newFile('$testPackageRootPath/lib/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveFileCode('$testPackageRootPath/lib/src/bar.dart', r'''
export 'package:test/src/foo.dart';
''');

    assertNoErrorsInResult();
  }

  void test_internalIsInGeneratedLibSrc() async {
    newFile('$testPackageDartToolPath/lib/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'package:test/src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 35),
    ]);
  }

  @override
  void test_internalIsLibSrc() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'package:test/src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 35),
    ]);
  }
}

@reflectiveTest
class InvalidExportOfInternalElement_PubPackageTest
    extends PubPackageResolutionTest with InvalidExportOfInternalElementTest {
  @override
  void setUp() async {
    super.setUp();
    writeTestPackageConfigWithMeta();
    newPubspecYamlFile(testPackageRootPath, r'''
name: test
version: 0.0.1
''');
  }

  void test_exporterIsInLib() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveFileCode('$testPackageLibPath/bar.dart', r'''
export 'src/foo.dart';
''');

    assertErrorsInResult([
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 22),
    ]);
  }

  void test_exporterIsInLibSrc() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveFileCode('$testPackageLibPath/src/bar.dart', r'''
export 'foo.dart';
''');

    assertNoErrorsInResult();
  }

  void test_exporterIsInTest() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveFileCode('$testPackageRootPath/test/foo_test.dart', r'''
export 'package:test/src/foo.dart';
''');

    assertNoErrorsInResult();
  }

  void test_internalIsLibSrc() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'package:test/src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 35),
    ]);
  }
}

mixin InvalidExportOfInternalElementTest on ContextResolutionTest {
  String get testPackageImplementationFilePath =>
      '$testPackageLibPath/src/foo.dart';

  String get testPackageLibPath;

  void test_hideCombinator_internalHidden() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
class Two {}
''');

    await assertNoErrorsInCode(r'''
export 'src/foo.dart' hide One;
''');
  }

  void test_hideCombinator_internalNotHidden() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
class Two {}
''');

    await assertErrorsInCode(r'''
export 'src/foo.dart' hide Two;
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 31),
    ]);
  }

  void test_indirectlyViaFunction_parameter() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal typedef int IntFunc(int x);
int func(IntFunc f, int x) => f(x);
''');

    await assertErrorsInCode(r'''
export 'src/foo.dart' show func;
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY, 0, 32),
    ]);
  }

  void test_indirectlyViaFunction_parameter_generic() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal typedef IntFunc = int Function(int);
int func(IntFunc f, int x) => f(x);
''');

    await assertErrorsInCode(r'''
export 'src/foo.dart' show func;
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY, 0, 32),
    ]);
  }

  void test_indirectlyViaFunction_parameter_generic_typeArg() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal typedef IntFunc<T> = int Function(T);
int func(IntFunc<num> f, int x) => f(x);
''');

    await assertErrorsInCode(r'''
export 'src/foo.dart' show func;
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY, 0, 32),
    ]);
  }

  void test_indirectlyViaFunction_returnType() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal typedef int IntFunc(int x);
IntFunc func() => (int x) => x;
''');

    await assertErrorsInCode(r'''
export 'src/foo.dart' show func;
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY, 0, 32),
    ]);
  }

  void test_indirectlyViaFunction_typeArgument_bounded() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal typedef int IntFunc(int x);
void func<T extends IntFunc>() {}
''');

    await assertErrorsInCode(r'''
export 'src/foo.dart' show func;
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY, 0, 32),
    ]);
  }

  void test_indirectlyViaFunction_typeArgument_unbounded() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal typedef int IntFunc(int x);
void func<T>() {}
''');

    await assertNoErrorsInCode(r'''
export 'src/foo.dart' show func;
''');
  }

  void test_noCombinators() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 22),
    ]);
  }

  void test_noCombinators_indirectExport() async {
    newFile(testPackageImplementationFilePath, content: r'''
export 'bar.dart';
''');

    newFile('$testPackageLibPath/src/bar.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 22),
    ]);
  }

  void test_noCombinators_library() async {
    newFile(testPackageImplementationFilePath, content: r'''
@internal
library foo;

import 'package:meta/meta.dart';
''');

    await assertErrorsInCode(r'''
export 'src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 22),
    ]);
  }

  void test_noCombinators_library_notInternal() async {
    newFile(testPackageImplementationFilePath, content: r'''
library foo;
''');

    await assertNoErrorsInCode(r'''
export 'src/foo.dart';
''');
  }

  void test_noCombinators_noInternal() async {
    newFile(testPackageImplementationFilePath, content: r'''
class One {}
''');

    await assertNoErrorsInCode(r'''
export 'src/foo.dart';
''');
  }

  void test_showCombinator_internalNotShown() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
class Two {}
''');

    await assertNoErrorsInCode(r'''
export 'src/foo.dart' show Two;
''');
  }

  void test_showCombinator_internalShown() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
class Two {}
''');

    await assertErrorsInCode(r'''
export 'src/foo.dart' show One;
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 31),
    ]);
  }
}
