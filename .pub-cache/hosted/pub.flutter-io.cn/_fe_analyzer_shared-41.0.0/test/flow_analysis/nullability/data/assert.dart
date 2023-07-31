// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

assertStatement(int? i) {
  // Assert statements do not promote because they only are only
  // checked in debug mode.
  assert(i != null);
  i;
}

class C {
  C.assertInitializer(int? i) : assert(i != null) {
    // Assert statements do not promote because they only are only
    // checked in debug mode.
    i;
  }
}
