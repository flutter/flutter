// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

forEach() {
  late Object v1, v2;
  for (var _ in (v1 = [0, 1, 2])) {
    v2 = 0;
  }
  v1;
  /*unassigned*/ v2;
}

forEach_break(bool c) {
  late int v1, v2;
  for (var _ in [0, 1, 2]) {
    v1 = 0;
    if (c) break;
    v2 = 0;
  }
  /*unassigned*/ v1;
  /*unassigned*/ v2;
}

forEach_continue(bool c) {
  late int v1, v2;
  for (var _ in [0, 1, 2]) {
    v1 = 0;
    if (c) continue;
    v2 = 0;
  }
  /*unassigned*/ v1;
  /*unassigned*/ v2;
}

forEach_assigns_to_identifier() {
  late int i;
  for (i in [0, 1, 2]) {
    i;
  }
  /*unassigned*/ i;
}

forEach_assigns_to_declared_var() {
  for (int i in [0, 1, 2]) {
    i;
  }
}

collection_forEach() {
  late Object v1, v2;
  [
    for (var _ in (v1 = [0, 1, 2])) (v2 = 0)
  ];
  v1;
  /*unassigned*/ v2;
}

collection_forEach_assigns_to_identifier() {
  late int i;
  [
    for (i in [0, 1, 2]) i
  ];
  /*unassigned*/ i;
}

collection_forEach_assigns_to_declared_var() {
  [
    for (int i in [0, 1, 2]) i
  ];
}
