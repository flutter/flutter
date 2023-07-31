// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InconsistentLanguageVersionOverrideTest);
  });
}

@reflectiveTest
class InconsistentLanguageVersionOverrideTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  // TODO(https://github.com/dart-lang/sdk/issues/44666): Use null safety in
  //  test cases.

  CompileTimeErrorCode get _errorCode =>
      CompileTimeErrorCode.INCONSISTENT_LANGUAGE_VERSION_OVERRIDE;

  test_both_different() async {
    await _checkLibraryAndPart(
      libraryContent: r'''
// @dart = 2.5
part 'b.dart';
''',
      partContent: r'''
// @dart = 2.6
part of 'a.dart';
''',
      libraryErrors: [
        error(_errorCode, 20, 8),
      ],
    );
  }

  test_both_same() async {
    await _checkLibraryAndPart(
      libraryContent: r'''
// @dart = 2.5
part 'b.dart';
''',
      partContent: r'''
// @dart = 2.5
part of 'a.dart';
''',
      libraryErrors: [],
    );
  }

  test_none() async {
    await _checkLibraryAndPart(
      libraryContent: r'''
part 'b.dart';
''',
      partContent: r'''
part of 'a.dart';
''',
      libraryErrors: [],
    );
  }

  test_onlyLibrary() async {
    await _checkLibraryAndPart(
      libraryContent: r'''
// @dart = 2.5
part 'b.dart';
''',
      partContent: r'''
part of 'a.dart';
''',
      libraryErrors: [
        error(_errorCode, 20, 8),
      ],
    );
  }

  test_onlyPart() async {
    await _checkLibraryAndPart(
      libraryContent: r'''
part 'b.dart';
''',
      partContent: r'''
// @dart = 2.5
part of 'a.dart';
''',
      libraryErrors: [
        error(_errorCode, 5, 8),
      ],
    );
  }

  Future<void> _checkLibraryAndPart({
    required String libraryContent,
    required String partContent,
    required List<ExpectedError> libraryErrors,
  }) async {
    var libraryPath = convertPath('$testPackageLibPath/a.dart');
    var partPath = convertPath('$testPackageLibPath/b.dart');

    newFile(libraryPath, libraryContent);

    newFile(partPath, partContent);

    await assertErrorsInFile2(libraryPath, libraryErrors);
  }
}
