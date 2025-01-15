// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/renderer/testing/mocks.h"
#include "flutter/testing/testing.h"
#include "impeller/entity/contents/text_contents.h"
#include "impeller/playground/playground_test.h"
#include "impeller/typographer/backends/skia/text_frame_skia.h"
#include "impeller/typographer/backends/skia/typographer_context_skia.h"
#include "third_party/googletest/googletest/include/gtest/gtest.h"
#include "txt/platform.h"

namespace impeller {
namespace testing {

using TextContentsTest = PlaygroundTest;
INSTANTIATE_PLAYGROUND_SUITE(TextContentsTest);

using ::testing::Return;

namespace {
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

std::shared_ptr<GlyphAtlas> CreateGlyphAtlas(
    Context& context,
    const TypographerContext* typographer_context,
    HostBuffer& host_buffer,
    GlyphAtlas::Type type,
    Scalar scale,
    const std::shared_ptr<GlyphAtlasContext>& atlas_context,
    const std::shared_ptr<TextFrame>& frame) {
  frame->SetPerFrameData(scale, /*offset=*/{0, 0},
                         /*glyph_properties=*/std::nullopt);
  return typographer_context->CreateGlyphAtlas(context, type, host_buffer,
                                               atlas_context, {frame});
}
}  // namespace

TEST_P(TextContentsTest, SimpleComputeVertexData) {
  GlyphAtlasPipeline::VertexShader::PerVertexData data[6];

  std::shared_ptr<TextFrame> text_frame =
      MakeTextFrame("1", "ahem.ttf", /*font_size=*/50);

  auto context = TypographerContextSkia::Make();
  auto atlas_context =
      context->CreateGlyphAtlasContext(GlyphAtlas::Type::kAlphaBitmap);
  auto host_buffer = HostBuffer::Create(GetContext()->GetResourceAllocator(),
                                        GetContext()->GetIdleWaiter());
  ASSERT_TRUE(context && context->IsValid());
  auto atlas = CreateGlyphAtlas(*GetContext(), context.get(), *host_buffer,
                                GlyphAtlas::Type::kAlphaBitmap, /*scale=*/1.0f,
                                atlas_context, text_frame);

  ISize texture_size = atlas->GetTexture()->GetSize();
  TextContents::ComputeVertexData(
      data, text_frame, /*scale=*/1.0, /*entity_transform=*/Matrix(),
      /*basis_transform=*/Matrix(), /*offset=*/Vector2(0, 0),
      /*glyph_properties=*/std::nullopt, atlas);

  EXPECT_NEAR(data[0].uv.x * texture_size.width, 0.5, 0.001);
  EXPECT_NEAR(data[0].uv.y * texture_size.height, 0.5, 0.001);
  EXPECT_NEAR(data[0].position.x, -1.0, 0.001);
  EXPECT_NEAR(data[0].position.y, -41.0, 0.001);

  EXPECT_NEAR(data[1].uv.x * texture_size.width, 53.5, 0.001);
  EXPECT_NEAR(data[1].uv.y * texture_size.height, 0.5, 0.001);
  EXPECT_NEAR(data[1].position.x, 51.0, 0.001);
  EXPECT_NEAR(data[1].position.y, -41.0, 0.001);

  EXPECT_NEAR(data[2].uv.x * texture_size.width, 0.5, 0.001);
  EXPECT_NEAR(data[2].uv.y * texture_size.height, 53.5, 0.001);
  EXPECT_NEAR(data[2].position.x, -1.0, 0.001);
  EXPECT_NEAR(data[2].position.y, 11.0, 0.001);

  EXPECT_NEAR(data[3].uv.x * texture_size.width, 53.5, 0.001);
  EXPECT_NEAR(data[3].uv.y * texture_size.height, 0.5, 0.001);
  EXPECT_NEAR(data[3].position.x, 51.0, 0.001);
  EXPECT_NEAR(data[3].position.y, -41.0, 0.001);

  EXPECT_NEAR(data[4].uv.x * texture_size.width, 0.5, 0.001);
  EXPECT_NEAR(data[4].uv.y * texture_size.height, 53.5, 0.001);
  EXPECT_NEAR(data[4].position.x, -1.0, 0.001);
  EXPECT_NEAR(data[4].position.y, 11.0, 0.001);

  EXPECT_NEAR(data[5].uv.x * texture_size.width, 53.5, 0.001);
  EXPECT_NEAR(data[5].uv.y * texture_size.height, 53.5, 0.001);
  EXPECT_NEAR(data[5].position.x, 51.0, 0.001);
  EXPECT_NEAR(data[5].position.y, 11.0, 0.001);
}

}  // namespace testing
}  // namespace impeller
