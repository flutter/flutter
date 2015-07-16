// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/sha2.h"

#include "base/basictypes.h"
#include "testing/gtest/include/gtest/gtest.h"

TEST(Sha256Test, Test1) {
  // Example B.1 from FIPS 180-2: one-block message.
  std::string input1 = "abc";
  int expected1[] = { 0xba, 0x78, 0x16, 0xbf,
                      0x8f, 0x01, 0xcf, 0xea,
                      0x41, 0x41, 0x40, 0xde,
                      0x5d, 0xae, 0x22, 0x23,
                      0xb0, 0x03, 0x61, 0xa3,
                      0x96, 0x17, 0x7a, 0x9c,
                      0xb4, 0x10, 0xff, 0x61,
                      0xf2, 0x00, 0x15, 0xad };

  uint8 output1[crypto::kSHA256Length];
  crypto::SHA256HashString(input1, output1, sizeof(output1));
  for (size_t i = 0; i < crypto::kSHA256Length; i++)
    EXPECT_EQ(expected1[i], static_cast<int>(output1[i]));

  uint8 output_truncated1[4];  // 4 bytes == 32 bits
  crypto::SHA256HashString(input1,
                           output_truncated1, sizeof(output_truncated1));
  for (size_t i = 0; i < sizeof(output_truncated1); i++)
    EXPECT_EQ(expected1[i], static_cast<int>(output_truncated1[i]));
}

TEST(Sha256Test, Test1_String) {
  // Same as the above, but using the wrapper that returns a std::string.
  // Example B.1 from FIPS 180-2: one-block message.
  std::string input1 = "abc";
  int expected1[] = { 0xba, 0x78, 0x16, 0xbf,
                      0x8f, 0x01, 0xcf, 0xea,
                      0x41, 0x41, 0x40, 0xde,
                      0x5d, 0xae, 0x22, 0x23,
                      0xb0, 0x03, 0x61, 0xa3,
                      0x96, 0x17, 0x7a, 0x9c,
                      0xb4, 0x10, 0xff, 0x61,
                      0xf2, 0x00, 0x15, 0xad };

  std::string output1 = crypto::SHA256HashString(input1);
  ASSERT_EQ(crypto::kSHA256Length, output1.size());
  for (size_t i = 0; i < crypto::kSHA256Length; i++)
    EXPECT_EQ(expected1[i], static_cast<uint8>(output1[i]));
}

TEST(Sha256Test, Test2) {
  // Example B.2 from FIPS 180-2: multi-block message.
  std::string input2 =
      "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";
  int expected2[] = { 0x24, 0x8d, 0x6a, 0x61,
                      0xd2, 0x06, 0x38, 0xb8,
                      0xe5, 0xc0, 0x26, 0x93,
                      0x0c, 0x3e, 0x60, 0x39,
                      0xa3, 0x3c, 0xe4, 0x59,
                      0x64, 0xff, 0x21, 0x67,
                      0xf6, 0xec, 0xed, 0xd4,
                      0x19, 0xdb, 0x06, 0xc1 };

  uint8 output2[crypto::kSHA256Length];
  crypto::SHA256HashString(input2, output2, sizeof(output2));
  for (size_t i = 0; i < crypto::kSHA256Length; i++)
    EXPECT_EQ(expected2[i], static_cast<int>(output2[i]));

  uint8 output_truncated2[6];
  crypto::SHA256HashString(input2,
                           output_truncated2, sizeof(output_truncated2));
  for (size_t i = 0; i < sizeof(output_truncated2); i++)
    EXPECT_EQ(expected2[i], static_cast<int>(output_truncated2[i]));
}

TEST(Sha256Test, Test3) {
  // Example B.3 from FIPS 180-2: long message.
  std::string input3(1000000, 'a');  // 'a' repeated a million times
  int expected3[] = { 0xcd, 0xc7, 0x6e, 0x5c,
                      0x99, 0x14, 0xfb, 0x92,
                      0x81, 0xa1, 0xc7, 0xe2,
                      0x84, 0xd7, 0x3e, 0x67,
                      0xf1, 0x80, 0x9a, 0x48,
                      0xa4, 0x97, 0x20, 0x0e,
                      0x04, 0x6d, 0x39, 0xcc,
                      0xc7, 0x11, 0x2c, 0xd0 };

  uint8 output3[crypto::kSHA256Length];
  crypto::SHA256HashString(input3, output3, sizeof(output3));
  for (size_t i = 0; i < crypto::kSHA256Length; i++)
    EXPECT_EQ(expected3[i], static_cast<int>(output3[i]));

  uint8 output_truncated3[12];
  crypto::SHA256HashString(input3,
                           output_truncated3, sizeof(output_truncated3));
  for (size_t i = 0; i < sizeof(output_truncated3); i++)
    EXPECT_EQ(expected3[i], static_cast<int>(output_truncated3[i]));
}
