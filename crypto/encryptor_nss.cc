// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/encryptor.h"

#include <cryptohi.h>
#include <vector>

#include "base/logging.h"
#include "crypto/nss_util.h"
#include "crypto/symmetric_key.h"

namespace crypto {

namespace {

inline CK_MECHANISM_TYPE GetMechanism(Encryptor::Mode mode) {
  switch (mode) {
    case Encryptor::CBC:
      return CKM_AES_CBC_PAD;
    case Encryptor::CTR:
      // AES-CTR encryption uses ECB encryptor as a building block since
      // NSS doesn't support CTR encryption mode.
      return CKM_AES_ECB;
    default:
      NOTREACHED() << "Unsupported mode of operation";
      break;
  }
  return static_cast<CK_MECHANISM_TYPE>(-1);
}

}  // namespace

Encryptor::Encryptor()
    : key_(NULL),
      mode_(CBC) {
  EnsureNSSInit();
}

Encryptor::~Encryptor() {
}

bool Encryptor::Init(SymmetricKey* key,
                     Mode mode,
                     const base::StringPiece& iv) {
  DCHECK(key);
  DCHECK(CBC == mode || CTR == mode) << "Unsupported mode of operation";

  key_ = key;
  mode_ = mode;

  if (mode == CBC && iv.size() != AES_BLOCK_SIZE)
    return false;

  switch (mode) {
    case CBC:
      SECItem iv_item;
      iv_item.type = siBuffer;
      iv_item.data = reinterpret_cast<unsigned char*>(
          const_cast<char *>(iv.data()));
      iv_item.len = iv.size();

      param_.reset(PK11_ParamFromIV(GetMechanism(mode), &iv_item));
      break;
    case CTR:
      param_.reset(PK11_ParamFromIV(GetMechanism(mode), NULL));
      break;
  }

  return param_ != NULL;
}

bool Encryptor::Encrypt(const base::StringPiece& plaintext,
                        std::string* ciphertext) {
  CHECK(!plaintext.empty() || (mode_ == CBC));
  ScopedPK11Context context(PK11_CreateContextBySymKey(GetMechanism(mode_),
                                                       CKA_ENCRYPT,
                                                       key_->key(),
                                                       param_.get()));
  if (!context.get())
    return false;

  return (mode_ == CTR) ?
      CryptCTR(context.get(), plaintext, ciphertext) :
      Crypt(context.get(), plaintext, ciphertext);
}

bool Encryptor::Decrypt(const base::StringPiece& ciphertext,
                        std::string* plaintext) {
  CHECK(!ciphertext.empty());
  ScopedPK11Context context(PK11_CreateContextBySymKey(
      GetMechanism(mode_), (mode_ == CTR ? CKA_ENCRYPT : CKA_DECRYPT),
      key_->key(), param_.get()));
  if (!context.get())
    return false;

  if (mode_ == CTR)
    return CryptCTR(context.get(), ciphertext, plaintext);

  if (ciphertext.size() % AES_BLOCK_SIZE != 0) {
    // Decryption will fail if the input is not a multiple of the block size.
    // PK11_CipherOp has a bug where it will do an invalid memory access before
    // the start of the input, so avoid calling it. (NSS bug 922780).
    plaintext->clear();
    return false;
  }

  return Crypt(context.get(), ciphertext, plaintext);
}

bool Encryptor::Crypt(PK11Context* context,
                      const base::StringPiece& input,
                      std::string* output) {
  size_t output_len = input.size() + AES_BLOCK_SIZE;
  CHECK_GT(output_len, input.size());

  output->resize(output_len);
  uint8* output_data =
      reinterpret_cast<uint8*>(const_cast<char*>(output->data()));

  int input_len = input.size();
  uint8* input_data =
      reinterpret_cast<uint8*>(const_cast<char*>(input.data()));

  int op_len;
  SECStatus rv = PK11_CipherOp(context,
                               output_data,
                               &op_len,
                               output_len,
                               input_data,
                               input_len);

  if (SECSuccess != rv) {
    output->clear();
    return false;
  }

  unsigned int digest_len;
  rv = PK11_DigestFinal(context,
                        output_data + op_len,
                        &digest_len,
                        output_len - op_len);
  if (SECSuccess != rv) {
    output->clear();
    return false;
  }

  output->resize(op_len + digest_len);
  return true;
}

bool Encryptor::CryptCTR(PK11Context* context,
                         const base::StringPiece& input,
                         std::string* output) {
  if (!counter_.get()) {
    LOG(ERROR) << "Counter value not set in CTR mode.";
    return false;
  }

  size_t output_len = ((input.size() + AES_BLOCK_SIZE - 1) / AES_BLOCK_SIZE) *
      AES_BLOCK_SIZE;
  CHECK_GE(output_len, input.size());
  output->resize(output_len);
  uint8* output_data =
      reinterpret_cast<uint8*>(const_cast<char*>(output->data()));

  size_t mask_len;
  bool ret = GenerateCounterMask(input.size(), output_data, &mask_len);
  if (!ret)
    return false;

  CHECK_EQ(mask_len, output_len);
  int op_len;
  SECStatus rv = PK11_CipherOp(context,
                               output_data,
                               &op_len,
                               output_len,
                               output_data,
                               mask_len);
  if (SECSuccess != rv)
    return false;
  CHECK_EQ(static_cast<int>(mask_len), op_len);

  unsigned int digest_len;
  rv = PK11_DigestFinal(context,
                        NULL,
                        &digest_len,
                        0);
  if (SECSuccess != rv)
    return false;
  CHECK(!digest_len);

  // Use |output_data| to mask |input|.
  MaskMessage(
      reinterpret_cast<uint8*>(const_cast<char*>(input.data())),
      input.length(), output_data, output_data);
  output->resize(input.length());
  return true;
}

}  // namespace crypto
