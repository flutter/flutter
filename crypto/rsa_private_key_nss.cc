// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/rsa_private_key.h"

#include <cryptohi.h>
#include <keyhi.h>
#include <pk11pub.h>

#include <list>

#include "base/debug/leak_annotations.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_util.h"
#include "crypto/nss_key_util.h"
#include "crypto/nss_util.h"
#include "crypto/scoped_nss_types.h"

// TODO(rafaelw): Consider using NSS's ASN.1 encoder.
namespace {

static bool ReadAttribute(SECKEYPrivateKey* key,
                          CK_ATTRIBUTE_TYPE type,
                          std::vector<uint8>* output) {
  SECItem item;
  SECStatus rv;
  rv = PK11_ReadRawAttribute(PK11_TypePrivKey, key, type, &item);
  if (rv != SECSuccess) {
    NOTREACHED();
    return false;
  }

  output->assign(item.data, item.data + item.len);
  SECITEM_FreeItem(&item, PR_FALSE);
  return true;
}

}  // namespace

namespace crypto {

RSAPrivateKey::~RSAPrivateKey() {
  if (key_)
    SECKEY_DestroyPrivateKey(key_);
  if (public_key_)
    SECKEY_DestroyPublicKey(public_key_);
}

// static
RSAPrivateKey* RSAPrivateKey::Create(uint16 num_bits) {
  EnsureNSSInit();

  ScopedPK11Slot slot(PK11_GetInternalSlot());
  if (!slot) {
    NOTREACHED();
    return nullptr;
  }

  ScopedSECKEYPublicKey public_key;
  ScopedSECKEYPrivateKey private_key;
  if (!GenerateRSAKeyPairNSS(slot.get(), num_bits, false /* not permanent */,
                             &public_key, &private_key)) {
    return nullptr;
  }

  RSAPrivateKey* rsa_key = new RSAPrivateKey;
  rsa_key->public_key_ = public_key.release();
  rsa_key->key_ = private_key.release();
  return rsa_key;
}

// static
RSAPrivateKey* RSAPrivateKey::CreateFromPrivateKeyInfo(
    const std::vector<uint8>& input) {
  EnsureNSSInit();

  ScopedPK11Slot slot(PK11_GetInternalSlot());
  if (!slot) {
    NOTREACHED();
    return nullptr;
  }
  ScopedSECKEYPrivateKey key(ImportNSSKeyFromPrivateKeyInfo(
      slot.get(), input, false /* not permanent */));
  if (!key || SECKEY_GetPrivateKeyType(key.get()) != rsaKey)
    return nullptr;
  return RSAPrivateKey::CreateFromKey(key.get());
}

// static
RSAPrivateKey* RSAPrivateKey::CreateFromKey(SECKEYPrivateKey* key) {
  DCHECK(key);
  if (SECKEY_GetPrivateKeyType(key) != rsaKey)
    return NULL;
  RSAPrivateKey* copy = new RSAPrivateKey();
  copy->key_ = SECKEY_CopyPrivateKey(key);
  copy->public_key_ = SECKEY_ConvertToPublicKey(key);
  if (!copy->key_ || !copy->public_key_) {
    NOTREACHED();
    delete copy;
    return NULL;
  }
  return copy;
}

RSAPrivateKey* RSAPrivateKey::Copy() const {
  RSAPrivateKey* copy = new RSAPrivateKey();
  copy->key_ = SECKEY_CopyPrivateKey(key_);
  copy->public_key_ = SECKEY_CopyPublicKey(public_key_);
  return copy;
}

bool RSAPrivateKey::ExportPrivateKey(std::vector<uint8>* output) const {
  PrivateKeyInfoCodec private_key_info(true);

  // Manually read the component attributes of the private key and build up
  // the PrivateKeyInfo.
  if (!ReadAttribute(key_, CKA_MODULUS, private_key_info.modulus()) ||
      !ReadAttribute(key_, CKA_PUBLIC_EXPONENT,
          private_key_info.public_exponent()) ||
      !ReadAttribute(key_, CKA_PRIVATE_EXPONENT,
          private_key_info.private_exponent()) ||
      !ReadAttribute(key_, CKA_PRIME_1, private_key_info.prime1()) ||
      !ReadAttribute(key_, CKA_PRIME_2, private_key_info.prime2()) ||
      !ReadAttribute(key_, CKA_EXPONENT_1, private_key_info.exponent1()) ||
      !ReadAttribute(key_, CKA_EXPONENT_2, private_key_info.exponent2()) ||
      !ReadAttribute(key_, CKA_COEFFICIENT, private_key_info.coefficient())) {
    NOTREACHED();
    return false;
  }

  return private_key_info.Export(output);
}

bool RSAPrivateKey::ExportPublicKey(std::vector<uint8>* output) const {
  ScopedSECItem der_pubkey(SECKEY_EncodeDERSubjectPublicKeyInfo(public_key_));
  if (!der_pubkey.get()) {
    NOTREACHED();
    return false;
  }

  output->assign(der_pubkey->data, der_pubkey->data + der_pubkey->len);
  return true;
}

RSAPrivateKey::RSAPrivateKey() : key_(NULL), public_key_(NULL) {
  EnsureNSSInit();
}

}  // namespace crypto
