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

    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
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

    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
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
  void _configureTestWithJsonConfig(String content) {
    newFile(
      '$testPackageRootPath/.dart_tool/package_config.json',
      content,
    );
  }
}
