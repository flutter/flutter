// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/ec_private_key.h"

extern "C" {
// Work around NSS missing SEC_BEGIN_PROTOS in secmodt.h.  This must come before
// other NSS headers.
#include <secmodt.h>
}

#include <cryptohi.h>
#include <keyhi.h>
#include <pk11pub.h>
#include <secmod.h>

#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "crypto/nss_util.h"
#include "crypto/nss_util_internal.h"
#include "crypto/scoped_nss_types.h"
#include "crypto/third_party/nss/chromium-nss.h"

namespace {

PK11SlotInfo* GetTempKeySlot() {
  return PK11_GetInternalSlot();
}

class EllipticCurveSupportChecker {
 public:
  EllipticCurveSupportChecker() {
    // NOTE: we can do this check here only because we use the NSS internal
    // slot.  If we support other slots in the future, checking whether they
    // support ECDSA may block NSS, and the value may also change as devices are
    // inserted/removed, so we would need to re-check on every use.
    crypto::EnsureNSSInit();
    crypto::ScopedPK11Slot slot(GetTempKeySlot());
    supported_ = PK11_DoesMechanism(slot.get(), CKM_EC_KEY_PAIR_GEN) &&
        PK11_DoesMechanism(slot.get(), CKM_ECDSA);
  }

  bool Supported() {
    return supported_;
  }

 private:
  bool supported_;
};

static base::LazyInstance<EllipticCurveSupportChecker>::Leaky
    g_elliptic_curve_supported = LAZY_INSTANCE_INITIALIZER;

// Copied from rsa_private_key_nss.cc.
static bool ReadAttribute(SECKEYPrivateKey* key,
                          CK_ATTRIBUTE_TYPE type,
                          std::vector<uint8>* output) {
  SECItem item;
  SECStatus rv;
  rv = PK11_ReadRawAttribute(PK11_TypePrivKey, key, type, &item);
  if (rv != SECSuccess) {
    DLOG(ERROR) << "PK11_ReadRawAttribute: " << PORT_GetError();
    return false;
  }

  output->assign(item.data, item.data + item.len);
  SECITEM_FreeItem(&item, PR_FALSE);
  return true;
}

}  // namespace

namespace crypto {

ECPrivateKey::~ECPrivateKey() {
  if (key_)
    SECKEY_DestroyPrivateKey(key_);
  if (public_key_)
    SECKEY_DestroyPublicKey(public_key_);
}

// static
bool ECPrivateKey::IsSupported() {
  return g_elliptic_curve_supported.Get().Supported();
}

// static
ECPrivateKey* ECPrivateKey::Create() {
  EnsureNSSInit();

  ScopedPK11Slot slot(GetTempKeySlot());
  if (!slot)
    return nullptr;

  scoped_ptr<ECPrivateKey> result(new ECPrivateKey);

  SECOidData* oid_data = SECOID_FindOIDByTag(SEC_OID_SECG_EC_SECP256R1);
  if (!oid_data) {
    DLOG(ERROR) << "SECOID_FindOIDByTag: " << PORT_GetError();
    return nullptr;
  }

  // SECKEYECParams is a SECItem containing the DER encoded ASN.1 ECParameters
  // value.  For a named curve, that is just the OBJECT IDENTIFIER of the curve.
  // In addition to the oid data, the encoding requires one byte for the ASN.1
  // tag and one byte for the length (assuming the length is <= 127).
  CHECK_LE(oid_data->oid.len, 127U);
  std::vector<unsigned char> parameters_buf(2 + oid_data->oid.len);
  SECKEYECParams ec_parameters = {
    siDEROID, &parameters_buf[0],
    static_cast<unsigned>(parameters_buf.size())
  };

  ec_parameters.data[0] = SEC_ASN1_OBJECT_ID;
  ec_parameters.data[1] = static_cast<unsigned char>(oid_data->oid.len);
  memcpy(ec_parameters.data + 2, oid_data->oid.data, oid_data->oid.len);

  result->key_ = PK11_GenerateKeyPair(slot.get(),
                                      CKM_EC_KEY_PAIR_GEN,
                                      &ec_parameters,
                                      &result->public_key_,
                                      PR_FALSE /* not permanent */,
                                      PR_FALSE /* not sensitive */,
                                      NULL);
  if (!result->key_) {
    DLOG(ERROR) << "PK11_GenerateKeyPair: " << PORT_GetError();
    return nullptr;
  }
  CHECK_EQ(ecKey, SECKEY_GetPublicKeyType(result->public_key_));

  return result.release();
}

// static
ECPrivateKey* ECPrivateKey::CreateFromEncryptedPrivateKeyInfo(
    const std::string& password,
    const std::vector<uint8>& encrypted_private_key_info,
    const std::vector<uint8>& subject_public_key_info) {
  EnsureNSSInit();

  ScopedPK11Slot slot(GetTempKeySlot());
  if (!slot)
    return nullptr;

  scoped_ptr<ECPrivateKey> result(new ECPrivateKey);

  SECItem encoded_spki = {
    siBuffer,
    const_cast<unsigned char*>(&subject_public_key_info[0]),
    static_cast<unsigned>(subject_public_key_info.size())
  };
  CERTSubjectPublicKeyInfo* decoded_spki = SECKEY_DecodeDERSubjectPublicKeyInfo(
      &encoded_spki);
  if (!decoded_spki) {
    DLOG(ERROR) << "SECKEY_DecodeDERSubjectPublicKeyInfo: " << PORT_GetError();
    return nullptr;
  }

  bool success = ImportFromEncryptedPrivateKeyInfo(
      slot.get(),
      password,
      &encrypted_private_key_info[0],
      encrypted_private_key_info.size(),
      decoded_spki,
      false /* not permanent */,
      false /* not sensitive */,
      &result->key_,
      &result->public_key_);

  SECKEY_DestroySubjectPublicKeyInfo(decoded_spki);

  if (success) {
    CHECK_EQ(ecKey, SECKEY_GetPublicKeyType(result->public_key_));
    return result.release();
  }

  return nullptr;
}

// static
bool ECPrivateKey::ImportFromEncryptedPrivateKeyInfo(
    PK11SlotInfo* slot,
    const std::string& password,
    const uint8* encrypted_private_key_info,
    size_t encrypted_private_key_info_len,
    CERTSubjectPublicKeyInfo* decoded_spki,
    bool permanent,
    bool sensitive,
    SECKEYPrivateKey** key,
    SECKEYPublicKey** public_key) {
  if (!slot)
    return false;

  *public_key = SECKEY_ExtractPublicKey(decoded_spki);

  if (!*public_key) {
    DLOG(ERROR) << "SECKEY_ExtractPublicKey: " << PORT_GetError();
    return false;
  }

  if (SECKEY_GetPublicKeyType(*public_key) != ecKey) {
    DLOG(ERROR) << "The public key is not an EC key";
    SECKEY_DestroyPublicKey(*public_key);
    *public_key = NULL;
    return false;
  }

  SECItem encoded_epki = {
    siBuffer,
    const_cast<unsigned char*>(encrypted_private_key_info),
    static_cast<unsigned>(encrypted_private_key_info_len)
  };
  SECKEYEncryptedPrivateKeyInfo epki;
  memset(&epki, 0, sizeof(epki));

  ScopedPLArenaPool arena(PORT_NewArena(DER_DEFAULT_CHUNKSIZE));

  SECStatus rv = SEC_QuickDERDecodeItem(
      arena.get(),
      &epki,
      SEC_ASN1_GET(SECKEY_EncryptedPrivateKeyInfoTemplate),
      &encoded_epki);
  if (rv != SECSuccess) {
    DLOG(ERROR) << "SEC_QuickDERDecodeItem: " << PORT_GetError();
    SECKEY_DestroyPublicKey(*public_key);
    *public_key = NULL;
    return false;
  }

  SECItem password_item = {
    siBuffer,
    reinterpret_cast<unsigned char*>(const_cast<char*>(password.data())),
    static_cast<unsigned>(password.size())
  };

  rv = ImportEncryptedECPrivateKeyInfoAndReturnKey(
      slot,
      &epki,
      &password_item,
      NULL,  // nickname
      &(*public_key)->u.ec.publicValue,
      permanent,
      sensitive,
      key,
      NULL);  // wincx
  if (rv != SECSuccess) {
    DLOG(ERROR) << "ImportEncryptedECPrivateKeyInfoAndReturnKey: "
                << PORT_GetError();
    SECKEY_DestroyPublicKey(*public_key);
    *public_key = NULL;
    return false;
  }

  return true;
}

ECPrivateKey* ECPrivateKey::Copy() const {
  scoped_ptr<ECPrivateKey> copy(new ECPrivateKey);
  if (key_) {
    copy->key_ = SECKEY_CopyPrivateKey(key_);
    if (!copy->key_)
      return NULL;
  }
  if (public_key_) {
    copy->public_key_ = SECKEY_CopyPublicKey(public_key_);
    if (!copy->public_key_)
      return NULL;
  }
  return copy.release();
}

bool ECPrivateKey::ExportEncryptedPrivateKey(
    const std::string& password,
    int iterations,
    std::vector<uint8>* output) {
  // We export as an EncryptedPrivateKeyInfo bundle instead of a plain PKCS #8
  // PrivateKeyInfo because PK11_ImportDERPrivateKeyInfoAndReturnKey doesn't
  // support EC keys.
  // https://bugzilla.mozilla.org/show_bug.cgi?id=327773
  SECItem password_item = {
    siBuffer,
    reinterpret_cast<unsigned char*>(const_cast<char*>(password.data())),
    static_cast<unsigned>(password.size())
  };

  SECKEYEncryptedPrivateKeyInfo* encrypted = PK11_ExportEncryptedPrivKeyInfo(
      NULL,  // Slot, optional.
      SEC_OID_PKCS12_V2_PBE_WITH_SHA1_AND_3KEY_TRIPLE_DES_CBC,
      &password_item,
      key_,
      iterations,
      NULL);  // wincx.

  if (!encrypted) {
    DLOG(ERROR) << "PK11_ExportEncryptedPrivKeyInfo: " << PORT_GetError();
    return false;
  }

  ScopedPLArenaPool arena(PORT_NewArena(DER_DEFAULT_CHUNKSIZE));
  SECItem der_key = {siBuffer, NULL, 0};
  SECItem* encoded_item = SEC_ASN1EncodeItem(
      arena.get(),
      &der_key,
      encrypted,
      SEC_ASN1_GET(SECKEY_EncryptedPrivateKeyInfoTemplate));
  SECKEY_DestroyEncryptedPrivateKeyInfo(encrypted, PR_TRUE);
  if (!encoded_item) {
    DLOG(ERROR) << "SEC_ASN1EncodeItem: " << PORT_GetError();
    return false;
  }

  output->assign(der_key.data, der_key.data + der_key.len);

  return true;
}

bool ECPrivateKey::ExportPublicKey(std::vector<uint8>* output) {
  ScopedSECItem der_pubkey(
      SECKEY_EncodeDERSubjectPublicKeyInfo(public_key_));
  if (!der_pubkey.get()) {
    return false;
  }

  output->assign(der_pubkey->data, der_pubkey->data + der_pubkey->len);
  return true;
}

bool ECPrivateKey::ExportRawPublicKey(std::string* output) {
  // public_key_->u.ec.publicValue is an ANSI X9.62 public key which, for
  // a P-256 key, is 0x04 (meaning uncompressed) followed by the x and y field
  // elements as 32-byte, big-endian numbers.
  static const unsigned int kExpectedKeyLength = 65;

  CHECK_EQ(ecKey, SECKEY_GetPublicKeyType(public_key_));
  const unsigned char* const data = public_key_->u.ec.publicValue.data;
  const unsigned int len = public_key_->u.ec.publicValue.len;
  if (len != kExpectedKeyLength || data[0] != 0x04)
    return false;

  output->assign(reinterpret_cast<const char*>(data + 1),
                 kExpectedKeyLength - 1);
  return true;
}

bool ECPrivateKey::ExportValue(std::vector<uint8>* output) {
  return ReadAttribute(key_, CKA_VALUE, output);
}

bool ECPrivateKey::ExportECParams(std::vector<uint8>* output) {
  return ReadAttribute(key_, CKA_EC_PARAMS, output);
}

ECPrivateKey::ECPrivateKey() : key_(NULL), public_key_(NULL) {}

}  // namespace crypto
