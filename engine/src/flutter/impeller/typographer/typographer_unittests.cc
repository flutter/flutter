// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/playground/playground_test.h"
#include "impeller/typographer/backends/skia/text_frame_skia.h"
#include "impeller/typographer/backends/skia/text_render_context_skia.h"
#include "impeller/typographer/lazy_glyph_atlas.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkTextBlob.h"

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
  OpenPlaygroundHere([](RenderTarget&) { return true; });
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

  ASSERT_FALSE(frame.HasColor());

  LazyGlyphAtlas lazy_atlas;
  ASSERT_FALSE(lazy_atlas.HasColor());

  lazy_atlas.AddTextFrame(frame);

  ASSERT_FALSE(lazy_atlas.HasColor());

  frame = TextFrameFromTextBlob(SkTextBlob::MakeFromString("😀 ", emoji_font));

  ASSERT_TRUE(frame.HasColor());

  lazy_atlas.AddTextFrame(frame);

  ASSERT_TRUE(lazy_atlas.HasColor());
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

  auto blob = SkTextBlob::MakeFromString(
      "QWERTYUIOPASDFGHJKLZXCVBNMqewrtyuiopasdfghjklzxcvbnm,.<>[]{};':"
      "2134567890-=!@#$%^&*()_+"
      "œ∑´®†¥¨ˆøπ““‘‘åß∂ƒ©˙∆˚¬…æ≈ç√∫˜µ≤≥≥≥≥÷¡™£¢∞§¶•ªº–≠⁄€‹›ﬁﬂ‡°·‚—±Œ„´‰Á¨Ø∏”’/"
      "* Í˝ */¸˛Ç◊ı˜Â¯˘¿",
      sk_font);
  ASSERT_TRUE(blob);

  TextFrame frame;
  size_t count = 0;
  TextRenderContext::FrameIterator iterator = [&]() -> const TextFrame* {
    if (count < 8) {
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

  ASSERT_EQ(atlas->GetTexture()->GetSize().width * 2,
            atlas->GetTexture()->GetSize().height);
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

  // now create a new glyph atlas with a nearly identical blob.

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

}  // namespace testing
}  // namespace impeller
