// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/abort.h"

#include "base/basictypes.h"

namespace tcmalloc {

// Try not to inline so we can find Abort() call from stack trace.
ATTRIBUTE_NOINLINE void Abort() {
  // Make a segmentation fault to force abort. Writing to a specific address
  // so it's easier to find on crash stacks.
  *(reinterpret_cast<volatile char*>(NULL) + 57) = 0x21;
}

} // namespace tcmalloc
