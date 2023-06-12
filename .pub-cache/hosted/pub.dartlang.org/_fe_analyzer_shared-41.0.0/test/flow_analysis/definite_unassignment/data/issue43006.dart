// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test() {
  late int x;
  late int y;
  var f = () => x;
  int z0 = /*unassigned*/ x;
  int z1 = /*unassigned*/ y;
  x = 3;
  y = 3;
}
