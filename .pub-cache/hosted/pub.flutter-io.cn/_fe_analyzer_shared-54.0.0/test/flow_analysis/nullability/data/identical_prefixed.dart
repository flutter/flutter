// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:core' as core;

void test(int? x) {
  if (core.identical(x, null)) {
    x;
  } else {
    /*nonNullable*/ x;
  }
}
