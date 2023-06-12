// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'dart/test_all.dart' as dart;
import 'error/test_all.dart' as error;
import 'file_system/test_all.dart' as file_system;
import 'generated/test_all.dart' as generated;
import 'instrumentation/test_all.dart' as instrumentation;
import 'source/test_all.dart' as source;
import 'src/test_all.dart' as src;
// import 'verify_diagnostics_test.dart' as verify_diagnostics;
// import 'verify_docs_test.dart' as verify_docs;
// import 'verify_tests_test.dart' as verify_tests;

main() {
  defineReflectiveSuite(() {
    dart.main();
    error.main();
    file_system.main();
    generated.main();
    instrumentation.main();
    source.main();
    src.main();
    // verify_diagnostics.main();
    // verify_docs.main();
    // verify_tests.main();
  }, name: 'analyzer');
}
