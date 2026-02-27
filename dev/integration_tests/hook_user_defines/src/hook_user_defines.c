// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "hook_user_defines.h"

FFI_PLUGIN_EXPORT intptr_t sum(intptr_t a, intptr_t b) {
  return a + b + MAGIC_VALUE;
}
