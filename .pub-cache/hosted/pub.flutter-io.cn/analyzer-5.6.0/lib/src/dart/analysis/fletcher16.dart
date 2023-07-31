// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int fletcher16(List<int> data) {
  int c0;
  int c1;

  int index = data.length;

  for (c0 = c1 = 0; index >= 5802; index -= 5802) {
    for (int i = 0; i < 5802; ++i) {
      c0 = c0 + data[index - i - 1];
      c1 = c1 + c0;
    }
    c0 = c0 % 255;
    c1 = c1 % 255;
  }

  for (int i = 0; i < index; ++i) {
    c0 = c0 + data[i];
    c1 = c1 + c0;
  }

  c0 = c0 % 255;
  c1 = c1 % 255;

  return c1 << 8 | c0;
}
