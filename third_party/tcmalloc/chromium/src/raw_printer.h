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
// Author: Sanjay Ghemawat
//
// A printf() wrapper that writes into a fixed length buffer.
// Useful in low-level code that does not want to use allocating
// routines like StringPrintf().
//
// The implementation currently uses vsnprintf().  This seems to
// be fine for use in many low-level contexts, but we may need to
// rethink this decision if we hit a problem with it calling
// down into malloc() etc.

#ifndef BASE_RAW_PRINTER_H_
#define BASE_RAW_PRINTER_H_

#include <config.h>
#include "base/basictypes.h"

namespace base {

class RawPrinter {
 public:
  // REQUIRES: "length > 0"
  // Will printf any data added to this into "buf[0,length-1]" and
  // will arrange to always keep buf[] null-terminated.
  RawPrinter(char* buf, int length);

  // Return the number of bytes that have been appended to the string
  // so far.  Does not count any bytes that were dropped due to overflow.
  int length() const { return (ptr_ - base_); }

  // Return the number of bytes that can be added to this.
  int space_left() const { return (limit_ - ptr_); }

  // Format the supplied arguments according to the "format" string
  // and append to this.  Will silently truncate the output if it does
  // not fit.
  void Printf(const char* format, ...)
#ifdef HAVE___ATTRIBUTE__
  __attribute__ ((__format__ (__printf__, 2, 3)))
#endif
;

 private:
  // We can write into [ptr_ .. limit_-1].
  // *limit_ is also writable, but reserved for a terminating \0
  // in case we overflow.
  //
  // Invariants: *ptr_ == \0
  // Invariants: *limit_ == \0
  char* base_;          // Initial pointer
  char* ptr_;           // Where should we write next
  char* limit_;         // One past last non-\0 char we can write

  DISALLOW_COPY_AND_ASSIGN(RawPrinter);
};

}

#endif  // BASE_RAW_PRINTER_H_
