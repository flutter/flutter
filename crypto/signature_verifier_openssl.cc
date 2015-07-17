// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/signature_verifier.h"

#include <openssl/evp.h>
#include <openssl/x509.h>

#include <vector>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/stl_util.h"
#include "crypto/openssl_util.h"
#include "crypto/scoped_openssl_types.h"

namespace crypto {

namespace {

const EVP_MD* ToOpenSSLDigest(SignatureVerifier::HashAlgorithm hash_alg) {
  switch (hash_alg) {
    case SignatureVerifier::SHA1:
      return EVP_sha1();
    case SignatureVerifier::SHA256:
      return EVP_sha256();
  }
  return NULL;
}

}  // namespace

struct SignatureVerifier::VerifyContext {
  ScopedEVP_MD_CTX ctx;
};

SignatureVerifier::SignatureVerifier()
    : verify_context_(NULL) {
}

SignatureVerifier::~SignatureVerifier() {
  Reset();
}

bool SignatureVerifier::VerifyInit(const uint8* signature_algorithm,
                                   int signature_algorithm_len,
                                   const uint8* signature,
                                   int signature_len,
                                   const uint8* public_key_info,
                                   int public_key_info_len) {
  OpenSSLErrStackTracer err_tracer(FROM_HERE);
  ScopedOpenSSL<X509_ALGOR, X509_ALGOR_free> algorithm(
      d2i_X509_ALGOR(NULL, &signature_algorithm, signature_algorithm_len));
  if (!algorithm.get())
    return false;
  int nid = OBJ_obj2nid(algorithm.get()->algorithm);
  const EVP_MD* digest;
  if (nid == NID_ecdsa_with_SHA1) {
    digest = EVP_sha1();
  } else if (nid == NID_ecdsa_with_SHA256) {
    digest = EVP_sha256();
  } else {
    // This works for PKCS #1 v1.5 RSA signatures, but not for ECDSA
    // signatures.
    digest = EVP_get_digestbyobj(algorithm.get()->algorithm);
  }
  if (!digest)
    return false;

  return CommonInit(digest, signature, signature_len, public_key_info,
                    public_key_info_len, NULL);
}

bool SignatureVerifier::VerifyInitRSAPSS(HashAlgorithm hash_alg,
                                         HashAlgorithm mask_hash_alg,
                                         int salt_len,
                                         const uint8* signature,
                                         int signature_len,
                                         const uint8* public_key_info,
                                         int public_key_info_len) {
  OpenSSLErrStackTracer err_tracer(FROM_HERE);
  const EVP_MD* const digest = ToOpenSSLDigest(hash_alg);
  DCHECK(digest);
  if (!digest) {
    return false;
  }

  EVP_PKEY_CTX* pkey_ctx;
  if (!CommonInit(digest, signature, signature_len, public_key_info,
                  public_key_info_len, &pkey_ctx)) {
    return false;
  }

  int rv = EVP_PKEY_CTX_set_rsa_padding(pkey_ctx, RSA_PKCS1_PSS_PADDING);
  if (rv != 1)
    return false;
  const EVP_MD* const mgf_digest = ToOpenSSLDigest(mask_hash_alg);
  DCHECK(mgf_digest);
  if (!mgf_digest) {
    return false;
  }
  rv = EVP_PKEY_CTX_set_rsa_mgf1_md(pkey_ctx, mgf_digest);
  if (rv != 1)
    return false;
  rv = EVP_PKEY_CTX_set_rsa_pss_saltlen(pkey_ctx, salt_len);
  return rv == 1;
}

void SignatureVerifier::VerifyUpdate(const uint8* data_part,
                                     int data_part_len) {
  DCHECK(verify_context_);
  OpenSSLErrStackTracer err_tracer(FROM_HERE);
  int rv = EVP_DigestVerifyUpdate(verify_context_->ctx.get(),
                                  data_part, data_part_len);
  DCHECK_EQ(rv, 1);
}

bool SignatureVerifier::VerifyFinal() {
  DCHECK(verify_context_);
  OpenSSLErrStackTracer err_tracer(FROM_HERE);
  int rv = EVP_DigestVerifyFinal(verify_context_->ctx.get(),
                                 vector_as_array(&signature_),
                                 signature_.size());
  DCHECK_EQ(static_cast<int>(!!rv), rv);
  Reset();
  return rv == 1;
}

bool SignatureVerifier::CommonInit(const EVP_MD* digest,
                                   const uint8* signature,
                                   int signature_len,
                                   const uint8* public_key_info,
                                   int public_key_info_len,
                                   EVP_PKEY_CTX** pkey_ctx) {
  if (verify_context_)
    return false;

  verify_context_ = new VerifyContext;

  signature_.assign(signature, signature + signature_len);

  const uint8_t* ptr = public_key_info;
  ScopedEVP_PKEY public_key(d2i_PUBKEY(nullptr, &ptr, public_key_info_len));
  if (!public_key.get() || ptr != public_key_info + public_key_info_len)
    return false;

  verify_context_->ctx.reset(EVP_MD_CTX_create());
  int rv = EVP_DigestVerifyInit(verify_context_->ctx.get(), pkey_ctx,
                                digest, nullptr, public_key.get());
  return rv == 1;
}

void SignatureVerifier::Reset() {
  delete verify_context_;
  verify_context_ = NULL;
  signature_.clear();
}

}  // namespace crypto
