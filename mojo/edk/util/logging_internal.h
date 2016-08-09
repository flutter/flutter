// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Internal logging macros, to avoid external dependencies.

#ifndef MOJO_EDK_UTIL_LOGGING_INTERNAL_H_
#define MOJO_EDK_UTIL_LOGGING_INTERNAL_H_

#if defined(NDEBUG) && !defined(DCHECK_ALWAYS_ON)

#define INTERNAL_DCHECK(condition) \
  do {                             \
  } while (false && (condition))

#define INTERNAL_DCHECK_WITH_ERRNO(condition, fn, error) \
  do {                                                   \
  } while (false && (condition) && (error))

#else

// Our own simplified "DCHECK". Asserts that |condition| is true. If not, "logs"
// the failing condition and aborts.
#define INTERNAL_DCHECK(condition)                                          \
  do {                                                                      \
    if (!(condition)) {                                                     \
      ::mojo::util::internal::DcheckHelper(__FILE__, __LINE__, #condition); \
    }                                                                       \
  } while (false)

// Our own simplified "DCHECK"/"DPCHECK" hybrid. Asserts that |condition| is
// true. If not, "logs" |fn| with errno value |error| and aborts. (This doesn't
// just use |errno| since some APIs, like pthreads, don't set errno.)
#define INTERNAL_DCHECK_WITH_ERRNO(condition, fn, error)                    \
  do {                                                                      \
    if (!(condition)) {                                                     \
      ::mojo::util::internal::DcheckWithErrnoHelper(__FILE__, __LINE__, fn, \
                                                    error);                 \
    }                                                                       \
  } while (false)

namespace mojo {
namespace util {
namespace internal {

// Helper for |INTERNAL_DCHECK_WITH_ERRNO()| above.
void DcheckHelper(const char* file, int line, const char* condition_string);

// Helper for |INTERNAL_DCHECK_WITH_ERRNO()| above.
void DcheckWithErrnoHelper(const char* file,
                           int line,
                           const char* fn,
                           int error);

}  // namespace internal
}  // namespace util
}  // namespace mojo

#endif  // defined(NDEBUG) && !defined(DCHECK_ALWAYS_ON)

#endif  // MOJO_EDK_UTIL_LOGGING_INTERNAL_H_
