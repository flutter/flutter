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
#endif  // defined(SK_PARAGRAPH_NATIVE_CORETEXT)
}  // namespace txt
