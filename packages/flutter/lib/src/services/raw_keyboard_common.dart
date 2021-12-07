// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


/// Converts upper letters to lower letters in ASCII and extended ASCII, and
/// returns as-is otherwise.
///
/// Independent of locale.
int toLower(int n) {
  const int lowerA = 0x61;
  const int upperA = 0x41;
  const int upperZ = 0x5a;

  const int lowerAGrave = 0xe0;
  const int upperAGrave = 0xc0;
  const int upperThorn = 0xde;
  const int division = 0xf7;

  // ASCII range.
  if (n >= upperA && n <= upperZ) {
    return n - upperA + lowerA;
  }

  // EASCII range.
  if (n >= upperAGrave && n <= upperThorn && n != division) {
    return n - upperAGrave + lowerAGrave;
  }

  return n;
}
