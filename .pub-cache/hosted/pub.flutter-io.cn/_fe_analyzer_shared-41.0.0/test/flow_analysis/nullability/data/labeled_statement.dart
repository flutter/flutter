// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

block_break(int? x, bool c) {
  label:
  {
    if (x == null) {
      if (c) {
        break label;
      }
      return;
    }
  }
  x;
}

if_break(int? x, bool c) {
  label:
  if (true) {
    if (x == null) {
      if (c) {
        break label;
      }
      return;
    }
  }
  x;
}

try_break(int? x, bool c) {
  label:
  try {
    if (x == null) {
      if (c) {
        break label;
      }
      return;
    }
  } finally {}
  x;
}
