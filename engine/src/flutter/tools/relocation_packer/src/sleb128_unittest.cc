// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sleb128.h"

#include <vector>
#include "elf_traits.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace relocation_packer {

TEST(Sleb128, Encoder) {
  std::vector<ELF::Sxword> values;
  values.push_back(624485);
  values.push_back(0);
  values.push_back(1);
  values.push_back(63);
  values.push_back(64);
  values.push_back(-1);
  values.push_back(-624485);

  Sleb128Encoder encoder;
  encoder.EnqueueAll(values);

  encoder.Enqueue(2147483647);
  encoder.Enqueue(-2147483648);
  encoder.Enqueue(9223372036854775807ll);
  encoder.Enqueue(-9223372036854775807ll - 1);

  std::vector<uint8_t> encoding;
  encoder.GetEncoding(&encoding);

  EXPECT_EQ(42u, encoding.size());
  // 624485
  EXPECT_EQ(0xe5, encoding[0]);
  EXPECT_EQ(0x8e, encoding[1]);
  EXPECT_EQ(0x26, encoding[2]);
  // 0
  EXPECT_EQ(0x00, encoding[3]);
  // 1
  EXPECT_EQ(0x01, encoding[4]);
  // 63
  EXPECT_EQ(0x3f, encoding[5]);
  // 64
  EXPECT_EQ(0xc0, encoding[6]);
  EXPECT_EQ(0x00, encoding[7]);
  // -1
  EXPECT_EQ(0x7f, encoding[8]);
  // -624485
  EXPECT_EQ(0x9b, encoding[9]);
  EXPECT_EQ(0xf1, encoding[10]);
  EXPECT_EQ(0x59, encoding[11]);
  // 2147483647
  EXPECT_EQ(0xff, encoding[12]);
  EXPECT_EQ(0xff, encoding[13]);
  EXPECT_EQ(0xff, encoding[14]);
  EXPECT_EQ(0xff, encoding[15]);
  EXPECT_EQ(0x07, encoding[16]);
  // -2147483648
  EXPECT_EQ(0x80, encoding[17]);
  EXPECT_EQ(0x80, encoding[18]);
  EXPECT_EQ(0x80, encoding[19]);
  EXPECT_EQ(0x80, encoding[20]);
  EXPECT_EQ(0x78, encoding[21]);
  // 9223372036854775807
  EXPECT_EQ(0xff, encoding[22]);
  EXPECT_EQ(0xff, encoding[23]);
  EXPECT_EQ(0xff, encoding[24]);
  EXPECT_EQ(0xff, encoding[25]);
  EXPECT_EQ(0xff, encoding[26]);
  EXPECT_EQ(0xff, encoding[27]);
  EXPECT_EQ(0xff, encoding[28]);
  EXPECT_EQ(0xff, encoding[29]);
  EXPECT_EQ(0xff, encoding[30]);
  EXPECT_EQ(0x00, encoding[31]);
  // -9223372036854775808
  EXPECT_EQ(0x80, encoding[32]);
  EXPECT_EQ(0x80, encoding[33]);
  EXPECT_EQ(0x80, encoding[34]);
  EXPECT_EQ(0x80, encoding[35]);
  EXPECT_EQ(0x80, encoding[36]);
  EXPECT_EQ(0x80, encoding[37]);
  EXPECT_EQ(0x80, encoding[38]);
  EXPECT_EQ(0x80, encoding[39]);
  EXPECT_EQ(0x80, encoding[40]);
  EXPECT_EQ(0x7f, encoding[41]);
}

TEST(Sleb128, Decoder) {
  std::vector<uint8_t> encoding;
  // 624485
  encoding.push_back(0xe5);
  encoding.push_back(0x8e);
  encoding.push_back(0x26);
  // 0
  encoding.push_back(0x00);
  // 1
  encoding.push_back(0x01);
  // 63
  encoding.push_back(0x3f);
  // 64
  encoding.push_back(0xc0);
  encoding.push_back(0x00);
  // -1
  encoding.push_back(0x7f);
  // -624485
  encoding.push_back(0x9b);
  encoding.push_back(0xf1);
  encoding.push_back(0x59);
  // 2147483647
  encoding.push_back(0xff);
  encoding.push_back(0xff);
  encoding.push_back(0xff);
  encoding.push_back(0xff);
  encoding.push_back(0x07);
  // -2147483648
  encoding.push_back(0x80);
  encoding.push_back(0x80);
  encoding.push_back(0x80);
  encoding.push_back(0x80);
  encoding.push_back(0x78);
  // 9223372036854775807
  encoding.push_back(0xff);
  encoding.push_back(0xff);
  encoding.push_back(0xff);
  encoding.push_back(0xff);
  encoding.push_back(0xff);
  encoding.push_back(0xff);
  encoding.push_back(0xff);
  encoding.push_back(0xff);
  encoding.push_back(0xff);
  encoding.push_back(0x00);
  // -9223372036854775808
  encoding.push_back(0x80);
  encoding.push_back(0x80);
  encoding.push_back(0x80);
  encoding.push_back(0x80);
  encoding.push_back(0x80);
  encoding.push_back(0x80);
  encoding.push_back(0x80);
  encoding.push_back(0x80);
  encoding.push_back(0x80);
  encoding.push_back(0x7f);

  Sleb128Decoder decoder(encoding);

  EXPECT_EQ(624485, decoder.Dequeue());

  std::vector<ELF::Sxword> dequeued;
  decoder.DequeueAll(&dequeued);

  EXPECT_EQ(10u, dequeued.size());
  EXPECT_EQ(0, dequeued[0]);
  EXPECT_EQ(1, dequeued[1]);
  EXPECT_EQ(63, dequeued[2]);
  EXPECT_EQ(64, dequeued[3]);
  EXPECT_EQ(-1, dequeued[4]);
  EXPECT_EQ(-624485, dequeued[5]);
  EXPECT_EQ(2147483647, dequeued[6]);
  EXPECT_EQ(-2147483648, dequeued[7]);
  EXPECT_EQ(9223372036854775807ll, dequeued[8]);
  EXPECT_EQ(-9223372036854775807ll - 1, dequeued[9]);
}

}  // namespace relocation_packer
