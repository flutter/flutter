// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_STRINGS_SAFE_SPRINTF_H_
#define BASE_STRINGS_SAFE_SPRINTF_H_

#include "build/build_config.h"

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#if defined(OS_POSIX)
// For ssize_t
#include <unistd.h>
#endif

#include "base/base_export.h"
#include "base/basictypes.h"

namespace base {
namespace strings {

#if defined(_MSC_VER)
// Define ssize_t inside of our namespace.
#if defined(_WIN64)
typedef __int64 ssize_t;
#else
typedef long ssize_t;
#endif
#endif

// SafeSPrintf() is a type-safe and completely self-contained version of
// snprintf().
//
// SafeSNPrintf() is an alternative function signature that can be used when
// not dealing with fixed-sized buffers. When possible, SafeSPrintf() should
// always be used instead of SafeSNPrintf()
//
// These functions allow for formatting complicated messages from contexts that
// require strict async-signal-safety. In fact, it is safe to call them from
// any low-level execution context, as they are guaranteed to make no library
// or system calls. It deliberately never touches "errno", either.
//
// The only exception to this rule is that in debug builds the code calls
// RAW_CHECK() to help diagnose problems when the format string does not
// match the rest of the arguments. In release builds, no CHECK()s are used,
// and SafeSPrintf() instead returns an output string that expands only
// those arguments that match their format characters. Mismatched arguments
// are ignored.
//
// The code currently only supports a subset of format characters:
//   %c, %o, %d, %x, %X, %p, and %s.
//
// SafeSPrintf() aims to be as liberal as reasonably possible. Integer-like
// values of arbitrary width can be passed to all of the format characters
// that expect integers. Thus, it is explicitly legal to pass an "int" to
// "%c", and output will automatically look at the LSB only. It is also
// explicitly legal to pass either signed or unsigned values, and the format
// characters will automatically interpret the arguments accordingly.
//
// It is still not legal to mix-and-match integer-like values with pointer
// values. For instance, you cannot pass a pointer to %x, nor can you pass an
// integer to %p.
//
// The one exception is "0" zero being accepted by "%p". This works-around
// the problem of C++ defining NULL as an integer-like value.
//
// All format characters take an optional width parameter. This must be a
// positive integer. For %d, %o, %x, %X and %p, if the width starts with
// a leading '0', padding is done with '0' instead of ' ' characters.
//
// There are a few features of snprintf()-style format strings, that
// SafeSPrintf() does not support at this time.
//
// If an actual user showed up, there is no particularly strong reason they
// couldn't be added. But that assumes that the trade-offs between complexity
// and utility are favorable.
//
// For example, adding support for negative padding widths, and for %n are all
// likely to be viewed positively. They are all clearly useful, low-risk, easy
// to test, don't jeopardize the async-signal-safety of the code, and overall
// have little impact on other parts of SafeSPrintf() function.
//
// On the other hands, adding support for alternate forms, positional
// arguments, grouping, wide characters, localization or floating point numbers
// are all unlikely to ever be added.
//
// SafeSPrintf() and SafeSNPrintf() mimic the behavior of snprintf() and they
// return the number of bytes needed to store the untruncated output. This
// does *not* include the terminating NUL byte.
//
// They return -1, iff a fatal error happened. This typically can only happen,
// if the buffer size is a) negative, or b) zero (i.e. not even the NUL byte
// can be written). The return value can never be larger than SSIZE_MAX-1.
// This ensures that the caller can always add one to the signed return code
// in order to determine the amount of storage that needs to be allocated.
//
// While the code supports type checking and while it is generally very careful
// to avoid printing incorrect values, it tends to be conservative in printing
// as much as possible, even when given incorrect parameters. Typically, in
// case of an error, the format string will not be expanded. (i.e. something
// like SafeSPrintf(buf, "%p %d", 1, 2) results in "%p 2"). See above for
// the use of RAW_CHECK() in debug builds, though.
//
// Basic example:
//   char buf[20];
//   base::strings::SafeSPrintf(buf, "The answer: %2d", 42);
//
// Example with dynamically sized buffer (async-signal-safe). This code won't
// work on Visual studio, as it requires dynamically allocating arrays on the
// stack. Consider picking a smaller value for |kMaxSize| if stack size is
// limited and known. On the other hand, if the parameters to SafeSNPrintf()
// are trusted and not controllable by the user, you can consider eliminating
// the check for |kMaxSize| altogether. The current value of SSIZE_MAX is
// essentially a no-op that just illustrates how to implement an upper bound:
//   const size_t kInitialSize = 128;
//   const size_t kMaxSize = std::numeric_limits<ssize_t>::max();
//   size_t size = kInitialSize;
//   for (;;) {
//     char buf[size];
//     size = SafeSNPrintf(buf, size, "Error message \"%s\"\n", err) + 1;
//     if (sizeof(buf) < kMaxSize && size > kMaxSize) {
//       size = kMaxSize;
//       continue;
//     } else if (size > sizeof(buf))
//       continue;
//     write(2, buf, size-1);
//     break;
//   }

namespace internal {
// Helpers that use C++ overloading, templates, and specializations to deduce
// and record type information from function arguments. This allows us to
// later write a type-safe version of snprintf().

struct Arg {
  enum Type { INT, UINT, STRING, POINTER };

  // Any integer-like value.
  Arg(signed char c) : type(INT) {
    integer.i = c;
    integer.width = sizeof(char);
  }
  Arg(unsigned char c) : type(UINT) {
    integer.i = c;
    integer.width = sizeof(char);
  }
  Arg(signed short j) : type(INT) {
    integer.i = j;
    integer.width = sizeof(short);
  }
  Arg(unsigned short j) : type(UINT) {
    integer.i = j;
    integer.width = sizeof(short);
  }
  Arg(signed int j) : type(INT) {
    integer.i = j;
    integer.width = sizeof(int);
  }
  Arg(unsigned int j) : type(UINT) {
    integer.i = j;
    integer.width = sizeof(int);
  }
  Arg(signed long j) : type(INT) {
    integer.i = j;
    integer.width = sizeof(long);
  }
  Arg(unsigned long j) : type(UINT) {
    integer.i = j;
    integer.width = sizeof(long);
  }
  Arg(signed long long j) : type(INT) {
    integer.i = j;
    integer.width = sizeof(long long);
  }
  Arg(unsigned long long j) : type(UINT) {
    integer.i = j;
    integer.width = sizeof(long long);
  }

  // A C-style text string.
  Arg(const char* s) : str(s), type(STRING) { }
  Arg(char* s)       : str(s), type(STRING) { }

  // Any pointer value that can be cast to a "void*".
  template<class T> Arg(T* p) : ptr((void*)p), type(POINTER) { }

  union {
    // An integer-like value.
    struct {
      int64_t       i;
      unsigned char width;
    } integer;

    // A C-style text string.
    const char* str;

    // A pointer to an arbitrary object.
    const void* ptr;
  };
  const enum Type type;
};

// This is the internal function that performs the actual formatting of
// an snprintf()-style format string.
BASE_EXPORT ssize_t SafeSNPrintf(char* buf, size_t sz, const char* fmt,
                                 const Arg* args, size_t max_args);

#if !defined(NDEBUG)
// In debug builds, allow unit tests to artificially lower the kSSizeMax
// constant that is used as a hard upper-bound for all buffers. In normal
// use, this constant should always be std::numeric_limits<ssize_t>::max().
BASE_EXPORT void SetSafeSPrintfSSizeMaxForTest(size_t max);
BASE_EXPORT size_t GetSafeSPrintfSSizeMaxForTest();
#endif

}  // namespace internal

template<typename... Args>
ssize_t SafeSNPrintf(char* buf, size_t N, const char* fmt, Args... args) {
  // Use Arg() object to record type information and then copy arguments to an
  // array to make it easier to iterate over them.
  const internal::Arg arg_array[] = { args... };
  return internal::SafeSNPrintf(buf, N, fmt, arg_array, sizeof...(args));
}

template<size_t N, typename... Args>
ssize_t SafeSPrintf(char (&buf)[N], const char* fmt, Args... args) {
  // Use Arg() object to record type information and then copy arguments to an
  // array to make it easier to iterate over them.
  const internal::Arg arg_array[] = { args... };
  return internal::SafeSNPrintf(buf, N, fmt, arg_array, sizeof...(args));
}

// Fast-path when we don't actually need to substitute any arguments.
BASE_EXPORT ssize_t SafeSNPrintf(char* buf, size_t N, const char* fmt);
template<size_t N>
inline ssize_t SafeSPrintf(char (&buf)[N], const char* fmt) {
  return SafeSNPrintf(buf, N, fmt);
}

}  // namespace strings
}  // namespace base

#endif  // BASE_STRINGS_SAFE_SPRINTF_H_
