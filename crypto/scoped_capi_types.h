// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_SCOPED_CAPI_TYPES_H_
#define CRYPTO_SCOPED_CAPI_TYPES_H_

#include <windows.h>

#include <algorithm>

#include "base/logging.h"
#include "crypto/wincrypt_shim.h"

namespace crypto {

// Simple destructor for the Free family of CryptoAPI functions, such as
// CryptDestroyHash, which take only a single argument to release.
template <typename CAPIHandle, BOOL (WINAPI *Destroyer)(CAPIHandle)>
struct CAPIDestroyer {
  void operator()(CAPIHandle handle) const {
    if (handle) {
      BOOL ok = Destroyer(handle);
      DCHECK(ok);
    }
  }
};

// Destructor for the Close/Release family of CryptoAPI functions, which take
// a second DWORD parameter indicating flags to use when closing or releasing.
// This includes functions like CertCloseStore or CryptReleaseContext.
template <typename CAPIHandle, BOOL (WINAPI *Destroyer)(CAPIHandle, DWORD),
          DWORD flags>
struct CAPIDestroyerWithFlags {
  void operator()(CAPIHandle handle) const {
    if (handle) {
      BOOL ok = Destroyer(handle, flags);
      DCHECK(ok);
    }
  }
};

// scoped_ptr-like class for the CryptoAPI cryptography and certificate
// handles. Because these handles are defined as integer types, and not
// pointers, the existing scoped classes, such as scoped_ptr, are insufficient.
// The semantics are the same as scoped_ptr.
template <class CAPIHandle, typename FreeProc>
class ScopedCAPIHandle {
 public:
  explicit ScopedCAPIHandle(CAPIHandle handle = NULL) : handle_(handle) {}

  ~ScopedCAPIHandle() {
    reset();
  }

  void reset(CAPIHandle handle = NULL) {
    if (handle_ != handle) {
      FreeProc free_proc;
      free_proc(handle_);
      handle_ = handle;
    }
  }

  operator CAPIHandle() const { return handle_; }
  CAPIHandle get() const { return handle_; }

  CAPIHandle* receive() {
    CHECK(handle_ == NULL);
    return &handle_;
  }

  bool operator==(CAPIHandle handle) const {
    return handle_ == handle;
  }

  bool operator!=(CAPIHandle handle) const {
    return handle_ != handle;
  }

  void swap(ScopedCAPIHandle& b) {
    CAPIHandle tmp = b.handle_;
    b.handle_ = handle_;
    handle_ = tmp;
  }

  CAPIHandle release() {
    CAPIHandle tmp = handle_;
    handle_ = NULL;
    return tmp;
  }

 private:
  CAPIHandle handle_;

  DISALLOW_COPY_AND_ASSIGN(ScopedCAPIHandle);
};

template<class CH, typename FP> inline
bool operator==(CH h, const ScopedCAPIHandle<CH, FP>& b) {
  return h == b.get();
}

template<class CH, typename FP> inline
bool operator!=(CH h, const ScopedCAPIHandle<CH, FP>& b) {
  return h != b.get();
}

typedef ScopedCAPIHandle<
    HCRYPTPROV,
    CAPIDestroyerWithFlags<HCRYPTPROV,
                           CryptReleaseContext, 0> > ScopedHCRYPTPROV;

typedef ScopedCAPIHandle<
    HCRYPTKEY, CAPIDestroyer<HCRYPTKEY, CryptDestroyKey> > ScopedHCRYPTKEY;

typedef ScopedCAPIHandle<
    HCRYPTHASH, CAPIDestroyer<HCRYPTHASH, CryptDestroyHash> > ScopedHCRYPTHASH;

}  // namespace crypto

#endif  // CRYPTO_SCOPED_CAPI_TYPES_H_
