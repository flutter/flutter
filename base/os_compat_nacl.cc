// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/os_compat_nacl.h"

#include <stdlib.h>
#include <time.h>

#if !defined (__GLIBC__)

extern "C" {
// Native Client has no timegm().
time_t timegm(struct tm* tm) {
  time_t ret;
  char* tz;
  tz = getenv("TZ");
  setenv("TZ", "", 1);
  tzset();
  ret = mktime(tm);
  if (tz)
    setenv("TZ", tz, 1);
  else
    unsetenv("TZ");
  tzset();
  return ret;
}
}  // extern "C"

#endif  // !defined (__GLIBC__)
