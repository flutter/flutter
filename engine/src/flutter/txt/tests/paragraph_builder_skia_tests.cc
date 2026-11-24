// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include <sstream>

#include "skia/paragraph_builder_skia.h"
#include "txt/paragraph_style.h"

namespace txt {

class SkiaParagraphBuilderTests : public ::testing::Test {
 public:
  SkiaParagraphBuilderTests() {}

  void SetUp() override {}
};

TEST_F(SkiaParagraphBuilderTests, ParagraphStrutStyle) {
  ParagraphStyle style = ParagraphStyle();
  auto collection = std::make_shared<FontCollection>();
  auto builder = ParagraphBuilderSkia(style, collection, false);

  auto strut_style = builder.TxtToSkia(style).getStrutStyle();
  ASSERT_FALSE(strut_style.getHalfLeading());

  style.strut_half_leading = true;
  strut_style = builder.TxtToSkia(style).getStrutStyle();
  ASSERT_TRUE(strut_style.getHalfLeading());
}

TEST_F(SkiaParagraphBuilderTests, RenderSoftHyphensEnabled) {
  ParagraphStyle style = ParagraphStyle();
  auto collection = std::make_shared<FontCollection>();
  auto builder = ParagraphBuilderSkia(style, collection, false);

  // Defaults to rendering the soft hyphen glyph (Hyphens.manual).
  ASSERT_TRUE(builder.TxtToSkia(style).getRenderSoftHyphens());

  // Hyphens.hidden suppresses the soft hyphen glyph.
  style.render_soft_hyphens = false;
  ASSERT_FALSE(builder.TxtToSkia(style).getRenderSoftHyphens());
}

TEST_F(SkiaParagraphBuilderTests, SoftHyphenString) {
  ParagraphStyle style = ParagraphStyle();
  auto collection = std::make_shared<FontCollection>();
  auto builder = ParagraphBuilderSkia(style, collection, false);

  // Unset keeps Skia's default hyphen.
  ASSERT_EQ(builder.TxtToSkia(style).getSoftHyphenString(), SkString("-"));

  style.soft_hyphen_string = u"\u2010";
  ASSERT_EQ(builder.TxtToSkia(style).getSoftHyphenString(), SkString("\u2010"));

  // The empty string is passed through and draws nothing.
  style.soft_hyphen_string = u"";
  ASSERT_EQ(builder.TxtToSkia(style).getSoftHyphenString(), SkString(""));
}

TEST_F(SkiaParagraphBuilderTests, TextShapingEngineSelection) {
  ParagraphStyle style = ParagraphStyle();
  ASSERT_FALSE(style.enable_skoretext);

  auto collection = std::make_shared<FontCollection>();
  auto builder = ParagraphBuilderSkia(style, collection, false);

#if defined(SK_PARAGRAPH_NATIVE_CORETEXT) && \
    defined(SK_PARAGRAPH_DISABLE_HARFBUZZ)
  ASSERT_EQ(builder.TxtToSkia(style).getTextShapingEngine(),
            skia::textlayout::TextShapingEngine::kCoreText);
#elif defined(SK_PARAGRAPH_NATIVE_CORETEXT)
  ASSERT_EQ(builder.TxtToSkia(style).getTextShapingEngine(),
            skia::textlayout::TextShapingEngine::kDefault);

  // Enabling SkUnicode_apple alone does not enable CoreText shaping.
  style.enable_skunicode_apple = true;
  ASSERT_EQ(builder.TxtToSkia(style).getTextShapingEngine(),
            skia::textlayout::TextShapingEngine::kDefault);

  style.enable_skunicode_apple = false;
  style.enable_skoretext = true;
  ASSERT_EQ(builder.TxtToSkia(style).getTextShapingEngine(),
            skia::textlayout::TextShapingEngine::kCoreText);
#else
  ASSERT_EQ(builder.TxtToSkia(style).getTextShapingEngine(),
            skia::textlayout::TextShapingEngine::kDefault);

  // Ignored on non-Apple platforms.
  style.enable_skoretext = true;
  ASSERT_EQ(builder.TxtToSkia(style).getTextShapingEngine(),
            skia::textlayout::TextShapingEngine::kDefault);
#endif
}

TEST_F(SkiaParagraphBuilderTests, AppleUnicodeSelection) {
  ParagraphStyle style = ParagraphStyle();
  ASSERT_FALSE(style.enable_skoretext);
  ASSERT_FALSE(style.enable_skunicode_apple);

#if defined(SK_UNICODE_APPLE_IMPLEMENTATION) && \
    (defined(SK_PARAGRAPH_DISABLE_HARFBUZZ) ||  \
     !defined(SK_UNICODE_ICU_IMPLEMENTATION))
  ASSERT_TRUE(ParagraphBuilderSkia::ShouldUseAppleUnicode(style));
#elif defined(SK_UNICODE_APPLE_IMPLEMENTATION)
  ASSERT_FALSE(ParagraphBuilderSkia::ShouldUseAppleUnicode(style));

  // Enabling SkUnicode_apple on its own selects Apple Unicode.
  style.enable_skunicode_apple = true;
  ASSERT_TRUE(ParagraphBuilderSkia::ShouldUseAppleUnicode(style));

  // Enabling SkoreText still couples Apple Unicode even when
  // enable_skunicode_apple is false.
  style.enable_skunicode_apple = false;
  style.enable_skoretext = true;
  ASSERT_TRUE(ParagraphBuilderSkia::ShouldUseAppleUnicode(style));

  style.enable_skunicode_apple = true;
  ASSERT_TRUE(ParagraphBuilderSkia::ShouldUseAppleUnicode(style));
#else
  ASSERT_FALSE(ParagraphBuilderSkia::ShouldUseAppleUnicode(style));

  // Ignored on non-Apple platforms.
  style.enable_skunicode_apple = true;
  ASSERT_FALSE(ParagraphBuilderSkia::ShouldUseAppleUnicode(style));

  style.enable_skoretext = true;
  ASSERT_FALSE(ParagraphBuilderSkia::ShouldUseAppleUnicode(style));
#endif
}

#if defined(SK_PARAGRAPH_NATIVE_CORETEXT)
TEST_F(SkiaParagraphBuilderTests, SkoreTextCoreTextAndAppleUnicodeLayout) {
  auto collection = std::make_shared<FontCollection>();
  collection->SetupDefaultFontManager(0);

  auto measure_apple_ui_font = [&](bool enable_skoretext, double font_size) {
    ParagraphStyle style;
    style.enable_skoretext = enable_skoretext;
    TextStyle text_style;
    text_style.font_families = {".AppleSystemUIFont"};
    text_style.font_size = font_size;

    ParagraphBuilderSkia builder(style, collection, /*impeller_enabled=*/true);
    builder.PushStyle(text_style);
    builder.AddText(u"DynamicTrackingTest Hello World");
    builder.Pop();
    auto paragraph = builder.Build();
    paragraph->Layout(2000.0);
    return paragraph->GetLongestLine();
  };

  // CoreText applies size-dependent optical sizing (opsz) and tracking (trak)
  // on .AppleSystemUIFont, tightening normalized width at 48pt vs 11pt.
  const double ct_11_norm = measure_apple_ui_font(true, 11.0) / 11.0;
  const double ct_48_norm = measure_apple_ui_font(true, 48.0) / 48.0;
  EXPECT_GT(ct_11_norm - ct_48_norm, 1.5);

#if !defined(SK_PARAGRAPH_DISABLE_HARFBUZZ)
  // When enable_skoretext is false (default), HarfBuzz + ICU are used and do
  // not apply CoreText's trak table, producing a wider 48pt line.
  const double hb_48_norm = measure_apple_ui_font(false, 48.0) / 48.0;
  EXPECT_GT(hb_48_norm - ct_48_norm, 1.0);
#endif

  // Verify SkUnicode_apple preserves a leading UTF-8 U+FEFF (EF BB BF) and
  // computes word boundaries accurately in UTF-16 code units.
  ParagraphStyle bom_style;
  bom_style.enable_skoretext = true;
  TextStyle bom_text_style;
  bom_text_style.font_families = {"Helvetica"};
  bom_text_style.font_size = 16.0;

  ParagraphBuilderSkia bom_builder(bom_style, collection,
                                   /*impeller_enabled=*/true);
  bom_builder.PushStyle(bom_text_style);
  constexpr std::string_view kBomText = "\xEF\xBB\xBFHello World";
  bom_builder.AddText(reinterpret_cast<const uint8_t*>(kBomText.data()),
                      kBomText.size());
  bom_builder.Pop();
  auto bom_paragraph = bom_builder.Build();
  bom_paragraph->Layout(1000.0);

  EXPECT_GT(bom_paragraph->GetLongestLine(), 0.0);
  // U+FEFF occupies UTF-16 index 0, so "Hello" spans [1, 6).
  EXPECT_EQ(bom_paragraph->GetWordBoundary(1), Paragraph::Range<size_t>(1, 6));
}

#if defined(SK_UNICODE_APPLE_IMPLEMENTATION) && \
    !defined(SK_PARAGRAPH_DISABLE_HARFBUZZ)
TEST_F(SkiaParagraphBuilderTests, SkUnicodeAppleStandaloneWithHarfBuzzLayout) {
  auto collection = std::make_shared<FontCollection>();
  collection->SetupDefaultFontManager(0);

  auto measure_apple_ui_font = [&](bool enable_skoretext,
                                   bool enable_skunicode_apple,
                                   double font_size) {
    ParagraphStyle style;
    style.enable_skoretext = enable_skoretext;
    style.enable_skunicode_apple = enable_skunicode_apple;
    TextStyle text_style;
    text_style.font_families = {".AppleSystemUIFont"};
    text_style.font_size = font_size;

    ParagraphBuilderSkia builder(style, collection, /*impeller_enabled=*/true);
    builder.PushStyle(text_style);
    builder.AddText(u"DynamicTrackingTest Hello World");
    builder.Pop();
    auto paragraph = builder.Build();
    paragraph->Layout(2000.0);
    return paragraph->GetLongestLine();
  };

  // Standalone SkUnicode_apple keeps HarfBuzz shaping (matching default
  // HarfBuzz + ICU width, and wider than CoreText's tracked 48pt layout).
  const double hb_icu_48 = measure_apple_ui_font(false, false, 48.0);
  const double hb_apple_48 = measure_apple_ui_font(false, true, 48.0);
  const double ct_48 = measure_apple_ui_font(true, false, 48.0);
  EXPECT_NEAR(hb_apple_48, hb_icu_48, 0.01);
  EXPECT_GT((hb_apple_48 - ct_48) / 48.0, 1.0);

  // Verify standalone SkUnicode_apple preserves a leading UTF-8 U+FEFF and
  // computes word boundaries accurately with HarfBuzz shaping.
  ParagraphStyle bom_style;
  bom_style.enable_skunicode_apple = true;
  TextStyle bom_text_style;
  bom_text_style.font_families = {"Helvetica"};
  bom_text_style.font_size = 16.0;

  ParagraphBuilderSkia bom_builder(bom_style, collection,
                                   /*impeller_enabled=*/true);
  bom_builder.PushStyle(bom_text_style);
  constexpr std::string_view kBomText = "\xEF\xBB\xBFHello World";
  bom_builder.AddText(reinterpret_cast<const uint8_t*>(kBomText.data()),
                      kBomText.size());
  bom_builder.Pop();
  auto bom_paragraph = bom_builder.Build();
  bom_paragraph->Layout(1000.0);

  EXPECT_GT(bom_paragraph->GetLongestLine(), 0.0);
  EXPECT_EQ(bom_paragraph->GetWordBoundary(1), Paragraph::Range<size_t>(1, 6));
}
#endif  // defined(SK_UNICODE_APPLE_IMPLEMENTATION) &&
        // !defined(SK_PARAGRAPH_DISABLE_HARFBUZZ)
#endif  // defined(SK_PARAGRAPH_NATIVE_CORETEXT)
}  // namespace txt
