// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that flow analysis understands that a late initializer
// doesn't execute immediately, so it may refer to other late variables that
// aren't assigned yet.

void use(Object? x) {}

eagerInitializerRefersToLateVar() {
  late int x;
  int y = /*unassigned*/ x;
  x = 0;
}

lateInitializerRefersToLateVar() {
  late int x;
  late int y = x;
  x = 0;
}

lateInitializerIsAssignment() {
  late int y;
  late int z1 = y = 3;
  use(y);
}
