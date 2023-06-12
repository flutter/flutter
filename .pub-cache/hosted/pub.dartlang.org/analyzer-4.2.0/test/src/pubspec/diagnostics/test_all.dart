// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'asset_directory_does_not_exist_test.dart'
    as asset_directory_does_not_exist;
import 'asset_does_not_exist_test.dart' as asset_does_not_exist;
import 'asset_field_not_list_test.dart' as asset_field_not_list;
import 'asset_not_string_test.dart' as asset_not_string;
import 'dependencies_field_not_map_test.dart' as dependencies_field_not_map;
import 'deprecated_field_test.dart' as deprecated_field;
import 'flutter_field_not_map_test.dart' as flutter_field_not_map;
import 'invalid_dependency_test.dart' as invalid_dependency;
import 'missing_name_test.dart' as missing_name;
import 'name_not_string_test.dart' as name_not_string;
import 'path_does_not_exist_test.dart' as path_does_not_exist;
import 'path_not_posix_test.dart' as path_not_posix;
import 'path_pubspec_does_not_exist_test.dart' as path_pubspec_does_not_exist;
import 'unnecessary_dev_dependency_test.dart' as unnecessary_dev_dependency;

main() {
  defineReflectiveSuite(() {
    asset_directory_does_not_exist.main();
    asset_does_not_exist.main();
    asset_field_not_list.main();
    asset_not_string.main();
    dependencies_field_not_map.main();
    deprecated_field.main();
    flutter_field_not_map.main();
    invalid_dependency.main();
    missing_name.main();
    name_not_string.main();
    path_does_not_exist.main();
    path_not_posix.main();
    path_pubspec_does_not_exist.main();
    unnecessary_dev_dependency.main();
  }, name: 'diagnostics');
}
