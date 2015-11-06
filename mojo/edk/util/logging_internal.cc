// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/util/mutex.h"

#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

namespace mojo {
namespace util {
namespace internal {

void DcheckHelper(const char* file, int line, const char* condition_string) {
  fprintf(stderr, "%s:%d: Check failed: %s\n", file, line, condition_string);
  abort();
}

void DcheckWithErrnoHelper(const char* file,
                           int line,
                           const char* fn,
                           int error) {
  fprintf(stderr, "%s:%d: %s: %s\n", file, line, fn, strerror(error));
  abort();
}

}  // namespace internal
}  // namespace util
}  // namespace mojo

#endif  // !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
