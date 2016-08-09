// Copyright (c) 2005, Google Inc.
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
// Author: Sanjay Ghemawat <opensource@google.com>
//
// Internal logging and related utility routines.

#ifndef TCMALLOC_INTERNAL_LOGGING_H_
#define TCMALLOC_INTERNAL_LOGGING_H_

#include <config.h>
#include <stddef.h>                     // for size_t
#if defined HAVE_STDINT_H
#include <stdint.h>
#elif defined HAVE_INTTYPES_H
#include <inttypes.h>
#else
#include <sys/types.h>
#endif

//-------------------------------------------------------------------
// Utility routines
//-------------------------------------------------------------------

// Safe logging helper: we write directly to the stderr file
// descriptor and avoid FILE buffering because that may invoke
// malloc().
//
// Example:
//   Log(kLog, __FILE__, __LINE__, "error", bytes);

namespace tcmalloc {
enum LogMode {
  kLog,                       // Just print the message
  kCrash,                     // Print the message and crash
  kCrashWithStats             // Print the message, some stats, and crash
};

class Logger;

// A LogItem holds any of the argument types that can be passed to Log()
class LogItem {
 public:
  LogItem()                     : tag_(kEnd)      { }
  LogItem(const char* v)        : tag_(kStr)      { u_.str = v; }
  LogItem(int v)                : tag_(kSigned)   { u_.snum = v; }
  LogItem(long v)               : tag_(kSigned)   { u_.snum = v; }
  LogItem(long long v)          : tag_(kSigned)   { u_.snum = v; }
  LogItem(unsigned int v)       : tag_(kUnsigned) { u_.unum = v; }
  LogItem(unsigned long v)      : tag_(kUnsigned) { u_.unum = v; }
  LogItem(unsigned long long v) : tag_(kUnsigned) { u_.unum = v; }
  LogItem(const void* v)        : tag_(kPtr)      { u_.ptr = v; }
 private:
  friend class Logger;
  enum Tag {
    kStr,
    kSigned,
    kUnsigned,
    kPtr,
    kEnd
  };
  Tag tag_;
  union {
    const char* str;
    const void* ptr;
    int64_t snum;
    uint64_t unum;
  } u_;
};

extern PERFTOOLS_DLL_DECL void Log(LogMode mode, const char* filename, int line,
                LogItem a, LogItem b = LogItem(),
                LogItem c = LogItem(), LogItem d = LogItem());

// Tests can override this function to collect logging messages.
extern PERFTOOLS_DLL_DECL void (*log_message_writer)(const char* msg, int length);

}  // end tcmalloc namespace

// Like assert(), but executed even in NDEBUG mode
#undef CHECK_CONDITION
#define CHECK_CONDITION(cond)                                            \
do {                                                                     \
  if (!(cond)) {                                                         \
    ::tcmalloc::Log(::tcmalloc::kCrash, __FILE__, __LINE__, #cond);      \
  }                                                                      \
} while (0)

#define CHECK_CONDITION_PRINT(cond, str)                                 \
do {                                                                     \
  if (!(cond)) {                                                         \
    ::tcmalloc::Log(::tcmalloc::kCrash, __FILE__, __LINE__, str);        \
  }                                                                      \
} while (0)

// Our own version of assert() so we can avoid hanging by trying to do
// all kinds of goofy printing while holding the malloc lock.
#ifndef NDEBUG
#define ASSERT(cond) CHECK_CONDITION(cond)
#define ASSERT_PRINT(cond, str) CHECK_CONDITION_PRINT(cond, str)
#else
#define ASSERT(cond) ((void) 0)
#define ASSERT_PRINT(cond, str) ((void) 0)
#endif

// Print into buffer
class TCMalloc_Printer {
 private:
  char* buf_;           // Where should we write next
  int   left_;          // Space left in buffer (including space for \0)

 public:
  // REQUIRES: "length > 0"
  TCMalloc_Printer(char* buf, int length) : buf_(buf), left_(length) {
    buf[0] = '\0';
  }

  void printf(const char* format, ...)
#ifdef HAVE___ATTRIBUTE__
    __attribute__ ((__format__ (__printf__, 2, 3)))
#endif
;
};

#endif  // TCMALLOC_INTERNAL_LOGGING_H_
