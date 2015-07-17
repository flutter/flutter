// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/symmetric_key.h"

#include <nss.h>
#include <pk11pub.h>

#include "base/logging.h"
#include "crypto/nss_util.h"

namespace crypto {

SymmetricKey::~SymmetricKey() {}

// static
SymmetricKey* SymmetricKey::GenerateRandomKey(Algorithm algorithm,
                                              size_t key_size_in_bits) {
  DCHECK_EQ(AES, algorithm);

  EnsureNSSInit();

  // Whitelist supported key sizes to avoid accidentaly relying on
  // algorithms available in NSS but not BoringSSL and vice
  // versa. Note that BoringSSL does not support AES-192.
  if (key_size_in_bits != 128 && key_size_in_bits != 256)
    return NULL;

  ScopedPK11Slot slot(PK11_GetInternalSlot());
  if (!slot.get())
    return NULL;

  PK11SymKey* sym_key = PK11_KeyGen(slot.get(), CKM_AES_KEY_GEN, NULL,
                                    key_size_in_bits / 8, NULL);
  if (!sym_key)
    return NULL;

  return new SymmetricKey(sym_key);
}

// static
SymmetricKey* SymmetricKey::DeriveKeyFromPassword(Algorithm algorithm,
                                                  const std::string& password,
                                                  const std::string& salt,
                                                  size_t iterations,
                                                  size_t key_size_in_bits) {
  EnsureNSSInit();
  if (salt.empty() || iterations == 0 || key_size_in_bits == 0)
    return NULL;

  if (algorithm == AES) {
    // Whitelist supported key sizes to avoid accidentaly relying on
    // algorithms available in NSS but not BoringSSL and vice
    // versa. Note that BoringSSL does not support AES-192.
    if (key_size_in_bits != 128 && key_size_in_bits != 256)
      return NULL;
  }

  SECItem password_item;
  password_item.type = siBuffer;
  password_item.data = reinterpret_cast<unsigned char*>(
      const_cast<char *>(password.data()));
  password_item.len = password.size();

  SECItem salt_item;
  salt_item.type = siBuffer;
  salt_item.data = reinterpret_cast<unsigned char*>(
      const_cast<char *>(salt.data()));
  salt_item.len = salt.size();

  SECOidTag cipher_algorithm =
      algorithm == AES ? SEC_OID_AES_256_CBC : SEC_OID_HMAC_SHA1;
  ScopedSECAlgorithmID alg_id(PK11_CreatePBEV2AlgorithmID(SEC_OID_PKCS5_PBKDF2,
                                                          cipher_algorithm,
                                                          SEC_OID_HMAC_SHA1,
                                                          key_size_in_bits / 8,
                                                          iterations,
                                                          &salt_item));
  if (!alg_id.get())
    return NULL;

  ScopedPK11Slot slot(PK11_GetInternalSlot());
  if (!slot.get())
    return NULL;

  PK11SymKey* sym_key = PK11_PBEKeyGen(slot.get(), alg_id.get(), &password_item,
                                       PR_FALSE, NULL);
  if (!sym_key)
    return NULL;

  return new SymmetricKey(sym_key);
}

// static
SymmetricKey* SymmetricKey::Import(Algorithm algorithm,
                                   const std::string& raw_key) {
  EnsureNSSInit();

  if (algorithm == AES) {
    // Whitelist supported key sizes to avoid accidentaly relying on
    // algorithms available in NSS but not BoringSSL and vice
    // versa. Note that BoringSSL does not support AES-192.
    if (raw_key.size() != 128/8 && raw_key.size() != 256/8)
      return NULL;
  }

  CK_MECHANISM_TYPE cipher =
      algorithm == AES ? CKM_AES_CBC : CKM_SHA_1_HMAC;

  SECItem key_item;
  key_item.type = siBuffer;
  key_item.data = reinterpret_cast<unsigned char*>(
      const_cast<char *>(raw_key.data()));
  key_item.len = raw_key.size();

  ScopedPK11Slot slot(PK11_GetInternalSlot());
  if (!slot.get())
    return NULL;

  // The exact value of the |origin| argument doesn't matter to NSS as long as
  // it's not PK11_OriginFortezzaHack, so we pass PK11_OriginUnwrap as a
  // placeholder.
  PK11SymKey* sym_key = PK11_ImportSymKey(slot.get(), cipher, PK11_OriginUnwrap,
                                          CKA_ENCRYPT, &key_item, NULL);
  if (!sym_key)
    return NULL;

  return new SymmetricKey(sym_key);
}

bool SymmetricKey::GetRawKey(std::string* raw_key) {
  SECStatus rv = PK11_ExtractKeyValue(key_.get());
  if (SECSuccess != rv)
    return false;

  SECItem* key_item = PK11_GetKeyData(key_.get());
  if (!key_item)
    return false;

  raw_key->assign(reinterpret_cast<char*>(key_item->data), key_item->len);
  return true;
}

SymmetricKey::SymmetricKey(PK11SymKey* key) : key_(key) {
  DCHECK(key);
}

}  // namespace crypto
