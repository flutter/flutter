// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:pub_semver/src/version_constraint.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IllegalLanguageVersionOverrideTest);
  });
}

@reflectiveTest
class IllegalLanguageVersionOverrideTest extends PubPackageResolutionTest {
  test_hasOverride_equal() async {
    await assertNoErrorsInCode(r'''
// @dart = 2.12
void f() {}
''');
  }

  test_hasOverride_greater() async {
    await assertNoErrorsInCode(r'''
// @dart = 2.14
void f() {}
''');
  }

  test_hasOverride_less() async {
    await assertErrorsInCode(r'''
// @dart = 2.9
int a = null;
''', [
      error(CompileTimeErrorCode.ILLEGAL_LANGUAGE_VERSION_OVERRIDE, 0, 14),
    ]);
  }

  test_hasPackageLanguage_less_hasOverride_greater() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.9',
    );

    await assertNoErrorsInCode(r'''
// @dart = 2.12
void f() {}
''');
  }

  test_hasPackageLanguage_less_noOverride_less() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.9',
    );

    await assertErrorsInCode(r'''
void f() {}
''', [
      error(CompileTimeErrorCode.ILLEGAL_LANGUAGE_VERSION_OVERRIDE, 0, 0),
    ]);
  }

  test_noOverride() async {
    await assertNoErrorsInCode(r'''
void f() {}
''');
  }

  @override
  void updateAnalysisOptions({
    required AnalysisOptionsImpl analysisOptions,
    required ContextRoot contextRoot,
    required DartSdk sdk,
  }) {
    analysisOptions.sourceLanguageConstraint =
        VersionConstraint.parse('>= 2.12.0');
  }
}
