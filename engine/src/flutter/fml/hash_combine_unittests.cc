// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/hash_combine.h"

#include "flutter/testing/testing.h"

namespace fml {
namespace testing {

TEST(HashCombineTest, CanHash) {
  std::string hello("Hello");
  std::string world("World");
  ASSERT_EQ(HashCombine(), HashCombine());
  ASSERT_EQ(HashCombine(hello), HashCombine(hello));
  ASSERT_NE(HashCombine(hello), HashCombine(world));
  ASSERT_EQ(HashCombine(hello, world), HashCombine(hello, world));
  ASSERT_NE(HashCombine(world, hello), HashCombine(hello, world));
  ASSERT_EQ(HashCombine(12u), HashCombine(12u));
  ASSERT_NE(HashCombine(12u), HashCombine(12.0f));
  ASSERT_EQ(HashCombine('a'), HashCombine('a'));
}

}  // namespace testing
}  // namespace fml
