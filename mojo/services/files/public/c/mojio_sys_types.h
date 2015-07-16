// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Partial <sys/types.h>-lookalike-ish. Note that this is a C header, so that
// crappy (and non-crappy) C programs can use it.
//
// In general, functions/types/macros are given "mojio_"/"MOJIO_"/etc. prefixes.
// There are a handful of exceptions (noted below).

#ifndef MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_SYS_TYPES_H_
#define MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_SYS_TYPES_H_

// Includes --------------------------------------------------------------------

// <sys/types.h> is required to define |size_t|. We don't define our own (with a
// prefix), and just use the standard one from <stddef.h>.
#include <stddef.h>

#include "files/public/c/mojio_config.h"

// <sys/types.h> is required to define |time_t| (which we have our own version
// of, because the one in the C standard <time.h> is defined to be opaque).
#include "files/public/c/mojio_time.h"

// Types -----------------------------------------------------------------------

typedef mojio_config_uint64 mojio_blkcnt_t;

// Inexplicably required to be signed.
typedef mojio_config_int64 mojio_blksize_t;

typedef mojio_config_uint64 mojio_dev_t;

typedef mojio_config_uint32 mojio_gid_t;

typedef mojio_config_uint64 mojio_ino_t;

typedef mojio_config_uint32 mojio_mode_t;

typedef mojio_config_uint32 mojio_nlink_t;

// |off_t| should be a signed type.
typedef mojio_config_int64 mojio_off_t;

// |ssize_t| should be a signed type of the same size as |size_t|.
// TODO(vtl): We may need to define this differently sometimes? (But how?) Also,
// add a suitable static_assert()/_Static_assert().
// TODO(vtl): We need a mojio_limits.h, defining MOJIO_SSIZE_MAX.
typedef long int mojio_ssize_t;

typedef mojio_config_uint32 mojio_uid_t;

#endif  // MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_SYS_TYPES_H_
