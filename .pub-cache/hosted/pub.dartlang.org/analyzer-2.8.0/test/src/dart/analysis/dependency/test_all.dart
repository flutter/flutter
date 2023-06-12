// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'declared_nodes_test.dart' as declared_nodes_test;
import 'reference_collector_test.dart' as reference_collector_test;

main() {
  defineReflectiveSuite(() {
    declared_nodes_test.main();
    reference_collector_test.main();
  }, name: 'dependency');
}
