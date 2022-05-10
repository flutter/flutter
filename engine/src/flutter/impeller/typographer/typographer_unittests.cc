// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/playground/playground.h"
#include "impeller/typographer/backends/skia/text_frame_skia.h"
#include "impeller/typographer/backends/skia/text_render_context_skia.h"
#include "third_party/skia/include/core/SkTextBlob.h"

namespace impeller {
namespace testing {

using TypographerTest = Playground;
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
  auto atlas = context->CreateGlyphAtlas(TextFrameFromTextBlob(blob));
  ASSERT_NE(atlas, nullptr);
  OpenPlaygroundHere([](RenderTarget&) { return true; });
}

}  // namespace testing
}  // namespace impeller
