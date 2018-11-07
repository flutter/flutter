// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/message.h"
#include "gtest/gtest.h"

namespace fml {

struct TestStruct {
  int a = 12;
  char b = 'x';
  float c = 99.0f;
};

TEST(MessageTest, CanEncodeTriviallyCopyableTypes) {
  Message message;
  ASSERT_TRUE(message.Encode(12));
  ASSERT_TRUE(message.Encode(11.0f));
  ASSERT_TRUE(message.Encode('a'));

  TestStruct s;
  ASSERT_TRUE(message.Encode(s));
  ASSERT_GE(message.GetDataLength(), 0u);
  ASSERT_GE(message.GetBufferSize(), 0u);
  ASSERT_EQ(message.GetSizeRead(), 0u);
}

TEST(MessageTest, CanDecodeTriviallyCopyableTypes) {
  Message message;
  ASSERT_TRUE(message.Encode(12));
  ASSERT_TRUE(message.Encode(11.0f));
  ASSERT_TRUE(message.Encode('a'));
  TestStruct s;
  s.a = 10;
  s.b = 'y';
  s.c = 11.1f;

  ASSERT_TRUE(message.Encode(s));

  ASSERT_GE(message.GetDataLength(), 0u);
  ASSERT_GE(message.GetBufferSize(), 0u);
  ASSERT_EQ(message.GetSizeRead(), 0u);

  int int1 = 0;
  ASSERT_TRUE(message.Decode(int1));
  ASSERT_EQ(12, int1);

  float float1 = 0.0f;
  ASSERT_TRUE(message.Decode(float1));
  ASSERT_EQ(float1, 11.0f);

  char char1 = 'x';
  ASSERT_TRUE(message.Decode(char1));
  ASSERT_EQ(char1, 'a');

  TestStruct s1;
  ASSERT_TRUE(message.Decode(s1));
  ASSERT_EQ(s1.a, 10);
  ASSERT_EQ(s1.b, 'y');
  ASSERT_EQ(s1.c, 11.1f);

  ASSERT_NE(message.GetSizeRead(), 0u);
  ASSERT_EQ(message.GetDataLength(), message.GetSizeRead());
}

}  // namespace fml
