// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/ec_signature_creator_impl.h"

#include <cryptohi.h>
#include <pk11pub.h>
#include <secerr.h>
#include <sechash.h>
#if defined(OS_POSIX)
#include <unistd.h>
#endif

#include "base/logging.h"
#include "crypto/ec_private_key.h"
#include "crypto/nss_util.h"
#include "crypto/scoped_nss_types.h"

namespace crypto {

namespace {

SECStatus SignData(SECItem* result,
                   SECItem* input,
                   SECKEYPrivateKey* key,
                   HASH_HashType hash_type,
                   size_t* out_signature_len) {
  if (key->keyType != ecKey) {
    DLOG(FATAL) << "Should be using an EC key.";
    PORT_SetError(SEC_ERROR_INVALID_ARGS);
    return SECFailure;
  }

  // Hash the input.
  std::vector<uint8> hash_data(HASH_ResultLen(hash_type));
  SECStatus rv = HASH_HashBuf(
      hash_type, &hash_data[0], input->data, input->len);
  if (rv != SECSuccess)
    return rv;
  SECItem hash = {siBuffer, &hash_data[0],
                  static_cast<unsigned int>(hash_data.size())};

  // Compute signature of hash.
  int signature_len = PK11_SignatureLen(key);
  std::vector<uint8> signature_data(signature_len);
  SECItem sig = {siBuffer, &signature_data[0],
                 static_cast<unsigned int>(signature_len)};
  rv = PK11_Sign(key, &sig, &hash);
  if (rv != SECSuccess)
    return rv;

  *out_signature_len = sig.len;

  // DER encode the signature.
  return DSAU_EncodeDerSigWithLen(result, &sig, sig.len);
}

}  // namespace

ECSignatureCreatorImpl::ECSignatureCreatorImpl(ECPrivateKey* key)
    : key_(key),
      signature_len_(0) {
  EnsureNSSInit();
}

ECSignatureCreatorImpl::~ECSignatureCreatorImpl() {}

bool ECSignatureCreatorImpl::Sign(const uint8* data,
                                  int data_len,
                                  std::vector<uint8>* signature) {
  // Data to be signed
  SECItem secret;
  secret.type = siBuffer;
  secret.len = data_len;
  secret.data = const_cast<unsigned char*>(data);

  // SECItem to receive the output buffer.
  SECItem result;
  result.type = siBuffer;
  result.len = 0;
  result.data = NULL;

  // Sign the secret data and save it to |result|.
  SECStatus rv =
      SignData(&result, &secret, key_->key(), HASH_AlgSHA256, &signature_len_);
  if (rv != SECSuccess) {
    DLOG(ERROR) << "DerSignData: " << PORT_GetError();
    return false;
  }

  // Copy the signed data into the output vector.
  signature->assign(result.data, result.data + result.len);
  SECITEM_FreeItem(&result, PR_FALSE /* only free |result.data| */);
  return true;
}

bool ECSignatureCreatorImpl::DecodeSignature(
    const std::vector<uint8>& der_sig,
    std::vector<uint8>* out_raw_sig) {
  SECItem der_sig_item;
  der_sig_item.type = siBuffer;
  der_sig_item.len = der_sig.size();
  der_sig_item.data = const_cast<uint8*>(&der_sig[0]);

  SECItem* raw_sig = DSAU_DecodeDerSigToLen(&der_sig_item, signature_len_);
  if (!raw_sig)
    return false;
  out_raw_sig->assign(raw_sig->data, raw_sig->data + raw_sig->len);
  SECITEM_FreeItem(raw_sig, PR_TRUE /* free SECItem structure itself. */);
  return true;
}

}  // namespace crypto
