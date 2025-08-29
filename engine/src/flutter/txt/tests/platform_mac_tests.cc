// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include <sstream>

#include "txt/platform_mac.h"

namespace txt {
namespace testing {

class PlatformMacTests : public ::testing::Test {
 public:
  PlatformMacTests() {}

  void SetUp() override {}
};

TEST_F(PlatformMacTests, RegisterSystemFonts) {
  DynamicFontManager dynamic_font_manager;
  RegisterSystemFonts(dynamic_font_manager);
  ASSERT_EQ(dynamic_font_manager.font_provider().GetFamilyCount(), 1ul);
  ASSERT_NE(dynamic_font_manager.font_provider().MatchFamily(
                "CupertinoSystemDisplay"),
            nullptr);
  ASSERT_EQ(dynamic_font_manager.font_provider()
                .MatchFamily("CupertinoSystemDisplay")
                ->count(),
            10);
}

TEST_F(PlatformMacTests, GetDefaultFontFamiliesOffMainThreadCrash) {
    std::thread t([]() {
        // Chamada intencional fora da main thread
        // Isso vai crashar no macOS/iOS real, simulando o bug da engine
        auto families = txt::GetDefaultFontFamilies();

        // Se não crashar, apenas printa
        for (const auto &f : families) {
            std::cout << f << std::endl;
        }
    });

    t.join();
}
}  // namespace testing
}  // namespace txt
