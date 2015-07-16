// Copyright (c) 2008, Google Inc.
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
// Author: sanjay@google.com (Sanjay Ghemawat)

#include <config.h>
#include <stdarg.h>
#include <stdio.h>
#include "raw_printer.h"
#include "base/logging.h"

namespace base {

RawPrinter::RawPrinter(char* buf, int length)
    : base_(buf),
      ptr_(buf),
      limit_(buf + length - 1) {
  RAW_DCHECK(length > 0, "");
  *ptr_ = '\0';
  *limit_ = '\0';
}

void RawPrinter::Printf(const char* format, ...) {
  if (limit_ > ptr_) {
    va_list ap;
    va_start(ap, format);
    int avail = limit_ - ptr_;
    // We pass avail+1 to vsnprintf() since that routine needs room
    // to store the trailing \0.
    const int r = perftools_vsnprintf(ptr_, avail+1, format, ap);
    va_end(ap);
    if (r < 0) {
      // Perhaps an old glibc that returns -1 on truncation?
      ptr_ = limit_;
    } else if (r > avail) {
      // Truncation
      ptr_ = limit_;
    } else {
      ptr_ += r;
    }
  }
}

}
