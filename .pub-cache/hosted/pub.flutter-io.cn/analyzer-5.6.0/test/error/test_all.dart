// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'error_listener_test.dart' as error_listener;
import 'error_reporter_test.dart' as error_reporter;

main() {
  defineReflectiveSuite(() {
    error_listener.main();
    error_reporter.main();
  }, name: 'error');
}
