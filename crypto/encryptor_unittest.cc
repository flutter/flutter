// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/encryptor.h"

#include <string>

#include "base/memory/scoped_ptr.h"
#include "base/strings/string_number_conversions.h"
#include "crypto/symmetric_key.h"
#include "testing/gtest/include/gtest/gtest.h"

TEST(EncryptorTest, EncryptDecrypt) {
  scoped_ptr<crypto::SymmetricKey> key(
      crypto::SymmetricKey::DeriveKeyFromPassword(
          crypto::SymmetricKey::AES, "password", "saltiest", 1000, 256));
  EXPECT_TRUE(key.get());

  crypto::Encryptor encryptor;
  // The IV must be exactly as long as the cipher block size.
  std::string iv("the iv: 16 bytes");
  EXPECT_EQ(16U, iv.size());
  EXPECT_TRUE(encryptor.Init(key.get(), crypto::Encryptor::CBC, iv));

  std::string plaintext("this is the plaintext");
  std::string ciphertext;
  EXPECT_TRUE(encryptor.Encrypt(plaintext, &ciphertext));

  EXPECT_LT(0U, ciphertext.size());

  std::string decrypted;
  EXPECT_TRUE(encryptor.Decrypt(ciphertext, &decrypted));

  EXPECT_EQ(plaintext, decrypted);
}

TEST(EncryptorTest, DecryptWrongKey) {
  scoped_ptr<crypto::SymmetricKey> key(
      crypto::SymmetricKey::DeriveKeyFromPassword(
          crypto::SymmetricKey::AES, "password", "saltiest", 1000, 256));
  EXPECT_TRUE(key.get());

  // A wrong key that can be detected by implementations that validate every
  // byte in the padding.
  scoped_ptr<crypto::SymmetricKey> wrong_key(
        crypto::SymmetricKey::DeriveKeyFromPassword(
            crypto::SymmetricKey::AES, "wrongword", "sweetest", 1000, 256));
  EXPECT_TRUE(wrong_key.get());

  // A wrong key that can't be detected by any implementation.  The password
  // "wrongword;" would also work.
  scoped_ptr<crypto::SymmetricKey> wrong_key2(
        crypto::SymmetricKey::DeriveKeyFromPassword(
            crypto::SymmetricKey::AES, "wrongword+", "sweetest", 1000, 256));
  EXPECT_TRUE(wrong_key2.get());

  // A wrong key that can be detected by all implementations.
  scoped_ptr<crypto::SymmetricKey> wrong_key3(
        crypto::SymmetricKey::DeriveKeyFromPassword(
            crypto::SymmetricKey::AES, "wrongwordx", "sweetest", 1000, 256));
  EXPECT_TRUE(wrong_key3.get());

  crypto::Encryptor encryptor;
  // The IV must be exactly as long as the cipher block size.
  std::string iv("the iv: 16 bytes");
  EXPECT_EQ(16U, iv.size());
  EXPECT_TRUE(encryptor.Init(key.get(), crypto::Encryptor::CBC, iv));

  std::string plaintext("this is the plaintext");
  std::string ciphertext;
  EXPECT_TRUE(encryptor.Encrypt(plaintext, &ciphertext));

  static const unsigned char expected_ciphertext[] = {
    0x7D, 0x67, 0x5B, 0x53, 0xE6, 0xD8, 0x0F, 0x27,
    0x74, 0xB1, 0x90, 0xFE, 0x6E, 0x58, 0x4A, 0xA0,
    0x0E, 0x35, 0xE3, 0x01, 0xC0, 0xFE, 0x9A, 0xD8,
    0x48, 0x1D, 0x42, 0xB0, 0xBA, 0x21, 0xB2, 0x0C
  };

  ASSERT_EQ(arraysize(expected_ciphertext), ciphertext.size());
  for (size_t i = 0; i < ciphertext.size(); ++i) {
    ASSERT_EQ(expected_ciphertext[i],
              static_cast<unsigned char>(ciphertext[i]));
  }

  std::string decrypted;

  // This wrong key causes the last padding byte to be 5, which is a valid
  // padding length, and the second to last padding byte to be 137, which is
  // invalid.  If an implementation simply uses the last padding byte to
  // determine the padding length without checking every padding byte,
  // Encryptor::Decrypt() will still return true.  This is the case for NSS
  // (crbug.com/124434).
#if !defined(USE_NSS_CERTS) && !defined(OS_WIN) && !defined(OS_MACOSX)
  crypto::Encryptor decryptor;
  EXPECT_TRUE(decryptor.Init(wrong_key.get(), crypto::Encryptor::CBC, iv));
  EXPECT_FALSE(decryptor.Decrypt(ciphertext, &decrypted));
#endif

  // This demonstrates that not all wrong keys can be detected by padding
  // error. This wrong key causes the last padding byte to be 1, which is
  // a valid padding block of length 1.
  crypto::Encryptor decryptor2;
  EXPECT_TRUE(decryptor2.Init(wrong_key2.get(), crypto::Encryptor::CBC, iv));
  EXPECT_TRUE(decryptor2.Decrypt(ciphertext, &decrypted));

  // This wrong key causes the last padding byte to be 253, which should be
  // rejected by all implementations.
  crypto::Encryptor decryptor3;
  EXPECT_TRUE(decryptor3.Init(wrong_key3.get(), crypto::Encryptor::CBC, iv));
  EXPECT_FALSE(decryptor3.Decrypt(ciphertext, &decrypted));
}

namespace {

// From NIST SP 800-38a test cast:
// - F.5.1 CTR-AES128.Encrypt
// - F.5.6 CTR-AES256.Encrypt
// http://csrc.nist.gov/publications/nistpubs/800-38a/sp800-38a.pdf
const unsigned char kAES128CTRKey[] = {
  0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
  0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c
};

const unsigned char kAES256CTRKey[] = {
  0x60, 0x3d, 0xeb, 0x10, 0x15, 0xca, 0x71, 0xbe,
  0x2b, 0x73, 0xae, 0xf0, 0x85, 0x7d, 0x77, 0x81,
  0x1f, 0x35, 0x2c, 0x07, 0x3b, 0x61, 0x08, 0xd7,
  0x2d, 0x98, 0x10, 0xa3, 0x09, 0x14, 0xdf, 0xf4
};

const unsigned char kAESCTRInitCounter[] = {
  0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7,
  0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff
};

const unsigned char kAESCTRPlaintext[] = {
  // Block #1
  0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96,
  0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a,
  // Block #2
  0xae, 0x2d, 0x8a, 0x57, 0x1e, 0x03, 0xac, 0x9c,
  0x9e, 0xb7, 0x6f, 0xac, 0x45, 0xaf, 0x8e, 0x51,
  // Block #3
  0x30, 0xc8, 0x1c, 0x46, 0xa3, 0x5c, 0xe4, 0x11,
  0xe5, 0xfb, 0xc1, 0x19, 0x1a, 0x0a, 0x52, 0xef,
  // Block #4
  0xf6, 0x9f, 0x24, 0x45, 0xdf, 0x4f, 0x9b, 0x17,
  0xad, 0x2b, 0x41, 0x7b, 0xe6, 0x6c, 0x37, 0x10
};

const unsigned char kAES128CTRCiphertext[] = {
  // Block #1
  0x87, 0x4d, 0x61, 0x91, 0xb6, 0x20, 0xe3, 0x26,
  0x1b, 0xef, 0x68, 0x64, 0x99, 0x0d, 0xb6, 0xce,
  // Block #2
  0x98, 0x06, 0xf6, 0x6b, 0x79, 0x70, 0xfd, 0xff,
  0x86, 0x17, 0x18, 0x7b, 0xb9, 0xff, 0xfd, 0xff,
  // Block #3
  0x5a, 0xe4, 0xdf, 0x3e, 0xdb, 0xd5, 0xd3, 0x5e,
  0x5b, 0x4f, 0x09, 0x02, 0x0d, 0xb0, 0x3e, 0xab,
  // Block #4
  0x1e, 0x03, 0x1d, 0xda, 0x2f, 0xbe, 0x03, 0xd1,
  0x79, 0x21, 0x70, 0xa0, 0xf3, 0x00, 0x9c, 0xee
};

const unsigned char kAES256CTRCiphertext[] = {
  // Block #1
  0x60, 0x1e, 0xc3, 0x13, 0x77, 0x57, 0x89, 0xa5,
  0xb7, 0xa7, 0xf5, 0x04, 0xbb, 0xf3, 0xd2, 0x28,
  // Block #2
  0xf4, 0x43, 0xe3, 0xca, 0x4d, 0x62, 0xb5, 0x9a,
  0xca, 0x84, 0xe9, 0x90, 0xca, 0xca, 0xf5, 0xc5,
  // Block #3
  0x2b, 0x09, 0x30, 0xda, 0xa2, 0x3d, 0xe9, 0x4c,
  0xe8, 0x70, 0x17, 0xba, 0x2d, 0x84, 0x98, 0x8d,
  // Block #4
  0xdf, 0xc9, 0xc5, 0x8d, 0xb6, 0x7a, 0xad, 0xa6,
  0x13, 0xc2, 0xdd, 0x08, 0x45, 0x79, 0x41, 0xa6
};

void TestAESCTREncrypt(
    const unsigned char* key, size_t key_size,
    const unsigned char* init_counter, size_t init_counter_size,
    const unsigned char* plaintext, size_t plaintext_size,
    const unsigned char* ciphertext, size_t ciphertext_size) {
  std::string key_str(reinterpret_cast<const char*>(key), key_size);
  scoped_ptr<crypto::SymmetricKey> sym_key(crypto::SymmetricKey::Import(
      crypto::SymmetricKey::AES, key_str));
  ASSERT_TRUE(sym_key.get());

  crypto::Encryptor encryptor;
  EXPECT_TRUE(encryptor.Init(sym_key.get(), crypto::Encryptor::CTR, ""));

  base::StringPiece init_counter_str(
      reinterpret_cast<const char*>(init_counter), init_counter_size);
  base::StringPiece plaintext_str(
      reinterpret_cast<const char*>(plaintext), plaintext_size);

  EXPECT_TRUE(encryptor.SetCounter(init_counter_str));
  std::string encrypted;
  EXPECT_TRUE(encryptor.Encrypt(plaintext_str, &encrypted));

  EXPECT_EQ(ciphertext_size, encrypted.size());
  EXPECT_EQ(0, memcmp(encrypted.data(), ciphertext, encrypted.size()));

  std::string decrypted;
  EXPECT_TRUE(encryptor.SetCounter(init_counter_str));
  EXPECT_TRUE(encryptor.Decrypt(encrypted, &decrypted));

  EXPECT_EQ(plaintext_str, decrypted);
}

void TestAESCTRMultipleDecrypt(
    const unsigned char* key, size_t key_size,
    const unsigned char* init_counter, size_t init_counter_size,
    const unsigned char* plaintext, size_t plaintext_size,
    const unsigned char* ciphertext, size_t ciphertext_size) {
  std::string key_str(reinterpret_cast<const char*>(key), key_size);
  scoped_ptr<crypto::SymmetricKey> sym_key(crypto::SymmetricKey::Import(
      crypto::SymmetricKey::AES, key_str));
  ASSERT_TRUE(sym_key.get());

  crypto::Encryptor encryptor;
  EXPECT_TRUE(encryptor.Init(sym_key.get(), crypto::Encryptor::CTR, ""));

  // Counter is set only once.
  EXPECT_TRUE(encryptor.SetCounter(base::StringPiece(
      reinterpret_cast<const char*>(init_counter), init_counter_size)));

  std::string ciphertext_str(reinterpret_cast<const char*>(ciphertext),
                             ciphertext_size);

  int kTestDecryptSizes[] = { 32, 16, 8 };

  int offset = 0;
  for (size_t i = 0; i < arraysize(kTestDecryptSizes); ++i) {
    std::string decrypted;
    size_t len = kTestDecryptSizes[i];
    EXPECT_TRUE(
        encryptor.Decrypt(ciphertext_str.substr(offset, len), &decrypted));
    EXPECT_EQ(len, decrypted.size());
    EXPECT_EQ(0, memcmp(decrypted.data(), plaintext + offset, len));
    offset += len;
  }
}

}  // namespace

TEST(EncryptorTest, EncryptAES128CTR) {
  TestAESCTREncrypt(
      kAES128CTRKey, arraysize(kAES128CTRKey),
      kAESCTRInitCounter, arraysize(kAESCTRInitCounter),
      kAESCTRPlaintext, arraysize(kAESCTRPlaintext),
      kAES128CTRCiphertext, arraysize(kAES128CTRCiphertext));
}

TEST(EncryptorTest, EncryptAES256CTR) {
  TestAESCTREncrypt(
      kAES256CTRKey, arraysize(kAES256CTRKey),
      kAESCTRInitCounter, arraysize(kAESCTRInitCounter),
      kAESCTRPlaintext, arraysize(kAESCTRPlaintext),
      kAES256CTRCiphertext, arraysize(kAES256CTRCiphertext));
}

TEST(EncryptorTest, EncryptAES128CTR_MultipleDecrypt) {
  TestAESCTRMultipleDecrypt(
      kAES128CTRKey, arraysize(kAES128CTRKey),
      kAESCTRInitCounter, arraysize(kAESCTRInitCounter),
      kAESCTRPlaintext, arraysize(kAESCTRPlaintext),
      kAES128CTRCiphertext, arraysize(kAES128CTRCiphertext));
}

TEST(EncryptorTest, EncryptAES256CTR_MultipleDecrypt) {
  TestAESCTRMultipleDecrypt(
      kAES256CTRKey, arraysize(kAES256CTRKey),
      kAESCTRInitCounter, arraysize(kAESCTRInitCounter),
      kAESCTRPlaintext, arraysize(kAESCTRPlaintext),
      kAES256CTRCiphertext, arraysize(kAES256CTRCiphertext));
}

TEST(EncryptorTest, EncryptDecryptCTR) {
  scoped_ptr<crypto::SymmetricKey> key(
      crypto::SymmetricKey::GenerateRandomKey(crypto::SymmetricKey::AES, 128));

  EXPECT_TRUE(key.get());
  const std::string kInitialCounter = "0000000000000000";

  crypto::Encryptor encryptor;
  EXPECT_TRUE(encryptor.Init(key.get(), crypto::Encryptor::CTR, ""));
  EXPECT_TRUE(encryptor.SetCounter(kInitialCounter));

  std::string plaintext("normal plaintext of random length");
  std::string ciphertext;
  EXPECT_TRUE(encryptor.Encrypt(plaintext, &ciphertext));
  EXPECT_LT(0U, ciphertext.size());

  std::string decrypted;
  EXPECT_TRUE(encryptor.SetCounter(kInitialCounter));
  EXPECT_TRUE(encryptor.Decrypt(ciphertext, &decrypted));
  EXPECT_EQ(plaintext, decrypted);

  plaintext = "0123456789012345";
  EXPECT_TRUE(encryptor.SetCounter(kInitialCounter));
  EXPECT_TRUE(encryptor.Encrypt(plaintext, &ciphertext));
  EXPECT_LT(0U, ciphertext.size());

  EXPECT_TRUE(encryptor.SetCounter(kInitialCounter));
  EXPECT_TRUE(encryptor.Decrypt(ciphertext, &decrypted));
  EXPECT_EQ(plaintext, decrypted);
}

TEST(EncryptorTest, CTRCounter) {
  const int kCounterSize = 16;
  const unsigned char kTest1[] =
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  unsigned char buf[16];

  // Increment 10 times.
  crypto::Encryptor::Counter counter1(
      std::string(reinterpret_cast<const char*>(kTest1), kCounterSize));
  for (int i = 0; i < 10; ++i)
    counter1.Increment();
  counter1.Write(buf);
  EXPECT_EQ(0, memcmp(buf, kTest1, 15));
  EXPECT_TRUE(buf[15] == 10);

  // Check corner cases.
  const unsigned char kTest2[] = {
      0, 0, 0, 0, 0, 0, 0, 0,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
  };
  const unsigned char kExpect2[] =
      {0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0};
  crypto::Encryptor::Counter counter2(
      std::string(reinterpret_cast<const char*>(kTest2), kCounterSize));
  counter2.Increment();
  counter2.Write(buf);
  EXPECT_EQ(0, memcmp(buf, kExpect2, kCounterSize));

  const unsigned char kTest3[] = {
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
  };
  const unsigned char kExpect3[] =
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  crypto::Encryptor::Counter counter3(
      std::string(reinterpret_cast<const char*>(kTest3), kCounterSize));
  counter3.Increment();
  counter3.Write(buf);
  EXPECT_EQ(0, memcmp(buf, kExpect3, kCounterSize));
}

// TODO(wtc): add more known-answer tests.  Test vectors are available from
// http://www.ietf.org/rfc/rfc3602
// http://csrc.nist.gov/publications/nistpubs/800-38a/sp800-38a.pdf
// http://gladman.plushost.co.uk/oldsite/AES/index.php
// http://csrc.nist.gov/groups/STM/cavp/documents/aes/KAT_AES.zip

// NIST SP 800-38A test vector F.2.5 CBC-AES256.Encrypt.
TEST(EncryptorTest, EncryptAES256CBC) {
  // From NIST SP 800-38a test cast F.2.5 CBC-AES256.Encrypt.
  static const unsigned char kRawKey[] = {
    0x60, 0x3d, 0xeb, 0x10, 0x15, 0xca, 0x71, 0xbe,
    0x2b, 0x73, 0xae, 0xf0, 0x85, 0x7d, 0x77, 0x81,
    0x1f, 0x35, 0x2c, 0x07, 0x3b, 0x61, 0x08, 0xd7,
    0x2d, 0x98, 0x10, 0xa3, 0x09, 0x14, 0xdf, 0xf4
  };
  static const unsigned char kRawIv[] = {
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
  };
  static const unsigned char kRawPlaintext[] = {
    // Block #1
    0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96,
    0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a,
    // Block #2
    0xae, 0x2d, 0x8a, 0x57, 0x1e, 0x03, 0xac, 0x9c,
    0x9e, 0xb7, 0x6f, 0xac, 0x45, 0xaf, 0x8e, 0x51,
    // Block #3
    0x30, 0xc8, 0x1c, 0x46, 0xa3, 0x5c, 0xe4, 0x11,
    0xe5, 0xfb, 0xc1, 0x19, 0x1a, 0x0a, 0x52, 0xef,
    // Block #4
    0xf6, 0x9f, 0x24, 0x45, 0xdf, 0x4f, 0x9b, 0x17,
    0xad, 0x2b, 0x41, 0x7b, 0xe6, 0x6c, 0x37, 0x10,
  };
  static const unsigned char kRawCiphertext[] = {
    // Block #1
    0xf5, 0x8c, 0x4c, 0x04, 0xd6, 0xe5, 0xf1, 0xba,
    0x77, 0x9e, 0xab, 0xfb, 0x5f, 0x7b, 0xfb, 0xd6,
    // Block #2
    0x9c, 0xfc, 0x4e, 0x96, 0x7e, 0xdb, 0x80, 0x8d,
    0x67, 0x9f, 0x77, 0x7b, 0xc6, 0x70, 0x2c, 0x7d,
    // Block #3
    0x39, 0xf2, 0x33, 0x69, 0xa9, 0xd9, 0xba, 0xcf,
    0xa5, 0x30, 0xe2, 0x63, 0x04, 0x23, 0x14, 0x61,
    // Block #4
    0xb2, 0xeb, 0x05, 0xe2, 0xc3, 0x9b, 0xe9, 0xfc,
    0xda, 0x6c, 0x19, 0x07, 0x8c, 0x6a, 0x9d, 0x1b,
    // PKCS #5 padding, encrypted.
    0x3f, 0x46, 0x17, 0x96, 0xd6, 0xb0, 0xd6, 0xb2,
    0xe0, 0xc2, 0xa7, 0x2b, 0x4d, 0x80, 0xe6, 0x44
  };

  std::string key(reinterpret_cast<const char*>(kRawKey), sizeof(kRawKey));
  scoped_ptr<crypto::SymmetricKey> sym_key(crypto::SymmetricKey::Import(
      crypto::SymmetricKey::AES, key));
  ASSERT_TRUE(sym_key.get());

  crypto::Encryptor encryptor;
  // The IV must be exactly as long a the cipher block size.
  std::string iv(reinterpret_cast<const char*>(kRawIv), sizeof(kRawIv));
  EXPECT_EQ(16U, iv.size());
  EXPECT_TRUE(encryptor.Init(sym_key.get(), crypto::Encryptor::CBC, iv));

  std::string plaintext(reinterpret_cast<const char*>(kRawPlaintext),
                        sizeof(kRawPlaintext));
  std::string ciphertext;
  EXPECT_TRUE(encryptor.Encrypt(plaintext, &ciphertext));

  EXPECT_EQ(sizeof(kRawCiphertext), ciphertext.size());
  EXPECT_EQ(0, memcmp(ciphertext.data(), kRawCiphertext, ciphertext.size()));

  std::string decrypted;
  EXPECT_TRUE(encryptor.Decrypt(ciphertext, &decrypted));

  EXPECT_EQ(plaintext, decrypted);
}

// Expected output derived from the NSS implementation.
TEST(EncryptorTest, EncryptAES128CBCRegression) {
  std::string key = "128=SixteenBytes";
  std::string iv = "Sweet Sixteen IV";
  std::string plaintext = "Plain text with a g-clef U+1D11E \360\235\204\236";
  std::string expected_ciphertext_hex =
      "D4A67A0BA33C30F207344D81D1E944BBE65587C3D7D9939A"
      "C070C62B9C15A3EA312EA4AD1BC7929F4D3C16B03AD5ADA8";

  scoped_ptr<crypto::SymmetricKey> sym_key(crypto::SymmetricKey::Import(
      crypto::SymmetricKey::AES, key));
  ASSERT_TRUE(sym_key.get());

  crypto::Encryptor encryptor;
  // The IV must be exactly as long a the cipher block size.
  EXPECT_EQ(16U, iv.size());
  EXPECT_TRUE(encryptor.Init(sym_key.get(), crypto::Encryptor::CBC, iv));

  std::string ciphertext;
  EXPECT_TRUE(encryptor.Encrypt(plaintext, &ciphertext));
  EXPECT_EQ(expected_ciphertext_hex, base::HexEncode(ciphertext.data(),
                                                     ciphertext.size()));

  std::string decrypted;
  EXPECT_TRUE(encryptor.Decrypt(ciphertext, &decrypted));
  EXPECT_EQ(plaintext, decrypted);
}

// Symmetric keys with an unsupported size should be rejected. Whether they are
// rejected by SymmetricKey::Import or Encryptor::Init depends on the platform.
TEST(EncryptorTest, UnsupportedKeySize) {
  std::string key = "7 = bad";
  std::string iv = "Sweet Sixteen IV";
  scoped_ptr<crypto::SymmetricKey> sym_key(crypto::SymmetricKey::Import(
      crypto::SymmetricKey::AES, key));
  if (!sym_key.get())
    return;

  crypto::Encryptor encryptor;
  // The IV must be exactly as long as the cipher block size.
  EXPECT_EQ(16U, iv.size());
  EXPECT_FALSE(encryptor.Init(sym_key.get(), crypto::Encryptor::CBC, iv));
}

TEST(EncryptorTest, UnsupportedIV) {
  std::string key = "128=SixteenBytes";
  std::string iv = "OnlyForteen :(";
  scoped_ptr<crypto::SymmetricKey> sym_key(crypto::SymmetricKey::Import(
      crypto::SymmetricKey::AES, key));
  ASSERT_TRUE(sym_key.get());

  crypto::Encryptor encryptor;
  EXPECT_FALSE(encryptor.Init(sym_key.get(), crypto::Encryptor::CBC, iv));
}

TEST(EncryptorTest, EmptyEncrypt) {
  std::string key = "128=SixteenBytes";
  std::string iv = "Sweet Sixteen IV";
  std::string plaintext;
  std::string expected_ciphertext_hex = "8518B8878D34E7185E300D0FCC426396";

  scoped_ptr<crypto::SymmetricKey> sym_key(crypto::SymmetricKey::Import(
      crypto::SymmetricKey::AES, key));
  ASSERT_TRUE(sym_key.get());

  crypto::Encryptor encryptor;
  // The IV must be exactly as long a the cipher block size.
  EXPECT_EQ(16U, iv.size());
  EXPECT_TRUE(encryptor.Init(sym_key.get(), crypto::Encryptor::CBC, iv));

  std::string ciphertext;
  EXPECT_TRUE(encryptor.Encrypt(plaintext, &ciphertext));
  EXPECT_EQ(expected_ciphertext_hex, base::HexEncode(ciphertext.data(),
                                                     ciphertext.size()));
}

TEST(EncryptorTest, CipherTextNotMultipleOfBlockSize) {
  std::string key = "128=SixteenBytes";
  std::string iv = "Sweet Sixteen IV";

  scoped_ptr<crypto::SymmetricKey> sym_key(crypto::SymmetricKey::Import(
      crypto::SymmetricKey::AES, key));
  ASSERT_TRUE(sym_key.get());

  crypto::Encryptor encryptor;
  // The IV must be exactly as long a the cipher block size.
  EXPECT_EQ(16U, iv.size());
  EXPECT_TRUE(encryptor.Init(sym_key.get(), crypto::Encryptor::CBC, iv));

  // Use a separately allocated array to improve the odds of the memory tools
  // catching invalid accesses.
  //
  // Otherwise when using std::string as the other tests do, accesses several
  // bytes off the end of the buffer may fall inside the reservation of
  // the string and not be detected.
  scoped_ptr<char[]> ciphertext(new char[1]);

  std::string plaintext;
  EXPECT_FALSE(
      encryptor.Decrypt(base::StringPiece(ciphertext.get(), 1), &plaintext));
}
