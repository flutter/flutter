// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Partial <unistd.h>-lookalike-ish. Note that this is a C header, so that
// crappy (and non-crappy) C programs can use it.
//
// In general, functions/types/macros are given "mojio_"/"MOJIO_"/etc. prefixes.
// There are a handful of exceptions (noted below).

#ifndef MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_UNISTD_H_
#define MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_UNISTD_H_

// Includes --------------------------------------------------------------------

// <unistd.h> is required to define |NULL| (as a macro) and |size_t|. We don't
// define our own (with prefixes), and just use the standard ones from
// <stddef.h>.
#include <stddef.h>

// <unistd.h> is required to |ssize_t|, |uid_t|, |gid_t|, |off_t|, |pid_t|, and
// |useconds_t| from <sys/types.h>, so we may as well define our versions by
// inclusion.
#include "files/public/c/mojio_sys_types.h"

// Macros ----------------------------------------------------------------------

// "Whence". These are duplicated (verbatim) in mojio_stdio.h.
#define MOJIO_SEEK_SET 0
#define MOJIO_SEEK_CUR 1
#define MOJIO_SEEK_END 2

// TODO(vtl): Nothing else here yet.

// Types -----------------------------------------------------------------------

// We don't use the "standard" |intptr_t| (it's not required by the C/C++
// standards), since we don't want to include <inttypes.h> (nor <stdint.h>,
// which need not define it except on XSI-compliant systems).
// TODO(vtl): We may need to define this differently sometimes? (But how?)
typedef long int mojio_intptr_t;

// TODO(vtl): Nothing else here yet.

// Functions -------------------------------------------------------------------

#ifdef __cplusplus
extern "C" {
#endif

// TODO(vtl): Below is a complete list of functions in <unistd.h> (according to
// POSIX.1-2008, 2013 edition). Figure out which ones we want/need to support.
//
//   int access(const char*, int);
//   unsigned alarm(unsigned);
//   [DONE] int chdir(const char*);
//   int chown(const char*, uid_t, gid_t);
//   [DONE] int close(int);
//   size_t confstr(int, char*, size_t);
//   [XSI] char* crypt(const char*, const char*);
//   [DONE] int dup(int);
//   int dup2(int, int);
//   void _exit(int);
//   [XSI] void encrypt(char [64], int);
//   int execl(const char*, const char*, ...);
//   int execle(const char*, const char*, ...);
//   int execlp(const char*, const char*, ...);
//   int execv(const char*, char* const []);
//   int execve(const char*, char* const [], char* const []);
//   int execvp(const char*, char* const []);
//   int faccessat(int, const char*, int, int);
//   int fchdir(int);
//   int fchown(int, uid_t, gid_t);
//   int fchownat(int, const char*, uid_t, gid_t, int);
//   [SIO] int fdatasync(int);
//   int fexecve(int, char* const [], char* const []);
//   pid_t fork(void);
//   long fpathconf(int, int);
//   [FSC] int fsync(int);
//   [DONE] int ftruncate(int, off_t);
//   char* getcwd(char*, size_t);
//   gid_t getegid(void);
//   uid_t geteuid(void);
//   gid_t getgid(void);
//   int getgroups(int, gid_t []);
//   [XSI] long gethostid(void);
//   int gethostname(char*, size_t);
//   char* getlogin(void);
//   int getlogin_r(char*, size_t);
//   int getopt(int, char* const [], const char*);
//   pid_t getpgid(pid_t);
//   pid_t getpgrp(void);
//   pid_t getpid(void);
//   pid_t getppid(void);
//   pid_t getsid(pid_t);
//   uid_t getuid(void);
//   int isatty(int);
//   int lchown(const char*, uid_t, gid_t);
//   int link(const char*, const char*);
//   int linkat(int, const char*, int, const char*, int);
//   [XSI] int lockf(int, int, off_t);
//   [DONE] off_t lseek(int, off_t, int);
//   [XSI] int nice(int);
//   long pathconf(const char*, int);
//   int pause(void);
//   int pipe(int [2]);
//   ssize_t pread(int, void*, size_t, off_t);
//   ssize_t pwrite(int, const void*, size_t, off_t);
//   [DONE] ssize_t read(int, void*, size_t);
//   ssize_t readlink(const char* restrict, char* restrict, size_t);
//   ssize_t readlinkat(int, const char* restrict, char* restrict, size_t);
//   int rmdir(const char*);
//   int setegid(gid_t);
//   int seteuid(uid_t);
//   int setgid(gid_t);
//   int setpgid(pid_t, pid_t);
//   [Obsolete XSI] pid_t setpgrp(void);
//   [XSI] int setregid(gid_t, gid_t);
//   [XSI] int setreuid(uid_t, uid_t);
//   pid_t setsid(void);
//   int setuid(uid_t);
//   unsigned sleep(unsigned);
//   [XSI] void swab(const void* restrict, void* restrict, ssize_t);
//   int symlink(const char*, const char*);
//   int symlinkat(const char*, int, const char*);
//   [XSI] void sync(void);
//   long sysconf(int);
//   pid_t tcgetpgrp(int);
//   int tcsetpgrp(int, pid_t);
//   int truncate(const char*, off_t);
//   char* ttyname(int);
//   int ttyname_r(int, char*, size_t);
//   int unlink(const char*);
//   int unlinkat(int, const char*, int);
//   [DONE] ssize_t write(int, const void*, size_t);

int mojio_chdir(const char* path);
int mojio_close(int fd);
int mojio_dup(int fd);
int mojio_ftruncate(int fd, mojio_off_t length);
mojio_off_t mojio_lseek(int fd, mojio_off_t offset, int whence);
mojio_ssize_t mojio_read(int fd, void* buf, size_t count);
mojio_ssize_t mojio_write(int fd, const void* buf, size_t count);

// TODO(vtl): Some of the others.

// Globals ---------------------------------------------------------------------

// TODO(vtl): Nothing here yet.

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // MOJO_SERVICES_FILES_PUBLIC_C_MOJIO_UNISTD_H_
