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
// Sanjay Ghemawat <opensource@google.com>

#include <config.h>
#include "internal_logging.h"
#include <stdarg.h>                     // for va_end, va_start
#include <stdio.h>                      // for vsnprintf, va_list, etc
#include <stdlib.h>                     // for abort
#include <string.h>                     // for strlen, memcpy
#ifdef HAVE_UNISTD_H
#include <unistd.h>    // for write()
#endif

#include <gperftools/malloc_extension.h>
#include "base/abort.h"
#include "base/logging.h"   // for perftools_vsnprintf
#include "base/spinlock.h"              // for SpinLockHolder, SpinLock

static const int kLogBufSize = 800;

// Variables for storing crash output.  Allocated statically since we
// may not be able to heap-allocate while crashing.
static SpinLock crash_lock(base::LINKER_INITIALIZED);
static bool crashed = false;
static const int kStatsBufferSize = 16 << 10;
static char stats_buffer[kStatsBufferSize] = { 0 };

namespace tcmalloc {

static void WriteMessage(const char* msg, int length) {
  write(STDERR_FILENO, msg, length);
}

void (*log_message_writer)(const char* msg, int length) = WriteMessage;


class Logger {
 public:
  bool Add(const LogItem& item);
  bool AddStr(const char* str, int n);
  bool AddNum(uint64_t num, int base);  // base must be 10 or 16.

  static const int kBufSize = 200;
  char* p_;
  char* end_;
  char buf_[kBufSize];
};

void Log(LogMode mode, const char* filename, int line,
         LogItem a, LogItem b, LogItem c, LogItem d) {
  Logger state;
  state.p_ = state.buf_;
  state.end_ = state.buf_ + sizeof(state.buf_);
  state.AddStr(filename, strlen(filename))
      && state.AddStr(":", 1)
      && state.AddNum(line, 10)
      && state.AddStr("]", 1)
      && state.Add(a)
      && state.Add(b)
      && state.Add(c)
      && state.Add(d);

  // Teminate with newline
  if (state.p_ >= state.end_) {
    state.p_ = state.end_ - 1;
  }
  *state.p_ = '\n';
  state.p_++;

  int msglen = state.p_ - state.buf_;
  if (mode == kLog) {
    (*log_message_writer)(state.buf_, msglen);
    return;
  }

  bool first_crash = false;
  {
    SpinLockHolder l(&crash_lock);
    if (!crashed) {
      crashed = true;
      first_crash = true;
    }
  }

  (*log_message_writer)(state.buf_, msglen);
  if (first_crash && mode == kCrashWithStats) {
    MallocExtension::instance()->GetStats(stats_buffer, kStatsBufferSize);
    (*log_message_writer)(stats_buffer, strlen(stats_buffer));
  }

  Abort();
}

bool Logger::Add(const LogItem& item) {
  // Separate items with spaces
  if (p_ < end_) {
    *p_ = ' ';
    p_++;
  }

  switch (item.tag_) {
    case LogItem::kStr:
      return AddStr(item.u_.str, strlen(item.u_.str));
    case LogItem::kUnsigned:
      return AddNum(item.u_.unum, 10);
    case LogItem::kSigned:
      if (item.u_.snum < 0) {
        // The cast to uint64_t is intentionally before the negation
        // so that we do not attempt to negate -2^63.
        return AddStr("-", 1)
            && AddNum(- static_cast<uint64_t>(item.u_.snum), 10);
      } else {
        return AddNum(static_cast<uint64_t>(item.u_.snum), 10);
      }
    case LogItem::kPtr:
      return AddStr("0x", 2)
          && AddNum(reinterpret_cast<uintptr_t>(item.u_.ptr), 16);
    default:
      return false;
  }
}

bool Logger::AddStr(const char* str, int n) {
  if (end_ - p_ < n) {
    return false;
  } else {
    memcpy(p_, str, n);
    p_ += n;
    return true;
  }
}

bool Logger::AddNum(uint64_t num, int base) {
  static const char kDigits[] = "0123456789abcdef";
  char space[22];  // more than enough for 2^64 in smallest supported base (10)
  char* end = space + sizeof(space);
  char* pos = end;
  do {
    pos--;
    *pos = kDigits[num % base];
    num /= base;
  } while (num > 0 && pos > space);
  return AddStr(pos, end - pos);
}

}  // end tcmalloc namespace

void TCMalloc_Printer::printf(const char* format, ...) {
  if (left_ > 0) {
    va_list ap;
    va_start(ap, format);
    const int r = perftools_vsnprintf(buf_, left_, format, ap);
    va_end(ap);
    if (r < 0) {
      // Perhaps an old glibc that returns -1 on truncation?
      left_ = 0;
    } else if (r > left_) {
      // Truncation
      left_ = 0;
    } else {
      left_ -= r;
      buf_ += r;
    }
  }
}
