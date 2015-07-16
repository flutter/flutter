// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "malloc_wrapper.h"

#include <stdlib.h>

void* MallocWrapper(size_t size) {
  return malloc(size);
}
