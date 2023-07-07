// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssetDoesNotExistTest);
  });
}

@reflectiveTest
class AssetDoesNotExistTest extends PubspecDiagnosticTest {
  test_assetDoesNotExist_path_error() {
    assertErrors('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''', [PubspecWarningCode.ASSET_DOES_NOT_EXIST]);
  }

  test_assetDoesNotExist_path_inRoot_noError() {
    newFile('/sample/assets/my_icon.png', '');
    assertNoErrors('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''');
  }

  test_assetDoesNotExist_path_inSubdir_noError() {
    newFile('/sample/assets/images/2.0x/my_icon.png', '');
    assertNoErrors('''
name: sample
flutter:
  assets:
    - assets/images/my_icon.png
''');
  }

  @failingTest
  test_assetDoesNotExist_uri_error() {
    assertErrors('''
name: sample
flutter:
  assets:
    - packages/icons/my_icon.png
''', [PubspecWarningCode.ASSET_DOES_NOT_EXIST]);
  }

  test_assetDoesNotExist_uri_noError() {
    // TODO(brianwilkerson) Create a package named `icons` that contains the
    // referenced file, and a `.packages` file that references that package.
    assertNoErrors('''
name: sample
flutter:
  assets:
    - packages/icons/my_icon.png
''');
  }
}
