// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_ENCRYPTOR_H_
#define CRYPTO_ENCRYPTOR_H_

#include <string>

#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_piece.h"
#include "build/build_config.h"
#include "crypto/crypto_export.h"

#if defined(USE_NSS_CERTS) || \
    (!defined(USE_OPENSSL) && (defined(OS_WIN) || defined(OS_MACOSX)))
#include "crypto/scoped_nss_types.h"
#endif

namespace crypto {

class SymmetricKey;

class CRYPTO_EXPORT Encryptor {
 public:
  enum Mode {
    CBC,
    CTR,
  };

  // This class implements a 128-bits counter to be used in AES-CTR encryption.
  // Only 128-bits counter is supported in this class.
  class CRYPTO_EXPORT Counter {
   public:
    explicit Counter(const base::StringPiece& counter);
    ~Counter();

    // Increment the counter value.
    bool Increment();

    // Write the content of the counter to |buf|. |buf| should have enough
    // space for |GetLengthInBytes()|.
    void Write(void* buf);

    // Return the length of this counter.
    size_t GetLengthInBytes() const;

   private:
    union {
      uint32 components32[4];
      uint64 components64[2];
    } counter_;
  };

  Encryptor();
  virtual ~Encryptor();

  // Initializes the encryptor using |key| and |iv|. Returns false if either the
  // key or the initialization vector cannot be used.
  //
  // If |mode| is CBC, |iv| must not be empty; if it is CTR, then |iv| must be
  // empty.
  bool Init(SymmetricKey* key, Mode mode, const base::StringPiece& iv);

  // Encrypts |plaintext| into |ciphertext|.  |plaintext| may only be empty if
  // the mode is CBC.
  bool Encrypt(const base::StringPiece& plaintext, std::string* ciphertext);

  // Decrypts |ciphertext| into |plaintext|.  |ciphertext| must not be empty.
  //
  // WARNING: In CBC mode, Decrypt() returns false if it detects the padding
  // in the decrypted plaintext is wrong. Padding errors can result from
  // tampered ciphertext or a wrong decryption key. But successful decryption
  // does not imply the authenticity of the data. The caller of Decrypt()
  // must either authenticate the ciphertext before decrypting it, or take
  // care to not report decryption failure. Otherwise it could inadvertently
  // be used as a padding oracle to attack the cryptosystem.
  bool Decrypt(const base::StringPiece& ciphertext, std::string* plaintext);

  // Sets the counter value when in CTR mode. Currently only 128-bits
  // counter value is supported.
  //
  // Returns true only if update was successful.
  bool SetCounter(const base::StringPiece& counter);

  // TODO(albertb): Support streaming encryption.

 private:
  // Generates a mask using |counter_| to be used for encryption in CTR mode.
  // Resulting mask will be written to |mask| with |mask_len| bytes.
  //
  // Make sure there's enough space in mask when calling this method.
  // Reserve at least |plaintext_len| + 16 bytes for |mask|.
  //
  // The generated mask will always have at least |plaintext_len| bytes and
  // will be a multiple of the counter length.
  //
  // This method is used only in CTR mode.
  //
  // Returns false if this call failed.
  bool GenerateCounterMask(size_t plaintext_len,
                           uint8* mask,
                           size_t* mask_len);

  // Mask the |plaintext| message using |mask|. The output will be written to
  // |ciphertext|. |ciphertext| must have at least |plaintext_len| bytes.
  void MaskMessage(const void* plaintext,
                   size_t plaintext_len,
                   const void* mask,
                   void* ciphertext) const;

  SymmetricKey* key_;
  Mode mode_;
  scoped_ptr<Counter> counter_;

#if defined(USE_OPENSSL)
  bool Crypt(bool do_encrypt,  // Pass true to encrypt, false to decrypt.
             const base::StringPiece& input,
             std::string* output);
  bool CryptCTR(bool do_encrypt,
                const base::StringPiece& input,
                std::string* output);
  std::string iv_;
#elif defined(USE_NSS_CERTS) || defined(OS_WIN) || defined(OS_MACOSX)
  bool Crypt(PK11Context* context,
             const base::StringPiece& input,
             std::string* output);
  bool CryptCTR(PK11Context* context,
                const base::StringPiece& input,
                std::string* output);
  ScopedSECItem param_;
#endif
};

}  // namespace crypto

#endif  // CRYPTO_ENCRYPTOR_H_
