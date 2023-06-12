// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_options_provider_test.dart' as analysis_options_provider_test;
import 'error_processor_test.dart' as error_processor_test;
import 'package_map_resolver_test.dart' as package_map_resolver_test;
import 'path_filter_test.dart' as path_filter_test;

main() {
  defineReflectiveSuite(() {
    analysis_options_provider_test.main();
    error_processor_test.main();
    package_map_resolver_test.main();
    path_filter_test.main();
  }, name: 'source');
}
