// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelVariableTest);
    defineReflectiveTests(TopLevelVariableWithoutNullSafetyTest);
  });
}

@reflectiveTest
class TopLevelVariableTest extends PubPackageResolutionTest
    with TopLevelVariableTestCases {
  test_type_inferred_nonNullify() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
var a = 0;
''');

    await assertErrorsInCode('''
import 'a.dart';

var v = a;
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertType(findElement.topVar('v').type, 'int');
  }
}

mixin TopLevelVariableTestCases on PubPackageResolutionTest {
  test_session_getterSetter() async {
    await resolveTestCode('''
var v = 0;
''');
    var getter = findElement.topGet('v');
    expect(getter.session, result.session);

    var setter = findElement.topSet('v');
    expect(setter.session, result.session);
  }

  test_type_inferred_int() async {
    await resolveTestCode('''
var v = 0;
''');
    assertType(findElement.topVar('v').type, 'int');
  }

  test_type_inferred_Never() async {
    await resolveTestCode('''
var v = throw 42;
''');
    assertType(
      findElement.topVar('v').type,
      typeStringByNullability(
        nullable: 'Never',
        legacy: 'dynamic',
      ),
    );
  }

  test_type_inferred_noInitializer() async {
    await resolveTestCode('''
var v;
''');
    assertType(findElement.topVar('v').type, 'dynamic');
  }

  test_type_inferred_null() async {
    await resolveTestCode('''
var v = null;
''');
    assertType(findElement.topVar('v').type, 'dynamic');
  }
}

@reflectiveTest
class TopLevelVariableWithoutNullSafetyTest extends PubPackageResolutionTest
    with TopLevelVariableTestCases, WithoutNullSafetyMixin {}
