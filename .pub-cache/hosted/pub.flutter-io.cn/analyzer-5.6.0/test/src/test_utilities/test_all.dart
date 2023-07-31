// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_code_format_test.dart' as test_code_format;

main() {
  defineReflectiveSuite(() {
    test_code_format.main();
  });
}
