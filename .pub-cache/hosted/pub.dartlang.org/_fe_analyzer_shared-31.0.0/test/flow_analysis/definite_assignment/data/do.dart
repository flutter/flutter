// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

break_afterAssignment(bool c) {
  late int v;
  do {
    v = 0;
    v;
    if (c) break;
  } while (c);
  v;
}

break_beforeAssignment(bool c) {
  late int v;
  do {
    if (c) break;
    v = 0;
  } while (c);
  /*unassigned*/ v;
}

breakOuterFromInner(bool c) {
  late int v1, v2, v3;
  L1:
  do {
    do {
      v1 = 0;
      if (c) break L1;
      v2 = 0;
      v3 = 0;
    } while (c);
    v2;
  } while (c);
  v1;
  /*unassigned*/ v3;
}

condition() {
  late int v1, v2;
  do {
    /*unassigned*/ v1; // assigned in the condition, but not yet
  } while ((v1 = 0) + (v2 = 0) >= 0);
  v2;
}

condition_break(bool c) {
  late int v;
  do {
    if (c) break;
  } while ((v = 0) >= 0);
  /*unassigned*/ v;
}

condition_break_continue(bool c1, bool c2) {
  late int v1, v2, v3, v4, v5, v6;
  do {
    v1 = 0; // visible outside, visible to the condition
    if (c1) break;
    v2 = 0; // not visible outside, visible to the condition
    v3 = 0; // not visible outside, visible to the condition
    if (c2) continue;
    v4 = 0; // not visible
    v5 = 0; // not visible
  } while ((v6 = v1 + v2 + /*unassigned*/ v4) ==
      0); // has break => v6 is not visible outside
  v1;
  /*unassigned*/ v3;
  /*unassigned*/ v5;
  /*unassigned*/ v6;
}

condition_continue(bool c) {
  late int v1, v2, v3, v4;
  do {
    v1 = 0; // visible outside, visible to the condition
    if (c) continue;
    v2 = 0; // not visible
    v3 = 0; // not visible
  } while (
      (v4 = v1 + /*unassigned*/ v2) == 0); // no break => v4 visible outside
  v1;
  /*unassigned*/ v3;
  v4;
}

continue_beforeAssignment(bool c) {
  late int v;
  do {
    if (c) continue;
    v = 0;
  } while (c);
  /*unassigned*/ v;
}
