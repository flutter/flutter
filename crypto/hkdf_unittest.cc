// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/hkdf.h"

#include <string>

#include "base/strings/string_number_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"

using crypto::HKDF;

namespace test {
namespace {

struct HKDFTest {
  const char* key_hex;
  const char* salt_hex;
  const char* info_hex;
  const char* output_hex;
};

// These test cases are taken from
// https://tools.ietf.org/html/rfc5869#appendix-A.
static const HKDFTest kHKDFTests[] = {{
    "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b",
    "000102030405060708090a0b0c",
    "f0f1f2f3f4f5f6f7f8f9",
    "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5"
    "b887185865",
  }, {
    "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f2021222324"
    "25262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f40414243444546474849"
    "4a4b4c4d4e4f",
    "606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f8081828384"
    "85868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9"
    "aaabacadaeaf",
    "b0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4"
    "d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9"
    "fafbfcfdfeff",
    "b11e398dc80327a1c8e7f78c596a49344f012eda2d4efad8a050cc4c19afa97c59045a99ca"
    "c7827271cb41c65e590e09da3275600c2f09b8367793a9aca3db71cc30c58179ec3e87c14c"
    "01d5c1f3434f1d87",
  }, {
    "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b",
    "",
    "",
    "8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395fa"
    "a4b61a96c8",
  },
};

TEST(HKDFTest, HKDF) {
  for (size_t i = 0; i < arraysize(kHKDFTests); i++) {
    const HKDFTest& test(kHKDFTests[i]);
    SCOPED_TRACE(i);

    std::vector<uint8> data;
    ASSERT_TRUE(base::HexStringToBytes(test.key_hex, &data));
    const std::string key(reinterpret_cast<char*>(&data[0]), data.size());

    data.clear();
    // |salt_hex| is optional and may be empty.
    std::string salt(test.salt_hex);
    if (!salt.empty()) {
      ASSERT_TRUE(base::HexStringToBytes(salt, &data));
      salt.assign(reinterpret_cast<char*>(&data[0]), data.size());
    }

    data.clear();
    // |info_hex| is optional and may be empty.
    std::string info(test.info_hex);
    if (!info.empty()) {
      ASSERT_TRUE(base::HexStringToBytes(info, &data));
      info.assign(reinterpret_cast<char*>(&data[0]), data.size());
    }

    data.clear();
    ASSERT_TRUE(base::HexStringToBytes(test.output_hex, &data));
    const std::string expected(reinterpret_cast<char*>(&data[0]), data.size());

    // We set the key_length to the length of the expected output and then take
    // the result from the first key, which is the client write key.
    HKDF hkdf(key, salt, info, expected.size(), 0, 0);

    ASSERT_EQ(expected.size(), hkdf.client_write_key().size());
    EXPECT_EQ(0, memcmp(expected.data(), hkdf.client_write_key().data(),
                        expected.size()));
  }
}

}  // namespace
}  // namespace test
