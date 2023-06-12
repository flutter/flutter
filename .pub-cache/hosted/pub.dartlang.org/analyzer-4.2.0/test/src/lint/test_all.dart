// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'config_test.dart' as config;
import 'io_test.dart' as io;
import 'lint_rule_test.dart' as lint_rule;
import 'linter/test_all.dart' as linter;
import 'pub_test.dart' as pub;

main() {
  defineReflectiveSuite(() {
    config.main();
    io.main();
    lint_rule.main();
    linter.main();
    pub.main();
  }, name: 'lint');
}
