// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'sdk_test.dart' as sdk;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    sdk.main();
  }, name: 'sdk');
}
