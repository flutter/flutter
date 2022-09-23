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
  ASSERT_TRUE(context && context->IsValid());
  SkFont sk_font;
  auto blob = SkTextBlob::MakeFromString("hello", sk_font);
  ASSERT_TRUE(blob);
  auto atlas = context->CreateGlyphAtlas(GlyphAtlas::Type::kAlphaBitmap,
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

  lazy_atlas.AddTextFrame(std::move(frame));

  ASSERT_FALSE(lazy_atlas.HasColor());

  frame = TextFrameFromTextBlob(SkTextBlob::MakeFromString("😀 ", emoji_font));

  ASSERT_TRUE(frame.HasColor());

  lazy_atlas.AddTextFrame(std::move(frame));

  ASSERT_TRUE(lazy_atlas.HasColor());
}

}  // namespace testing
}  // namespace impeller
