// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/hmac.h"

#include <nss.h>
#include <pk11pub.h>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "crypto/nss_util.h"
#include "crypto/scoped_nss_types.h"

namespace crypto {

struct HMACPlatformData {
  CK_MECHANISM_TYPE mechanism_;
  ScopedPK11Slot slot_;
  ScopedPK11SymKey sym_key_;
};

HMAC::HMAC(HashAlgorithm hash_alg)
    : hash_alg_(hash_alg), plat_(new HMACPlatformData()) {
  // Only SHA-1 and SHA-256 hash algorithms are supported.
  switch (hash_alg_) {
    case SHA1:
      plat_->mechanism_ = CKM_SHA_1_HMAC;
      break;
    case SHA256:
      plat_->mechanism_ = CKM_SHA256_HMAC;
      break;
    default:
      NOTREACHED() << "Unsupported hash algorithm";
      break;
  }
}

HMAC::~HMAC() {
}

bool HMAC::Init(const unsigned char *key, size_t key_length) {
  EnsureNSSInit();

  if (plat_->slot_.get()) {
    // Init must not be called more than twice on the same HMAC object.
    NOTREACHED();
    return false;
  }

  plat_->slot_.reset(PK11_GetInternalSlot());
  if (!plat_->slot_.get()) {
    NOTREACHED();
    return false;
  }

  SECItem key_item;
  key_item.type = siBuffer;
  key_item.data = const_cast<unsigned char*>(key);  // NSS API isn't const.
  key_item.len = key_length;

  plat_->sym_key_.reset(PK11_ImportSymKey(plat_->slot_.get(),
                                          plat_->mechanism_,
                                          PK11_OriginUnwrap,
                                          CKA_SIGN,
                                          &key_item,
                                          NULL));
  if (!plat_->sym_key_.get()) {
    NOTREACHED();
    return false;
  }

  return true;
}

bool HMAC::Sign(const base::StringPiece& data,
                unsigned char* digest,
                size_t digest_length) const {
  if (!plat_->sym_key_.get()) {
    // Init has not been called before Sign.
    NOTREACHED();
    return false;
  }

  SECItem param = { siBuffer, NULL, 0 };
  ScopedPK11Context context(PK11_CreateContextBySymKey(plat_->mechanism_,
                                                       CKA_SIGN,
                                                       plat_->sym_key_.get(),
                                                       &param));
  if (!context.get()) {
    NOTREACHED();
    return false;
  }

  if (PK11_DigestBegin(context.get()) != SECSuccess) {
    NOTREACHED();
    return false;
  }

  if (PK11_DigestOp(context.get(),
                    reinterpret_cast<const unsigned char*>(data.data()),
                    data.length()) != SECSuccess) {
    NOTREACHED();
    return false;
  }

  unsigned int len = 0;
  if (PK11_DigestFinal(context.get(),
                       digest, &len, digest_length) != SECSuccess) {
    NOTREACHED();
    return false;
  }

  return true;
}

}  // namespace crypto
