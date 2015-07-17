// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/rsa_private_key.h"

#include <openssl/bio.h>
#include <openssl/bn.h>
#include <openssl/evp.h>
#include <openssl/pkcs12.h>
#include <openssl/rsa.h>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "crypto/openssl_util.h"
#include "crypto/scoped_openssl_types.h"

namespace crypto {

namespace {

using ScopedPKCS8_PRIV_KEY_INFO =
    ScopedOpenSSL<PKCS8_PRIV_KEY_INFO, PKCS8_PRIV_KEY_INFO_free>;

// Function pointer definition, for injecting the required key export function
// into ExportKey, below. The supplied function should export EVP_PKEY into
// the supplied BIO, returning 1 on success or 0 on failure.
using ExportFunction = int (*)(BIO*, EVP_PKEY*);

// Helper to export |key| into |output| via the specified ExportFunction.
bool ExportKey(EVP_PKEY* key,
               ExportFunction export_fn,
               std::vector<uint8>* output) {
  if (!key)
    return false;

  OpenSSLErrStackTracer err_tracer(FROM_HERE);
  ScopedBIO bio(BIO_new(BIO_s_mem()));

  int res = export_fn(bio.get(), key);
  if (!res)
    return false;

  char* data = NULL;
  long len = BIO_get_mem_data(bio.get(), &data);
  if (!data || len < 0)
    return false;

  output->assign(data, data + len);
  return true;
}

}  // namespace

// static
RSAPrivateKey* RSAPrivateKey::Create(uint16 num_bits) {
  OpenSSLErrStackTracer err_tracer(FROM_HERE);

  ScopedRSA rsa_key(RSA_new());
  ScopedBIGNUM bn(BN_new());
  if (!rsa_key.get() || !bn.get() || !BN_set_word(bn.get(), 65537L))
    return NULL;

  if (!RSA_generate_key_ex(rsa_key.get(), num_bits, bn.get(), NULL))
    return NULL;

  scoped_ptr<RSAPrivateKey> result(new RSAPrivateKey);
  result->key_ = EVP_PKEY_new();
  if (!result->key_ || !EVP_PKEY_set1_RSA(result->key_, rsa_key.get()))
    return NULL;

  return result.release();
}

// static
RSAPrivateKey* RSAPrivateKey::CreateFromPrivateKeyInfo(
    const std::vector<uint8>& input) {
  if (input.empty())
    return NULL;

  OpenSSLErrStackTracer err_tracer(FROM_HERE);

  // Importing is a little more involved than exporting, as we must first
  // PKCS#8 decode the input, and then import the EVP_PKEY from Private Key
  // Info structure returned.
  const uint8_t* ptr = &input[0];
  ScopedPKCS8_PRIV_KEY_INFO p8inf(
      d2i_PKCS8_PRIV_KEY_INFO(nullptr, &ptr, input.size()));
  if (!p8inf.get() || ptr != &input[0] + input.size())
    return NULL;

  scoped_ptr<RSAPrivateKey> result(new RSAPrivateKey);
  result->key_ = EVP_PKCS82PKEY(p8inf.get());
  if (!result->key_ || EVP_PKEY_id(result->key_) != EVP_PKEY_RSA)
    return NULL;

  return result.release();
}

// static
RSAPrivateKey* RSAPrivateKey::CreateFromKey(EVP_PKEY* key) {
  DCHECK(key);
  if (EVP_PKEY_type(key->type) != EVP_PKEY_RSA)
    return NULL;
  RSAPrivateKey* copy = new RSAPrivateKey();
  copy->key_ = EVP_PKEY_up_ref(key);
  return copy;
}

RSAPrivateKey::RSAPrivateKey()
    : key_(NULL) {
}

RSAPrivateKey::~RSAPrivateKey() {
  if (key_)
    EVP_PKEY_free(key_);
}

RSAPrivateKey* RSAPrivateKey::Copy() const {
  scoped_ptr<RSAPrivateKey> copy(new RSAPrivateKey());
  ScopedRSA rsa(EVP_PKEY_get1_RSA(key_));
  if (!rsa)
    return NULL;
  copy->key_ = EVP_PKEY_new();
  if (!EVP_PKEY_set1_RSA(copy->key_, rsa.get()))
    return NULL;
  return copy.release();
}

bool RSAPrivateKey::ExportPrivateKey(std::vector<uint8>* output) const {
  return ExportKey(key_, i2d_PKCS8PrivateKeyInfo_bio, output);
}

bool RSAPrivateKey::ExportPublicKey(std::vector<uint8>* output) const {
  return ExportKey(key_, i2d_PUBKEY_bio, output);
}

}  // namespace crypto
