// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/ec_signature_creator_impl.h"

#include <openssl/bn.h>
#include <openssl/ec.h>
#include <openssl/ecdsa.h>
#include <openssl/evp.h>
#include <openssl/sha.h>

#include "base/logging.h"
#include "crypto/ec_private_key.h"
#include "crypto/openssl_util.h"
#include "crypto/scoped_openssl_types.h"

namespace crypto {

ECSignatureCreatorImpl::ECSignatureCreatorImpl(ECPrivateKey* key)
    : key_(key), signature_len_(0) {
  EnsureOpenSSLInit();
}

ECSignatureCreatorImpl::~ECSignatureCreatorImpl() {}

bool ECSignatureCreatorImpl::Sign(const uint8* data,
                                  int data_len,
                                  std::vector<uint8>* signature) {
  OpenSSLErrStackTracer err_tracer(FROM_HERE);
  ScopedEVP_MD_CTX ctx(EVP_MD_CTX_create());
  size_t sig_len = 0;
  if (!ctx.get() ||
      !EVP_DigestSignInit(ctx.get(), NULL, EVP_sha256(), NULL, key_->key()) ||
      !EVP_DigestSignUpdate(ctx.get(), data, data_len) ||
      !EVP_DigestSignFinal(ctx.get(), NULL, &sig_len)) {
    return false;
  }

  signature->resize(sig_len);
  if (!EVP_DigestSignFinal(ctx.get(), &signature->front(), &sig_len))
    return false;

  // NOTE: A call to EVP_DigestSignFinal() with a NULL second parameter returns
  // a maximum allocation size, while the call without a NULL returns the real
  // one, which may be smaller.
  signature->resize(sig_len);
  return true;
}

bool ECSignatureCreatorImpl::DecodeSignature(const std::vector<uint8>& der_sig,
                                             std::vector<uint8>* out_raw_sig) {
  OpenSSLErrStackTracer err_tracer(FROM_HERE);
  // Create ECDSA_SIG object from DER-encoded data.
  const unsigned char* der_data = &der_sig.front();
  ScopedECDSA_SIG ecdsa_sig(
      d2i_ECDSA_SIG(NULL, &der_data, static_cast<long>(der_sig.size())));
  if (!ecdsa_sig.get())
    return false;

  // The result is made of two 32-byte vectors.
  const size_t kMaxBytesPerBN = 32;
  std::vector<uint8> result(2 * kMaxBytesPerBN);

  if (!BN_bn2bin_padded(&result[0], kMaxBytesPerBN, ecdsa_sig->r) ||
      !BN_bn2bin_padded(&result[kMaxBytesPerBN], kMaxBytesPerBN,
                        ecdsa_sig->s)) {
    return false;
  }
  out_raw_sig->swap(result);
  return true;
}

}  // namespace crypto
