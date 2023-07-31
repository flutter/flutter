// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_options_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveIncludeFileTest);
  });
}

@reflectiveTest
class RecursiveIncludeFileTest extends AbstractAnalysisOptionsTest {
  void test_itself() {
    assertErrorsInCode('''
include: analysis_options.yaml
''', [
      error(
        AnalysisOptionsWarningCode.RECURSIVE_INCLUDE_FILE,
        9,
        21,
        text: "The include file 'analysis_options.yaml' "
            "in '${convertPath('/analysis_options.yaml')}' includes itself recursively.",
      )
    ]);
  }

  void test_recursive() {
    newFile('/a.yaml', '''
include: b.yaml
''');
    newFile('/b.yaml', '''
include: analysis_options.yaml
''');
    assertErrorsInCode('''
include: a.yaml
''', [
      error(
        AnalysisOptionsWarningCode.RECURSIVE_INCLUDE_FILE,
        9,
        6,
        text: "The include file 'analysis_options.yaml' "
            "in '${convertPath('/b.yaml')}' includes itself recursively.",
      )
    ]);
  }

  void test_recursive_itself() {
    newFile('/a.yaml', '''
include: a.yaml
''');
    assertErrorsInCode('''
include: a.yaml
''', [
      error(
        AnalysisOptionsWarningCode.INCLUDED_FILE_WARNING,
        9,
        6,
        messageContains: [
          "Warning in the included options file ${convertPath('/a.yaml')}",
          ": The file includes itself recursively."
        ],
      )
    ]);
  }

  void test_recursive_notInBeginning() {
    newFile('/a.yaml', '''
include: b.yaml
''');
    newFile('/b.yaml', '''
include: a.yaml
''');
    assertErrorsInCode('''
include: a.yaml
''', [
      error(
        AnalysisOptionsWarningCode.INCLUDED_FILE_WARNING,
        9,
        6,
        messageContains: [
          "Warning in the included options file ${convertPath('/a.yaml')}",
          ": The file includes itself recursively."
        ],
      )
    ]);
  }
}
