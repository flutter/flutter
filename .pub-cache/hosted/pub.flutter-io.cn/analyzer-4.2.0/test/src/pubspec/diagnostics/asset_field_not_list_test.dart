// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssetFieldNotListTest);
  });
}

@reflectiveTest
class AssetFieldNotListTest extends PubspecDiagnosticTest {
  test_assetFieldNotList_error_empty() {
    assertErrors('''
name: sample
flutter:
  assets:
''', [PubspecWarningCode.ASSET_FIELD_NOT_LIST]);
  }

  test_assetFieldNotList_error_string() {
    assertErrors('''
name: sample
flutter:
  assets: assets/my_icon.png
''', [PubspecWarningCode.ASSET_FIELD_NOT_LIST]);
  }

  test_assetFieldNotList_noError() {
    newFile('/sample/assets/my_icon.png', '');
    assertNoErrors('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''');
  }
}
