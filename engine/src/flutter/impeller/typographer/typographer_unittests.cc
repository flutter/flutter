// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/playground/playground_test.h"
#include "impeller/typographer/backends/skia/text_frame_skia.h"
#include "impeller/typographer/backends/skia/text_render_context_skia.h"
#include "impeller/typographer/lazy_glyph_atlas.h"
#include "impeller/typographer/rectangle_packer.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkFontMgr.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkTextBlob.h"

// TODO(zanderso): https://github.com/flutter/flutter/issues/127701
// NOLINTBEGIN(bugprone-unchecked-optional-access)

namespace impeller {
namespace testing {

using TypographerTest = PlaygroundTest;
INSTANTIATE_PLAYGROUND_SUITE(TypographerTest);

TEST_P(TypographerTest, CanConvertTextBlob) {
  SkFont font;
  auto blob = SkTextBlob::MakeFromString(
      "the quick brown fox jumped over the lazy dog.", font);
  ASSERT_TRUE(blob);
  auto frame = TextFrameFromTextBlob(blob);
  ASSERT_EQ(frame.GetRunCount(), 1u);
  for (const auto& run : frame.GetRuns()) {
    ASSERT_TRUE(run.IsValid());
    ASSERT_EQ(run.GetGlyphCount(), 45u);
  }
}

TEST_P(TypographerTest, CanCreateRenderContext) {
  auto context = TextRenderContext::Create(GetContext());
  ASSERT_TRUE(context && context->IsValid());
}

TEST_P(TypographerTest, CanCreateGlyphAtlas) {
  auto context = TextRenderContext::Create(GetContext());
  auto atlas_context = std::make_shared<GlyphAtlasContext>();
  ASSERT_TRUE(context && context->IsValid());
  SkFont sk_font;
  auto blob = SkTextBlob::MakeFromString("hello", sk_font);
  ASSERT_TRUE(blob);
  auto atlas =
      context->CreateGlyphAtlas(GlyphAtlas::Type::kAlphaBitmap, atlas_context,
                                TextFrameFromTextBlob(blob));
  ASSERT_NE(atlas, nullptr);
  ASSERT_NE(atlas->GetTexture(), nullptr);
  ASSERT_EQ(atlas->GetType(), GlyphAtlas::Type::kAlphaBitmap);
  ASSERT_EQ(atlas->GetGlyphCount(), 4llu);

  std::optional<FontGlyphPair> first_pair;
  Rect first_rect;
  atlas->IterateGlyphs(
      [&](const FontGlyphPair& pair, const Rect& rect) -> bool {
        first_pair = pair;
        first_rect = rect;
        return false;
      });

  ASSERT_TRUE(first_pair.has_value());
  ASSERT_TRUE(atlas->FindFontGlyphBounds(first_pair.value()).has_value());
}

static sk_sp<SkData> OpenFixtureAsSkData(const char* fixture_name) {
  auto mapping = flutter::testing::OpenFixtureAsMapping(fixture_name);
  if (!mapping) {
    return nullptr;
  }
  auto data = SkData::MakeWithProc(
      mapping->GetMapping(), mapping->GetSize(),
      [](const void* ptr, void* context) {
        delete reinterpret_cast<fml::Mapping*>(context);
      },
      mapping.get());
  mapping.release();
  return data;
}

TEST_P(TypographerTest, LazyAtlasTracksColor) {
#if FML_OS_MACOSX
  auto mapping = OpenFixtureAsSkData("Apple Color Emoji.ttc");
#else
  auto mapping = OpenFixtureAsSkData("NotoColorEmoji.ttf");
#endif
  ASSERT_TRUE(mapping);
  SkFont emoji_font(SkTypeface::MakeFromData(mapping), 50.0);
  SkFont sk_font;

  auto blob = SkTextBlob::MakeFromString("hello", sk_font);
  ASSERT_TRUE(blob);
  auto frame = TextFrameFromTextBlob(blob);

  ASSERT_FALSE(frame.GetAtlasType() == GlyphAtlas::Type::kColorBitmap);

  LazyGlyphAtlas lazy_atlas;

  lazy_atlas.AddTextFrame(frame);

  frame = TextFrameFromTextBlob(SkTextBlob::MakeFromString("😀 ", emoji_font));

  ASSERT_TRUE(frame.GetAtlasType() == GlyphAtlas::Type::kColorBitmap);

  lazy_atlas.AddTextFrame(frame);

  // Creates different atlases for color and alpha bitmap.
  auto color_context = std::make_shared<GlyphAtlasContext>();
  auto bitmap_context = std::make_shared<GlyphAtlasContext>();
  auto color_atlas = lazy_atlas.CreateOrGetGlyphAtlas(
      GlyphAtlas::Type::kColorBitmap, color_context, GetContext());

  auto bitmap_atlas = lazy_atlas.CreateOrGetGlyphAtlas(
      GlyphAtlas::Type::kAlphaBitmap, bitmap_context, GetContext());

  ASSERT_FALSE(color_atlas == bitmap_atlas);
}

TEST_P(TypographerTest, GlyphAtlasWithOddUniqueGlyphSize) {
  auto context = TextRenderContext::Create(GetContext());
  auto atlas_context = std::make_shared<GlyphAtlasContext>();
  ASSERT_TRUE(context && context->IsValid());
  SkFont sk_font;
  auto blob = SkTextBlob::MakeFromString("AGH", sk_font);
  ASSERT_TRUE(blob);
  auto atlas =
      context->CreateGlyphAtlas(GlyphAtlas::Type::kAlphaBitmap, atlas_context,
                                TextFrameFromTextBlob(blob));
  ASSERT_NE(atlas, nullptr);
  ASSERT_NE(atlas->GetTexture(), nullptr);

  ASSERT_EQ(atlas->GetTexture()->GetSize().width,
            atlas->GetTexture()->GetSize().height);
}

TEST_P(TypographerTest, GlyphAtlasIsRecycledIfUnchanged) {
  auto context = TextRenderContext::Create(GetContext());
  auto atlas_context = std::make_shared<GlyphAtlasContext>();
  ASSERT_TRUE(context && context->IsValid());
  SkFont sk_font;
  auto blob = SkTextBlob::MakeFromString("spooky skellingtons", sk_font);
  ASSERT_TRUE(blob);
  auto atlas =
      context->CreateGlyphAtlas(GlyphAtlas::Type::kAlphaBitmap, atlas_context,
                                TextFrameFromTextBlob(blob));
  ASSERT_NE(atlas, nullptr);
  ASSERT_NE(atlas->GetTexture(), nullptr);
  ASSERT_EQ(atlas, atlas_context->GetGlyphAtlas());

  // now attempt to re-create an atlas with the same text blob.

  auto next_atlas =
      context->CreateGlyphAtlas(GlyphAtlas::Type::kAlphaBitmap, atlas_context,
                                TextFrameFromTextBlob(blob));
  ASSERT_EQ(atlas, next_atlas);
  ASSERT_EQ(atlas_context->GetGlyphAtlas(), atlas);
}

TEST_P(TypographerTest, GlyphAtlasWithLotsOfdUniqueGlyphSize) {
  auto context = TextRenderContext::Create(GetContext());
  auto atlas_context = std::make_shared<GlyphAtlasContext>();
  ASSERT_TRUE(context && context->IsValid());
  SkFont sk_font;

  const char* test_string =
      "QWERTYUIOPASDFGHJKLZXCVBNMqewrtyuiopasdfghjklzxcvbnm,.<>[]{};':"
      "2134567890-=!@#$%^&*()_+"
      "œ∑´®†¥¨ˆøπ““‘‘åß∂ƒ©˙∆˚¬…æ≈ç√∫˜µ≤≥≥≥≥÷¡™£¢∞§¶•ªº–≠⁄€‹›ﬁﬂ‡°·‚—±Œ„´‰Á¨Ø∏”’/"
      "* Í˝ */¸˛Ç◊ı˜Â¯˘¿";

  auto blob = SkTextBlob::MakeFromString(test_string, sk_font);
  ASSERT_TRUE(blob);

  TextFrame frame;
  size_t count = 0;
  const int size_count = 8;
  TextRenderContext::FrameIterator iterator = [&]() -> const TextFrame* {
    if (count < size_count) {
      count++;
      frame = TextFrameFromTextBlob(blob, 0.6 * count);
      return &frame;
    }
    return nullptr;
  };
  auto atlas = context->CreateGlyphAtlas(GlyphAtlas::Type::kAlphaBitmap,
                                         atlas_context, iterator);
  ASSERT_NE(atlas, nullptr);
  ASSERT_NE(atlas->GetTexture(), nullptr);

  std::set<uint16_t> unique_glyphs;
  std::vector<uint16_t> total_glyphs;
  atlas->IterateGlyphs([&](const FontGlyphPair& pair, const Rect& rect) {
    unique_glyphs.insert(pair.glyph.index);
    total_glyphs.push_back(pair.glyph.index);
    return true;
  });

  EXPECT_EQ(unique_glyphs.size() * size_count, atlas->GetGlyphCount());
  EXPECT_EQ(total_glyphs.size(), atlas->GetGlyphCount());

  EXPECT_TRUE(atlas->GetGlyphCount() > 0);
  EXPECT_TRUE(atlas->GetTexture()->GetSize().width > 0);
  EXPECT_TRUE(atlas->GetTexture()->GetSize().height > 0);
}

TEST_P(TypographerTest, GlyphAtlasTextureIsRecycledIfUnchanged) {
  auto context = TextRenderContext::Create(GetContext());
  auto atlas_context = std::make_shared<GlyphAtlasContext>();
  ASSERT_TRUE(context && context->IsValid());
  SkFont sk_font;
  auto blob = SkTextBlob::MakeFromString("spooky 1", sk_font);
  ASSERT_TRUE(blob);
  auto atlas =
      context->CreateGlyphAtlas(GlyphAtlas::Type::kAlphaBitmap, atlas_context,
                                TextFrameFromTextBlob(blob));
  auto old_packer = atlas_context->GetRectPacker();

  ASSERT_NE(atlas, nullptr);
  ASSERT_NE(atlas->GetTexture(), nullptr);
  ASSERT_EQ(atlas, atlas_context->GetGlyphAtlas());

  auto* first_texture = atlas->GetTexture().get();

  // Now create a new glyph atlas with a nearly identical blob.

  auto blob2 = SkTextBlob::MakeFromString("spooky 2", sk_font);
  auto next_atlas =
      context->CreateGlyphAtlas(GlyphAtlas::Type::kAlphaBitmap, atlas_context,
                                TextFrameFromTextBlob(blob2));
  ASSERT_EQ(atlas, next_atlas);
  auto* second_texture = next_atlas->GetTexture().get();

  auto new_packer = atlas_context->GetRectPacker();

  ASSERT_EQ(second_texture, first_texture);
  ASSERT_EQ(old_packer, new_packer);
}

TEST_P(TypographerTest, GlyphAtlasTextureIsRecreatedIfTypeChanges) {
  auto context = TextRenderContext::Create(GetContext());
  auto atlas_context = std::make_shared<GlyphAtlasContext>();
  ASSERT_TRUE(context && context->IsValid());
  SkFont sk_font;
  auto blob = SkTextBlob::MakeFromString("spooky 1", sk_font);
  ASSERT_TRUE(blob);
  auto atlas =
      context->CreateGlyphAtlas(GlyphAtlas::Type::kAlphaBitmap, atlas_context,
                                TextFrameFromTextBlob(blob));
  auto old_packer = atlas_context->GetRectPacker();

  ASSERT_NE(atlas, nullptr);
  ASSERT_NE(atlas->GetTexture(), nullptr);
  ASSERT_EQ(atlas, atlas_context->GetGlyphAtlas());

  auto* first_texture = atlas->GetTexture().get();

  // now create a new glyph atlas with an identical blob,
  // but change the type.

  auto blob2 = SkTextBlob::MakeFromString("spooky 1", sk_font);
  auto next_atlas =
      context->CreateGlyphAtlas(GlyphAtlas::Type::kColorBitmap, atlas_context,
                                TextFrameFromTextBlob(blob2));
  ASSERT_NE(atlas, next_atlas);
  auto* second_texture = next_atlas->GetTexture().get();

  auto new_packer = atlas_context->GetRectPacker();

  ASSERT_NE(second_texture, first_texture);
  ASSERT_NE(old_packer, new_packer);
}

TEST_P(TypographerTest, FontGlyphPairTypeChangesHashAndEquals) {
  Font font = Font(nullptr, {});
  FontGlyphPair pair_1 = {
      .font = font,
      .glyph = Glyph(0, Glyph::Type::kBitmap, Rect::MakeXYWH(0, 0, 1, 1))};
  // Same glyph same type.
  FontGlyphPair pair_2 = {
      .font = font,
      .glyph = Glyph(0, Glyph::Type::kBitmap, Rect::MakeXYWH(0, 0, 1, 1))};
  // Same glyph different type.
  FontGlyphPair pair_3 = {
      .font = font,
      .glyph = Glyph(0, Glyph::Type::kPath, Rect::MakeXYWH(0, 0, 1, 1))};

  ASSERT_TRUE(FontGlyphPair::Equal{}(pair_1, pair_2));
  ASSERT_FALSE(FontGlyphPair::Equal{}(pair_1, pair_3));
}

TEST_P(TypographerTest, MaybeHasOverlapping) {
  sk_sp<SkFontMgr> font_mgr = SkFontMgr::RefDefault();
  sk_sp<SkTypeface> typeface =
      font_mgr->matchFamilyStyle("Arial", SkFontStyle::Normal());
  SkFont sk_font(typeface, 0.5f);

  auto frame = TextFrameFromTextBlob(SkTextBlob::MakeFromString("1", sk_font));
  // Single character has no overlapping
  ASSERT_FALSE(frame.MaybeHasOverlapping());

  auto frame_2 =
      TextFrameFromTextBlob(SkTextBlob::MakeFromString("123456789", sk_font));
  // Characters probably have overlap due to low fidelity text metrics, but this
  // could be fixed.
  ASSERT_TRUE(frame_2.MaybeHasOverlapping());
}

TEST_P(TypographerTest, RectanglePackerAddsNonoverlapingRectangles) {
  auto packer = RectanglePacker::Factory(200, 100);
  ASSERT_NE(packer, nullptr);
  ASSERT_EQ(packer->percentFull(), 0);

  const SkIRect packer_area = SkIRect::MakeXYWH(0, 0, 200, 100);

  IPoint16 first_output = {-1, -1};  // Fill with sentinel values
  ASSERT_TRUE(packer->addRect(20, 20, &first_output));
  // Make sure the rectangle is placed such that it is inside the bounds of
  // the packer's area.
  const SkIRect first_rect =
      SkIRect::MakeXYWH(first_output.x(), first_output.y(), 20, 20);
  ASSERT_TRUE(SkIRect::Intersects(packer_area, first_rect));

  // Initial area was 200 x 100 = 20_000
  // We added 20x20 = 400. 400 / 20_000 == 0.02 == 2%
  ASSERT_TRUE(flutter::testing::NumberNear(packer->percentFull(), 0.02));

  IPoint16 second_output = {-1, -1};
  ASSERT_TRUE(packer->addRect(140, 90, &second_output));
  const SkIRect second_rect =
      SkIRect::MakeXYWH(second_output.x(), second_output.y(), 140, 90);
  // Make sure the rectangle is placed such that it is inside the bounds of
  // the packer's area but not in the are of the first rectangle.
  ASSERT_TRUE(SkIRect::Intersects(packer_area, second_rect));
  ASSERT_FALSE(SkIRect::Intersects(first_rect, second_rect));

  // We added another 90 x 140 = 12_600 units, now taking us to 13_000
  // 13_000 / 20_000 == 0.65 == 65%
  ASSERT_TRUE(flutter::testing::NumberNear(packer->percentFull(), 0.65));

  // There's enough area to add this rectangle, but no space big enough for
  // the 50 units of width.
  IPoint16 output;
  ASSERT_FALSE(packer->addRect(50, 50, &output));
  // Should be unchanged.
  ASSERT_TRUE(flutter::testing::NumberNear(packer->percentFull(), 0.65));

  packer->reset();
  // Should be empty now.
  ASSERT_EQ(packer->percentFull(), 0);
}

}  // namespace testing
}  // namespace impeller

// NOLINTEND(bugprone-unchecked-optional-access)
