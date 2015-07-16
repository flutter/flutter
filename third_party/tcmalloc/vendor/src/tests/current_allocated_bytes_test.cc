// Copyright (c) 2011, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ---
//
// Author: Craig Silverstein

// This tests the accounting done by tcmalloc.  When we allocate and
// free a small buffer, the number of bytes used by the application
// before the alloc+free should match the number of bytes used after.
// However, the internal data structures used by tcmalloc will be
// quite different -- new spans will have been allocated, etc.  This
// is, thus, a simple test that we account properly for the internal
// data structures, so that we report the actual application-used
// bytes properly.

#include "config_for_unittests.h"
#include <stdlib.h>
#include <stdio.h>
#include <gperftools/malloc_extension.h>
#include "base/logging.h"

const char kCurrent[] = "generic.current_allocated_bytes";

int main() {
  // We don't do accounting right when using debugallocation.cc, so
  // turn off the test then.  TODO(csilvers): get this working too.
#ifdef NDEBUG
  size_t before_bytes, after_bytes;
  MallocExtension::instance()->GetNumericProperty(kCurrent, &before_bytes);
  free(malloc(200));
  MallocExtension::instance()->GetNumericProperty(kCurrent, &after_bytes);

  CHECK_EQ(before_bytes, after_bytes);
#endif
  printf("PASS\n");
  return 0;
}
