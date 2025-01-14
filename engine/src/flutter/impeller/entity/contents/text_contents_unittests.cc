// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/renderer/testing/mocks.h"
#include "flutter/testing/testing.h"
#include "impeller/entity/contents/text_contents.h"
#include "impeller/typographer/backends/skia/text_frame_skia.h"
#include "impeller/typographer/backends/skia/typographer_context_skia.h"
#include "third_party/googletest/googletest/include/gtest/gtest.h"
#include "txt/platform.h"

namespace impeller {
namespace testing {

using ::testing::Return;

std::shared_ptr<TextFrame> MakeTextFrame(const std::string& text,
                                         const std::string_view& font_fixture,
                                         Scalar font_size) {
  auto c_font_fixture = std::string(font_fixture);
  auto mapping = flutter::testing::OpenFixtureAsSkData(c_font_fixture.c_str());
  if (!mapping) {
    return nullptr;
  }
  sk_sp<SkFontMgr> font_mgr = txt::GetDefaultFontManager();
  SkFont sk_font(font_mgr->makeFromData(mapping), font_size);
  auto blob = SkTextBlob::MakeFromString(text.c_str(), sk_font);
  if (!blob) {
    return nullptr;
  }

  return MakeTextFrameFromTextBlobSkia(blob);
}

TEST(TextContentsTest, SimpleComputeVertexData) {
  GlyphAtlasPipeline::VertexShader::PerVertexData data[6];

  std::shared_ptr<TextFrame> text_frame =
      MakeTextFrame("A", "Roboto-Regular.ttf", /*font_size=*/50);

  TextureDescriptor texture_descriptor;
  texture_descriptor.size = ISize(1024, 1024);
  std::shared_ptr<MockTexture> mock_texture =
      std::make_shared<MockTexture>(texture_descriptor);
  EXPECT_CALL(*mock_texture, GetSize())
      .WillOnce(Return(texture_descriptor.size));
  std::shared_ptr<GlyphAtlas> atlas =
      std::make_shared<GlyphAtlas>(GlyphAtlas::Type::kAlphaBitmap, 0);
  atlas->SetTexture(mock_texture);

  text_frame->SetPerFrameData(/*scale=*/1.0, /*offset=*/Vector2(0, 0),
                              /*glyph_properties=*/std::nullopt);

  TypographerContextSkia::CollectNewGlyphs(atlas, {text_frame});

  TextContents::ComputeVertexData(
      data, text_frame, /*scale=*/1.0, /*entity_transform=*/Matrix(),
      /*basis_transform=*/Matrix(), /*offset=*/Vector2(0, 0),
      /*glyph_properties=*/std::nullopt, atlas);
}

}  // namespace testing
}  // namespace impeller
