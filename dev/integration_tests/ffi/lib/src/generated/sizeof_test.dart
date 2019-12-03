// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import "expect.dart";

void main() async {
  Expect.equals(true, 4 == sizeOf<Pointer>() || 8 == sizeOf<Pointer>());
}
