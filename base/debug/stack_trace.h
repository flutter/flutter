// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_DEBUG_STACK_TRACE_H_
#define BASE_DEBUG_STACK_TRACE_H_

#include <iosfwd>
#include <string>

#include "base/base_export.h"
#include "build/build_config.h"

#if defined(OS_POSIX)
#include <unistd.h>
#endif

#if defined(OS_WIN)
struct _EXCEPTION_POINTERS;
struct _CONTEXT;
#endif

namespace base {
namespace debug {

// Enables stack dump to console output on exception and signals.
// When enabled, the process will quit immediately. This is meant to be used in
// unit_tests only! This is not thread-safe: only call from main thread.
BASE_EXPORT bool EnableInProcessStackDumping();

// A different version of EnableInProcessStackDumping that also works for
// sandboxed processes.  For more details take a look at the description
// of EnableInProcessStackDumping.
// Calling this function on Linux opens /proc/self/maps and caches its
// contents. In DEBUG builds, this function also opens the object files that
// are loaded in memory and caches their file descriptors (this cannot be
// done in official builds because it has security implications).
BASE_EXPORT bool EnableInProcessStackDumpingForSandbox();

// A stacktrace can be helpful in debugging. For example, you can include a
// stacktrace member in a object (probably around #ifndef NDEBUG) so that you
// can later see where the given object was created from.
class BASE_EXPORT StackTrace {
 public:
  // Creates a stacktrace from the current location.
  StackTrace();

  // Creates a stacktrace from an existing array of instruction
  // pointers (such as returned by Addresses()).  |count| will be
  // trimmed to |kMaxTraces|.
  StackTrace(const void* const* trace, size_t count);

#if defined(OS_WIN)
  // Creates a stacktrace for an exception.
  // Note: this function will throw an import not found (StackWalk64) exception
  // on system without dbghelp 5.1.
  StackTrace(const _EXCEPTION_POINTERS* exception_pointers);
  StackTrace(const _CONTEXT* context);
#endif

  // Copying and assignment are allowed with the default functions.

  ~StackTrace();

  // Gets an array of instruction pointer values. |*count| will be set to the
  // number of elements in the returned array.
  const void* const* Addresses(size_t* count) const;

  // Prints the stack trace to stderr.
  void Print() const;

#if !defined(__UCLIBC__)
  // Resolves backtrace to symbols and write to stream.
  void OutputToStream(std::ostream* os) const;
#endif

  // Resolves backtrace to symbols and returns as string.
  std::string ToString() const;

 private:
#if defined(OS_WIN)
  void InitTrace(_CONTEXT* context_record);
#endif

  // From http://msdn.microsoft.com/en-us/library/bb204633.aspx,
  // the sum of FramesToSkip and FramesToCapture must be less than 63,
  // so set it to 62. Even if on POSIX it could be a larger value, it usually
  // doesn't give much more information.
  static const int kMaxTraces = 62;

  void* trace_[kMaxTraces];

  // The number of valid frames in |trace_|.
  size_t count_;
};

namespace internal {

#if defined(OS_POSIX) && !defined(OS_ANDROID)
// POSIX doesn't define any async-signal safe function for converting
// an integer to ASCII. We'll have to define our own version.
// itoa_r() converts a (signed) integer to ASCII. It returns "buf", if the
// conversion was successful or NULL otherwise. It never writes more than "sz"
// bytes. Output will be truncated as needed, and a NUL character is always
// appended.
BASE_EXPORT char *itoa_r(intptr_t i,
                         char *buf,
                         size_t sz,
                         int base,
                         size_t padding);
#endif  // defined(OS_POSIX) && !defined(OS_ANDROID)

}  // namespace internal

}  // namespace debug
}  // namespace base

#endif  // BASE_DEBUG_STACK_TRACE_H_
