// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Partial <time.h>-lookalike-ish. Note that this is a C header, so that crappy
// (and non-crappy) C programs can use it.
//
// In general, functions/types/macros are given "mojio_"/"MOJIO_"/etc. prefixes.
// There are a handful of exceptions (noted below).
//
// Ordinarily, we'd just use |time_t| from <time.h> (since that's provided by
// the C standard), but |time_t| is opaque. Thus we need to define our own
// equivalent. On top of that, we need to define a |struct timespec| equivalent.

#ifndef MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_TIME_H_
#define MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_TIME_H_

// Includes --------------------------------------------------------------------

#include "files/public/c/mojio_config.h"

// Types -----------------------------------------------------------------------

typedef mojio_config_int64 mojio_time_t;

struct mojio_timespec {
  mojio_time_t tv_sec;
  long tv_nsec;
};

#endif  // MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_TIME_H_
