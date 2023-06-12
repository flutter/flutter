// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that flow analysis understands that two late initializers
// may execute independently, so an assignment in one doesn't place the variable
// into the "assigned" state in the other.

twoEagerVariables() {
  late int x;
  int y = (x = 0), z = x;
}

twoLateVariables() {
  late int x;
  late int y = (x = 0), z = /*unassigned*/ x;
}
