// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/thread_local_storage.h"

#include "base/atomicops.h"
#include "base/logging.h"

using base::internal::PlatformThreadLocalStorage;

namespace {
// In order to make TLS destructors work, we need to keep around a function
// pointer to the destructor for each slot. We keep this array of pointers in a
// global (static) array.
// We use the single OS-level TLS slot (giving us one pointer per thread) to
// hold a pointer to a per-thread array (table) of slots that we allocate to
// Chromium consumers.

// g_native_tls_key is the one native TLS that we use.  It stores our table.
base::subtle::Atomic32 g_native_tls_key =
    PlatformThreadLocalStorage::TLS_KEY_OUT_OF_INDEXES;

// g_last_used_tls_key is the high-water-mark of allocated thread local storage.
// Each allocation is an index into our g_tls_destructors[].  Each such index is
// assigned to the instance variable slot_ in a ThreadLocalStorage::Slot
// instance.  We reserve the value slot_ == 0 to indicate that the corresponding
// instance of ThreadLocalStorage::Slot has been freed (i.e., destructor called,
// etc.).  This reserved use of 0 is then stated as the initial value of
// g_last_used_tls_key, so that the first issued index will be 1.
base::subtle::Atomic32 g_last_used_tls_key = 0;

// The maximum number of 'slots' in our thread local storage stack.
const int kThreadLocalStorageSize = 256;

// The maximum number of times to try to clear slots by calling destructors.
// Use pthread naming convention for clarity.
const int kMaxDestructorIterations = kThreadLocalStorageSize;

// An array of destructor function pointers for the slots.  If a slot has a
// destructor, it will be stored in its corresponding entry in this array.
// The elements are volatile to ensure that when the compiler reads the value
// to potentially call the destructor, it does so once, and that value is tested
// for null-ness and then used. Yes, that would be a weird de-optimization,
// but I can imagine some register machines where it was just as easy to
// re-fetch an array element, and I want to be sure a call to free the key
// (i.e., null out the destructor entry) that happens on a separate thread can't
// hurt the racy calls to the destructors on another thread.
volatile base::ThreadLocalStorage::TLSDestructorFunc
    g_tls_destructors[kThreadLocalStorageSize];

// This function is called to initialize our entire Chromium TLS system.
// It may be called very early, and we need to complete most all of the setup
// (initialization) before calling *any* memory allocator functions, which may
// recursively depend on this initialization.
// As a result, we use Atomics, and avoid anything (like a singleton) that might
// require memory allocations.
void** ConstructTlsVector() {
  PlatformThreadLocalStorage::TLSKey key =
      base::subtle::NoBarrier_Load(&g_native_tls_key);
  if (key == PlatformThreadLocalStorage::TLS_KEY_OUT_OF_INDEXES) {
    CHECK(PlatformThreadLocalStorage::AllocTLS(&key));

    // The TLS_KEY_OUT_OF_INDEXES is used to find out whether the key is set or
    // not in NoBarrier_CompareAndSwap, but Posix doesn't have invalid key, we
    // define an almost impossible value be it.
    // If we really get TLS_KEY_OUT_OF_INDEXES as value of key, just alloc
    // another TLS slot.
    if (key == PlatformThreadLocalStorage::TLS_KEY_OUT_OF_INDEXES) {
      PlatformThreadLocalStorage::TLSKey tmp = key;
      CHECK(PlatformThreadLocalStorage::AllocTLS(&key) &&
            key != PlatformThreadLocalStorage::TLS_KEY_OUT_OF_INDEXES);
      PlatformThreadLocalStorage::FreeTLS(tmp);
    }
    // Atomically test-and-set the tls_key.  If the key is
    // TLS_KEY_OUT_OF_INDEXES, go ahead and set it.  Otherwise, do nothing, as
    // another thread already did our dirty work.
    if (PlatformThreadLocalStorage::TLS_KEY_OUT_OF_INDEXES !=
        base::subtle::NoBarrier_CompareAndSwap(&g_native_tls_key,
            PlatformThreadLocalStorage::TLS_KEY_OUT_OF_INDEXES, key)) {
      // We've been shortcut. Another thread replaced g_native_tls_key first so
      // we need to destroy our index and use the one the other thread got
      // first.
      PlatformThreadLocalStorage::FreeTLS(key);
      key = base::subtle::NoBarrier_Load(&g_native_tls_key);
    }
  }
  CHECK(!PlatformThreadLocalStorage::GetTLSValue(key));

  // Some allocators, such as TCMalloc, make use of thread local storage.
  // As a result, any attempt to call new (or malloc) will lazily cause such a
  // system to initialize, which will include registering for a TLS key.  If we
  // are not careful here, then that request to create a key will call new back,
  // and we'll have an infinite loop.  We avoid that as follows:
  // Use a stack allocated vector, so that we don't have dependence on our
  // allocator until our service is in place.  (i.e., don't even call new until
  // after we're setup)
  void* stack_allocated_tls_data[kThreadLocalStorageSize];
  memset(stack_allocated_tls_data, 0, sizeof(stack_allocated_tls_data));
  // Ensure that any rentrant calls change the temp version.
  PlatformThreadLocalStorage::SetTLSValue(key, stack_allocated_tls_data);

  // Allocate an array to store our data.
  void** tls_data = new void*[kThreadLocalStorageSize];
  memcpy(tls_data, stack_allocated_tls_data, sizeof(stack_allocated_tls_data));
  PlatformThreadLocalStorage::SetTLSValue(key, tls_data);
  return tls_data;
}

void OnThreadExitInternal(void* value) {
  DCHECK(value);
  void** tls_data = static_cast<void**>(value);
  // Some allocators, such as TCMalloc, use TLS.  As a result, when a thread
  // terminates, one of the destructor calls we make may be to shut down an
  // allocator.  We have to be careful that after we've shutdown all of the
  // known destructors (perchance including an allocator), that we don't call
  // the allocator and cause it to resurrect itself (with no possibly destructor
  // call to follow).  We handle this problem as follows:
  // Switch to using a stack allocated vector, so that we don't have dependence
  // on our allocator after we have called all g_tls_destructors.  (i.e., don't
  // even call delete[] after we're done with destructors.)
  void* stack_allocated_tls_data[kThreadLocalStorageSize];
  memcpy(stack_allocated_tls_data, tls_data, sizeof(stack_allocated_tls_data));
  // Ensure that any re-entrant calls change the temp version.
  PlatformThreadLocalStorage::TLSKey key =
      base::subtle::NoBarrier_Load(&g_native_tls_key);
  PlatformThreadLocalStorage::SetTLSValue(key, stack_allocated_tls_data);
  delete[] tls_data;  // Our last dependence on an allocator.

  int remaining_attempts = kMaxDestructorIterations;
  bool need_to_scan_destructors = true;
  while (need_to_scan_destructors) {
    need_to_scan_destructors = false;
    // Try to destroy the first-created-slot (which is slot 1) in our last
    // destructor call.  That user was able to function, and define a slot with
    // no other services running, so perhaps it is a basic service (like an
    // allocator) and should also be destroyed last.  If we get the order wrong,
    // then we'll itterate several more times, so it is really not that
    // critical (but it might help).
    base::subtle::Atomic32 last_used_tls_key =
        base::subtle::NoBarrier_Load(&g_last_used_tls_key);
    for (int slot = last_used_tls_key; slot > 0; --slot) {
      void* tls_value = stack_allocated_tls_data[slot];
      if (tls_value == NULL)
        continue;

      base::ThreadLocalStorage::TLSDestructorFunc destructor =
          g_tls_destructors[slot];
      if (destructor == NULL)
        continue;
      stack_allocated_tls_data[slot] = NULL;  // pre-clear the slot.
      destructor(tls_value);
      // Any destructor might have called a different service, which then set
      // a different slot to a non-NULL value.  Hence we need to check
      // the whole vector again.  This is a pthread standard.
      need_to_scan_destructors = true;
    }
    if (--remaining_attempts <= 0) {
      NOTREACHED();  // Destructors might not have been called.
      break;
    }
  }

  // Remove our stack allocated vector.
  PlatformThreadLocalStorage::SetTLSValue(key, NULL);
}

}  // namespace

namespace base {

namespace internal {

#if defined(OS_WIN)
void PlatformThreadLocalStorage::OnThreadExit() {
  PlatformThreadLocalStorage::TLSKey key =
      base::subtle::NoBarrier_Load(&g_native_tls_key);
  if (key == PlatformThreadLocalStorage::TLS_KEY_OUT_OF_INDEXES)
    return;
  void *tls_data = GetTLSValue(key);
  // Maybe we have never initialized TLS for this thread.
  if (!tls_data)
    return;
  OnThreadExitInternal(tls_data);
}
#elif defined(OS_POSIX)
void PlatformThreadLocalStorage::OnThreadExit(void* value) {
  OnThreadExitInternal(value);
}
#endif  // defined(OS_WIN)

}  // namespace internal

ThreadLocalStorage::Slot::Slot(TLSDestructorFunc destructor) {
  initialized_ = false;
  slot_ = 0;
  Initialize(destructor);
}

void ThreadLocalStorage::StaticSlot::Initialize(TLSDestructorFunc destructor) {
  PlatformThreadLocalStorage::TLSKey key =
      base::subtle::NoBarrier_Load(&g_native_tls_key);
  if (key == PlatformThreadLocalStorage::TLS_KEY_OUT_OF_INDEXES ||
      !PlatformThreadLocalStorage::GetTLSValue(key))
    ConstructTlsVector();

  // Grab a new slot.
  slot_ = base::subtle::NoBarrier_AtomicIncrement(&g_last_used_tls_key, 1);
  DCHECK_GT(slot_, 0);
  CHECK_LT(slot_, kThreadLocalStorageSize);

  // Setup our destructor.
  g_tls_destructors[slot_] = destructor;
  initialized_ = true;
}

void ThreadLocalStorage::StaticSlot::Free() {
  // At this time, we don't reclaim old indices for TLS slots.
  // So all we need to do is wipe the destructor.
  DCHECK_GT(slot_, 0);
  DCHECK_LT(slot_, kThreadLocalStorageSize);
  g_tls_destructors[slot_] = NULL;
  slot_ = 0;
  initialized_ = false;
}

void* ThreadLocalStorage::StaticSlot::Get() const {
  void** tls_data = static_cast<void**>(
      PlatformThreadLocalStorage::GetTLSValue(
          base::subtle::NoBarrier_Load(&g_native_tls_key)));
  if (!tls_data)
    tls_data = ConstructTlsVector();
  DCHECK_GT(slot_, 0);
  DCHECK_LT(slot_, kThreadLocalStorageSize);
  return tls_data[slot_];
}

void ThreadLocalStorage::StaticSlot::Set(void* value) {
  void** tls_data = static_cast<void**>(
      PlatformThreadLocalStorage::GetTLSValue(
          base::subtle::NoBarrier_Load(&g_native_tls_key)));
  if (!tls_data)
    tls_data = ConstructTlsVector();
  DCHECK_GT(slot_, 0);
  DCHECK_LT(slot_, kThreadLocalStorageSize);
  tls_data[slot_] = value;
}

}  // namespace base
