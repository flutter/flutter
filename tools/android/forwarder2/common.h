// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Common helper functions/classes used both in the host and device forwarder.

#ifndef TOOLS_ANDROID_FORWARDER2_COMMON_H_
#define TOOLS_ANDROID_FORWARDER2_COMMON_H_

#include <stdarg.h>
#include <stdio.h>
#include <errno.h>

#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/logging.h"
#include "base/posix/eintr_wrapper.h"

// Preserving errno for Close() is important because the function is very often
// used in cleanup code, after an error occurred, and it is very easy to pass an
// invalid file descriptor to close() in this context, or more rarely, a
// spurious signal might make close() return -1 + setting errno to EINTR,
// masking the real reason for the original error. This leads to very unpleasant
// debugging sessions.
#define PRESERVE_ERRNO_HANDLE_EINTR(Func)                     \
  do {                                                        \
    int local_errno = errno;                                  \
    (void) HANDLE_EINTR(Func);                                \
    errno = local_errno;                                      \
  } while (false);

// Wrapper around RAW_LOG() which is signal-safe. The only purpose of this macro
// is to avoid documenting uses of RawLog().
#define SIGNAL_SAFE_LOG(Level, Msg) \
  RAW_LOG(Level, Msg);

namespace forwarder2 {

// Note that the two following functions are not signal-safe.

// Chromium logging-aware implementation of libc's perror().
void PError(const char* msg);

// Closes the provided file descriptor and logs an error if it failed.
void CloseFD(int fd);

// Helps build a formatted C-string allocated in a fixed-size array. This is
// useful in signal handlers where base::StringPrintf() can't be used safely
// (due to its use of LOG()).
template <int BufferSize>
class FixedSizeStringBuilder {
 public:
  FixedSizeStringBuilder() {
    Reset();
  }

  const char* buffer() const { return buffer_; }

  void Reset() {
    buffer_[0] = 0;
    write_ptr_ = buffer_;
  }

  // Returns the number of bytes appended to the underlying buffer or -1 if it
  // failed.
  int Append(const char* format, ...) PRINTF_FORMAT(/* + 1 for 'this' */ 2, 3) {
    if (write_ptr_ >= buffer_ + BufferSize)
      return -1;
    va_list ap;
    va_start(ap, format);
    const int bytes_written = vsnprintf(
        write_ptr_, BufferSize - (write_ptr_ - buffer_), format, ap);
    va_end(ap);
    if (bytes_written > 0)
      write_ptr_ += bytes_written;
    return bytes_written;
  }

 private:
  char* write_ptr_;
  char buffer_[BufferSize];

  static_assert(BufferSize >= 1, "size of buffer must be at least one");
  DISALLOW_COPY_AND_ASSIGN(FixedSizeStringBuilder);
};

}  // namespace forwarder2

#endif  // TOOLS_ANDROID_FORWARDER2_COMMON_H_
