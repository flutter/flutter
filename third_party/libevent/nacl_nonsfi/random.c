/* Copyright 2014 The Chromium Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

#include <stdlib.h>

/* The newlib-based PNaCl toolchain does not provide random(). So, here we
 * define it. It just redirects to the rand(), which is provided by the
 * toolchain. */
long int random() {
  return rand();
}
