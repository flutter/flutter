// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'ast_builder_test.dart' as ast_builder;
import 'message_coverage_test.dart' as message_coverage;
import 'recovery/test_all.dart' as recovery;
import 'token_utils_test.dart' as token_utils;

main() {
  defineReflectiveSuite(() {
    ast_builder.main();
    message_coverage.main();
    recovery.main();
    token_utils.main();
  }, name: 'fasta');
}
