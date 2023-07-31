// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedFieldTest);
  });
}

@reflectiveTest
class DeprecatedFieldTest extends PubspecDiagnosticTest {
  test_deprecated_author() {
    assertErrors('''
name: sample
author: foo
''', [PubspecWarningCode.DEPRECATED_FIELD]);
  }

  test_deprecated_authors() {
    assertErrors('''
name: sample
authors:
  - foo
  - bar
''', [PubspecWarningCode.DEPRECATED_FIELD]);
  }

  test_deprecated_transformers() {
    assertErrors('''
name: sample
transformers:
  - foo
''', [PubspecWarningCode.DEPRECATED_FIELD]);
  }

  test_deprecated_web() {
    assertErrors('''
name: sample
web: foo
''', [PubspecWarningCode.DEPRECATED_FIELD]);
  }
}
