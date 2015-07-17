// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/aead_openssl.h"

#if defined(USE_OPENSSL)

#include <openssl/aes.h>
#include <openssl/evp.h>
#include <string>

#include "base/basictypes.h"
#include "base/strings/string_util.h"
#include "crypto/openssl_util.h"

namespace crypto {

Aead::Aead(AeadAlgorithm algorithm) : key_(nullptr) {
  EnsureOpenSSLInit();
  switch (algorithm) {
    case AES_128_CTR_HMAC_SHA256:
      aead_ = EVP_aead_aes_128_ctr_hmac_sha256();
      break;
  }
}

Aead::~Aead() {
}

void Aead::Init(const std::string* key) {
  DCHECK(!key_);
  DCHECK_EQ(KeyLength(), key->size());
  key_ = key;
}

bool Aead::Seal(const base::StringPiece& plaintext,
                const base::StringPiece& nonce,
                const base::StringPiece& additional_data,
                std::string* ciphertext) const {
  DCHECK(key_);
  DCHECK_EQ(NonceLength(), nonce.size());
  EVP_AEAD_CTX ctx;

  if (!EVP_AEAD_CTX_init(&ctx, aead_,
                         reinterpret_cast<const uint8*>(key_->data()),
                         key_->size(), EVP_AEAD_DEFAULT_TAG_LENGTH, nullptr)) {
    return false;
  }

  std::string result;
  const size_t max_output_length =
      EVP_AEAD_max_overhead(aead_) + plaintext.size();
  size_t output_length;
  uint8* out_ptr =
      reinterpret_cast<uint8*>(base::WriteInto(&result, max_output_length + 1));

  if (!EVP_AEAD_CTX_seal(
          &ctx, out_ptr, &output_length, max_output_length,
          reinterpret_cast<const uint8*>(nonce.data()), nonce.size(),
          reinterpret_cast<const uint8*>(plaintext.data()), plaintext.size(),
          reinterpret_cast<const uint8*>(additional_data.data()),
          additional_data.size())) {
    EVP_AEAD_CTX_cleanup(&ctx);
    return false;
  }

  DCHECK_LE(output_length, max_output_length);
  result.resize(output_length);

  ciphertext->swap(result);
  EVP_AEAD_CTX_cleanup(&ctx);

  return true;
}

bool Aead::Open(const base::StringPiece& ciphertext,
                const base::StringPiece& nonce,
                const base::StringPiece& additional_data,
                std::string* plaintext) const {
  DCHECK(key_);
  EVP_AEAD_CTX ctx;

  if (!EVP_AEAD_CTX_init(&ctx, aead_,
                         reinterpret_cast<const uint8*>(key_->data()),
                         key_->size(), EVP_AEAD_DEFAULT_TAG_LENGTH, nullptr)) {
    return false;
  }

  std::string result;
  const size_t max_output_length = ciphertext.size();
  size_t output_length;
  uint8* out_ptr =
      reinterpret_cast<uint8*>(base::WriteInto(&result, max_output_length + 1));

  if (!EVP_AEAD_CTX_open(
          &ctx, out_ptr, &output_length, max_output_length,
          reinterpret_cast<const uint8*>(nonce.data()), nonce.size(),
          reinterpret_cast<const uint8*>(ciphertext.data()), ciphertext.size(),
          reinterpret_cast<const uint8*>(additional_data.data()),
          additional_data.size())) {
    EVP_AEAD_CTX_cleanup(&ctx);
    return false;
  }

  DCHECK_LE(output_length, max_output_length);
  result.resize(output_length);

  plaintext->swap(result);
  EVP_AEAD_CTX_cleanup(&ctx);

  return true;
}

size_t Aead::KeyLength() const {
  return EVP_AEAD_key_length(aead_);
}

size_t Aead::NonceLength() const {
  return EVP_AEAD_nonce_length(aead_);
}

}  // namespace

#endif
