// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicatePartTest);
  });
}

@reflectiveTest
class DuplicatePartTest extends PubPackageResolutionTest {
  test_no_duplicates() async {
    newFile('$testPackageLibPath/part1.dart', '''
part of lib;
''');
    newFile('$testPackageLibPath/part2.dart', '''
part of lib;
''');
    await assertNoErrorsInCode(r'''
library lib;
part 'part1.dart';
part 'part2.dart';
''');
  }

  test_sameSource() async {
    newFile('$testPackageLibPath/part.dart', 'part of lib;');
    await assertErrorsInCode(r'''
library lib;
part 'part.dart';
part 'foo/../part.dart';
''', [
      error(CompileTimeErrorCode.DUPLICATE_PART, 36, 18),
    ]);
  }

  test_sameUri() async {
    newFile('$testPackageLibPath/part.dart', 'part of lib;');
    await assertErrorsInCode(r'''
library lib;
part 'part.dart';
part 'part.dart';
''', [
      error(CompileTimeErrorCode.DUPLICATE_PART, 36, 11),
    ]);
  }
}
