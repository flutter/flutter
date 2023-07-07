// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidLanguageOverrideGreaterTest);
  });
}

@reflectiveTest
class InvalidLanguageOverrideGreaterTest extends PubPackageResolutionTest {
  @override
  String? get testPackageLanguageVersion => null;

  test_greaterThanLatest() async {
    var latestVersion = ExperimentStatus.currentVersion;
    await assertErrorsInCode('''
// @dart = ${latestVersion.major}.${latestVersion.minor + 1}
class A {}
''', [
      error(HintCode.INVALID_LANGUAGE_VERSION_OVERRIDE_GREATER, 0, 15),
    ]);
    _assertUnitLanguageVersion(
      package: latestVersion,
      override: null,
    );
  }

  test_greaterThanPackage() async {
    _configureTestPackageLanguageVersion('2.5');
    await assertNoErrorsInCode(r'''
// @dart = 2.12
int? a;
''');
    _assertUnitLanguageVersion(
      package: Version.parse('2.5.0'),
      override: Version.parse('2.12.0'),
    );
  }

  test_lessThanPackage() async {
    _configureTestPackageLanguageVersion('2.5');
    await assertNoErrorsInCode(r'''
// @dart = 2.4
class A {}
''');
    _assertUnitLanguageVersion(
      package: Version.parse('2.5.0'),
      override: Version.parse('2.4.0'),
    );
  }

  void _assertUnitLanguageVersion({
    required Version package,
    required Version? override,
  }) {
    var unitImpl = result.unit as CompilationUnitImpl;
    var languageVersion = unitImpl.languageVersion!;
    expect(languageVersion.package, package);
    expect(languageVersion.override, override);
  }

  void _configureTestPackageLanguageVersion(String versionStr) {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: versionStr,
    );
  }
}
