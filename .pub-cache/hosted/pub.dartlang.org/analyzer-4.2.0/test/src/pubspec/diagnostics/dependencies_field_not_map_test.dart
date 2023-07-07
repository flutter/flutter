// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DependenciesFieldNotMapTest);
  });
}

@reflectiveTest
class DependenciesFieldNotMapTest extends PubspecDiagnosticTest {
  test_dependenciesField_empty() {
    assertNoErrors('''
name: sample
dependencies:
''');
  }

  test_dependenciesFieldNotMap_error_bool() {
    assertErrors('''
name: sample
dependencies: true
''', [PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP]);
  }

  test_dependenciesFieldNotMap_noError() {
    assertNoErrors('''
name: sample
dependencies:
  a: any
''');
  }

  test_devDependenciesFieldNotMap_dev_error_bool() {
    assertErrors('''
name: sample
dev_dependencies: true
''', [PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP]);
  }
}
