// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PathPubspecDoesNotExistTest);
  });
}

@reflectiveTest
class PathPubspecDoesNotExistTest extends PubspecDiagnosticTest {
  test_dependencyPath_pubspecDoesNotExist() {
    newFolder('/foo');
    assertErrors('''
name: sample
dependencies:
  foo:
    path: /foo
''', [PubspecWarningCode.PATH_PUBSPEC_DOES_NOT_EXIST]);
  }

  test_dependencyPath_pubspecExists() {
    newFolder('/foo');
    newPubspecYamlFile('/foo', '''
name: foo
''');
    assertNoErrors('''
name: sample
dependencies:
  foo:
    path: /foo
''');
  }
}
