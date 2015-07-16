// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_FORMAT_MACROS_H_
#define BASE_FORMAT_MACROS_H_

// This file defines the format macros for some integer types.

// To print a 64-bit value in a portable way:
//   int64_t value;
//   printf("xyz:%" PRId64, value);
// The "d" in the macro corresponds to %d; you can also use PRIu64 etc.
//
// For wide strings, prepend "Wide" to the macro:
//   int64_t value;
//   StringPrintf(L"xyz: %" WidePRId64, value);
//
// To print a size_t value in a portable way:
//   size_t size;
//   printf("xyz: %" PRIuS, size);
// The "u" in the macro corresponds to %u, and S is for "size".

#include "build/build_config.h"

#if defined(OS_POSIX) && (defined(_INTTYPES_H) || defined(_INTTYPES_H_)) && \
    !defined(PRId64)
#error "inttypes.h has already been included before this header file, but "
#error "without __STDC_FORMAT_MACROS defined."
#endif

#if defined(OS_POSIX) && !defined(__STDC_FORMAT_MACROS)
#define __STDC_FORMAT_MACROS
#endif

#include <inttypes.h>

#if defined(OS_POSIX)

// GCC will concatenate wide and narrow strings correctly, so nothing needs to
// be done here.
#define WidePRId64 PRId64
#define WidePRIu64 PRIu64
#define WidePRIx64 PRIx64

#if !defined(PRIuS)
#define PRIuS "zu"
#endif

// The size of NSInteger and NSUInteger varies between 32-bit and 64-bit
// architectures and Apple does not provides standard format macros and
// recommends casting. This has many drawbacks, so instead define macros
// for formatting those types.
#if defined(OS_MACOSX)
#if defined(ARCH_CPU_64_BITS)
#if !defined(PRIdNS)
#define PRIdNS "ld"
#endif
#if !defined(PRIuNS)
#define PRIuNS "lu"
#endif
#if !defined(PRIxNS)
#define PRIxNS "lx"
#endif
#else  // defined(ARCH_CPU_64_BITS)
#if !defined(PRIdNS)
#define PRIdNS "d"
#endif
#if !defined(PRIuNS)
#define PRIuNS "u"
#endif
#if !defined(PRIxNS)
#define PRIxNS "x"
#endif
#endif
#endif  // defined(OS_MACOSX)

#else  // OS_WIN

#if !defined(PRId64) || !defined(PRIu64) || !defined(PRIx64)
#error "inttypes.h provided by win toolchain should define these."
#endif

#define WidePRId64 L"I64d"
#define WidePRIu64 L"I64u"
#define WidePRIx64 L"I64x"

#if !defined(PRIuS)
#define PRIuS "Iu"
#endif

#endif

#endif  // BASE_FORMAT_MACROS_H_
