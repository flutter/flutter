// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include <sstream>

#include "txt/font_collection.h"

namespace txt {
namespace testing {

class FontCollectionTests : public ::testing::Test {
 public:
  FontCollectionTests() {}

  void SetUp() override {}
};

TEST_F(FontCollectionTests, SettingUpDefaultFontManagerClearsCache) {
  FontCollection font_collection;
  sk_sp<skia::textlayout::FontCollection> sk_font_collection =
      font_collection.CreateSktFontCollection();
  ASSERT_EQ(sk_font_collection->getFallbackManager().get(), nullptr);
  font_collection.SetupDefaultFontManager(0);
  sk_font_collection = font_collection.CreateSktFontCollection();
  ASSERT_NE(sk_font_collection->getFallbackManager().get(), nullptr);
}
}  // namespace testing
}  // namespace txt
