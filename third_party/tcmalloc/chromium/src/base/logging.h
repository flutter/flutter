// Copyright (c) 2005, Google Inc.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
// 
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ---
// This file contains #include information about logging-related stuff.
// Pretty much everybody needs to #include this file so that they can
// log various happenings.
//
#ifndef _LOGGING_H_
#define _LOGGING_H_

#include <config.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>    // for write()
#endif
#include <string.h>    // for strlen(), strcmp()
#include <assert.h>
#include <errno.h>     // for errno
#include "base/abort.h"
#include "base/commandlineflags.h"

// On some systems (like freebsd), we can't call write() at all in a
// global constructor, perhaps because errno hasn't been set up.
// (In windows, we can't call it because it might call malloc.)
// Calling the write syscall is safer (it doesn't set errno), so we
// prefer that.  Note we don't care about errno for logging: we just
// do logging on a best-effort basis.
#if defined(_MSC_VER)
#define WRITE_TO_STDERR(buf, len) WriteToStderr(buf, len);  // in port.cc
#elif defined(__ANDROID__) || defined(ANDROID)
#include <android/log.h>
#define WRITE_TO_STDERR(buf, len) \
    __android_log_write(ANDROID_LOG_ERROR, "gperftools", buf)
#elif defined(HAVE_SYS_SYSCALL_H)
#include <sys/syscall.h>
#define WRITE_TO_STDERR(buf, len) syscall(SYS_write, STDERR_FILENO, buf, len)
#else
#define WRITE_TO_STDERR(buf, len) write(STDERR_FILENO, buf, len)
#endif

// MSVC and mingw define their own, safe version of vnsprintf (the
// windows one in broken) in port.cc.  Everyone else can use the
// version here.  We had to give it a unique name for windows.
#ifndef _WIN32
# define perftools_vsnprintf vsnprintf
#endif


// We log all messages at this log-level and below.
// INFO == -1, WARNING == -2, ERROR == -3, FATAL == -4
DECLARE_int32(verbose);

// CHECK dies with a fatal error if condition is not true.  It is *not*
// controlled by NDEBUG, so the check will be executed regardless of
// compilation mode.  Therefore, it is safe to do things like:
//    CHECK(fp->Write(x) == 4)
// Note we use write instead of printf/puts to avoid the risk we'll
// call malloc().
#define CHECK(condition)                                                \
  do {                                                                  \
    if (!(condition)) {                                                 \
      WRITE_TO_STDERR("Check failed: " #condition "\n",                 \
                      sizeof("Check failed: " #condition "\n")-1);      \
      tcmalloc::Abort();                                                \
    }                                                                   \
  } while (0)

// This takes a message to print.  The name is historical.
#define RAW_CHECK(condition, message)                                          \
  do {                                                                         \
    if (!(condition)) {                                                        \
      WRITE_TO_STDERR("Check failed: " #condition ": " message "\n",           \
                      sizeof("Check failed: " #condition ": " message "\n")-1);\
      tcmalloc::Abort();                                                       \
    }                                                                          \
  } while (0)

// This is like RAW_CHECK, but only in debug-mode
#ifdef NDEBUG
enum { DEBUG_MODE = 0 };
#define RAW_DCHECK(condition, message)
#else
enum { DEBUG_MODE = 1 };
#define RAW_DCHECK(condition, message)  RAW_CHECK(condition, message)
#endif

// This prints errno as well.  Note we use write instead of printf/puts to
// avoid the risk we'll call malloc().
#define PCHECK(condition)                                               \
  do {                                                                  \
    if (!(condition)) {                                                 \
      const int err_no = errno;                                         \
      WRITE_TO_STDERR("Check failed: " #condition ": ",                 \
                      sizeof("Check failed: " #condition ": ")-1);      \
      WRITE_TO_STDERR(strerror(err_no), strlen(strerror(err_no)));      \
      WRITE_TO_STDERR("\n", sizeof("\n")-1);                            \
      tcmalloc::Abort();                                                \
    }                                                                   \
  } while (0)

// Helper macro for binary operators; prints the two values on error
// Don't use this macro directly in your code, use CHECK_EQ et al below

// WARNING: These don't compile correctly if one of the arguments is a pointer
// and the other is NULL. To work around this, simply static_cast NULL to the
// type of the desired pointer.

// TODO(jandrews): Also print the values in case of failure.  Requires some
// sort of type-sensitive ToString() function.
#define CHECK_OP(op, val1, val2)                                        \
  do {                                                                  \
    if (!((val1) op (val2))) {                                          \
      fprintf(stderr, "Check failed: %s %s %s\n", #val1, #op, #val2);   \
      tcmalloc::Abort();                                                \
    }                                                                   \
  } while (0)

#define CHECK_EQ(val1, val2) CHECK_OP(==, val1, val2)
#define CHECK_NE(val1, val2) CHECK_OP(!=, val1, val2)
#define CHECK_LE(val1, val2) CHECK_OP(<=, val1, val2)
#define CHECK_LT(val1, val2) CHECK_OP(< , val1, val2)
#define CHECK_GE(val1, val2) CHECK_OP(>=, val1, val2)
#define CHECK_GT(val1, val2) CHECK_OP(> , val1, val2)

// Synonyms for CHECK_* that are used in some unittests.
#define EXPECT_EQ(val1, val2) CHECK_EQ(val1, val2)
#define EXPECT_NE(val1, val2) CHECK_NE(val1, val2)
#define EXPECT_LE(val1, val2) CHECK_LE(val1, val2)
#define EXPECT_LT(val1, val2) CHECK_LT(val1, val2)
#define EXPECT_GE(val1, val2) CHECK_GE(val1, val2)
#define EXPECT_GT(val1, val2) CHECK_GT(val1, val2)
#define ASSERT_EQ(val1, val2) EXPECT_EQ(val1, val2)
#define ASSERT_NE(val1, val2) EXPECT_NE(val1, val2)
#define ASSERT_LE(val1, val2) EXPECT_LE(val1, val2)
#define ASSERT_LT(val1, val2) EXPECT_LT(val1, val2)
#define ASSERT_GE(val1, val2) EXPECT_GE(val1, val2)
#define ASSERT_GT(val1, val2) EXPECT_GT(val1, val2)
// As are these variants.
#define EXPECT_TRUE(cond)     CHECK(cond)
#define EXPECT_FALSE(cond)    CHECK(!(cond))
#define EXPECT_STREQ(a, b)    CHECK(strcmp(a, b) == 0)
#define ASSERT_TRUE(cond)     EXPECT_TRUE(cond)
#define ASSERT_FALSE(cond)    EXPECT_FALSE(cond)
#define ASSERT_STREQ(a, b)    EXPECT_STREQ(a, b)

// Used for (libc) functions that return -1 and set errno
#define CHECK_ERR(invocation)  PCHECK((invocation) != -1)

// A few more checks that only happen in debug mode
#ifdef NDEBUG
#define DCHECK_EQ(val1, val2)
#define DCHECK_NE(val1, val2)
#define DCHECK_LE(val1, val2)
#define DCHECK_LT(val1, val2)
#define DCHECK_GE(val1, val2)
#define DCHECK_GT(val1, val2)
#else
#define DCHECK_EQ(val1, val2)  CHECK_EQ(val1, val2)
#define DCHECK_NE(val1, val2)  CHECK_NE(val1, val2)
#define DCHECK_LE(val1, val2)  CHECK_LE(val1, val2)
#define DCHECK_LT(val1, val2)  CHECK_LT(val1, val2)
#define DCHECK_GE(val1, val2)  CHECK_GE(val1, val2)
#define DCHECK_GT(val1, val2)  CHECK_GT(val1, val2)
#endif


#ifdef ERROR
#undef ERROR      // may conflict with ERROR macro on windows
#endif
enum LogSeverity {INFO = -1, WARNING = -2, ERROR = -3, FATAL = -4};

// NOTE: we add a newline to the end of the output if it's not there already
inline void LogPrintf(int severity, const char* pat, va_list ap) {
  // We write directly to the stderr file descriptor and avoid FILE
  // buffering because that may invoke malloc()
  char buf[1600];
  perftools_vsnprintf(buf, sizeof(buf)-1, pat, ap);
  if (buf[0] != '\0' && buf[strlen(buf)-1] != '\n') {
    assert(strlen(buf)+1 < sizeof(buf));
    strcat(buf, "\n");
  }
#if defined(__ANDROID__) || defined(ANDROID)
  android_LogPriority priority = ANDROID_LOG_UNKNOWN;
  if (severity >= 0) {
    priority = ANDROID_LOG_VERBOSE;
  } else {
    switch (severity) {
      case INFO: {
        priority = ANDROID_LOG_INFO;
        break;
      }
      case WARNING: {
        priority = ANDROID_LOG_WARN;
        break;
      }
      case ERROR: {
        priority = ANDROID_LOG_ERROR;
        break;
      }
      case FATAL: {
        priority = ANDROID_LOG_FATAL;
        break;
      }
    }
  }
  __android_log_write(priority, "gperftools", buf);
#else  // defined(__ANDROID__) || defined(ANDROID)
  WRITE_TO_STDERR(buf, strlen(buf));
#endif  // defined(__ANDROID__) || defined(ANDROID)
  if ((severity) == FATAL) {
    // LOG(FATAL) indicates a big problem, so don't run atexit() calls
    tcmalloc::Abort();
  }
}

// Note that since the order of global constructors is unspecified,
// global code that calls RAW_LOG may execute before FLAGS_verbose is set.
// Such code will run with verbosity == 0 no matter what.
#define VLOG_IS_ON(severity) (FLAGS_verbose >= severity)

// In a better world, we'd use __VA_ARGS__, but VC++ 7 doesn't support it.
#define LOG_PRINTF(severity, pat) do {          \
  if (VLOG_IS_ON(severity)) {                   \
    va_list ap;                                 \
    va_start(ap, pat);                          \
    LogPrintf(severity, pat, ap);               \
    va_end(ap);                                 \
  }                                             \
} while (0)

// RAW_LOG is the main function; some synonyms are used in unittests.
inline void RAW_LOG(int lvl, const char* pat, ...)  { LOG_PRINTF(lvl, pat); }
inline void RAW_VLOG(int lvl, const char* pat, ...) { LOG_PRINTF(lvl, pat); }
inline void LOG(int lvl, const char* pat, ...)      { LOG_PRINTF(lvl, pat); }
inline void VLOG(int lvl, const char* pat, ...)     { LOG_PRINTF(lvl, pat); }
inline void LOG_IF(int lvl, bool cond, const char* pat, ...) {
  if (cond)  LOG_PRINTF(lvl, pat);
}

// This isn't technically logging, but it's also IO and also is an
// attempt to be "raw" -- that is, to not use any higher-level libc
// routines that might allocate memory or (ideally) try to allocate
// locks.  We use an opaque file handle (not necessarily an int)
// to allow even more low-level stuff in the future.
// Like other "raw" routines, these functions are best effort, and
// thus don't return error codes (except RawOpenForWriting()).
#if defined(_WIN32) || defined(__CYGWIN__) || defined(__CYGWIN32__)
#ifndef NOMINMAX
#define NOMINMAX     // @#!$& windows
#endif
#include <windows.h>
typedef HANDLE RawFD;
const RawFD kIllegalRawFD = INVALID_HANDLE_VALUE;
#else
typedef int RawFD;
const RawFD kIllegalRawFD = -1;   // what open returns if it fails
#endif  // defined(_WIN32) || defined(__CYGWIN__) || defined(__CYGWIN32__)

RawFD RawOpenForWriting(const char* filename);   // uses default permissions
void RawWrite(RawFD fd, const char* buf, size_t len);
void RawClose(RawFD fd);

#endif // _LOGGING_H_
