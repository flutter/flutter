// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/base32.h"
#include "gtest/gtest.h"

TEST(Base32Test, CanEncode) {
  {
    auto result = fml::Base32Encode("hello");
    ASSERT_TRUE(result.first);
    ASSERT_EQ(result.second, "NBSWY3DP");
  }

  {
    auto result = fml::Base32Encode("helLo");
    ASSERT_TRUE(result.first);
    ASSERT_EQ(result.second, "NBSWYTDP");
  }

  {
    auto result = fml::Base32Encode("");
    ASSERT_TRUE(result.first);
    ASSERT_EQ(result.second, "");
  }

  {
    auto result = fml::Base32Encode("1");
    ASSERT_TRUE(result.first);
    ASSERT_EQ(result.second, "GE");
  }

  {
    auto result = fml::Base32Encode("helLo");
    ASSERT_TRUE(result.first);
    ASSERT_EQ(result.second, "NBSWYTDP");
  }
}
