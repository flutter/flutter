// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_options_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IncludeFileWarningTest);
  });
}

@reflectiveTest
class IncludeFileWarningTest extends AbstractAnalysisOptionsTest {
  void test_fileWarning() {
    newFile('/a.yaml', '''
analyzer:
  something: bad
''');
    assertErrorsInCode('''
include: a.yaml
''', [
      error(
        AnalysisOptionsWarningCode.INCLUDED_FILE_WARNING,
        9,
        6,
        messageContains: [
          'Warning in the included options file ${convertPath('/a.yaml')}',
          ": The option 'something' isn't supported by 'analyzer'."
        ],
      )
    ]);
  }
}
