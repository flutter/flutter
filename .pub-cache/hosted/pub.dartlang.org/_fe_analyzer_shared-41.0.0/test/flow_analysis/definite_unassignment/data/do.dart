// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
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
  v;
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
  v3;
}

condition() {
  late int v1, v2;
  do {
    v1;
  } while ((v1 = 0) + (v2 = 0) >= 0);
  v2;
}

condition_break(bool c) {
  late int v;
  do {
    if (c) break;
  } while ((v = 0) >= 0);
  v;
}

condition_break_continue(bool c1, bool c2) {
  late int v1, v2, v3, v4, v5, v6;
  do {
    v1 = 0;
    if (c1) break;
    v2 = 0;
    v3 = 0;
    if (c2) continue;
    v4 = 0;
    v5 = 0;
  } while ((v6 = v1 + v2 + v4) == 0);
  v1;
  v3;
  v5;
  v6;
}

condition_continue(bool c) {
  late int v1, v2, v3, v4;
  do {
    v1 = 0;
    if (c) continue;
    v2 = 0;
    v3 = 0;
  } while ((v4 = v1 + v2) == 0);
  v1;
  v3;
  v4;
}

continue_beforeAssignment(bool c) {
  late int v;
  do {
    if (c) continue;
    v = 0;
  } while (c);
  v;
}
