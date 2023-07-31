// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

for_body(bool c) {
  late int v;
  for (; c;) {
    v = 0;
  }
  /*unassigned*/ v;
}

for_break(bool c) {
  late int v1, v2;
  for (; c;) {
    v1 = 0;
    if (c) break;
    v2 = 0;
  }
  /*unassigned*/ v1;
  /*unassigned*/ v2;
}

for_break_updaters(bool c) {
  late int v1, v2;
  for (; c; v1 + v2) {
    v1 = 0;
    if (c) break;
    v2 = 0;
  }
}

for_condition() {
  late int v;
  for (; (v = 0) >= 0;) {
    v;
  }
  v;
}

for_continue(bool c) {
  late int v1, v2;
  for (; c;) {
    v1 = 0;
    if (c) continue;
    v2 = 0;
  }
  /*unassigned*/ v1;
  /*unassigned*/ v2;
}

for_continue_updaters(bool c) {
  late int v1, v2;
  for (; c; v1 + /*unassigned*/ v2) {
    v1 = 0;
    if (c) continue;
    v2 = 0;
  }
}

for_initializer_expression() {
  late int v;
  for (v = 0;;) {
    v;
  }
  v;
}

for_initializer_variable() {
  late int v;
  for (var t = (v = 0);;) {
    v;
  }
  v;
}

for_updaters(bool c) {
  late int v1, v2, v3, v4;
  for (; c; v1 = 0, v2 = 0, v3 = 0, /*unassigned*/ v4) {
    /*unassigned*/ v1;
  }
  /*unassigned*/ v2;
}

for_updaters_afterBody(bool c) {
  late int v;
  for (; c; v) {
    v = 0;
  }
}

collection_for_body(bool c) {
  late int v;
  [for (; c;) (v = 0)];
  /*unassigned*/ v;
}

collection_for_condition() {
  late int v;
  [for (; (v = 0) >= 0;) null];
  v;
}

collection_for_initializer_expression() {
  late int v;
  [for (v = 0;;) v];
  v;
}

collection_for_initializer_variable() {
  late int v;
  [for (var t = (v = 0);;) v];
  v;
}

collection_for_updaters(bool c) {
  late int v1, v2, v3, v4;
  [for (; c; v1 = 0, v2 = 0, v3 = 0, /*unassigned*/ v4) /*unassigned*/ v1 ];
  /*unassigned*/ v2;
}

collection_for_updaters_afterBody(bool c) {
  late int v;
  [for (; c; v) (v = 0)];
}
