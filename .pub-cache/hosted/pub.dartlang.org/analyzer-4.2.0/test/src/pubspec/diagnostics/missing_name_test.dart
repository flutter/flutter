// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingNameTest);
  });
}

@reflectiveTest
class MissingNameTest extends PubspecDiagnosticTest {
  test_missingName_error() {
    assertErrors('', [PubspecWarningCode.MISSING_NAME]);
  }

  test_missingName_noError() {
    assertNoErrors('''
name: sample
''');
  }
}
