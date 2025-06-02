// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/geometry/geometry_asserts.h"
#include "flutter/impeller/renderer/testing/mocks.h"
#include "flutter/testing/testing.h"
#include "impeller/entity/contents/text_contents.h"
#include "impeller/playground/playground_test.h"
#include "impeller/typographer/backends/skia/text_frame_skia.h"
#include "impeller/typographer/backends/skia/typographer_context_skia.h"
#include "third_party/googletest/googletest/include/gtest/gtest.h"
#include "txt/platform.h"

#pragma GCC diagnostic ignored "-Wunreachable-code"

namespace impeller {
namespace testing {

using TextContentsTest = PlaygroundTest;
INSTANTIATE_PLAYGROUND_SUITE(TextContentsTest);

using ::testing::Return;

namespace {
<<<<<<< HEAD
std::shared_ptr<TextFrame> MakeTextFrame(const std::string& text,
                                         const std::string_view& font_fixture,
                                         Scalar font_size) {
=======
struct TextOptions {
  Scalar font_size = 50;
  bool is_subpixel = false;
};

std::shared_ptr<TextFrame> MakeTextFrame(const std::string& text,
                                         const std::string_view& font_fixture,
                                         const TextOptions& options) {
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
  auto c_font_fixture = std::string(font_fixture);
  auto mapping = flutter::testing::OpenFixtureAsSkData(c_font_fixture.c_str());
  if (!mapping) {
    return nullptr;
  }
  sk_sp<SkFontMgr> font_mgr = txt::GetDefaultFontManager();
<<<<<<< HEAD
  SkFont sk_font(font_mgr->makeFromData(mapping), font_size);
=======
  SkFont sk_font(font_mgr->makeFromData(mapping), options.font_size);
  if (options.is_subpixel) {
    sk_font.setSubpixel(true);
  }
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
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
<<<<<<< HEAD
    Scalar scale,
    const std::shared_ptr<GlyphAtlasContext>& atlas_context,
    const std::shared_ptr<TextFrame>& frame) {
  frame->SetPerFrameData(
      TextFrame::RoundScaledFontSize(scale), /*offset=*/{0, 0},
      /*transform=*/Matrix::MakeScale(Vector3{scale, scale, 1}),
=======
    Rational scale,
    const std::shared_ptr<GlyphAtlasContext>& atlas_context,
    const std::shared_ptr<TextFrame>& frame,
    Point offset) {
  frame->SetPerFrameData(
      TextFrame::RoundScaledFontSize(scale), /*offset=*/offset,
      /*transform=*/
      Matrix::MakeScale(
          Vector3{static_cast<Scalar>(scale), static_cast<Scalar>(scale), 1}),
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
      /*properties=*/std::nullopt);
  return typographer_context->CreateGlyphAtlas(context, type, host_buffer,
                                               atlas_context, {frame});
}

Rect PerVertexDataPositionToRect(
<<<<<<< HEAD
    GlyphAtlasPipeline::VertexShader::PerVertexData data[6]) {
=======
    std::vector<GlyphAtlasPipeline::VertexShader::PerVertexData>::iterator
        data) {
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
  Scalar right = FLT_MIN;
  Scalar left = FLT_MAX;
  Scalar top = FLT_MAX;
  Scalar bottom = FLT_MIN;
<<<<<<< HEAD
  for (int i = 0; i < 6; ++i) {
=======
  for (int i = 0; i < 4; ++i) {
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
    right = std::max(right, data[i].position.x);
    left = std::min(left, data[i].position.x);
    top = std::min(top, data[i].position.y);
    bottom = std::max(bottom, data[i].position.y);
  }

  return Rect::MakeLTRB(left, top, right, bottom);
}

Rect PerVertexDataUVToRect(
<<<<<<< HEAD
    GlyphAtlasPipeline::VertexShader::PerVertexData data[6],
=======
    std::vector<GlyphAtlasPipeline::VertexShader::PerVertexData>::iterator data,
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
    ISize texture_size) {
  Scalar right = FLT_MIN;
  Scalar left = FLT_MAX;
  Scalar top = FLT_MAX;
  Scalar bottom = FLT_MIN;
<<<<<<< HEAD
  for (int i = 0; i < 6; ++i) {
=======
  for (int i = 0; i < 4; ++i) {
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
    right = std::max(right, data[i].uv.x * texture_size.width);
    left = std::min(left, data[i].uv.x * texture_size.width);
    top = std::min(top, data[i].uv.y * texture_size.height);
    bottom = std::max(bottom, data[i].uv.y * texture_size.height);
  }

  return Rect::MakeLTRB(left, top, right, bottom);
}

double GetAspectRatio(Rect rect) {
  return static_cast<double>(rect.GetWidth()) / rect.GetHeight();
}
}  // namespace

TEST_P(TextContentsTest, SimpleComputeVertexData) {
#ifndef FML_OS_MACOSX
  GTEST_SKIP() << "Results aren't stable across linux and macos.";
#endif

<<<<<<< HEAD
  GlyphAtlasPipeline::VertexShader::PerVertexData data[6];

  std::shared_ptr<TextFrame> text_frame =
      MakeTextFrame("1", "ahem.ttf", /*font_size=*/50);
=======
  std::vector<GlyphAtlasPipeline::VertexShader::PerVertexData> data(4);

  std::shared_ptr<TextFrame> text_frame =
      MakeTextFrame("1", "ahem.ttf", TextOptions{.font_size = 50});
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8

  std::shared_ptr<TypographerContext> context = TypographerContextSkia::Make();
  std::shared_ptr<GlyphAtlasContext> atlas_context =
      context->CreateGlyphAtlasContext(GlyphAtlas::Type::kAlphaBitmap);
  std::shared_ptr<HostBuffer> host_buffer = HostBuffer::Create(
      GetContext()->GetResourceAllocator(), GetContext()->GetIdleWaiter());
  ASSERT_TRUE(context && context->IsValid());
  std::shared_ptr<GlyphAtlas> atlas =
      CreateGlyphAtlas(*GetContext(), context.get(), *host_buffer,
<<<<<<< HEAD
                       GlyphAtlas::Type::kAlphaBitmap, /*scale=*/1.0f,
                       atlas_context, text_frame);

  ISize texture_size = atlas->GetTexture()->GetSize();
  TextContents::ComputeVertexData(data, text_frame, /*scale=*/1.0,
=======
                       GlyphAtlas::Type::kAlphaBitmap, /*scale=*/Rational(1, 1),
                       atlas_context, text_frame, /*offset=*/{0, 0});

  ISize texture_size = atlas->GetTexture()->GetSize();
  TextContents::ComputeVertexData(data.data(), text_frame, /*scale=*/1.0,
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
                                  /*entity_transform=*/Matrix(),
                                  /*offset=*/Vector2(0, 0),
                                  /*glyph_properties=*/std::nullopt, atlas);

<<<<<<< HEAD
  Rect position_rect = PerVertexDataPositionToRect(data);
  Rect uv_rect = PerVertexDataUVToRect(data, texture_size);
=======
  Rect position_rect = PerVertexDataPositionToRect(data.begin());
  Rect uv_rect = PerVertexDataUVToRect(data.begin(), texture_size);
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
  // The -1 offset comes from Skia in `ComputeGlyphSize`. So since the font size
  // is 50, the math appears to be to get back a 50x50 rect and apply 1 pixel
  // of padding.
  EXPECT_RECT_NEAR(position_rect, Rect::MakeXYWH(-1, -41, 52, 52));
  EXPECT_RECT_NEAR(uv_rect, Rect::MakeXYWH(1.0, 1.0, 52, 52));
}

TEST_P(TextContentsTest, SimpleComputeVertexData2x) {
#ifndef FML_OS_MACOSX
  GTEST_SKIP() << "Results aren't stable across linux and macos.";
#endif

<<<<<<< HEAD
  GlyphAtlasPipeline::VertexShader::PerVertexData data[6];

  std::shared_ptr<TextFrame> text_frame =
      MakeTextFrame("1", "ahem.ttf", /*font_size=*/50);
=======
  std::vector<GlyphAtlasPipeline::VertexShader::PerVertexData> data(4);
  std::shared_ptr<TextFrame> text_frame =
      MakeTextFrame("1", "ahem.ttf", TextOptions{.font_size = 50});
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8

  std::shared_ptr<TypographerContext> context = TypographerContextSkia::Make();
  std::shared_ptr<GlyphAtlasContext> atlas_context =
      context->CreateGlyphAtlasContext(GlyphAtlas::Type::kAlphaBitmap);
  std::shared_ptr<HostBuffer> host_buffer = HostBuffer::Create(
      GetContext()->GetResourceAllocator(), GetContext()->GetIdleWaiter());
  ASSERT_TRUE(context && context->IsValid());
<<<<<<< HEAD
  Scalar font_scale = 2.f;
  std::shared_ptr<GlyphAtlas> atlas = CreateGlyphAtlas(
      *GetContext(), context.get(), *host_buffer,
      GlyphAtlas::Type::kAlphaBitmap, font_scale, atlas_context, text_frame);

  ISize texture_size = atlas->GetTexture()->GetSize();
  TextContents::ComputeVertexData(
      data, text_frame, font_scale,
      /*entity_transform=*/Matrix::MakeScale({font_scale, font_scale, 1}),
      /*offset=*/Vector2(0, 0),
      /*glyph_properties=*/std::nullopt, atlas);

  Rect position_rect = PerVertexDataPositionToRect(data);
  Rect uv_rect = PerVertexDataUVToRect(data, texture_size);
=======
  Rational font_scale(2, 1);
  std::shared_ptr<GlyphAtlas> atlas =
      CreateGlyphAtlas(*GetContext(), context.get(), *host_buffer,
                       GlyphAtlas::Type::kAlphaBitmap, font_scale,
                       atlas_context, text_frame, /*offset=*/{0, 0});

  ISize texture_size = atlas->GetTexture()->GetSize();
  TextContents::ComputeVertexData(
      data.data(), text_frame, static_cast<Scalar>(font_scale),
      /*entity_transform=*/
      Matrix::MakeScale({static_cast<Scalar>(font_scale),
                         static_cast<Scalar>(font_scale), 1}),
      /*offset=*/Vector2(0, 0),
      /*glyph_properties=*/std::nullopt, atlas);

  Rect position_rect = PerVertexDataPositionToRect(data.begin());
  Rect uv_rect = PerVertexDataUVToRect(data.begin(), texture_size);
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
  EXPECT_RECT_NEAR(position_rect, Rect::MakeXYWH(-1, -81, 102, 102));
  EXPECT_RECT_NEAR(uv_rect, Rect::MakeXYWH(1.0, 1.0, 102, 102));
}

TEST_P(TextContentsTest, MaintainsShape) {
  std::shared_ptr<TextFrame> text_frame =
<<<<<<< HEAD
      MakeTextFrame("th", "ahem.ttf", /*font_size=*/50);
=======
      MakeTextFrame("th", "ahem.ttf", TextOptions{.font_size = 50});
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8

  std::shared_ptr<TypographerContext> context = TypographerContextSkia::Make();
  std::shared_ptr<GlyphAtlasContext> atlas_context =
      context->CreateGlyphAtlasContext(GlyphAtlas::Type::kAlphaBitmap);
  std::shared_ptr<HostBuffer> host_buffer = HostBuffer::Create(
      GetContext()->GetResourceAllocator(), GetContext()->GetIdleWaiter());
  ASSERT_TRUE(context && context->IsValid());

  for (int i = 0; i <= 1000; ++i) {
<<<<<<< HEAD
    Scalar font_scale = 0.440 + (i / 1000.0);
=======
    Rational font_scale(440 + i, 1000.0);
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
    Rect position_rect[2];
    Rect uv_rect[2];

    {
<<<<<<< HEAD
      GlyphAtlasPipeline::VertexShader::PerVertexData data[12];
      std::shared_ptr<GlyphAtlas> atlas =
          CreateGlyphAtlas(*GetContext(), context.get(), *host_buffer,
                           GlyphAtlas::Type::kAlphaBitmap, font_scale,
                           atlas_context, text_frame);
      ISize texture_size = atlas->GetTexture()->GetSize();

      TextContents::ComputeVertexData(
          data, text_frame, font_scale,
          /*entity_transform=*/Matrix::MakeScale({font_scale, font_scale, 1}),
          /*offset=*/Vector2(0, 0),
          /*glyph_properties=*/std::nullopt, atlas);
      position_rect[0] = PerVertexDataPositionToRect(data);
      uv_rect[0] = PerVertexDataUVToRect(data, texture_size);
      position_rect[1] = PerVertexDataPositionToRect(data + 6);
      uv_rect[1] = PerVertexDataUVToRect(data + 6, texture_size);
=======
      std::vector<GlyphAtlasPipeline::VertexShader::PerVertexData> data(12);

      std::shared_ptr<GlyphAtlas> atlas =
          CreateGlyphAtlas(*GetContext(), context.get(), *host_buffer,
                           GlyphAtlas::Type::kAlphaBitmap, font_scale,
                           atlas_context, text_frame, /*offset=*/{0, 0});
      ISize texture_size = atlas->GetTexture()->GetSize();

      TextContents::ComputeVertexData(
          data.data(), text_frame, static_cast<Scalar>(font_scale),
          /*entity_transform=*/
          Matrix::MakeScale({static_cast<Scalar>(font_scale),
                             static_cast<Scalar>(font_scale), 1}),
          /*offset=*/Vector2(0, 0),
          /*glyph_properties=*/std::nullopt, atlas);
      position_rect[0] = PerVertexDataPositionToRect(data.begin());
      uv_rect[0] = PerVertexDataUVToRect(data.begin(), texture_size);
      position_rect[1] = PerVertexDataPositionToRect(data.begin() + 4);
      uv_rect[1] = PerVertexDataUVToRect(data.begin() + 4, texture_size);
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
    }
    EXPECT_NEAR(GetAspectRatio(position_rect[1]), GetAspectRatio(uv_rect[1]),
                0.001)
        << i;
  }
}

<<<<<<< HEAD
=======
TEST_P(TextContentsTest, SimpleSubpixel) {
#ifndef FML_OS_MACOSX
  GTEST_SKIP() << "Results aren't stable across linux and macos.";
#endif

  std::vector<GlyphAtlasPipeline::VertexShader::PerVertexData> data(4);

  std::shared_ptr<TextFrame> text_frame = MakeTextFrame(
      "1", "ahem.ttf", TextOptions{.font_size = 50, .is_subpixel = true});

  std::shared_ptr<TypographerContext> context = TypographerContextSkia::Make();
  std::shared_ptr<GlyphAtlasContext> atlas_context =
      context->CreateGlyphAtlasContext(GlyphAtlas::Type::kAlphaBitmap);
  std::shared_ptr<HostBuffer> host_buffer = HostBuffer::Create(
      GetContext()->GetResourceAllocator(), GetContext()->GetIdleWaiter());
  ASSERT_TRUE(context && context->IsValid());
  Point offset = Point(0.5, 0);
  std::shared_ptr<GlyphAtlas> atlas =
      CreateGlyphAtlas(*GetContext(), context.get(), *host_buffer,
                       GlyphAtlas::Type::kAlphaBitmap, /*scale=*/Rational(1),
                       atlas_context, text_frame, offset);

  ISize texture_size = atlas->GetTexture()->GetSize();
  TextContents::ComputeVertexData(
      data.data(), text_frame, /*scale=*/1.0,
      /*entity_transform=*/Matrix::MakeTranslation(offset), offset,
      /*glyph_properties=*/std::nullopt, atlas);

  Rect position_rect = PerVertexDataPositionToRect(data.begin());
  Rect uv_rect = PerVertexDataUVToRect(data.begin(), texture_size);
  // The values at Point(0, 0).
  // EXPECT_RECT_NEAR(position_rect, Rect::MakeXYWH(-1, -41, 52, 52));
  // EXPECT_RECT_NEAR(uv_rect, Rect::MakeXYWH(1.0, 1.0, 52, 52));
  EXPECT_RECT_NEAR(position_rect, Rect::MakeXYWH(-2, -41, 54, 52));
  EXPECT_RECT_NEAR(uv_rect, Rect::MakeXYWH(1.0, 1.0, 54, 52));
}

TEST_P(TextContentsTest, SimpleSubpixel3x) {
#ifndef FML_OS_MACOSX
  GTEST_SKIP() << "Results aren't stable across linux and macos.";
#endif

  std::vector<GlyphAtlasPipeline::VertexShader::PerVertexData> data(4);

  std::shared_ptr<TextFrame> text_frame = MakeTextFrame(
      "1", "ahem.ttf", TextOptions{.font_size = 50, .is_subpixel = true});

  std::shared_ptr<TypographerContext> context = TypographerContextSkia::Make();
  std::shared_ptr<GlyphAtlasContext> atlas_context =
      context->CreateGlyphAtlasContext(GlyphAtlas::Type::kAlphaBitmap);
  std::shared_ptr<HostBuffer> host_buffer = HostBuffer::Create(
      GetContext()->GetResourceAllocator(), GetContext()->GetIdleWaiter());
  ASSERT_TRUE(context && context->IsValid());
  Rational font_scale(3, 1);
  Point offset = {0.16667, 0};
  std::shared_ptr<GlyphAtlas> atlas =
      CreateGlyphAtlas(*GetContext(), context.get(), *host_buffer,
                       GlyphAtlas::Type::kAlphaBitmap, font_scale,
                       atlas_context, text_frame, offset);

  ISize texture_size = atlas->GetTexture()->GetSize();
  TextContents::ComputeVertexData(
      data.data(), text_frame, static_cast<Scalar>(font_scale),
      /*entity_transform=*/
      Matrix::MakeTranslation(offset) *
          Matrix::MakeScale({static_cast<Scalar>(font_scale),
                             static_cast<Scalar>(font_scale), 1}),
      offset,
      /*glyph_properties=*/std::nullopt, atlas);

  Rect position_rect = PerVertexDataPositionToRect(data.begin());
  Rect uv_rect = PerVertexDataUVToRect(data.begin(), texture_size);
  // Values at Point(0, 0)
  // EXPECT_RECT_NEAR(position_rect, Rect::MakeXYWH(-1, -121, 152, 152));
  // EXPECT_RECT_NEAR(uv_rect, Rect::MakeXYWH(1.0, 1.0, 152, 152));
  EXPECT_RECT_NEAR(position_rect, Rect::MakeXYWH(-2, -121, 154, 152))
      << "position size:" << position_rect.GetSize();
  EXPECT_RECT_NEAR(uv_rect, Rect::MakeXYWH(1.0, 1.0, 154, 152))
      << "position size:" << position_rect.GetSize();
}

TEST_P(TextContentsTest, SimpleSubpixel26) {
#ifndef FML_OS_MACOSX
  GTEST_SKIP() << "Results aren't stable across linux and macos.";
#endif

  std::vector<GlyphAtlasPipeline::VertexShader::PerVertexData> data(4);

  std::shared_ptr<TextFrame> text_frame = MakeTextFrame(
      "1", "ahem.ttf", TextOptions{.font_size = 50, .is_subpixel = true});

  std::shared_ptr<TypographerContext> context = TypographerContextSkia::Make();
  std::shared_ptr<GlyphAtlasContext> atlas_context =
      context->CreateGlyphAtlasContext(GlyphAtlas::Type::kAlphaBitmap);
  std::shared_ptr<HostBuffer> host_buffer = HostBuffer::Create(
      GetContext()->GetResourceAllocator(), GetContext()->GetIdleWaiter());
  ASSERT_TRUE(context && context->IsValid());
  Point offset = Point(0.26, 0);
  std::shared_ptr<GlyphAtlas> atlas =
      CreateGlyphAtlas(*GetContext(), context.get(), *host_buffer,
                       GlyphAtlas::Type::kAlphaBitmap, /*scale=*/Rational(1),
                       atlas_context, text_frame, offset);

  ISize texture_size = atlas->GetTexture()->GetSize();
  TextContents::ComputeVertexData(
      data.data(), text_frame, /*scale=*/1.0,
      /*entity_transform=*/Matrix::MakeTranslation(offset), offset,
      /*glyph_properties=*/std::nullopt, atlas);

  Rect position_rect = PerVertexDataPositionToRect(data.begin());
  Rect uv_rect = PerVertexDataUVToRect(data.begin(), texture_size);
  // The values without subpixel.
  // EXPECT_RECT_NEAR(position_rect, Rect::MakeXYWH(-1, -41, 52, 52));
  // EXPECT_RECT_NEAR(uv_rect, Rect::MakeXYWH(1.0, 1.0, 52, 52));
  EXPECT_RECT_NEAR(position_rect, Rect::MakeXYWH(-2, -41, 54, 52));
  EXPECT_RECT_NEAR(uv_rect, Rect::MakeXYWH(1.0, 1.0, 54, 52));
}

TEST_P(TextContentsTest, SimpleSubpixel80) {
#ifndef FML_OS_MACOSX
  GTEST_SKIP() << "Results aren't stable across linux and macos.";
#endif

  std::vector<GlyphAtlasPipeline::VertexShader::PerVertexData> data(4);

  std::shared_ptr<TextFrame> text_frame = MakeTextFrame(
      "1", "ahem.ttf", TextOptions{.font_size = 50, .is_subpixel = true});

  std::shared_ptr<TypographerContext> context = TypographerContextSkia::Make();
  std::shared_ptr<GlyphAtlasContext> atlas_context =
      context->CreateGlyphAtlasContext(GlyphAtlas::Type::kAlphaBitmap);
  std::shared_ptr<HostBuffer> host_buffer = HostBuffer::Create(
      GetContext()->GetResourceAllocator(), GetContext()->GetIdleWaiter());
  ASSERT_TRUE(context && context->IsValid());
  Point offset = Point(0.80, 0);
  std::shared_ptr<GlyphAtlas> atlas =
      CreateGlyphAtlas(*GetContext(), context.get(), *host_buffer,
                       GlyphAtlas::Type::kAlphaBitmap, /*scale=*/Rational(1),
                       atlas_context, text_frame, offset);

  ISize texture_size = atlas->GetTexture()->GetSize();
  TextContents::ComputeVertexData(
      data.data(), text_frame, /*scale=*/1.0,
      /*entity_transform=*/Matrix::MakeTranslation(offset), offset,
      /*glyph_properties=*/std::nullopt, atlas);

  Rect position_rect = PerVertexDataPositionToRect(data.begin());
  Rect uv_rect = PerVertexDataUVToRect(data.begin(), texture_size);
  // The values without subpixel.
  // EXPECT_RECT_NEAR(position_rect, Rect::MakeXYWH(-1, -41, 52, 52));
  // EXPECT_RECT_NEAR(uv_rect, Rect::MakeXYWH(1.0, 1.0, 52, 52));
  EXPECT_RECT_NEAR(position_rect, Rect::MakeXYWH(-2, -41, 54, 52));
  EXPECT_RECT_NEAR(uv_rect, Rect::MakeXYWH(1.0, 1.0, 54, 52));
}

>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
}  // namespace testing
}  // namespace impeller
