/* Copyright (c) 2007, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ---
 * Author: Craig Silverstein
 *
 * These are some portability typedefs and defines to make it a bit
 * easier to compile this code under VC++.
 *
 * Several of these are taken from glib:
 *    http://developer.gnome.org/doc/API/glib/glib-windows-compatability-functions.html
 */

#ifndef GOOGLE_BASE_WINDOWS_H_
#define GOOGLE_BASE_WINDOWS_H_

/* You should never include this file directly, but always include it
   from either config.h (MSVC) or mingw.h (MinGW/msys). */
#if !defined(GOOGLE_PERFTOOLS_WINDOWS_CONFIG_H_) && \
    !defined(GOOGLE_PERFTOOLS_WINDOWS_MINGW_H_)
# error "port.h should only be included from config.h or mingw.h"
#endif

#ifdef _WIN32

#ifndef NOMINMAX
#define NOMINMAX             /* Do not define min and max macros. */
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN  /* We always want minimal includes */
#endif
#include <windows.h>
#include <io.h>              /* because we so often use open/close/etc */
#include <direct.h>          /* for _getcwd */
#include <process.h>         /* for _getpid */
#include <limits.h>          /* for PATH_MAX */
#include <stdarg.h>          /* for va_list */
#include <stdio.h>           /* need this to override stdio's (v)snprintf */
#include <sys/types.h>       /* for _off_t */
#include <assert.h>
#include <stdlib.h>          /* for rand, srand, _strtoxxx */

/*
 * 4018: signed/unsigned mismatch is common (and ok for signed_i < unsigned_i)
 * 4244: otherwise we get problems when subtracting two size_t's to an int
 * 4288: VC++7 gets confused when a var is defined in a loop and then after it
 * 4267: too many false positives for "conversion gives possible data loss"
 * 4290: it's ok windows ignores the "throw" directive
 * 4996: Yes, we're ok using "unsafe" functions like vsnprintf and getenv()
 * 4146: internal_logging.cc intentionally negates an unsigned value
 */
#ifdef _MSC_VER
#pragma warning(disable:4018 4244 4288 4267 4290 4996 4146)
#endif

#ifndef __cplusplus
/* MSVC does not support C99 */
# if !defined(__STDC_VERSION__) || __STDC_VERSION__ < 199901L
#  ifdef _MSC_VER
#    define inline __inline
#  else
#    define inline static
#  endif
# endif
#endif

#ifdef __cplusplus
# define EXTERN_C  extern "C"
#else
# define EXTERN_C  extern
#endif

/* ----------------------------------- BASIC TYPES */

#ifndef HAVE_STDINT_H
#ifndef HAVE___INT64    /* we need to have all the __intX names */
# error  Do not know how to set up type aliases.  Edit port.h for your system.
#endif

typedef __int8 int8_t;
typedef __int16 int16_t;
typedef __int32 int32_t;
typedef __int64 int64_t;
typedef unsigned __int8 uint8_t;
typedef unsigned __int16 uint16_t;
typedef unsigned __int32 uint32_t;
typedef unsigned __int64 uint64_t;
#endif  /* #ifndef HAVE_STDINT_H */

/* I guess MSVC's <types.h> doesn't include ssize_t by default? */
#ifdef _MSC_VER
typedef intptr_t ssize_t;
#endif

/* ----------------------------------- THREADS */

#ifndef HAVE_PTHREAD   /* not true for MSVC, but may be true for MSYS */
typedef DWORD pthread_t;
typedef DWORD pthread_key_t;
typedef LONG pthread_once_t;
enum { PTHREAD_ONCE_INIT = 0 };   /* important that this be 0! for SpinLock */

inline pthread_t pthread_self(void) {
  return GetCurrentThreadId();
}

#ifdef __cplusplus
inline bool pthread_equal(pthread_t left, pthread_t right) {
  return left == right;
}

/* This replaces maybe_threads.{h,cc} */
EXTERN_C pthread_key_t PthreadKeyCreate(void (*destr_fn)(void*));  /* port.cc */

inline int perftools_pthread_key_create(pthread_key_t *pkey,
                                        void (*destructor)(void*)) {
  pthread_key_t key = PthreadKeyCreate(destructor);
  if (key != TLS_OUT_OF_INDEXES) {
    *(pkey) = key;
    return 0;
  } else {
    return GetLastError();
  }
}

inline void* perftools_pthread_getspecific(DWORD key) {
  DWORD err = GetLastError();
  void* rv = TlsGetValue(key);
  if (err) SetLastError(err);
  return rv;
}

inline int perftools_pthread_setspecific(pthread_key_t key, const void *value) {
  if (TlsSetValue(key, (LPVOID)value))
    return 0;
  else
    return GetLastError();
}

EXTERN_C int perftools_pthread_once(pthread_once_t *once_control,
                                    void (*init_routine)(void));

#endif  /* __cplusplus */
#endif  /* HAVE_PTHREAD */

inline void sched_yield(void) {
  Sleep(0);
}

/*
 * __declspec(thread) isn't usable in a dll opened via LoadLibrary().
 * But it doesn't work to LoadLibrary() us anyway, because of all the
 * things we need to do before main()!  So this kind of TLS is safe for us.
 */
#define __thread __declspec(thread)

/*
 * This code is obsolete, but I keep it around in case we are ever in
 * an environment where we can't or don't want to use google spinlocks
 * (from base/spinlock.{h,cc}).  In that case, uncommenting this out,
 * and removing spinlock.cc from the build, should be enough to revert
 * back to using native spinlocks.
 */
#if 0
// Windows uses a spinlock internally for its mutexes, making our life easy!
// However, the Windows spinlock must always be initialized, making life hard,
// since we want LINKER_INITIALIZED.  We work around this by having the
// linker initialize a bool to 0, and check that before accessing the mutex.
// This replaces spinlock.{h,cc}, and all the stuff it depends on (atomicops)
#ifdef __cplusplus
class SpinLock {
 public:
  SpinLock() : initialize_token_(PTHREAD_ONCE_INIT) {}
  // Used for global SpinLock vars (see base/spinlock.h for more details).
  enum StaticInitializer { LINKER_INITIALIZED };
  explicit SpinLock(StaticInitializer) : initialize_token_(PTHREAD_ONCE_INIT) {
    perftools_pthread_once(&initialize_token_, InitializeMutex);
  }

  // It's important SpinLock not have a destructor: otherwise we run
  // into problems when the main thread has exited, but other threads
  // are still running and try to access a main-thread spinlock.  This
  // means we leak mutex_ (we should call DeleteCriticalSection()
  // here).  However, I've verified that all SpinLocks used in
  // perftools have program-long scope anyway, so the leak is
  // perfectly fine.  But be aware of this for the future!

  void Lock() {
    // You'd thionk this would be unnecessary, since we call
    // InitializeMutex() in our constructor.  But sometimes Lock() can
    // be called before our constructor is!  This can only happen in
    // global constructors, when this is a global.  If we live in
    // bar.cc, and some global constructor in foo.cc calls a routine
    // in bar.cc that calls this->Lock(), then Lock() may well run
    // before our global constructor does.  To protect against that,
    // we do this check.  For SpinLock objects created after main()
    // has started, this pthread_once call will always be a noop.
    perftools_pthread_once(&initialize_token_, InitializeMutex);
    EnterCriticalSection(&mutex_);
  }
  void Unlock() {
    LeaveCriticalSection(&mutex_);
  }

  // Used in assertion checks: assert(lock.IsHeld()) (see base/spinlock.h).
  inline bool IsHeld() const {
    // This works, but probes undocumented internals, so I've commented it out.
    // c.f. http://msdn.microsoft.com/msdnmag/issues/03/12/CriticalSections/
    //return mutex_.LockCount>=0 && mutex_.OwningThread==GetCurrentThreadId();
    return true;
  }
 private:
  void InitializeMutex() { InitializeCriticalSection(&mutex_); }

  pthread_once_t initialize_token_;
  CRITICAL_SECTION mutex_;
};

class SpinLockHolder {  // Acquires a spinlock for as long as the scope lasts
 private:
  SpinLock* lock_;
 public:
  inline explicit SpinLockHolder(SpinLock* l) : lock_(l) { l->Lock(); }
  inline ~SpinLockHolder() { lock_->Unlock(); }
};
#endif  // #ifdef __cplusplus

// This keeps us from using base/spinlock.h's implementation of SpinLock.
#define BASE_SPINLOCK_H_ 1

#endif  /* #if 0 */

/* ----------------------------------- MMAP and other memory allocation */

#ifndef HAVE_MMAP   /* not true for MSVC, but may be true for msys */
#define MAP_FAILED  0
#define MREMAP_FIXED  2  /* the value in linux, though it doesn't really matter */
/* These, when combined with the mmap invariants below, yield the proper action */
#define PROT_READ      PAGE_READWRITE
#define PROT_WRITE     PAGE_READWRITE
#define MAP_ANONYMOUS  MEM_RESERVE
#define MAP_PRIVATE    MEM_COMMIT
#define MAP_SHARED     MEM_RESERVE   /* value of this #define is 100% arbitrary */

#if __STDC__ && !defined(__MINGW32__)
typedef _off_t off_t;
#endif

/* VirtualAlloc only replaces for mmap when certain invariants are kept. */
inline void *mmap(void *addr, size_t length, int prot, int flags,
                  int fd, off_t offset) {
  if (addr == NULL && fd == -1 && offset == 0 &&
      prot == (PROT_READ|PROT_WRITE) && flags == (MAP_PRIVATE|MAP_ANONYMOUS)) {
    return VirtualAlloc(0, length, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
  } else {
    return NULL;
  }
}

inline int munmap(void *addr, size_t length) {
  return VirtualFree(addr, 0, MEM_RELEASE) ? 0 : -1;
}
#endif  /* HAVE_MMAP */

/* We could maybe use VirtualAlloc for sbrk as well, but no need */
inline void *sbrk(intptr_t increment) {
  // sbrk returns -1 on failure
  return (void*)-1;
}


/* ----------------------------------- STRING ROUTINES */

/*
 * We can't just use _vsnprintf and _snprintf as drop-in-replacements,
 * because they don't always NUL-terminate. :-(  We also can't use the
 * name vsnprintf, since windows defines that (but not snprintf (!)).
 */
#if defined(_MSC_VER) && _MSC_VER >= 1400
/* We can use safe CRT functions, which the required functionality */
inline int perftools_vsnprintf(char *str, size_t size, const char *format,
                               va_list ap) {
  return vsnprintf_s(str, size, _TRUNCATE, format, ap);
}
#else
inline int perftools_vsnprintf(char *str, size_t size, const char *format,
                               va_list ap) {
  if (size == 0)        /* not even room for a \0? */
    return -1;        /* not what C99 says to do, but what windows does */
  str[size-1] = '\0';
  return _vsnprintf(str, size-1, format, ap);
}
#endif

#ifndef HAVE_SNPRINTF
inline int snprintf(char *str, size_t size, const char *format, ...) {
  va_list ap;
  int r;
  va_start(ap, format);
  r = perftools_vsnprintf(str, size, format, ap);
  va_end(ap);
  return r;
}
#endif

#define PRIx64  "I64x"
#define SCNx64  "I64x"
#define PRId64  "I64d"
#define SCNd64  "I64d"
#define PRIu64  "I64u"
#ifdef _WIN64
# define PRIuPTR "llu"
# define PRIxPTR "llx"
#else
# define PRIuPTR "lu"
# define PRIxPTR "lx"
#endif

/* ----------------------------------- FILE IO */

#ifndef PATH_MAX
#define PATH_MAX 1024
#endif
#ifndef __MINGW32__
enum { STDIN_FILENO = 0, STDOUT_FILENO = 1, STDERR_FILENO = 2 };
#endif
#ifndef O_RDONLY
#define O_RDONLY  _O_RDONLY
#endif

#if __STDC__ && !defined(__MINGW32__)
/* These functions are considered non-standard */
inline int access(const char *pathname, int mode) {
  return _access(pathname, mode);
}
inline int open(const char *pathname, int flags, int mode = 0) {
  return _open(pathname, flags, mode);
}
inline int close(int fd) {
  return _close(fd);
}
inline ssize_t read(int fd, void *buf, size_t count) {
  return _read(fd, buf, count);
}
inline ssize_t write(int fd, const void *buf, size_t count) {
  return _write(fd, buf, count);
}
inline off_t lseek(int fd, off_t offset, int whence) {
  return _lseek(fd, offset, whence);
}
inline char *getcwd(char *buf, size_t size) {
  return _getcwd(buf, size);
}
inline int mkdir(const char *pathname, int) {
  return _mkdir(pathname);
}

inline FILE *popen(const char *command, const char *type) {
  return _popen(command, type);
}
inline int pclose(FILE *stream) {
  return _pclose(stream);
}
#endif

EXTERN_C PERFTOOLS_DLL_DECL void WriteToStderr(const char* buf, int len);

/* ----------------------------------- SYSTEM/PROCESS */

typedef int pid_t;
#if __STDC__ && !defined(__MINGW32__)
inline pid_t getpid(void) { return _getpid(); }
#endif
inline pid_t getppid(void) { return 0; }

/* Handle case when poll is used to simulate sleep. */
inline int poll(struct pollfd* fds, int nfds, int timeout) {
  assert(fds == NULL);
  assert(nfds == 0);
  Sleep(timeout);
  return 0;
}

EXTERN_C int getpagesize();   /* in port.cc */

/* ----------------------------------- OTHER */

inline void srandom(unsigned int seed) { srand(seed); }
inline long random(void) { return rand(); }
inline unsigned int sleep(unsigned int seconds) {
  Sleep(seconds * 1000);
  return 0;
}

// mingw64 seems to define timespec (though mingw.org mingw doesn't),
// protected by the _TIMESPEC_DEFINED macro.
#ifndef _TIMESPEC_DEFINED
struct timespec {
  int tv_sec;
  int tv_nsec;
};
#endif

inline int nanosleep(const struct timespec *req, struct timespec *rem) {
  Sleep(req->tv_sec * 1000 + req->tv_nsec / 1000000);
  return 0;
}

#ifndef __MINGW32__
#if _MSC_VER < 1800  // Not required >= VS2013.
inline long long int strtoll(const char *nptr, char **endptr, int base) {
    return _strtoi64(nptr, endptr, base);
}
inline unsigned long long int strtoull(const char *nptr, char **endptr,
                                       int base) {
    return _strtoui64(nptr, endptr, base);
}
inline long long int strtoq(const char *nptr, char **endptr, int base) {
    return _strtoi64(nptr, endptr, base);
}
#endif
inline unsigned long long int strtouq(const char *nptr, char **endptr,
                                      int base) {
    return _strtoui64(nptr, endptr, base);
}
inline long long atoll(const char *nptr) {
  return _atoi64(nptr);
}
#endif

#define __THROW throw()

/* ----------------------------------- TCMALLOC-SPECIFIC */

/* tcmalloc.cc calls this so we can patch VirtualAlloc() et al. */
extern void PatchWindowsFunctions();

// ----------------------------------- BUILD-SPECIFIC

/*
 * windows/port.h defines compatibility APIs for several .h files, which
 * we therefore shouldn't be #including directly.  This hack keeps us from
 * doing so.  TODO(csilvers): do something more principled.
 */
#define GOOGLE_MAYBE_THREADS_H_ 1


#endif  /* _WIN32 */

#undef inline
#undef EXTERN_C

#endif  /* GOOGLE_BASE_WINDOWS_H_ */
