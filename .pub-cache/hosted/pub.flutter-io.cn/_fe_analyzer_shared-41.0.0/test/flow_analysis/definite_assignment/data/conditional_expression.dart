// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

in_both(bool c) {
  late int v;
  c ? (v = 0) : (v = 0);
  v;
}

in_condition() {
  late int v;
  (v = 0) >= 0 ? 1 : 2;
  v;
}

in_else(bool c) {
  late int v;
  c ? (v = 0) : 2;
  /*unassigned*/ v;
}

in_then(bool c) {
  late int v;
  c ? (v = 0) : 2;
  /*unassigned*/ v;
}
