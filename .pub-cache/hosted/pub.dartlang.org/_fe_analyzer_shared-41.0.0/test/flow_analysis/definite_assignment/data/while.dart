// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

condition() {
  late int v;
  while ((v = 0) >= 0) {
    v;
  }
  v;
}

condition_notTrue(bool c) {
  late int v1, v2;
  while (c) {
    v1 = 0;
    v2 = 0;
    v1;
  }
  /*unassigned*/ v2;
}

true_break_afterAssignment(bool c) {
  late int v1, v2;
  while (true) {
    v1 = 0;
    v1;
    if (c) break;
    v1;
    v2 = 0;
    v2;
  }
  v1;
}

true_break_beforeAssignment(bool c) {
  late int v1, v2;
  while (true) {
    if (c) break;
    v1 = 0;
    v2 = 0;
    v2;
  }
  /*unassigned*/ v1;
}

true_break_if(bool c) {
  late int v;
  while (true) {
    if (c) {
      v = 0;
      break;
    } else {
      v = 0;
      break;
    }
    v;
  }
  v;
}

true_break_if2(bool c) {
  late Object v;
  while (true) {
    if (c) {
      break;
    } else {
      v = 0;
    }
    v;
  }
}

true_break_if3(bool c) {
  late int v1, v2;
  while (true) {
    if (c) {
      v1 = 0;
      v2 = 0;
      if (c) break;
    } else {
      if (c) break;
      v1 = 0;
      v2 = 0;
    }
    v1;
  }
  /*unassigned*/ v2;
}

true_breakOuterFromInner(bool c) {
  late int v1, v2, v3;
  L1:
  while (true) {
    L2:
    while (true) {
      v1 = 0;
      if (c) break L1;
      v2 = 0;
      v3 = 0;
      if (c) break L2;
    }
    v2;
  }
  v1;
  /*unassigned*/ v3;
}

true_continue(bool c) {
  late int v;
  while (true) {
    if (c) continue;
    v = 0;
  }
  /*unassigned*/ v;
}

true_noBreak(bool c) {
  late int v;
  while (true) {
    // No assignment, but not break.
    // So, we don't exit the loop.
  }
  /*unassigned*/ v;
}
