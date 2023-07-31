// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

block_break(bool c) {
  late int v;
  label:
  {
    if (c) {
      break label;
    }
    v = 0;
    return;
  }
  /*unassigned*/ v;
}

if_break(bool c) {
  late int v;
  label:
  if (c) {
    if (c) {
      break label;
    }
    v = 0;
    return;
  }
  /*unassigned*/ v;
}

try_break(bool c) {
  late int v;
  label:
  try {
    if (c) {
      break label;
    }
    v = 0;
    return;
  } finally {}
  /*unassigned*/ v;
}
