// Protocol Buffers - Google's data interchange format
// Copyright 2012 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
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

// from google3/base/stringprintf.cc

#include <google/protobuf/stubs/stringprintf.h>

#include <errno.h>
#include <stdarg.h> // For va_list and related operations
#include <stdio.h> // MSVC requires this for _vsnprintf
#include <vector>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/testing/googletest.h>

namespace google {
namespace protobuf {

#ifdef _MSC_VER
enum { IS_COMPILER_MSVC = 1 };
#ifndef va_copy
// Define va_copy for MSVC. This is a hack, assuming va_list is simply a
// pointer into the stack and is safe to copy.
#define va_copy(dest, src) ((dest) = (src))
#endif
#else
enum { IS_COMPILER_MSVC = 0 };
#endif

void StringAppendV(string* dst, const char* format, va_list ap) {
  // First try with a small fixed size buffer
  static const int kSpaceLength = 1024;
  char space[kSpaceLength];

  // It's possible for methods that use a va_list to invalidate
  // the data in it upon use.  The fix is to make a copy
  // of the structure before using it and use that copy instead.
  va_list backup_ap;
  va_copy(backup_ap, ap);
  int result = vsnprintf(space, kSpaceLength, format, backup_ap);
  va_end(backup_ap);

  if (result < kSpaceLength) {
    if (result >= 0) {
      // Normal case -- everything fit.
      dst->append(space, result);
      return;
    }

    if (IS_COMPILER_MSVC) {
      // Error or MSVC running out of space.  MSVC 8.0 and higher
      // can be asked about space needed with the special idiom below:
      va_copy(backup_ap, ap);
      result = vsnprintf(NULL, 0, format, backup_ap);
      va_end(backup_ap);
    }

    if (result < 0) {
      // Just an error.
      return;
    }
  }

  // Increase the buffer size to the size requested by vsnprintf,
  // plus one for the closing \0.
  int length = result+1;
  char* buf = new char[length];

  // Restore the va_list before we use it again
  va_copy(backup_ap, ap);
  result = vsnprintf(buf, length, format, backup_ap);
  va_end(backup_ap);

  if (result >= 0 && result < length) {
    // It fit
    dst->append(buf, result);
  }
  delete[] buf;
}


string StringPrintf(const char* format, ...) {
  va_list ap;
  va_start(ap, format);
  string result;
  StringAppendV(&result, format, ap);
  va_end(ap);
  return result;
}

const string& SStringPrintf(string* dst, const char* format, ...) {
  va_list ap;
  va_start(ap, format);
  dst->clear();
  StringAppendV(dst, format, ap);
  va_end(ap);
  return *dst;
}

void StringAppendF(string* dst, const char* format, ...) {
  va_list ap;
  va_start(ap, format);
  StringAppendV(dst, format, ap);
  va_end(ap);
}

// Max arguments supported by StringPrintVector
const int kStringPrintfVectorMaxArgs = 32;

// An empty block of zero for filler arguments.  This is const so that if
// printf tries to write to it (via %n) then the program gets a SIGSEGV
// and we can fix the problem or protect against an attack.
static const char string_printf_empty_block[256] = { '\0' };

string StringPrintfVector(const char* format, const vector<string>& v) {
  GOOGLE_CHECK_LE(v.size(), kStringPrintfVectorMaxArgs)
      << "StringPrintfVector currently only supports up to "
      << kStringPrintfVectorMaxArgs << " arguments. "
      << "Feel free to add support for more if you need it.";

  // Add filler arguments so that bogus format+args have a harder time
  // crashing the program, corrupting the program (%n),
  // or displaying random chunks of memory to users.

  const char* cstr[kStringPrintfVectorMaxArgs];
  for (int i = 0; i < v.size(); ++i) {
    cstr[i] = v[i].c_str();
  }
  for (int i = v.size(); i < GOOGLE_ARRAYSIZE(cstr); ++i) {
    cstr[i] = &string_printf_empty_block[0];
  }

  // I do not know any way to pass kStringPrintfVectorMaxArgs arguments,
  // or any way to build a va_list by hand, or any API for printf
  // that accepts an array of arguments.  The best I can do is stick
  // this COMPILE_ASSERT right next to the actual statement.

  GOOGLE_COMPILE_ASSERT(kStringPrintfVectorMaxArgs == 32, arg_count_mismatch);
  return StringPrintf(format,
                      cstr[0], cstr[1], cstr[2], cstr[3], cstr[4],
                      cstr[5], cstr[6], cstr[7], cstr[8], cstr[9],
                      cstr[10], cstr[11], cstr[12], cstr[13], cstr[14],
                      cstr[15], cstr[16], cstr[17], cstr[18], cstr[19],
                      cstr[20], cstr[21], cstr[22], cstr[23], cstr[24],
                      cstr[25], cstr[26], cstr[27], cstr[28], cstr[29],
                      cstr[30], cstr[31]);
}
}  // namespace protobuf
}  // namespace google
