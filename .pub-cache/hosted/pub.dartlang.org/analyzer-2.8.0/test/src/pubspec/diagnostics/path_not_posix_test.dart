// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PathNotPosixTest);
  });
}

@reflectiveTest
class PathNotPosixTest extends PubspecDiagnosticTest {
  test_pathNotPosix_error() {
    newFolder('/foo');
    newPubspecYamlFile('/foo', '''
name: foo
''');
    assertErrors(r'''
name: sample
version: 0.1.0
publish_to: none
dependencies:
  foo:
    path: \foo
''', [
      PubspecWarningCode.PATH_NOT_POSIX,
    ]);
  }
}
