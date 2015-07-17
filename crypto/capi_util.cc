// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/capi_util.h"

#include "base/basictypes.h"
#include "base/memory/singleton.h"
#include "base/synchronization/lock.h"

namespace {

class CAPIUtilSingleton {
 public:
  static CAPIUtilSingleton* GetInstance() {
    return Singleton<CAPIUtilSingleton>::get();
  }

  // Returns a lock to guard calls to CryptAcquireContext with
  // CRYPT_DELETEKEYSET or CRYPT_NEWKEYSET.
  base::Lock& acquire_context_lock() {
    return acquire_context_lock_;
  }

 private:
  friend class Singleton<CAPIUtilSingleton>;
  friend struct DefaultSingletonTraits<CAPIUtilSingleton>;

  CAPIUtilSingleton() {}

  base::Lock acquire_context_lock_;

  DISALLOW_COPY_AND_ASSIGN(CAPIUtilSingleton);
};

}  // namespace

namespace crypto {

BOOL CryptAcquireContextLocked(HCRYPTPROV* prov,
                               LPCWSTR container,
                               LPCWSTR provider,
                               DWORD prov_type,
                               DWORD flags) {
  base::AutoLock lock(CAPIUtilSingleton::GetInstance()->acquire_context_lock());
  return CryptAcquireContext(prov, container, provider, prov_type, flags);
}

void* WINAPI CryptAlloc(size_t size) {
  return malloc(size);
}

void WINAPI CryptFree(void* p) {
  free(p);
}

}  // namespace crypto
