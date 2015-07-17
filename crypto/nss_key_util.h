// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_NSS_KEY_UTIL_H_
#define CRYPTO_NSS_KEY_UTIL_H_

#include <stdint.h>

#include <vector>

#include "build/build_config.h"
#include "crypto/crypto_export.h"
#include "crypto/scoped_nss_types.h"

typedef struct PK11SlotInfoStr PK11SlotInfo;

namespace crypto {

// Generates a new RSA keypair of size |num_bits| in |slot|. Returns true on
// success and false on failure. If |permanent| is true, the resulting key is
// permanent and is not exportable in plaintext form.
CRYPTO_EXPORT bool GenerateRSAKeyPairNSS(
    PK11SlotInfo* slot,
    uint16_t num_bits,
    bool permanent,
    ScopedSECKEYPublicKey* out_public_key,
    ScopedSECKEYPrivateKey* out_private_key);

// Imports a private key from |input| into |slot|. |input| is interpreted as a
// DER-encoded PrivateKeyInfo block from PKCS #8. Returns nullptr on error. If
// |permanent| is true, the resulting key is permanent and is not exportable in
// plaintext form.
CRYPTO_EXPORT ScopedSECKEYPrivateKey
ImportNSSKeyFromPrivateKeyInfo(PK11SlotInfo* slot,
                               const std::vector<uint8_t>& input,
                               bool permanent);

#if defined(USE_NSS_CERTS)

// Decodes |input| as a DER-encoded X.509 SubjectPublicKeyInfo and searches for
// the private key half in the key database. Returns the private key on success
// or nullptr on error.
CRYPTO_EXPORT ScopedSECKEYPrivateKey
FindNSSKeyFromPublicKeyInfo(const std::vector<uint8_t>& input);

// Decodes |input| as a DER-encoded X.509 SubjectPublicKeyInfo and searches for
// the private key half in the slot specified by |slot|. Returns the private key
// on success or nullptr on error.
CRYPTO_EXPORT ScopedSECKEYPrivateKey
FindNSSKeyFromPublicKeyInfoInSlot(const std::vector<uint8_t>& input,
                                  PK11SlotInfo* slot);

#endif  // defined(USE_NSS_CERTS)

}  // namespace crypto

#endif  // CRYPTO_NSS_KEY_UTIL_H_
