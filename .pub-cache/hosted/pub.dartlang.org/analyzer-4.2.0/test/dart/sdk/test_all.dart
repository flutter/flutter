// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'build_sdk_summary_test.dart' as build_sdk_summary;

main() {
  defineReflectiveSuite(() {
    build_sdk_summary.main();
  }, name: 'sdk');
}
