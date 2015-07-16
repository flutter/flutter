// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Configuration for other mojio_*.h. Note that this is a C header.
//
// Things in this file may be tweaked (the values of macros or the underlying
// types for typedefs) as necessary/appropriate, but they should not be used
// directly by application code.

#ifndef MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_CONFIG_H_
#define MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_CONFIG_H_

// Macros ----------------------------------------------------------------------

#define MOJIO_CONFIG_BUFSIZ 8192
#define MOJIO_CONFIG_FILENAME_MAX 4096
#define MOJIO_CONFIG_FOPEN_MAX 16

// What to use for the C |restrict| keyword (not supported in C++).
// TODO(vtl): Is this right?
#define MOJIO_CONFIG_RESTRICT __restrict__

// Maximum number of (simultaneously open) FDs.
#define MOJIO_CONFIG_MAX_NUM_FDS 1024

// Types -----------------------------------------------------------------------

// We want types of exact bitwidths (since values will usually come from Mojo
// messages), but we don't want to include <stdint.h> from our headers. Thus we
// define our own. These are meant for internal use only.
// TODO(vtl): Add static_assert()s/_Static_assert()s verifying the sizes.
typedef int mojio_config_int32;
typedef unsigned mojio_config_uint32;
typedef long long mojio_config_int64;
typedef unsigned long long mojio_config_uint64;

#endif  // MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_CONFIG_H_
