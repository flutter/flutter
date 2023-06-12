// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssetNotStringTest);
  });
}

@reflectiveTest
class AssetNotStringTest extends PubspecDiagnosticTest {
  test_assetNotString_error_int() {
    assertErrors('''
name: sample
flutter:
  assets:
    - 23
''', [PubspecWarningCode.ASSET_NOT_STRING]);
  }

  test_assetNotString_error_map() {
    assertErrors('''
name: sample
flutter:
  assets:
    - my_icon:
      default: assets/my_icon.png
      large: assets/large/my_icon.png
''', [PubspecWarningCode.ASSET_NOT_STRING]);
  }

  test_assetNotString_noError() {
    newFile('/sample/assets/my_icon.png', '');
    assertNoErrors('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''');
  }
}
