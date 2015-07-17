// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/symmetric_key.h"

#include <string>

#include "base/memory/scoped_ptr.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_util.h"
#include "testing/gtest/include/gtest/gtest.h"

TEST(SymmetricKeyTest, GenerateRandomKey) {
  scoped_ptr<crypto::SymmetricKey> key(
      crypto::SymmetricKey::GenerateRandomKey(crypto::SymmetricKey::AES, 256));
  ASSERT_TRUE(NULL != key.get());
  std::string raw_key;
  EXPECT_TRUE(key->GetRawKey(&raw_key));
  EXPECT_EQ(32U, raw_key.size());

  // Do it again and check that the keys are different.
  // (Note: this has a one-in-10^77 chance of failure!)
  scoped_ptr<crypto::SymmetricKey> key2(
      crypto::SymmetricKey::GenerateRandomKey(crypto::SymmetricKey::AES, 256));
  ASSERT_TRUE(NULL != key2.get());
  std::string raw_key2;
  EXPECT_TRUE(key2->GetRawKey(&raw_key2));
  EXPECT_EQ(32U, raw_key2.size());
  EXPECT_NE(raw_key, raw_key2);
}

TEST(SymmetricKeyTest, ImportGeneratedKey) {
  scoped_ptr<crypto::SymmetricKey> key1(
      crypto::SymmetricKey::GenerateRandomKey(crypto::SymmetricKey::AES, 256));
  ASSERT_TRUE(NULL != key1.get());
  std::string raw_key1;
  EXPECT_TRUE(key1->GetRawKey(&raw_key1));

  scoped_ptr<crypto::SymmetricKey> key2(
      crypto::SymmetricKey::Import(crypto::SymmetricKey::AES, raw_key1));
  ASSERT_TRUE(NULL != key2.get());

  std::string raw_key2;
  EXPECT_TRUE(key2->GetRawKey(&raw_key2));

  EXPECT_EQ(raw_key1, raw_key2);
}

TEST(SymmetricKeyTest, ImportDerivedKey) {
  scoped_ptr<crypto::SymmetricKey> key1(
      crypto::SymmetricKey::DeriveKeyFromPassword(
          crypto::SymmetricKey::HMAC_SHA1, "password", "somesalt", 1024, 160));
  ASSERT_TRUE(NULL != key1.get());
  std::string raw_key1;
  EXPECT_TRUE(key1->GetRawKey(&raw_key1));

  scoped_ptr<crypto::SymmetricKey> key2(
      crypto::SymmetricKey::Import(crypto::SymmetricKey::HMAC_SHA1, raw_key1));
  ASSERT_TRUE(NULL != key2.get());

  std::string raw_key2;
  EXPECT_TRUE(key2->GetRawKey(&raw_key2));

  EXPECT_EQ(raw_key1, raw_key2);
}

struct PBKDF2TestVector {
  crypto::SymmetricKey::Algorithm algorithm;
  const char* password;
  const char* salt;
  unsigned int rounds;
  unsigned int key_size_in_bits;
  const char* expected;  // ASCII encoded hex bytes
};

class SymmetricKeyDeriveKeyFromPasswordTest
    : public testing::TestWithParam<PBKDF2TestVector> {
};

TEST_P(SymmetricKeyDeriveKeyFromPasswordTest, DeriveKeyFromPassword) {
  PBKDF2TestVector test_data(GetParam());
#if defined(OS_MACOSX) && !defined(OS_IOS)
  // The OS X crypto libraries have minimum salt and iteration requirements
  // so some of the tests below will cause them to barf. Skip these.
  if (strlen(test_data.salt) < 8 || test_data.rounds < 1000) {
    VLOG(1) << "Skipped test vector for " << test_data.expected;
    return;
  }
#endif  // OS_MACOSX

  scoped_ptr<crypto::SymmetricKey> key(
      crypto::SymmetricKey::DeriveKeyFromPassword(
          test_data.algorithm,
          test_data.password, test_data.salt,
          test_data.rounds, test_data.key_size_in_bits));
  ASSERT_TRUE(NULL != key.get());

  std::string raw_key;
  key->GetRawKey(&raw_key);
  EXPECT_EQ(test_data.key_size_in_bits / 8, raw_key.size());
  EXPECT_EQ(test_data.expected,
            base::StringToLowerASCII(base::HexEncode(raw_key.data(),
                                               raw_key.size())));
}

static const PBKDF2TestVector kTestVectors[] = {
  // These tests come from
  // http://www.ietf.org/id/draft-josefsson-pbkdf2-test-vectors-00.txt
  {
    crypto::SymmetricKey::HMAC_SHA1,
    "password",
    "salt",
    1,
    160,
    "0c60c80f961f0e71f3a9b524af6012062fe037a6",
  },
  {
    crypto::SymmetricKey::HMAC_SHA1,
    "password",
    "salt",
    2,
    160,
    "ea6c014dc72d6f8ccd1ed92ace1d41f0d8de8957",
  },
  {
    crypto::SymmetricKey::HMAC_SHA1,
    "password",
    "salt",
    4096,
    160,
    "4b007901b765489abead49d926f721d065a429c1",
  },
  // This test takes over 30s to run on the trybots.
#if 0
  {
    crypto::SymmetricKey::HMAC_SHA1,
    "password",
    "salt",
    16777216,
    160,
    "eefe3d61cd4da4e4e9945b3d6ba2158c2634e984",
  },
#endif

  // These tests come from RFC 3962, via BSD source code at
  // http://www.openbsd.org/cgi-bin/cvsweb/src/sbin/bioctl/pbkdf2.c?rev=HEAD&content-type=text/plain
  {
    crypto::SymmetricKey::HMAC_SHA1,
    "password",
    "ATHENA.MIT.EDUraeburn",
    1,
    160,
    "cdedb5281bb2f801565a1122b25635150ad1f7a0",
  },
  {
    crypto::SymmetricKey::HMAC_SHA1,
    "password",
    "ATHENA.MIT.EDUraeburn",
    2,
    160,
    "01dbee7f4a9e243e988b62c73cda935da05378b9",
  },
  {
    crypto::SymmetricKey::HMAC_SHA1,
    "password",
    "ATHENA.MIT.EDUraeburn",
    1200,
    160,
    "5c08eb61fdf71e4e4ec3cf6ba1f5512ba7e52ddb",
  },
  {
    crypto::SymmetricKey::HMAC_SHA1,
    "password",
    "\022" "4VxxV4\022", /* 0x1234567878563412 */
    5,
    160,
    "d1daa78615f287e6a1c8b120d7062a493f98d203",
  },
  {
    crypto::SymmetricKey::HMAC_SHA1,
    "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "pass phrase equals block size",
    1200,
    160,
    "139c30c0966bc32ba55fdbf212530ac9c5ec59f1",
  },
  {
    crypto::SymmetricKey::HMAC_SHA1,
    "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "pass phrase exceeds block size",
    1200,
    160,
    "9ccad6d468770cd51b10e6a68721be611a8b4d28",
  },
  {
    crypto::SymmetricKey::HMAC_SHA1,
    "\360\235\204\236", /* g-clef (0xf09d849e) */
    "EXAMPLE.COMpianist",
    50,
    160,
    "6b9cf26d45455a43a5b8bb276a403b39e7fe37a0",
  },

  // Regression tests for AES keys, derived from the Linux NSS implementation.
  {
    crypto::SymmetricKey::AES,
    "A test password",
    "saltsalt",
    1,
    256,
    "44899a7777f0e6e8b752f875f02044b8ac593de146de896f2e8a816e315a36de",
  },
  {
    crypto::SymmetricKey::AES,
    "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "pass phrase exceeds block size",
    20,
    256,
    "e0739745dc28b8721ba402e05214d2ac1eab54cf72bee1fba388297a09eb493c",
  },
};

INSTANTIATE_TEST_CASE_P(, SymmetricKeyDeriveKeyFromPasswordTest,
                        testing::ValuesIn(kTestVectors));
