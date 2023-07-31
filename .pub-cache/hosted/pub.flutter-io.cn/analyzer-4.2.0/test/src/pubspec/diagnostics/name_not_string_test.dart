// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NameNotStringTest);
  });
}

@reflectiveTest
class NameNotStringTest extends PubspecDiagnosticTest {
  test_nameNotString_error_int() {
    assertErrors('''
name: 42
''', [PubspecWarningCode.NAME_NOT_STRING]);
  }

  test_nameNotString_noError() {
    assertNoErrors('''
name: sample
''');
  }
}
