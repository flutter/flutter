// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_THREADING_THREAD_LOCAL_STORAGE_H_
#define BASE_THREADING_THREAD_LOCAL_STORAGE_H_

#include "base/base_export.h"
#include "base/basictypes.h"

#if defined(OS_WIN)
#include <windows.h>
#elif defined(OS_POSIX)
#include <pthread.h>
#endif

namespace base {

namespace internal {

// WARNING: You should *NOT* be using this class directly.
// PlatformThreadLocalStorage is low-level abstraction to the OS's TLS
// interface, you should instead be using ThreadLocalStorage::StaticSlot/Slot.
class BASE_EXPORT PlatformThreadLocalStorage {
 public:

#if defined(OS_WIN)
  typedef unsigned long TLSKey;
  enum { TLS_KEY_OUT_OF_INDEXES = TLS_OUT_OF_INDEXES };
#elif defined(OS_POSIX)
  typedef pthread_key_t TLSKey;
  // The following is a "reserved key" which is used in our generic Chromium
  // ThreadLocalStorage implementation.  We expect that an OS will not return
  // such a key, but if it is returned (i.e., the OS tries to allocate it) we
  // will just request another key.
  enum { TLS_KEY_OUT_OF_INDEXES = 0x7FFFFFFF };
#endif

  // The following methods need to be supported on each OS platform, so that
  // the Chromium ThreadLocalStore functionality can be constructed.
  // Chromium will use these methods to acquire a single OS slot, and then use
  // that to support a much larger number of Chromium slots (independent of the
  // OS restrictions).
  // The following returns true if it successfully is able to return an OS
  // key in |key|.
  static bool AllocTLS(TLSKey* key);
  // Note: FreeTLS() doesn't have to be called, it is fine with this leak, OS
  // might not reuse released slot, you might just reset the TLS value with
  // SetTLSValue().
  static void FreeTLS(TLSKey key);
  static void SetTLSValue(TLSKey key, void* value);
  static void* GetTLSValue(TLSKey key);

  // Each platform (OS implementation) is required to call this method on each
  // terminating thread when the thread is about to terminate.  This method
  // will then call all registered destructors for slots in Chromium
  // ThreadLocalStorage, until there are no slot values remaining as having
  // been set on this thread.
  // Destructors may end up being called multiple times on a terminating
  // thread, as other destructors may re-set slots that were previously
  // destroyed.
#if defined(OS_WIN)
  // Since Windows which doesn't support TLS destructor, the implementation
  // should use GetTLSValue() to retrieve the value of TLS slot.
  static void OnThreadExit();
#elif defined(OS_POSIX)
  // |Value| is the data stored in TLS slot, The implementation can't use
  // GetTLSValue() to retrieve the value of slot as it has already been reset
  // in Posix.
  static void OnThreadExit(void* value);
#endif
};

}  // namespace internal

// Wrapper for thread local storage.  This class doesn't do much except provide
// an API for portability.
class BASE_EXPORT ThreadLocalStorage {
 public:

  // Prototype for the TLS destructor function, which can be optionally used to
  // cleanup thread local storage on thread exit.  'value' is the data that is
  // stored in thread local storage.
  typedef void (*TLSDestructorFunc)(void* value);

  // StaticSlot uses its own struct initializer-list style static
  // initialization, as base's LINKER_INITIALIZED requires a constructor and on
  // some compilers (notably gcc 4.4) this still ends up needing runtime
  // initialization.
  #define TLS_INITIALIZER {0}

  // A key representing one value stored in TLS.
  // Initialize like
  //   ThreadLocalStorage::StaticSlot my_slot = TLS_INITIALIZER;
  // If you're not using a static variable, use the convenience class
  // ThreadLocalStorage::Slot (below) instead.
  struct BASE_EXPORT StaticSlot {
    // Set up the TLS slot.  Called by the constructor.
    // 'destructor' is a pointer to a function to perform per-thread cleanup of
    // this object.  If set to NULL, no cleanup is done for this TLS slot.
    void Initialize(TLSDestructorFunc destructor);

    // Free a previously allocated TLS 'slot'.
    // If a destructor was set for this slot, removes
    // the destructor so that remaining threads exiting
    // will not free data.
    void Free();

    // Get the thread-local value stored in slot 'slot'.
    // Values are guaranteed to initially be zero.
    void* Get() const;

    // Set the thread-local value stored in slot 'slot' to
    // value 'value'.
    void Set(void* value);

    bool initialized() const { return initialized_; }

    // The internals of this struct should be considered private.
    bool initialized_;
    int slot_;
  };

  // A convenience wrapper around StaticSlot with a constructor. Can be used
  // as a member variable.
  class BASE_EXPORT Slot : public StaticSlot {
   public:
    // Calls StaticSlot::Initialize().
    explicit Slot(TLSDestructorFunc destructor = NULL);

   private:
    using StaticSlot::initialized_;
    using StaticSlot::slot_;

    DISALLOW_COPY_AND_ASSIGN(Slot);
  };

 private:
  DISALLOW_COPY_AND_ASSIGN(ThreadLocalStorage);
};

}  // namespace base

#endif  // BASE_THREADING_THREAD_LOCAL_STORAGE_H_
