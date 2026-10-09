// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A C translation unit, so the smoke test also exercises the C compiler
// configuration (the engine has C dependencies such as zlib and ICU's C
// sources).

#include <inttypes.h>
#include <stdio.h>

int FlutterBazelSmokeAddFromC(int a, int b);

int FlutterBazelSmokeAddFromC(int a, int b) {
  char buffer[32];
  int written = snprintf(buffer, sizeof(buffer), "%" PRId32, (int32_t)(a + b));
  return written > 0 ? a + b : 0;
}
