// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNullableBlazeWorkspaceTest);
  });
}

@reflectiveTest
class NonNullableBlazeWorkspaceTest extends BlazeWorkspaceResolutionTest {
  @override
  bool get isNullSafetyEnabled => true;

  test_buildFile_legacy_commentedOut() async {
    newFile('$myPackageRootPath/BUILD', r'''
dart_package(
#  null_safety = True,
''');

    await resolveFileCode(
      '$myPackageRootPath/lib/a.dart',
      'int v = 0;',
    );
    assertNoErrorsInResult();
    assertType(findNode.namedType('int v'), 'int*');
  }

  test_buildFile_nonNullable() async {
    newFile('$myPackageRootPath/BUILD', r'''
dart_package(
  null_safety = True,
)
''');

    // Non-nullable in lib/.
    await resolveFileCode(
      '$myPackageRootPath/lib/a.dart',
      'int v = 0;',
    );
    assertNoErrorsInResult();
    assertType(findNode.namedType('int v'), 'int');

    // Non-nullable in test/.
    await resolveFileCode(
      '$myPackageRootPath/test/a.dart',
      'int v = 0;',
    );
    assertNoErrorsInResult();
    assertType(findNode.namedType('int v'), 'int');

    // Non-nullable in bin/.
    await resolveFileCode(
      '$myPackageRootPath/bin/a.dart',
      'int v = 0;',
    );
    assertNoErrorsInResult();
    assertType(findNode.namedType('int v'), 'int');
  }

  test_buildFile_nonNullable_languageVersion_current() async {
    newFile('$myPackageRootPath/BUILD', r'''
dart_package(
  null_safety = True,
)
''');

    await resolveFileCode(
      '$myPackageRootPath/lib/a.dart',
      'int v = 0;',
    );
    _assertLanguageVersion(
      package: ExperimentStatus.currentVersion,
      override: null,
    );
  }

  test_buildFile_nonNullable_languageVersion_fromWorkspace() async {
    newFile('$workspaceRootPath/dart/build_defs/bzl/language.bzl', r'''
_version = "2.9"
_version_null_safety = "2.14"
_version_for_analyzer = _version_null_safety

language = struct(
    version = _version,
    version_null_safety = _version_null_safety,
    version_for_analyzer = _version_for_analyzer,
)
''');

    newFile('$myPackageRootPath/BUILD', r'''
dart_package(
  null_safety = True,
)
''');

    await resolveFileCode(
      '$myPackageRootPath/lib/a.dart',
      'int v = 0;',
    );
    _assertLanguageVersion(
      package: Version.parse('2.14.0'),
      override: null,
    );
  }

  test_buildFile_nonNullable_oneLine_noComma() async {
    newFile('$myPackageRootPath/BUILD', r'''
dart_package(null_safety = True)
''');

    await resolveFileCode(
      '$myPackageRootPath/lib/a.dart',
      'int v = 0;',
    );
    assertNoErrorsInResult();
    assertType(findNode.namedType('int v'), 'int');
  }

  test_buildFile_nonNullable_soundNullSafety() async {
    newFile('$myPackageRootPath/BUILD', r'''
dart_package(
  sound_null_safety = True
)
''');

    await resolveFileCode(
      '$myPackageRootPath/lib/a.dart',
      'int v = 0;',
    );
    assertNoErrorsInResult();
    assertType(findNode.namedType('int v'), 'int');
  }

  test_buildFile_nonNullable_withComments() async {
    newFile('$myPackageRootPath/BUILD', r'''
dart_package(
  # Preceding comment.
  null_safety = True,  # Trailing comment.
)  # Last comment.
''');

    await resolveFileCode(
      '$myPackageRootPath/lib/a.dart',
      'int v = 0;',
    );
    assertNoErrorsInResult();
    assertType(findNode.namedType('int v'), 'int');
  }

  test_noBuildFile_legacy() async {
    await assertNoErrorsInCode('''
int v = 0;
''');

    assertType(findNode.namedType('int v'), 'int*');
  }

  void _assertLanguageVersion({
    required Version package,
    required Version? override,
  }) async {
    var element = result.libraryElement;
    expect(element.languageVersion.package, package);
    expect(element.languageVersion.override, override);
  }
}
