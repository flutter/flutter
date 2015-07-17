// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/symmetric_key.h"

#include <openssl/evp.h>
#include <openssl/rand.h>

#include <algorithm>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_util.h"
#include "crypto/openssl_util.h"

namespace crypto {

SymmetricKey::~SymmetricKey() {
  std::fill(key_.begin(), key_.end(), '\0');  // Zero out the confidential key.
}

// static
SymmetricKey* SymmetricKey::GenerateRandomKey(Algorithm algorithm,
                                              size_t key_size_in_bits) {
  DCHECK_EQ(AES, algorithm);

  // Whitelist supported key sizes to avoid accidentaly relying on
  // algorithms available in NSS but not BoringSSL and vice
  // versa. Note that BoringSSL does not support AES-192.
  if (key_size_in_bits != 128 && key_size_in_bits != 256)
    return NULL;

  size_t key_size_in_bytes = key_size_in_bits / 8;
  DCHECK_EQ(key_size_in_bits, key_size_in_bytes * 8);

  if (key_size_in_bytes == 0)
    return NULL;

  OpenSSLErrStackTracer err_tracer(FROM_HERE);
  scoped_ptr<SymmetricKey> key(new SymmetricKey);
  uint8* key_data = reinterpret_cast<uint8*>(
      base::WriteInto(&key->key_, key_size_in_bytes + 1));

  int rv = RAND_bytes(key_data, static_cast<int>(key_size_in_bytes));
  return rv == 1 ? key.release() : NULL;
}

// static
SymmetricKey* SymmetricKey::DeriveKeyFromPassword(Algorithm algorithm,
                                                  const std::string& password,
                                                  const std::string& salt,
                                                  size_t iterations,
                                                  size_t key_size_in_bits) {
  DCHECK(algorithm == AES || algorithm == HMAC_SHA1);

  if (algorithm == AES) {
    // Whitelist supported key sizes to avoid accidentaly relying on
    // algorithms available in NSS but not BoringSSL and vice
    // versa. Note that BoringSSL does not support AES-192.
    if (key_size_in_bits != 128 && key_size_in_bits != 256)
      return NULL;
  }

  size_t key_size_in_bytes = key_size_in_bits / 8;
  DCHECK_EQ(key_size_in_bits, key_size_in_bytes * 8);

  if (key_size_in_bytes == 0)
    return NULL;

  OpenSSLErrStackTracer err_tracer(FROM_HERE);
  scoped_ptr<SymmetricKey> key(new SymmetricKey);
  uint8* key_data = reinterpret_cast<uint8*>(
      base::WriteInto(&key->key_, key_size_in_bytes + 1));
  int rv = PKCS5_PBKDF2_HMAC_SHA1(password.data(), password.length(),
                                  reinterpret_cast<const uint8*>(salt.data()),
                                  salt.length(), iterations,
                                  static_cast<int>(key_size_in_bytes),
                                  key_data);
  return rv == 1 ? key.release() : NULL;
}

// static
SymmetricKey* SymmetricKey::Import(Algorithm algorithm,
                                   const std::string& raw_key) {
  if (algorithm == AES) {
    // Whitelist supported key sizes to avoid accidentaly relying on
    // algorithms available in NSS but not BoringSSL and vice
    // versa. Note that BoringSSL does not support AES-192.
    if (raw_key.size() != 128/8 && raw_key.size() != 256/8)
      return NULL;
  }

  scoped_ptr<SymmetricKey> key(new SymmetricKey);
  key->key_ = raw_key;
  return key.release();
}

bool SymmetricKey::GetRawKey(std::string* raw_key) {
  *raw_key = key_;
  return true;
}

}  // namespace crypto
