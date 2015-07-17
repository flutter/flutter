// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/signature_creator.h"

#include <openssl/evp.h>
#include <openssl/rsa.h>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/stl_util.h"
#include "crypto/openssl_util.h"
#include "crypto/rsa_private_key.h"
#include "crypto/scoped_openssl_types.h"

namespace crypto {

namespace {

const EVP_MD* ToOpenSSLDigest(SignatureCreator::HashAlgorithm hash_alg) {
  switch (hash_alg) {
    case SignatureCreator::SHA1:
      return EVP_sha1();
    case SignatureCreator::SHA256:
      return EVP_sha256();
  }
  return NULL;
}

int ToOpenSSLDigestType(SignatureCreator::HashAlgorithm hash_alg) {
  switch (hash_alg) {
    case SignatureCreator::SHA1:
      return NID_sha1;
    case SignatureCreator::SHA256:
      return NID_sha256;
  }
  return NID_undef;
}

}  // namespace

// static
SignatureCreator* SignatureCreator::Create(RSAPrivateKey* key,
                                           HashAlgorithm hash_alg) {
  OpenSSLErrStackTracer err_tracer(FROM_HERE);
  scoped_ptr<SignatureCreator> result(new SignatureCreator);
  const EVP_MD* const digest = ToOpenSSLDigest(hash_alg);
  DCHECK(digest);
  if (!digest) {
    return NULL;
  }
  if (!EVP_DigestSignInit(result->sign_context_, NULL, digest, NULL,
                          key->key())) {
    return NULL;
  }
  return result.release();
}

// static
bool SignatureCreator::Sign(RSAPrivateKey* key,
                            HashAlgorithm hash_alg,
                            const uint8* data,
                            int data_len,
                            std::vector<uint8>* signature) {
  ScopedRSA rsa_key(EVP_PKEY_get1_RSA(key->key()));
  if (!rsa_key)
    return false;
  signature->resize(RSA_size(rsa_key.get()));

  unsigned int len = 0;
  if (!RSA_sign(ToOpenSSLDigestType(hash_alg), data, data_len,
                vector_as_array(signature), &len, rsa_key.get())) {
    signature->clear();
    return false;
  }
  signature->resize(len);
  return true;
}

SignatureCreator::SignatureCreator()
    : sign_context_(EVP_MD_CTX_create()) {
}

SignatureCreator::~SignatureCreator() {
  EVP_MD_CTX_destroy(sign_context_);
}

bool SignatureCreator::Update(const uint8* data_part, int data_part_len) {
  OpenSSLErrStackTracer err_tracer(FROM_HERE);
  return !!EVP_DigestSignUpdate(sign_context_, data_part, data_part_len);
}

bool SignatureCreator::Final(std::vector<uint8>* signature) {
  OpenSSLErrStackTracer err_tracer(FROM_HERE);

  // Determine the maximum length of the signature.
  size_t len = 0;
  if (!EVP_DigestSignFinal(sign_context_, NULL, &len)) {
    signature->clear();
    return false;
  }
  signature->resize(len);

  // Sign it.
  if (!EVP_DigestSignFinal(sign_context_, vector_as_array(signature), &len)) {
    signature->clear();
    return false;
  }
  signature->resize(len);
  return true;
}

}  // namespace crypto
