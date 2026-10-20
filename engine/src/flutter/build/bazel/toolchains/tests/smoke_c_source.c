// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A C translation unit, so the smoke test also exercises the C compiler
// configuration (the engine has C dependencies such as zlib and ICU's C
// sources): the sysroot's C headers and a call into its libc.

#include <inttypes.h>
#include <string.h>

int FlutterBazelSmokeAddFromC(int a, int b);

int FlutterBazelSmokeAddFromC(int a, int b) {
  // The string depends on the arguments, so the call is not folded away.
  const char* word = a > b ? "sysroot" : "libc";
  const int32_t sum = (int32_t)a + (int32_t)b;
  return strlen(word) > 0 ? (int)sum : 0;
}
