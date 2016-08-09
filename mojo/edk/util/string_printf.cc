// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/util/string_printf.h"

#include <assert.h>
#include <errno.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>

#include <memory>

namespace mojo {
namespace util {
namespace {

void StringVAppendfHelper(std::string* dest, const char* format, va_list ap) {
  // Size of the small stack buffer to use first. This should be kept in sync
  // with the numbers in StringPrintfTest.StringPrintf_Boundary.
  constexpr size_t kStackBufferSize = 1024u;

  // First, try with a small buffer on the stack.
  char stack_buf[kStackBufferSize];
  // Copy |ap| (which can only be used once), in case we need to retry.
  va_list ap_copy;
  va_copy(ap_copy, ap);
  int result = vsnprintf(stack_buf, kStackBufferSize, format, ap_copy);
  va_end(ap_copy);
  if (result < 0) {
    // As far as I can tell, we'd only get |EOVERFLOW| if the result is so large
    // that it can't be represented by an |int| (in which case retrying would be
    // futile), so Chromium's implementation is wrong.
    return;
  }
  // |result| should be the number of characters we need, not including the
  // terminating null. However, |vsnprintf()| always null-terminates!
  size_t output_size = static_cast<size_t>(result);
  // Check if the output fit into our stack buffer. This is "<" not "<=", since
  // |vsnprintf()| will null-terminate.
  if (output_size < kStackBufferSize) {
    // It fit.
    dest->append(stack_buf, static_cast<size_t>(result));
    return;
  }

  // Since we have the required output size, we can just heap allocate that.
  // (Add 1 because |vsnprintf()| will always null-terminate.)
  size_t heap_buf_size = output_size + 1u;
  std::unique_ptr<char[]> heap_buf(new char[heap_buf_size]);
  result = vsnprintf(heap_buf.get(), heap_buf_size, format, ap);
  if (result < 0 || static_cast<size_t>(result) > output_size) {
    assert(false);
    return;
  }
  assert(static_cast<size_t>(result) == output_size);
  dest->append(heap_buf.get(), static_cast<size_t>(result));
}

}  // namespace

std::string StringPrintf(const char* format, ...) {
  va_list ap;
  va_start(ap, format);
  std::string rv;
  StringVAppendf(&rv, format, ap);
  va_end(ap);
  return rv;
}

std::string StringVPrintf(const char* format, va_list ap) {
  std::string rv;
  StringVAppendf(&rv, format, ap);
  return rv;
}

void StringAppendf(std::string* dest, const char* format, ...) {
  va_list ap;
  va_start(ap, format);
  StringVAppendf(dest, format, ap);
  va_end(ap);
}

void StringVAppendf(std::string* dest, const char* format, va_list ap) {
  int old_errno = errno;
  StringVAppendfHelper(dest, format, ap);
  errno = old_errno;
}

}  // namespace util
}  // namespace mojo
