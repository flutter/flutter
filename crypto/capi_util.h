// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_CAPI_UTIL_H_
#define CRYPTO_CAPI_UTIL_H_

#include <windows.h>

#include "crypto/crypto_export.h"
#include "crypto/wincrypt_shim.h"

namespace crypto {

// CryptAcquireContext when passed CRYPT_NEWKEYSET or CRYPT_DELETEKEYSET in
// flags is not thread-safe. For such calls, we create a global lock to
// synchronize it.
//
// From "Threading Issues with Cryptographic Service Providers",
// <http://msdn.microsoft.com/en-us/library/aa388149(v=VS.85).aspx>:
//
// "The CryptAcquireContext function is generally thread safe unless
// CRYPT_NEWKEYSET or CRYPT_DELETEKEYSET is specified in the dwFlags
// parameter."
CRYPTO_EXPORT BOOL CryptAcquireContextLocked(HCRYPTPROV* prov,
                                             LPCWSTR container,
                                             LPCWSTR provider,
                                             DWORD prov_type,
                                             DWORD flags);

// Wrappers of malloc and free for CryptoAPI routines that need memory
// allocators, such as in CRYPT_DECODE_PARA. Such routines require WINAPI
// calling conventions.
CRYPTO_EXPORT void* WINAPI CryptAlloc(size_t size);
CRYPTO_EXPORT void WINAPI CryptFree(void* p);

}  // namespace crypto

#endif  // CRYPTO_CAPI_UTIL_H_
