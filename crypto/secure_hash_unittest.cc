// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/secure_hash.h"

#include <string>

#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"
#include "base/pickle.h"
#include "crypto/sha2.h"
#include "testing/gtest/include/gtest/gtest.h"

TEST(SecureHashTest, TestUpdate) {
  // Example B.3 from FIPS 180-2: long message.
  std::string input3(500000, 'a');  // 'a' repeated half a million times
  int expected3[] = { 0xcd, 0xc7, 0x6e, 0x5c,
                      0x99, 0x14, 0xfb, 0x92,
                      0x81, 0xa1, 0xc7, 0xe2,
                      0x84, 0xd7, 0x3e, 0x67,
                      0xf1, 0x80, 0x9a, 0x48,
                      0xa4, 0x97, 0x20, 0x0e,
                      0x04, 0x6d, 0x39, 0xcc,
                      0xc7, 0x11, 0x2c, 0xd0 };

  uint8 output3[crypto::kSHA256Length];

  scoped_ptr<crypto::SecureHash> ctx(crypto::SecureHash::Create(
      crypto::SecureHash::SHA256));
  ctx->Update(input3.data(), input3.size());
  ctx->Update(input3.data(), input3.size());

  ctx->Finish(output3, sizeof(output3));
  for (size_t i = 0; i < crypto::kSHA256Length; i++)
    EXPECT_EQ(expected3[i], static_cast<int>(output3[i]));
}

// Save the crypto state mid-stream, and create another instance with the
// saved state.  Then feed the same data afterwards to both.
// When done, both should have the same hash value.
TEST(SecureHashTest, TestSerialization) {
  std::string input1(10001, 'a');  // 'a' repeated 10001 times
  std::string input2(10001, 'b');  // 'b' repeated 10001 times
  std::string input3(10001, 'c');  // 'c' repeated 10001 times
  std::string input4(10001, 'd');  // 'd' repeated 10001 times
  std::string input5(10001, 'e');  // 'e' repeated 10001 times

  uint8 output1[crypto::kSHA256Length];
  uint8 output2[crypto::kSHA256Length];

  scoped_ptr<crypto::SecureHash> ctx1(crypto::SecureHash::Create(
      crypto::SecureHash::SHA256));
  scoped_ptr<crypto::SecureHash> ctx2(crypto::SecureHash::Create(
      crypto::SecureHash::SHA256));
  base::Pickle pickle;
  ctx1->Update(input1.data(), input1.size());
  ctx1->Update(input2.data(), input2.size());
  ctx1->Update(input3.data(), input3.size());

  EXPECT_TRUE(ctx1->Serialize(&pickle));
  ctx1->Update(input4.data(), input4.size());
  ctx1->Update(input5.data(), input5.size());

  ctx1->Finish(output1, sizeof(output1));

  base::PickleIterator data_iterator(pickle);
  EXPECT_TRUE(ctx2->Deserialize(&data_iterator));
  ctx2->Update(input4.data(), input4.size());
  ctx2->Update(input5.data(), input5.size());

  ctx2->Finish(output2, sizeof(output2));

  EXPECT_EQ(0, memcmp(output1, output2, crypto::kSHA256Length));
}
