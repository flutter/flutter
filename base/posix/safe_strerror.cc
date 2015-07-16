// Copyright (c) 2006-2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if defined(__ANDROID__)
// Post-L versions of bionic define the GNU-specific strerror_r if _GNU_SOURCE
// is defined, but the symbol is renamed to __gnu_strerror_r which only exists
// on those later versions. To preserve ABI compatibility with older versions,
// undefine _GNU_SOURCE and use the POSIX version.
#undef _GNU_SOURCE
#endif

#include "base/posix/safe_strerror.h"

#include <errno.h>
#include <stdio.h>
#include <string.h>

#include "build/build_config.h"

namespace base {

#define USE_HISTORICAL_STRERRO_R (defined(__GLIBC__) || defined(OS_NACL))

#if USE_HISTORICAL_STRERRO_R && defined(__GNUC__)
// GCC will complain about the unused second wrap function unless we tell it
// that we meant for them to be potentially unused, which is exactly what this
// attribute is for.
#define POSSIBLY_UNUSED __attribute__((unused))
#else
#define POSSIBLY_UNUSED
#endif

#if USE_HISTORICAL_STRERRO_R
// glibc has two strerror_r functions: a historical GNU-specific one that
// returns type char *, and a POSIX.1-2001 compliant one available since 2.3.4
// that returns int. This wraps the GNU-specific one.
static void POSSIBLY_UNUSED wrap_posix_strerror_r(
    char *(*strerror_r_ptr)(int, char *, size_t),
    int err,
    char *buf,
    size_t len) {
  // GNU version.
  char *rc = (*strerror_r_ptr)(err, buf, len);
  if (rc != buf) {
    // glibc did not use buf and returned a static string instead. Copy it
    // into buf.
    buf[0] = '\0';
    strncat(buf, rc, len - 1);
  }
  // The GNU version never fails. Unknown errors get an "unknown error" message.
  // The result is always null terminated.
}
#endif  // USE_HISTORICAL_STRERRO_R

// Wrapper for strerror_r functions that implement the POSIX interface. POSIX
// does not define the behaviour for some of the edge cases, so we wrap it to
// guarantee that they are handled. This is compiled on all POSIX platforms, but
// it will only be used on Linux if the POSIX strerror_r implementation is
// being used (see below).
static void POSSIBLY_UNUSED wrap_posix_strerror_r(
    int (*strerror_r_ptr)(int, char *, size_t),
    int err,
    char *buf,
    size_t len) {
  int old_errno = errno;
  // Have to cast since otherwise we get an error if this is the GNU version
  // (but in such a scenario this function is never called). Sadly we can't use
  // C++-style casts because the appropriate one is reinterpret_cast but it's
  // considered illegal to reinterpret_cast a type to itself, so we get an
  // error in the opposite case.
  int result = (*strerror_r_ptr)(err, buf, len);
  if (result == 0) {
    // POSIX is vague about whether the string will be terminated, although
    // it indirectly implies that typically ERANGE will be returned, instead
    // of truncating the string. We play it safe by always terminating the
    // string explicitly.
    buf[len - 1] = '\0';
  } else {
    // Error. POSIX is vague about whether the return value is itself a system
    // error code or something else. On Linux currently it is -1 and errno is
    // set. On BSD-derived systems it is a system error and errno is unchanged.
    // We try and detect which case it is so as to put as much useful info as
    // we can into our message.
    int strerror_error;  // The error encountered in strerror
    int new_errno = errno;
    if (new_errno != old_errno) {
      // errno was changed, so probably the return value is just -1 or something
      // else that doesn't provide any info, and errno is the error.
      strerror_error = new_errno;
    } else {
      // Either the error from strerror_r was the same as the previous value, or
      // errno wasn't used. Assume the latter.
      strerror_error = result;
    }
    // snprintf truncates and always null-terminates.
    snprintf(buf,
             len,
             "Error %d while retrieving error %d",
             strerror_error,
             err);
  }
  errno = old_errno;
}

void safe_strerror_r(int err, char *buf, size_t len) {
  if (buf == NULL || len <= 0) {
    return;
  }
  // If using glibc (i.e., Linux), the compiler will automatically select the
  // appropriate overloaded function based on the function type of strerror_r.
  // The other one will be elided from the translation unit since both are
  // static.
  wrap_posix_strerror_r(&strerror_r, err, buf, len);
}

std::string safe_strerror(int err) {
  const int buffer_size = 256;
  char buf[buffer_size];
  safe_strerror_r(err, buf, sizeof(buf));
  return std::string(buf);
}

}  // namespace base
