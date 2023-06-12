// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

forEach() {
  late Object v1, v2;
  for (var _ in (v1 = [0, 1, 2])) {
    v2 = 0;
  }
  v1;
  v2;
}

forEach_break(bool c) {
  late int v1, v2;
  for (var _ in [0, 1, 2]) {
    v1 = 0;
    if (c) break;
    v2 = 0;
  }
  v1;
  v2;
}

forEach_continue(bool c) {
  late int v1, v2;
  for (var _ in [0, 1, 2]) {
    v1 = 0;
    if (c) continue;
    v2 = 0;
  }
  v1;
  v2;
}

forEach_assigns_to_identifier() {
  late int i;
  for (i in [0, 1, 2]) {
    i;
  }
  i;
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
  v2;
}

collection_forEach_assigns_to_identifier() {
  late int i;
  [
    for (i in [0, 1, 2]) i
  ];
  i;
}

collection_forEach_assigns_to_declared_var() {
  [
    for (int i in [0, 1, 2]) i
  ];
}

forEach_contains_unreachable_assignment() {
  late Object v1;
  for (var _ in [0, 1, 2]) {
    break;
    v1 = 0;
  }
  // v1 is considered potentially assigned here, for consistency with how we
  // would analyze the equivalent desugared loop.
  v1;
}
