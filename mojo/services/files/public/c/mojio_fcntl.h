// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Partial <fcntl.h>-lookalike-ish. Note that this is a C header, so that crappy
// (and non-crappy) C programs can use it.
//
// In general, functions/types/macros are given "mojio_"/"MOJIO_"/etc. prefixes.
// There are a handful of exceptions (noted below).

#ifndef MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_FCNTL_H_
#define MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_FCNTL_H_

// Includes --------------------------------------------------------------------

#include "files/public/c/mojio_sys_types.h"

// Macros ----------------------------------------------------------------------

// Values for |mojio_fcntl()|'s |cmd| argument (not all are actually
// implemented):
#define MOJIO_F_DUPFD 0
#define MOJIO_F_GETFD 1
#define MOJIO_F_SETFD 2
#define MOJIO_F_GETFL 3
#define MOJIO_F_SETFL 4
#define MOJIO_F_GETLK 5
#define MOJIO_F_SETLK 6
#define MOJIO_F_SETLKW 7
#define MOJIO_F_GETOWN 8
#define MOJIO_F_SETOWN 9

// Values for |mojio_open()| and |mojio_fcntl()| flags:
#define MOJIO_O_ACCMODE 3  // MOJIO_O_RDONLY | MOJIO_O_RDWR | MOJIO_O_WRONLY.
#define MOJIO_O_RDONLY 0
#define MOJIO_O_RDWR 1
#define MOJIO_O_WRONLY 2
#define MOJIO_O_CREAT 64
#define MOJIO_O_EXCL 128
#define MOJIO_O_NOCTTY 256
#define MOJIO_O_TRUNC 512
#define MOJIO_O_APPEND 1024
#define MOJIO_O_NONBLOCK 2048
#define MOJIO_O_DSYNC 4096
#define MOJIO_O_RSYNC 8192
#define MOJIO_O_SYNC 16384

// Types -----------------------------------------------------------------------

// TODO(vtl): |struct flock| equivalent?

// Functions -------------------------------------------------------------------

#ifdef __cplusplus
extern "C" {
#endif

int mojio_creat(const char* path, mojio_mode_t mode);
// TODO(vtl): int mojio_fcntl(int fd, int cmd, ...);
int mojio_open(const char* path, int oflag, ...);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_FCNTL_H_
