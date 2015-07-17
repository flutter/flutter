// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/aead_openssl.h"

#include <string>

#include "testing/gtest/include/gtest/gtest.h"

namespace {

#if defined(USE_OPENSSL)

TEST(AeadTest, SealOpen) {
  crypto::Aead aead(crypto::Aead::AES_128_CTR_HMAC_SHA256);
  std::string key(aead.KeyLength(), 0);
  aead.Init(&key);
  std::string nonce(aead.NonceLength(), 0);
  std::string plaintext("this is the plaintext");
  std::string ad("this is the additional data");
  std::string ciphertext;
  EXPECT_TRUE(aead.Seal(plaintext, nonce, ad, &ciphertext));
  EXPECT_LT(0U, ciphertext.size());

  std::string decrypted;
  EXPECT_TRUE(aead.Open(ciphertext, nonce, ad, &decrypted));

  EXPECT_EQ(plaintext, decrypted);
}

TEST(AeadTest, SealOpenWrongKey) {
  crypto::Aead aead(crypto::Aead::AES_128_CTR_HMAC_SHA256);
  std::string key(aead.KeyLength(), 0);
  std::string wrong_key(aead.KeyLength(), 1);
  aead.Init(&key);
  crypto::Aead aead_wrong_key(crypto::Aead::AES_128_CTR_HMAC_SHA256);
  aead_wrong_key.Init(&wrong_key);

  std::string nonce(aead.NonceLength(), 0);
  std::string plaintext("this is the plaintext");
  std::string ad("this is the additional data");
  std::string ciphertext;
  EXPECT_TRUE(aead.Seal(plaintext, nonce, ad, &ciphertext));
  EXPECT_LT(0U, ciphertext.size());

  std::string decrypted;
  EXPECT_FALSE(aead_wrong_key.Open(ciphertext, nonce, ad, &decrypted));
  EXPECT_EQ(0U, decrypted.size());
}

#endif

}  // namespace
