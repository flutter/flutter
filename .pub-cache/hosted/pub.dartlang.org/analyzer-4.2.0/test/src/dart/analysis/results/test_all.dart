// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'get_element_declaration_test.dart' as results;

main() {
  defineReflectiveSuite(() {
    results.main();
  }, name: 'results');
}
