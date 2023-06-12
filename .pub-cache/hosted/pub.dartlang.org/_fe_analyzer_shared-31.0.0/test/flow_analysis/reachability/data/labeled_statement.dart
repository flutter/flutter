// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

block_break(bool b) {
  label:
  {
    if (b) {
      break label;
    }
    return;
  }
  1;
}

if_break(bool b) {
  label:
  if (true) {
    if (b) {
      break label;
    }
    return;
  }
  1;
}

try_break(bool b) {
  label:
  try {
    if (b) {
      break label;
    }
    return;
  } finally {
    1;
  }
  2;
}
