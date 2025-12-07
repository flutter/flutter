// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include <sstream>

#include "third_party/skia/include/core/SkTypeface.h"
#include "txt/platform.h"
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

// Tests that font weight is preserved during fallback.
// Uses "ゐ" (U+3090) which triggers Hiragino Sans fallback.
// see: https://github.com/flutter/flutter/issues/132475
TEST_F(PlatformMacTests, FontFallbackPreservesWeight) {
  sk_sp<SkFontMgr> font_manager = GetDefaultFontManager(0);
  ASSERT_NE(font_manager, nullptr);

  SkUnichar test_char = 0x3090;

  for (int weight : {100, 200, 300, 400, 500, 600, 700, 800, 900}) {
    SkFontStyle style(weight, SkFontStyle::kNormal_Width,
                      SkFontStyle::kUpright_Slant);

    sk_sp<SkTypeface> typeface = font_manager->matchFamilyStyleCharacter(
        nullptr, style, nullptr, 0, test_char);
    ASSERT_NE(typeface, nullptr);

    EXPECT_EQ(typeface->fontStyle().weight(), weight)
        << "Weight mismatch for requested weight " << weight;
  }
}

// Tests that Regular (400) and Bold (700) weights are preserved for various
// scripts.
// see: https://github.com/flutter/flutter/issues/132475
TEST_F(PlatformMacTests, FontFallbackPreservesWeightOtherScripts) {
  sk_sp<SkFontMgr> font_manager = GetDefaultFontManager(0);
  ASSERT_NE(font_manager, nullptr);

  struct TestCase {
    SkUnichar character;
    const char* name;
  };
  TestCase test_cases[] = {
      {0x0621, "Arabic"},    // ء
      {0x4E01, "Chinese"},   // 丁
      {0x0915, "Hindi"},     // क
      {0x3090, "Japanese"},  // ゐ
      {0x3131, "Korean"},    // ㄱ
  };

  for (const auto& test_case : test_cases) {
    for (int weight : {400, 700}) {
      SkFontStyle style(weight, SkFontStyle::kNormal_Width,
                        SkFontStyle::kUpright_Slant);

      sk_sp<SkTypeface> typeface = font_manager->matchFamilyStyleCharacter(
          nullptr, style, nullptr, 0, test_case.character);
      ASSERT_NE(typeface, nullptr) << "No font for " << test_case.name;

      EXPECT_EQ(typeface->fontStyle().weight(), weight)
          << "Weight mismatch for " << test_case.name << ", requested weight "
          << weight;
    }
  }
}

// Tests that italic system font correctly reports SkFontStyle.
TEST_F(PlatformMacTests, ItalicSystemFontSlant) {
  sk_sp<SkFontMgr> font_manager = GetDefaultFontManager(0);
  ASSERT_NE(font_manager, nullptr);

  // Request italic style for the system font
  SkFontStyle italic_style(SkFontStyle::kNormal_Weight,
                           SkFontStyle::kNormal_Width,
                           SkFontStyle::kItalic_Slant);

  sk_sp<SkTypeface> typeface = font_manager->matchFamilyStyleCharacter(
      nullptr, italic_style, nullptr, 0, 'A');
  ASSERT_NE(typeface, nullptr);

  // Verify that the returned typeface reports italic slant
  EXPECT_EQ(typeface->fontStyle().slant(), SkFontStyle::kItalic_Slant)
      << "Expected italic slant, got upright";
}

}  // namespace testing
}  // namespace txt
