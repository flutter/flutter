// Copyright (c) 2007, Google Inc.
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
// 
// ---
// Author: Craig Silverstein.
//
// A simple mutex wrapper, supporting locks and read-write locks.
// You should assume the locks are *not* re-entrant.
//
// To use: you should define the following macros in your configure.ac:
//   ACX_PTHREAD
//   AC_RWLOCK
// The latter is defined in ../autoconf.
//
// This class is meant to be internal-only and should be wrapped by an
// internal namespace.  Before you use this module, please give the
// name of your internal namespace for this module.  Or, if you want
// to expose it, you'll want to move it to the Google namespace.  We
// cannot put this class in global namespace because there can be some
// problems when we have multiple versions of Mutex in each shared object.
//
// NOTE: TryLock() is broken for NO_THREADS mode, at least in NDEBUG
//       mode.
//
// CYGWIN NOTE: Cygwin support for rwlock seems to be buggy:
//    http://www.cygwin.com/ml/cygwin/2008-12/msg00017.html
// Because of that, we might as well use windows locks for
// cygwin.  They seem to be more reliable than the cygwin pthreads layer.
//
// TRICKY IMPLEMENTATION NOTE:
// This class is designed to be safe to use during
// dynamic-initialization -- that is, by global constructors that are
// run before main() starts.  The issue in this case is that
// dynamic-initialization happens in an unpredictable order, and it
// could be that someone else's dynamic initializer could call a
// function that tries to acquire this mutex -- but that all happens
// before this mutex's constructor has run.  (This can happen even if
// the mutex and the function that uses the mutex are in the same .cc
// file.)  Basically, because Mutex does non-trivial work in its
// constructor, it's not, in the naive implementation, safe to use
// before dynamic initialization has run on it.
//
// The solution used here is to pair the actual mutex primitive with a
// bool that is set to true when the mutex is dynamically initialized.
// (Before that it's false.)  Then we modify all mutex routines to
// look at the bool, and not try to lock/unlock until the bool makes
// it to true (which happens after the Mutex constructor has run.)
//
// This works because before main() starts -- particularly, during
// dynamic initialization -- there are no threads, so a) it's ok that
// the mutex operations are a no-op, since we don't need locking then
// anyway; and b) we can be quite confident our bool won't change
// state between a call to Lock() and a call to Unlock() (that would
// require a global constructor in one translation unit to call Lock()
// and another global constructor in another translation unit to call
// Unlock() later, which is pretty perverse).
//
// That said, it's tricky, and can conceivably fail; it's safest to
// avoid trying to acquire a mutex in a global constructor, if you
// can.  One way it can fail is that a really smart compiler might
// initialize the bool to true at static-initialization time (too
// early) rather than at dynamic-initialization time.  To discourage
// that, we set is_safe_ to true in code (not the constructor
// colon-initializer) and set it to true via a function that always
// evaluates to true, but that the compiler can't know always
// evaluates to true.  This should be good enough.
//
// A related issue is code that could try to access the mutex
// after it's been destroyed in the global destructors (because
// the Mutex global destructor runs before some other global
// destructor, that tries to acquire the mutex).  The way we
// deal with this is by taking a constructor arg that global
// mutexes should pass in, that causes the destructor to do no
// work.  We still depend on the compiler not doing anything
// weird to a Mutex's memory after it is destroyed, but for a
// static global variable, that's pretty safe.

#ifndef GOOGLE_MUTEX_H_
#define GOOGLE_MUTEX_H_

#include <config.h>

#if defined(NO_THREADS)
  typedef int MutexType;      // to keep a lock-count
#elif defined(_WIN32) || defined(__CYGWIN__) || defined(__CYGWIN32__)
# ifndef WIN32_LEAN_AND_MEAN
#   define WIN32_LEAN_AND_MEAN  // We only need minimal includes
# endif
  // We need Windows NT or later for TryEnterCriticalSection().  If you
  // don't need that functionality, you can remove these _WIN32_WINNT
  // lines, and change TryLock() to assert(0) or something.
# ifndef _WIN32_WINNT
#   define _WIN32_WINNT 0x0400
# endif
# include <windows.h>
  typedef CRITICAL_SECTION MutexType;
#elif defined(HAVE_PTHREAD) && defined(HAVE_RWLOCK)
  // Needed for pthread_rwlock_*.  If it causes problems, you could take it
  // out, but then you'd have to unset HAVE_RWLOCK (at least on linux -- it
  // *does* cause problems for FreeBSD, or MacOSX, but isn't needed
  // for locking there.)
# ifdef __linux__
#   define _XOPEN_SOURCE 500  // may be needed to get the rwlock calls
# endif
# include <pthread.h>
  typedef pthread_rwlock_t MutexType;
#elif defined(HAVE_PTHREAD)
# include <pthread.h>
  typedef pthread_mutex_t MutexType;
#else
# error Need to implement mutex.h for your architecture, or #define NO_THREADS
#endif

#include <assert.h>
#include <stdlib.h>      // for abort()

#define MUTEX_NAMESPACE perftools_mutex_namespace

namespace MUTEX_NAMESPACE {

class Mutex {
 public:
  // This is used for the single-arg constructor
  enum LinkerInitialized { LINKER_INITIALIZED };

  // Create a Mutex that is not held by anybody.  This constructor is
  // typically used for Mutexes allocated on the heap or the stack.
  inline Mutex();
  // This constructor should be used for global, static Mutex objects.
  // It inhibits work being done by the destructor, which makes it
  // safer for code that tries to acqiure this mutex in their global
  // destructor.
  inline Mutex(LinkerInitialized);

  // Destructor
  inline ~Mutex();

  inline void Lock();    // Block if needed until free then acquire exclusively
  inline void Unlock();  // Release a lock acquired via Lock()
  inline bool TryLock(); // If free, Lock() and return true, else return false
  // Note that on systems that don't support read-write locks, these may
  // be implemented as synonyms to Lock() and Unlock().  So you can use
  // these for efficiency, but don't use them anyplace where being able
  // to do shared reads is necessary to avoid deadlock.
  inline void ReaderLock();   // Block until free or shared then acquire a share
  inline void ReaderUnlock(); // Release a read share of this Mutex
  inline void WriterLock() { Lock(); }     // Acquire an exclusive lock
  inline void WriterUnlock() { Unlock(); } // Release a lock from WriterLock()

 private:
  MutexType mutex_;
  // We want to make sure that the compiler sets is_safe_ to true only
  // when we tell it to, and never makes assumptions is_safe_ is
  // always true.  volatile is the most reliable way to do that.
  volatile bool is_safe_;
  // This indicates which constructor was called.
  bool destroy_;

  inline void SetIsSafe() { is_safe_ = true; }

  // Catch the error of writing Mutex when intending MutexLock.
  Mutex(Mutex* /*ignored*/) {}
  // Disallow "evil" constructors
  Mutex(const Mutex&);
  void operator=(const Mutex&);
};

// Now the implementation of Mutex for various systems
#if defined(NO_THREADS)

// When we don't have threads, we can be either reading or writing,
// but not both.  We can have lots of readers at once (in no-threads
// mode, that's most likely to happen in recursive function calls),
// but only one writer.  We represent this by having mutex_ be -1 when
// writing and a number > 0 when reading (and 0 when no lock is held).
//
// In debug mode, we assert these invariants, while in non-debug mode
// we do nothing, for efficiency.  That's why everything is in an
// assert.

Mutex::Mutex() : mutex_(0) { }
Mutex::Mutex(Mutex::LinkerInitialized) : mutex_(0) { }
Mutex::~Mutex()            { assert(mutex_ == 0); }
void Mutex::Lock()         { assert(--mutex_ == -1); }
void Mutex::Unlock()       { assert(mutex_++ == -1); }
bool Mutex::TryLock()      { if (mutex_) return false; Lock(); return true; }
void Mutex::ReaderLock()   { assert(++mutex_ > 0); }
void Mutex::ReaderUnlock() { assert(mutex_-- > 0); }

#elif defined(_WIN32) || defined(__CYGWIN__) || defined(__CYGWIN32__)

Mutex::Mutex() : destroy_(true) {
  InitializeCriticalSection(&mutex_);
  SetIsSafe();
}
Mutex::Mutex(LinkerInitialized) : destroy_(false) {
  InitializeCriticalSection(&mutex_);
  SetIsSafe();
}
Mutex::~Mutex()            { if (destroy_) DeleteCriticalSection(&mutex_); }
void Mutex::Lock()         { if (is_safe_) EnterCriticalSection(&mutex_); }
void Mutex::Unlock()       { if (is_safe_) LeaveCriticalSection(&mutex_); }
bool Mutex::TryLock()      { return is_safe_ ?
                                 TryEnterCriticalSection(&mutex_) != 0 : true; }
void Mutex::ReaderLock()   { Lock(); }      // we don't have read-write locks
void Mutex::ReaderUnlock() { Unlock(); }

#elif defined(HAVE_PTHREAD) && defined(HAVE_RWLOCK)

#define SAFE_PTHREAD(fncall)  do {   /* run fncall if is_safe_ is true */  \
  if (is_safe_ && fncall(&mutex_) != 0) abort();                           \
} while (0)

Mutex::Mutex() : destroy_(true) {
  SetIsSafe();
  if (is_safe_ && pthread_rwlock_init(&mutex_, NULL) != 0) abort();
}
Mutex::Mutex(Mutex::LinkerInitialized) : destroy_(false) {
  SetIsSafe();
  if (is_safe_ && pthread_rwlock_init(&mutex_, NULL) != 0) abort();
}
Mutex::~Mutex()       { if (destroy_) SAFE_PTHREAD(pthread_rwlock_destroy); }
void Mutex::Lock()         { SAFE_PTHREAD(pthread_rwlock_wrlock); }
void Mutex::Unlock()       { SAFE_PTHREAD(pthread_rwlock_unlock); }
bool Mutex::TryLock()      { return is_safe_ ?
                               pthread_rwlock_trywrlock(&mutex_) == 0 : true; }
void Mutex::ReaderLock()   { SAFE_PTHREAD(pthread_rwlock_rdlock); }
void Mutex::ReaderUnlock() { SAFE_PTHREAD(pthread_rwlock_unlock); }
#undef SAFE_PTHREAD

#elif defined(HAVE_PTHREAD)

#define SAFE_PTHREAD(fncall)  do {   /* run fncall if is_safe_ is true */  \
  if (is_safe_ && fncall(&mutex_) != 0) abort();                           \
} while (0)

Mutex::Mutex() : destroy_(true) {
  SetIsSafe();
  if (is_safe_ && pthread_mutex_init(&mutex_, NULL) != 0) abort();
}
Mutex::Mutex(Mutex::LinkerInitialized) : destroy_(false) {
  SetIsSafe();
  if (is_safe_ && pthread_mutex_init(&mutex_, NULL) != 0) abort();
}
Mutex::~Mutex()       { if (destroy_) SAFE_PTHREAD(pthread_mutex_destroy); }
void Mutex::Lock()         { SAFE_PTHREAD(pthread_mutex_lock); }
void Mutex::Unlock()       { SAFE_PTHREAD(pthread_mutex_unlock); }
bool Mutex::TryLock()      { return is_safe_ ?
                                 pthread_mutex_trylock(&mutex_) == 0 : true; }
void Mutex::ReaderLock()   { Lock(); }
void Mutex::ReaderUnlock() { Unlock(); }
#undef SAFE_PTHREAD

#endif

// --------------------------------------------------------------------------
// Some helper classes

// MutexLock(mu) acquires mu when constructed and releases it when destroyed.
class MutexLock {
 public:
  explicit MutexLock(Mutex *mu) : mu_(mu) { mu_->Lock(); }
  ~MutexLock() { mu_->Unlock(); }
 private:
  Mutex * const mu_;
  // Disallow "evil" constructors
  MutexLock(const MutexLock&);
  void operator=(const MutexLock&);
};

// ReaderMutexLock and WriterMutexLock do the same, for rwlocks
class ReaderMutexLock {
 public:
  explicit ReaderMutexLock(Mutex *mu) : mu_(mu) { mu_->ReaderLock(); }
  ~ReaderMutexLock() { mu_->ReaderUnlock(); }
 private:
  Mutex * const mu_;
  // Disallow "evil" constructors
  ReaderMutexLock(const ReaderMutexLock&);
  void operator=(const ReaderMutexLock&);
};

class WriterMutexLock {
 public:
  explicit WriterMutexLock(Mutex *mu) : mu_(mu) { mu_->WriterLock(); }
  ~WriterMutexLock() { mu_->WriterUnlock(); }
 private:
  Mutex * const mu_;
  // Disallow "evil" constructors
  WriterMutexLock(const WriterMutexLock&);
  void operator=(const WriterMutexLock&);
};

// Catch bug where variable name is omitted, e.g. MutexLock (&mu);
#define MutexLock(x) COMPILE_ASSERT(0, mutex_lock_decl_missing_var_name)
#define ReaderMutexLock(x) COMPILE_ASSERT(0, rmutex_lock_decl_missing_var_name)
#define WriterMutexLock(x) COMPILE_ASSERT(0, wmutex_lock_decl_missing_var_name)

}  // namespace MUTEX_NAMESPACE

using namespace MUTEX_NAMESPACE;

#undef MUTEX_NAMESPACE

#endif  /* #define GOOGLE_SIMPLE_MUTEX_H_ */
