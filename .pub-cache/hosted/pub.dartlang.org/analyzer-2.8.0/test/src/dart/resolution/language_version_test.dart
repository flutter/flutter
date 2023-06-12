// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullSafetyExperimentGlobalTest);
    defineReflectiveTests(NullSafetyUsingAllowedExperimentsTest);
    defineReflectiveTests(PackageConfigAndLanguageOverrideTest);
  });
}

@reflectiveTest
class NullSafetyExperimentGlobalTest extends _FeaturesTest {
  test_jsonConfig_legacyContext_nonNullDependency() async {
    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.7"
    },
    {
      "name": "aaa",
      "rootUri": "${toUriStr('$workspaceRootPath/aaa')}",
      "packageUri": "lib/"
    }
  ]
}
''');

    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
int a = 0;
''');

    await assertNoErrorsInCode('''
import 'dart:math';
import 'package:aaa/a.dart';

var x = 0;
var y = a;
var z = pi;
''');
    assertType(findElement.topVar('x').type, 'int*');
    assertType(findElement.topVar('y').type, 'int*');
    assertType(findElement.topVar('z').type, 'double*');
  }

  test_jsonConfig_nonNullContext_legacyDependency() async {
    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/"
    },
    {
      "name": "aaa",
      "rootUri": "${toUriStr('$workspaceRootPath/aaa')}",
      "packageUri": "lib/",
      "languageVersion": "2.7"
    }
  ]
}
''');

    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
int a = 0;
''');

    await assertErrorsInCode('''
import 'dart:math';
import 'package:aaa/a.dart';

var x = 0;
var y = a;
var z = pi;
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 27, 20),
    ]);
    assertType(findElement.topVar('x').type, 'int');
    assertType(findElement.topVar('y').type, 'int');
    assertType(findElement.topVar('z').type, 'double');

    var importFind = findElement.importFind('package:aaa/a.dart');
    assertType(importFind.topVar('a').type, 'int*');
  }
}

@reflectiveTest
class NullSafetyUsingAllowedExperimentsTest extends _FeaturesTest {
  test_jsonConfig_disable_bin() async {
    _configureAllowedExperimentsTestNullSafety();

    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.8"
    }
  ]
}
''');

    var path = '$testPackageRootPath/bin/a.dart';

    await resolveFileCode(path, r'''
var x = 0;
''');
    assertErrorsInResult([]);
    assertType(findElement.topVar('x').type, 'int*');

    // Upgrade the language version to `2.10`, so enable Null Safety.
    _changeFile(path);
    await resolveFileCode(path, r'''
// @dart = 2.10
var x = 0;
''');
    assertType(findElement.topVar('x').type, 'int');
  }

  test_jsonConfig_disable_lib() async {
    _configureAllowedExperimentsTestNullSafety();

    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.8"
    }
  ]
}
''');

    var path = testFilePath;

    await resolveFileCode(path, '''
var x = 0;
''');
    assertErrorsInResult([]);
    assertType(findElement.topVar('x').type, 'int*');

    // Upgrade the language version to `2.10`, so enable Null Safety.
    _changeFile(path);
    await assertNoErrorsInCode('''
// @dart = 2.10
var x = 0;
''');
    assertType(findElement.topVar('x').type, 'int');
  }

  test_jsonConfig_enable_bin() async {
    _configureAllowedExperimentsTestNullSafety();

    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/"
    }
  ]
}
''');

    var path = '$testPackageRootPath/bin/a.dart';

    await resolveFileCode(path, r'''
var x = 0;
''');
    assertErrorsInList(result.errors, []);
    assertType(findElement.topVar('x').type, 'int');

    // Downgrade the version to `2.8`, so disable Null Safety.
    _changeFile(path);
    await resolveFileCode(path, r'''
// @dart = 2.8
var x = 0;
''');
    assertType(findElement.topVar('x').type, 'int*');
  }

  test_jsonConfig_enable_lib() async {
    _configureAllowedExperimentsTestNullSafety();

    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/"
    }
  ]
}
''');

    var path = testFilePath;

    await resolveFileCode(path, '''
var x = 0;
''');
    assertErrorsInResult([]);
    assertType(findElement.topVar('x').type, 'int');

    // Downgrade the version to `2.8`, so disable Null Safety.
    _changeFile(path);
    await assertNoErrorsInCode('''
// @dart = 2.8
var x = 0;
''');
    assertType(findElement.topVar('x').type, 'int*');
  }

  void _configureAllowedExperimentsTestNullSafety() {
    _newSdkExperimentsFile(r'''
{
  "version": 1,
  "experimentSets": {
    "nullSafety": ["non-nullable"]
  },
  "sdk": {
    "default": {
      "experimentSet": "nullSafety"
    }
  },
  "packages": {
    "test": {
      "experimentSet": "nullSafety"
    }
  }
}
''');
  }

  void _newSdkExperimentsFile(String content) {
    newFile(
      '${sdkRoot.path}/lib/_internal/allowed_experiments.json',
      content: content,
    );
  }
}

@reflectiveTest
class PackageConfigAndLanguageOverrideTest extends _FeaturesTest {
  test_jsonConfigDisablesExtensions() async {
    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.3"
    }
  ]
}
''');

    await assertErrorsInCode('''
extension E on int {}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 0, 9),
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 0, 9),
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 12, 2),
      error(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 15, 3),
    ]);
  }

  test_jsonConfigDisablesExtensions_languageOverrideEnables() async {
    _configureTestWithJsonConfig('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.3"
    }
  ]
}
''');

    await assertNoErrorsInCode('''
// @dart = 2.6
extension E on int {}
''');
  }
}

class _FeaturesTest extends PubPackageResolutionTest {
  /// Do necessary work to ensure that the file with the [path] is considered
  /// changed for the purpose of following analysis.
  ///
  /// Currently we just dispose the whole analysis context collection, so when
  /// we ask to analyze anything again, we will pick up the new file content.
  void _changeFile(String path) {
    disposeAnalysisContextCollection();
  }

  void _configureTestWithJsonConfig(String content) {
    newFile(
      '$testPackageRootPath/.dart_tool/package_config.json',
      content: content,
    );
  }
}
