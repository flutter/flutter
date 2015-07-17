// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/nss_key_util.h"

#include <cryptohi.h>
#include <keyhi.h>
#include <pk11pub.h>

#include "base/logging.h"
#include "base/stl_util.h"
#include "crypto/nss_util.h"

#if defined(USE_NSS_CERTS)
#include <secmod.h>
#include "crypto/nss_util_internal.h"
#endif

namespace crypto {

namespace {

#if defined(USE_NSS_CERTS)

struct PublicKeyInfoDeleter {
  inline void operator()(CERTSubjectPublicKeyInfo* spki) {
    SECKEY_DestroySubjectPublicKeyInfo(spki);
  }
};

typedef scoped_ptr<CERTSubjectPublicKeyInfo, PublicKeyInfoDeleter>
    ScopedPublicKeyInfo;

// Decodes |input| as a SubjectPublicKeyInfo and returns a SECItem containing
// the CKA_ID of that public key or nullptr on error.
ScopedSECItem MakeIDFromSPKI(const std::vector<uint8_t>& input) {
  // First, decode and save the public key.
  SECItem key_der;
  key_der.type = siBuffer;
  key_der.data = const_cast<unsigned char*>(vector_as_array(&input));
  key_der.len = input.size();

  ScopedPublicKeyInfo spki(SECKEY_DecodeDERSubjectPublicKeyInfo(&key_der));
  if (!spki)
    return nullptr;

  ScopedSECKEYPublicKey result(SECKEY_ExtractPublicKey(spki.get()));
  if (!result)
    return nullptr;

  // See pk11_MakeIDFromPublicKey from NSS. For now, only RSA keys are
  // supported.
  if (SECKEY_GetPublicKeyType(result.get()) != rsaKey)
    return nullptr;

  return ScopedSECItem(PK11_MakeIDFromPubKey(&result->u.rsa.modulus));
}

#endif  // defined(USE_NSS_CERTS)

}  // namespace

bool GenerateRSAKeyPairNSS(PK11SlotInfo* slot,
                           uint16_t num_bits,
                           bool permanent,
                           ScopedSECKEYPublicKey* public_key,
                           ScopedSECKEYPrivateKey* private_key) {
  DCHECK(slot);

  PK11RSAGenParams param;
  param.keySizeInBits = num_bits;
  param.pe = 65537L;
  SECKEYPublicKey* public_key_raw = nullptr;
  private_key->reset(PK11_GenerateKeyPair(slot, CKM_RSA_PKCS_KEY_PAIR_GEN,
                                          &param, &public_key_raw, permanent,
                                          permanent /* sensitive */, nullptr));
  if (!*private_key)
    return false;

  public_key->reset(public_key_raw);
  return true;
}

ScopedSECKEYPrivateKey ImportNSSKeyFromPrivateKeyInfo(
    PK11SlotInfo* slot,
    const std::vector<uint8_t>& input,
    bool permanent) {
  DCHECK(slot);

  ScopedPLArenaPool arena(PORT_NewArena(DER_DEFAULT_CHUNKSIZE));
  DCHECK(arena);

  // Excess data is illegal, but NSS silently accepts it, so first ensure that
  // |input| consists of a single ASN.1 element.
  SECItem input_item;
  input_item.data = const_cast<unsigned char*>(vector_as_array(&input));
  input_item.len = input.size();
  SECItem der_private_key_info;
  SECStatus rv =
      SEC_QuickDERDecodeItem(arena.get(), &der_private_key_info,
                             SEC_ASN1_GET(SEC_AnyTemplate), &input_item);
  if (rv != SECSuccess)
    return nullptr;

  // Allow the private key to be used for key unwrapping, data decryption,
  // and signature generation.
  const unsigned int key_usage =
      KU_KEY_ENCIPHERMENT | KU_DATA_ENCIPHERMENT | KU_DIGITAL_SIGNATURE;
  SECKEYPrivateKey* key_raw = nullptr;
  rv = PK11_ImportDERPrivateKeyInfoAndReturnKey(
      slot, &der_private_key_info, nullptr, nullptr, permanent,
      permanent /* sensitive */, key_usage, &key_raw, nullptr);
  if (rv != SECSuccess)
    return nullptr;
  return ScopedSECKEYPrivateKey(key_raw);
}

#if defined(USE_NSS_CERTS)

ScopedSECKEYPrivateKey FindNSSKeyFromPublicKeyInfo(
    const std::vector<uint8_t>& input) {
  EnsureNSSInit();

  ScopedSECItem cka_id(MakeIDFromSPKI(input));
  if (!cka_id)
    return nullptr;

  // Search all slots in all modules for the key with the given ID.
  AutoSECMODListReadLock auto_lock;
  const SECMODModuleList* head = SECMOD_GetDefaultModuleList();
  for (const SECMODModuleList* item = head; item != nullptr;
       item = item->next) {
    int slot_count = item->module->loaded ? item->module->slotCount : 0;
    for (int i = 0; i < slot_count; i++) {
      // Look for the key in slot |i|.
      ScopedSECKEYPrivateKey key(
          PK11_FindKeyByKeyID(item->module->slots[i], cka_id.get(), nullptr));
      if (key)
        return key.Pass();
    }
  }

  // The key wasn't found in any module.
  return nullptr;
}

ScopedSECKEYPrivateKey FindNSSKeyFromPublicKeyInfoInSlot(
    const std::vector<uint8_t>& input,
    PK11SlotInfo* slot) {
  DCHECK(slot);

  ScopedSECItem cka_id(MakeIDFromSPKI(input));
  if (!cka_id)
    return nullptr;

  return ScopedSECKEYPrivateKey(
      PK11_FindKeyByKeyID(slot, cka_id.get(), nullptr));
}

#endif  // defined(USE_NSS_CERTS)

}  // namespace crypto
