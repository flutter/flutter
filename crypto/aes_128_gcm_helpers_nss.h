// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_AES_128_GCM_HELPERS_NSS_H_
#define CRYPTO_AES_128_GCM_HELPERS_NSS_H_

#include <pk11pub.h>
#include <secerr.h>

#include "crypto/crypto_export.h"

namespace crypto {

// When using the CKM_AES_GCM mechanism, one must consider that the mechanism
// had a bug in NSS 3.14.x (https://bugzilla.mozilla.org/show_bug.cgi?id=853285)
// which also lacks the PK11_Decrypt and PK11_Encrypt functions.
// (https://bugzilla.mozilla.org/show_bug.cgi?id=854063)
//
// While both these bugs were resolved in NSS 3.15, certain builds of Chromium
// may still be loading older versions of NSS as the system libraries. These
// helper methods emulate support by using CKM_AES_CTR and the GaloisHash.

// Helper function for using PK11_Decrypt. |mechanism| must be set to
// CKM_AES_GCM for this method.
CRYPTO_EXPORT SECStatus PK11DecryptHelper(PK11SymKey* key,
                                          CK_MECHANISM_TYPE mechanism,
                                          SECItem* param,
                                          unsigned char* out,
                                          unsigned int* out_len,
                                          unsigned int max_len,
                                          const unsigned char* data,
                                          unsigned int data_len);

// Helper function for using PK11_Encrypt. |mechanism| must be set to
// CKM_AES_GCM for this method.
CRYPTO_EXPORT SECStatus PK11EncryptHelper(PK11SymKey* key,
                                          CK_MECHANISM_TYPE mechanism,
                                          SECItem* param,
                                          unsigned char* out,
                                          unsigned int* out_len,
                                          unsigned int max_len,
                                          const unsigned char* data,
                                          unsigned int data_len);

}  // namespace crypto

#endif  // CRYPTO_AES_128_GCM_HELPERS_NSS_H_
