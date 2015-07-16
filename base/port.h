// Copyright (c) 2006-2008 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PORT_H_
#define BASE_PORT_H_

#include <stdarg.h>
#include "build/build_config.h"

// DEPRECATED: Use ...LL and ...ULL suffixes.
// TODO(viettrungluu): Delete these. These are only here until |GG_(U)INT64_C|
// are deleted (some other header files (re)define |GG_(U)INT64_C|, so our
// definitions of them must exactly match theirs).
#ifdef COMPILER_MSVC
#define GG_LONGLONG(x) x##I64
#define GG_ULONGLONG(x) x##UI64
#else
#define GG_LONGLONG(x) x##LL
#define GG_ULONGLONG(x) x##ULL
#endif

// DEPRECATED: In Chromium, we force-define __STDC_CONSTANT_MACROS, so you can
// just use the regular (U)INTn_C macros from <stdint.h>.
// TODO(viettrungluu): Remove the remaining GG_(U)INTn_C macros.
#define GG_INT64_C(x)   GG_LONGLONG(x)
#define GG_UINT64_C(x)  GG_ULONGLONG(x)

// Define an OS-neutral wrapper for shared library entry points
#if defined(OS_WIN)
#define API_CALL __stdcall
#else
#define API_CALL
#endif

#endif  // BASE_PORT_H_
