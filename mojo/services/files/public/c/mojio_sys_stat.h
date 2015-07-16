// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Partial <sys/stat.h>-lookalike-ish. Note that this is a C header, so that
// crappy (and non-crappy) C programs can use it.
//
// In general, functions/types/macros are given "mojio_"/"MOJIO_"/etc. prefixes.
// There are a handful of exceptions (noted below).

#ifndef MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_SYS_STAT_H_
#define MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_SYS_STAT_H_

// Includes --------------------------------------------------------------------

// <sys/stat.h> is required to define a large number of types defined in
// <sys/types.h>, so we just include our equivalent of the latter.
#include "files/public/c/mojio_sys_types.h"

// We need our |struct timespec| equivalent.
#include "files/public/c/mojio_time.h"

// Macros ----------------------------------------------------------------------

#define MOJIO_S_IRWXU (MOJIO_S_IRUSR | MOJIO_S_IWUSR | MOJIO_S_IXUSR)
#define MOJIO_S_IRUSR 00400
#define MOJIO_S_IWUSR 00200
#define MOJIO_S_IXUSR 00100

#define MOJIO_S_IRWXG (MOJIO_S_IRGRP | MOJIO_S_IWGRP | MOJIO_S_IXGRP)
#define MOJIO_S_IRGRP 00040
#define MOJIO_S_IWGRP 00020
#define MOJIO_S_IXGRP 00010

#define MOJIO_S_IRWXO (MOJIO_S_IROTH | MOJIO_S_IWOTH | MOJIO_S_IXOTH)
#define MOJIO_S_IROTH 00004
#define MOJIO_S_IWOTH 00002
#define MOJIO_S_IXOTH 00001

#define MOJIO_S_ISUID 04000
#define MOJIO_S_ISGID 02000
#define MOJIO_S_ISVTX 01000

// Mask for the values below.
#define MOJIO_S_IFMT 0170000
// These values are mysterious, but are the standard values on Linux.
#define MOJIO_S_IFBLK 0060000
#define MOJIO_S_IFCHR 0020000
#define MOJIO_S_IFDIR 0040000
#define MOJIO_S_IFIFO 0010000
#define MOJIO_S_IFLNK 0120000
#define MOJIO_S_IFREG 0100000
#define MOJIO_S_IFSOCK 0140000

#define MOJIO_S_ISBLK(mode) (((mode)&MOJIO_S_IFMT) == MOJIO_S_IFBLK)
#define MOJIO_S_ISCHR(mode) (((mode)&MOJIO_S_IFMT) == MOJIO_S_IFCHR)
#define MOJIO_S_ISDIR(mode) (((mode)&MOJIO_S_IFMT) == MOJIO_S_IFDIR)
#define MOJIO_S_ISFIFO(mode) (((mode)&MOJIO_S_IFMT) == MOJIO_S_IFIFO)
#define MOJIO_S_ISLNK(mode) (((mode)&MOJIO_S_IFMT) == MOJIO_S_IFLNK)
#define MOJIO_S_ISREG(mode) (((mode)&MOJIO_S_IFMT) == MOJIO_S_IFREG)
#define MOJIO_S_ISSOCK(mode) (((mode)&MOJIO_S_IFMT) == MOJIO_S_IFSOCK)

// POSIX.1-2008 says we should define |st_atime| to |st_atim.tv_sec| (and
// similarly for |st_mtime| and |st_ctime|). This is to provide (source)
// backwards compatibility with older versions of POSIX.
//
// We could reasonably provide these macros on systems that are compliant with
// POSIX.1-2008 (or later): even though they might collide with macro
// definitions in the "real" <sys/stat.h>, it's okay since the macro definitions
// will be identical. However, providing these macros on systems that aren't
// POSIX.1-2008-compliant (like Android) leads to an intractable conflict. Thus
// we provide prefixed macros instead.
#define mojio_st_atime st_atim.tv_sec
#define mojio_st_mtime st_mtim.tv_sec
#define mojio_st_ctime st_ctim.tv_sec

// Types -----------------------------------------------------------------------

struct mojio_stat {
  mojio_dev_t st_dev;
  mojio_ino_t st_ino;
  mojio_mode_t st_mode;
  mojio_nlink_t st_nlink;
  mojio_uid_t st_uid;
  mojio_gid_t st_gid;
  mojio_dev_t st_rdev;
  mojio_off_t st_size;
  struct mojio_timespec st_atim;
  struct mojio_timespec st_mtim;
  struct mojio_timespec st_ctim;
  mojio_blksize_t st_blksize;
  mojio_blkcnt_t st_blocks;
};

// Functions -------------------------------------------------------------------

#ifdef __cplusplus
extern "C" {
#endif

// TODO(vtl): Below is a complete list of functions in <sys/stat.h> (according
// to POSIX.1-2008, 2013 edition). Figure out which ones we want/need to
// support.
//
//   int chmod(const char*, mode_t);
//   int fchmod(int, mode_t);
//   int fchmodat(int, const char*, mode_t, int);
//   [DONE] int fstat(int, struct stat*);
//   int fstatat(int, const char* restrict, struct stat* restrict, int);
//   int futimens(int, const struct timespec [2]);
//   int lstat(const char* restrict, struct stat* restrict);
//   int mkdir(const char*, mode_t);
//   int mkdirat(int, const char*, mode_t);
//   int mkfifo(const char*, mode_t);
//   int mkfifoat(int, const char*, mode_t);
//   [XSI] int mknod(const char*, mode_t, dev_t);
//   [XSI] int mknodat(int, const char*, mode_t, dev_t);
//   int stat(const char* restrict, struct stat* restrict);
//   mode_t umask(mode_t);
//   int utimensat(int, const char*, const struct timespec [2], int);

int mojio_fstat(int fd, struct mojio_stat* buf);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_SYS_STAT_H_
