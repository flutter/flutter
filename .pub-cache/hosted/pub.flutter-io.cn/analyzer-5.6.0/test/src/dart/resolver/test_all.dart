// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'exit_detector_test.dart' as exit_detector;
import 'legacy_type_asserter_test.dart' as legacy_type_asserter;

main() {
  defineReflectiveSuite(() {
    exit_detector.main();
    legacy_type_asserter.main();
  }, name: 'resolver');
}
