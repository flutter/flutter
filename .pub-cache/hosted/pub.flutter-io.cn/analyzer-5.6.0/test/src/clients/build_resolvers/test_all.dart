// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'build_resolvers_test.dart' as build_resolvers;

main() {
  defineReflectiveSuite(() {
    build_resolvers.main();
  }, name: 'build_resolvers');
}
