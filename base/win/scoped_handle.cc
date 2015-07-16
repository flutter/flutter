// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/scoped_handle.h"

#include <unordered_map>

#include "base/debug/alias.h"
#include "base/hash.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/synchronization/lock_impl.h"

extern "C" {
__declspec(dllexport) void* GetHandleVerifier();
typedef void* (*GetHandleVerifierFn)();
}

namespace {

struct HandleHash {
  size_t operator()(const HANDLE& handle) const {
    char buffer[sizeof(handle)];
    memcpy(buffer, &handle, sizeof(handle));
    return base::Hash(buffer, sizeof(buffer));
  }
};

struct Info {
  const void* owner;
  const void* pc1;
  const void* pc2;
  DWORD thread_id;
};
typedef std::unordered_map<HANDLE, Info, HandleHash> HandleMap;

// g_lock protects the handle map and setting g_active_verifier.
typedef base::internal::LockImpl NativeLock;
base::LazyInstance<NativeLock>::Leaky g_lock = LAZY_INSTANCE_INITIALIZER;

bool CloseHandleWrapper(HANDLE handle) {
  if (!::CloseHandle(handle))
    CHECK(false);
  return true;
}

// Simple automatic locking using a native critical section so it supports
// recursive locking.
class AutoNativeLock {
 public:
  explicit AutoNativeLock(NativeLock& lock) : lock_(lock) {
    lock_.Lock();
  }

  ~AutoNativeLock() {
    lock_.Unlock();
  }

 private:
  NativeLock& lock_;
  DISALLOW_COPY_AND_ASSIGN(AutoNativeLock);
};

// Implements the actual object that is verifying handles for this process.
// The active instance is shared across the module boundary but there is no
// way to delete this object from the wrong side of it (or any side, actually).
class ActiveVerifier {
 public:
  explicit ActiveVerifier(bool enabled)
      : enabled_(enabled), closing_(false), lock_(g_lock.Pointer()) {
  }

  // Retrieves the current verifier.
  static ActiveVerifier* Get();

  // The methods required by HandleTraits. They are virtual because we need to
  // forward the call execution to another module, instead of letting the
  // compiler call the version that is linked in the current module.
  virtual bool CloseHandle(HANDLE handle);
  virtual void StartTracking(HANDLE handle, const void* owner,
                             const void* pc1, const void* pc2);
  virtual void StopTracking(HANDLE handle, const void* owner,
                            const void* pc1, const void* pc2);
  virtual void Disable();
  virtual void OnHandleBeingClosed(HANDLE handle);

 private:
  ~ActiveVerifier();  // Not implemented.

  static void InstallVerifier();

  bool enabled_;
  bool closing_;
  NativeLock* lock_;
  HandleMap map_;
  DISALLOW_COPY_AND_ASSIGN(ActiveVerifier);
};
ActiveVerifier* g_active_verifier = NULL;

// static
ActiveVerifier* ActiveVerifier::Get() {
  if (!g_active_verifier)
    ActiveVerifier::InstallVerifier();

  return g_active_verifier;
}

// static
void ActiveVerifier::InstallVerifier() {
#if defined(COMPONENT_BUILD)
  AutoNativeLock lock(g_lock.Get());
  g_active_verifier = new ActiveVerifier(true);
#else
  // If you are reading this, wondering why your process seems deadlocked, take
  // a look at your DllMain code and remove things that should not be done
  // there, like doing whatever gave you that nice windows handle you are trying
  // to store in a ScopedHandle.
  HMODULE main_module = ::GetModuleHandle(NULL);
  GetHandleVerifierFn get_handle_verifier =
      reinterpret_cast<GetHandleVerifierFn>(::GetProcAddress(
          main_module, "GetHandleVerifier"));

  if (!get_handle_verifier) {
    g_active_verifier = new ActiveVerifier(false);
    return;
  }

  ActiveVerifier* verifier =
      reinterpret_cast<ActiveVerifier*>(get_handle_verifier());

  // This lock only protects against races in this module, which is fine.
  AutoNativeLock lock(g_lock.Get());
  g_active_verifier = verifier ? verifier : new ActiveVerifier(true);
#endif
}

bool ActiveVerifier::CloseHandle(HANDLE handle) {
  if (!enabled_)
    return CloseHandleWrapper(handle);

  AutoNativeLock lock(*lock_);
  closing_ = true;
  CloseHandleWrapper(handle);
  closing_ = false;

  return true;
}

void ActiveVerifier::StartTracking(HANDLE handle, const void* owner,
                                   const void* pc1, const void* pc2) {
  if (!enabled_)
    return;

  // Idea here is to make our handles non-closable until we close it ourselves.
  // Handles provided could be totally fabricated especially through our
  // unittest, we are ignoring that for now by not checking return value.
  ::SetHandleInformation(handle, HANDLE_FLAG_PROTECT_FROM_CLOSE,
                         HANDLE_FLAG_PROTECT_FROM_CLOSE);

  // Grab the thread id before the lock.
  DWORD thread_id = GetCurrentThreadId();

  AutoNativeLock lock(*lock_);

  Info handle_info = { owner, pc1, pc2, thread_id };
  std::pair<HANDLE, Info> item(handle, handle_info);
  std::pair<HandleMap::iterator, bool> result = map_.insert(item);
  if (!result.second) {
    Info other = result.first->second;
    base::debug::Alias(&other);
    CHECK(false);
  }
}

void ActiveVerifier::StopTracking(HANDLE handle, const void* owner,
                                  const void* pc1, const void* pc2) {
  if (!enabled_)
    return;

  // We expect handle to be protected till this point.
  DWORD flags = 0;
  if (::GetHandleInformation(handle, &flags)) {
    CHECK_NE(0U, (flags & HANDLE_FLAG_PROTECT_FROM_CLOSE));

    // Unprotect handle so that it could be closed.
    ::SetHandleInformation(handle, HANDLE_FLAG_PROTECT_FROM_CLOSE, 0);
  }

  AutoNativeLock lock(*lock_);
  HandleMap::iterator i = map_.find(handle);
  if (i == map_.end())
    CHECK(false);

  Info other = i->second;
  if (other.owner != owner) {
    base::debug::Alias(&other);
    CHECK(false);
  }

  map_.erase(i);
}

void ActiveVerifier::Disable() {
  enabled_ = false;
}

void ActiveVerifier::OnHandleBeingClosed(HANDLE handle) {
  AutoNativeLock lock(*lock_);
  if (closing_)
    return;

  HandleMap::iterator i = map_.find(handle);
  if (i == map_.end())
    return;

  Info other = i->second;
  base::debug::Alias(&other);
  CHECK(false);
}

}  // namespace

void* GetHandleVerifier() {
  return g_active_verifier;
}

namespace base {
namespace win {

// Static.
bool HandleTraits::CloseHandle(HANDLE handle) {
  return ActiveVerifier::Get()->CloseHandle(handle);
}

// Static.
void VerifierTraits::StartTracking(HANDLE handle, const void* owner,
                                   const void* pc1, const void* pc2) {
  return ActiveVerifier::Get()->StartTracking(handle, owner, pc1, pc2);
}

// Static.
void VerifierTraits::StopTracking(HANDLE handle, const void* owner,
                                  const void* pc1, const void* pc2) {
  return ActiveVerifier::Get()->StopTracking(handle, owner, pc1, pc2);
}

void DisableHandleVerifier() {
  return ActiveVerifier::Get()->Disable();
}

void OnHandleBeingClosed(HANDLE handle) {
  return ActiveVerifier::Get()->OnHandleBeingClosed(handle);
}

}  // namespace win
}  // namespace base
