// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/hmac.h"

#include <windows.h>

#include <algorithm>
#include <vector>

#include "base/logging.h"
#include "crypto/scoped_capi_types.h"
#include "crypto/third_party/nss/chromium-blapi.h"
#include "crypto/third_party/nss/chromium-sha256.h"
#include "crypto/wincrypt_shim.h"

namespace crypto {

namespace {

// Implementation of HMAC-SHA-256:
//
// SHA-256 is supported in Windows XP SP3 or later.  We still need to support
// Windows XP SP2, so unfortunately we have to implement HMAC-SHA-256 here.

enum {
  SHA256_BLOCK_SIZE = 64  // Block size (in bytes) of the input to SHA-256.
};

// NSS doesn't accept size_t for text size, divide the data into smaller
// chunks as needed.
void Wrapped_SHA256_Update(SHA256Context* ctx, const unsigned char* text,
                           size_t text_len) {
  const unsigned int kChunkSize = 1 << 30;
  while (text_len > kChunkSize) {
    SHA256_Update(ctx, text, kChunkSize);
    text += kChunkSize;
    text_len -= kChunkSize;
  }
  SHA256_Update(ctx, text, (unsigned int)text_len);
}

// See FIPS 198: The Keyed-Hash Message Authentication Code (HMAC).
void ComputeHMACSHA256(const unsigned char* key, size_t key_len,
                       const unsigned char* text, size_t text_len,
                       unsigned char* output, size_t output_len) {
  SHA256Context ctx;

  // Pre-process the key, if necessary.
  unsigned char key0[SHA256_BLOCK_SIZE];
  if (key_len > SHA256_BLOCK_SIZE) {
    SHA256_Begin(&ctx);
    Wrapped_SHA256_Update(&ctx, key, key_len);
    SHA256_End(&ctx, key0, NULL, SHA256_LENGTH);
    memset(key0 + SHA256_LENGTH, 0, SHA256_BLOCK_SIZE - SHA256_LENGTH);
  } else {
    memcpy(key0, key, key_len);
    if (key_len < SHA256_BLOCK_SIZE)
      memset(key0 + key_len, 0, SHA256_BLOCK_SIZE - key_len);
  }

  unsigned char padded_key[SHA256_BLOCK_SIZE];
  unsigned char inner_hash[SHA256_LENGTH];

  // XOR key0 with ipad.
  for (int i = 0; i < SHA256_BLOCK_SIZE; ++i)
    padded_key[i] = key0[i] ^ 0x36;

  // Compute the inner hash.
  SHA256_Begin(&ctx);
  SHA256_Update(&ctx, padded_key, SHA256_BLOCK_SIZE);
  Wrapped_SHA256_Update(&ctx, text, text_len);
  SHA256_End(&ctx, inner_hash, NULL, SHA256_LENGTH);

  // XOR key0 with opad.
  for (int i = 0; i < SHA256_BLOCK_SIZE; ++i)
    padded_key[i] = key0[i] ^ 0x5c;

  // Compute the outer hash.
  SHA256_Begin(&ctx);
  SHA256_Update(&ctx, padded_key, SHA256_BLOCK_SIZE);
  SHA256_Update(&ctx, inner_hash, SHA256_LENGTH);
  SHA256_End(&ctx, output, NULL, (unsigned int) output_len);
}

}  // namespace

struct HMACPlatformData {
  ~HMACPlatformData() {
    if (!raw_key_.empty()) {
      SecureZeroMemory(&raw_key_[0], raw_key_.size());
    }

    // Destroy the key before releasing the provider.
    key_.reset();
  }

  ScopedHCRYPTPROV provider_;
  ScopedHCRYPTKEY key_;

  // For HMAC-SHA-256 only.
  std::vector<unsigned char> raw_key_;
};

HMAC::HMAC(HashAlgorithm hash_alg)
    : hash_alg_(hash_alg), plat_(new HMACPlatformData()) {
  // Only SHA-1 and SHA-256 hash algorithms are supported now.
  DCHECK(hash_alg_ == SHA1 || hash_alg_ == SHA256);
}

bool HMAC::Init(const unsigned char* key, size_t key_length) {
  if (plat_->provider_ || plat_->key_ || !plat_->raw_key_.empty()) {
    // Init must not be called more than once on the same HMAC object.
    NOTREACHED();
    return false;
  }

  if (hash_alg_ == SHA256) {
    plat_->raw_key_.assign(key, key + key_length);
    return true;
  }

  if (!CryptAcquireContext(plat_->provider_.receive(), NULL, NULL,
                           PROV_RSA_FULL, CRYPT_VERIFYCONTEXT)) {
    NOTREACHED();
    return false;
  }

  // This code doesn't work on Win2k because PLAINTEXTKEYBLOB and
  // CRYPT_IPSEC_HMAC_KEY are not supported on Windows 2000.  PLAINTEXTKEYBLOB
  // allows the import of an unencrypted key.  For Win2k support, a cubmbersome
  // exponent-of-one key procedure must be used:
  //     http://support.microsoft.com/kb/228786/en-us
  // CRYPT_IPSEC_HMAC_KEY allows keys longer than 16 bytes.

  struct KeyBlob {
    BLOBHEADER header;
    DWORD key_size;
    BYTE key_data[1];
  };
  size_t key_blob_size = std::max(offsetof(KeyBlob, key_data) + key_length,
                                  sizeof(KeyBlob));
  std::vector<BYTE> key_blob_storage = std::vector<BYTE>(key_blob_size);
  KeyBlob* key_blob = reinterpret_cast<KeyBlob*>(&key_blob_storage[0]);
  key_blob->header.bType = PLAINTEXTKEYBLOB;
  key_blob->header.bVersion = CUR_BLOB_VERSION;
  key_blob->header.reserved = 0;
  key_blob->header.aiKeyAlg = CALG_RC2;
  key_blob->key_size = static_cast<DWORD>(key_length);
  memcpy(key_blob->key_data, key, key_length);

  if (!CryptImportKey(plat_->provider_, &key_blob_storage[0],
                      (DWORD)key_blob_storage.size(), 0,
                      CRYPT_IPSEC_HMAC_KEY, plat_->key_.receive())) {
    NOTREACHED();
    return false;
  }

  // Destroy the copy of the key.
  SecureZeroMemory(key_blob->key_data, key_length);

  return true;
}

HMAC::~HMAC() {
}

bool HMAC::Sign(const base::StringPiece& data,
                unsigned char* digest,
                size_t digest_length) const {
  if (hash_alg_ == SHA256) {
    if (plat_->raw_key_.empty())
      return false;
    ComputeHMACSHA256(&plat_->raw_key_[0], plat_->raw_key_.size(),
                      reinterpret_cast<const unsigned char*>(data.data()),
                      data.size(), digest, digest_length);
    return true;
  }

  if (!plat_->provider_ || !plat_->key_)
    return false;

  if (hash_alg_ != SHA1) {
    NOTREACHED();
    return false;
  }

  ScopedHCRYPTHASH hash;
  if (!CryptCreateHash(plat_->provider_, CALG_HMAC, plat_->key_, 0,
                       hash.receive()))
    return false;

  HMAC_INFO hmac_info;
  memset(&hmac_info, 0, sizeof(hmac_info));
  hmac_info.HashAlgid = CALG_SHA1;
  if (!CryptSetHashParam(hash, HP_HMAC_INFO,
                         reinterpret_cast<BYTE*>(&hmac_info), 0))
    return false;

  if (!CryptHashData(hash, reinterpret_cast<const BYTE*>(data.data()),
                     static_cast<DWORD>(data.size()), 0))
    return false;

  DWORD sha1_size = static_cast<DWORD>(digest_length);
  return !!CryptGetHashParam(hash, HP_HASHVAL, digest, &sha1_size, 0);
}

}  // namespace crypto
