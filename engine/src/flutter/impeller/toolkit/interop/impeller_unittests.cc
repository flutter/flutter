// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/native_library.h"
#include "flutter/fml/string_conversion.h"
#include "flutter/testing/testing.h"
#include "impeller/base/allocation.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/toolkit/interop/context.h"
#include "impeller/toolkit/interop/dl.h"
#include "impeller/toolkit/interop/dl_builder.h"
#include "impeller/toolkit/interop/formats.h"
#include "impeller/toolkit/interop/impeller.h"
#include "impeller/toolkit/interop/impeller.hpp"
#include "impeller/toolkit/interop/paint.h"
#include "impeller/toolkit/interop/paragraph.h"
#include "impeller/toolkit/interop/paragraph_builder.h"
#include "impeller/toolkit/interop/paragraph_style.h"
#include "impeller/toolkit/interop/playground_test.h"
#include "impeller/toolkit/interop/surface.h"
#include "impeller/toolkit/interop/texture.h"
#include "impeller/toolkit/interop/typography_context.h"

namespace impeller::interop::testing {

using InteropPlaygroundTest = PlaygroundTest;
INSTANTIATE_PLAYGROUND_SUITE(InteropPlaygroundTest);

// Just ensures that context can be subclassed.
class ContextSub : public hpp::Context {};

TEST_P(InteropPlaygroundTest, CanCreateContext) {
  auto context = CreateContext();
  ASSERT_TRUE(context);
}

TEST_P(InteropPlaygroundTest, CanCreateDisplayListBuilder) {
  hpp::DisplayListBuilder builder;
  ASSERT_TRUE(builder);
  ASSERT_TRUE(ToImpellerType(builder.GetTransform()).IsIdentity());
  ASSERT_EQ(builder.GetSaveCount(), 1u);
  builder.Save();
  ASSERT_EQ(builder.GetSaveCount(), 2u);
  builder.Restore();
  ASSERT_EQ(builder.GetSaveCount(), 1u);
}

TEST_P(InteropPlaygroundTest, CanCreateSurface) {
  if (GetBackend() != PlaygroundBackend::kOpenGLES) {
    GTEST_SKIP()
        << "This test checks wrapping FBOs which is an OpenGL ES only call.";
    return;
  }
  auto context = CreateContext();
  ASSERT_TRUE(context);
  const auto window_size = GetWindowSize();
  ImpellerISize size = {window_size.width, window_size.height};
  auto surface = Adopt<Surface>(ImpellerSurfaceCreateWrappedFBONew(
      context.GetC(),                                     //
      0u,                                                 //
      ImpellerPixelFormat::kImpellerPixelFormatRGBA8888,  //
      &size)                                              //
  );
  ASSERT_TRUE(surface);
}

TEST_P(InteropPlaygroundTest, CanDrawRect) {
  auto builder =
      Adopt<DisplayListBuilder>(ImpellerDisplayListBuilderNew(nullptr));
  auto paint = Adopt<Paint>(ImpellerPaintNew());
  ImpellerColor color = {0.0, 0.0, 1.0, 1.0};
  ImpellerPaintSetColor(paint.GetC(), &color);
  ImpellerRect rect = {10, 20, 100, 200};
  ImpellerDisplayListBuilderDrawRect(builder.GetC(), &rect, paint.GetC());
  color = {1.0, 0.0, 0.0, 1.0};
  ImpellerPaintSetColor(paint.GetC(), &color);
  ImpellerDisplayListBuilderTranslate(builder.GetC(), 110, 210);
  ImpellerMatrix scale_transform = {
      // clang-format off
      2.0, 0.0, 0.0, 0.0, //
      0.0, 2.0, 0.0, 0.0, //
      0.0, 0.0, 1.0, 0.0, //
      0.0, 0.0, 0.0, 1.0, //
      // clang-format on
  };
  ImpellerDisplayListBuilderTransform(builder.GetC(), &scale_transform);
  ImpellerDisplayListBuilderDrawRect(builder.GetC(), &rect, paint.GetC());
  auto dl = Adopt<DisplayList>(
      ImpellerDisplayListBuilderCreateDisplayListNew(builder.GetC()));
  ASSERT_TRUE(dl);
  ASSERT_TRUE(
      OpenPlaygroundHere([&](const auto& context, const auto& surface) -> bool {
        ImpellerSurfaceDrawDisplayList(surface.GetC(), dl.GetC());
        return true;
      }));
}

TEST_P(InteropPlaygroundTest, CanDrawImage) {
  auto compressed = LoadFixtureImageCompressed(
      flutter::testing::OpenFixtureAsMapping("boston.jpg"));
  ASSERT_NE(compressed, nullptr);
  auto decompressed = std::make_shared<impeller::DecompressedImage>(
      compressed->Decode().ConvertToRGBA());
  ASSERT_TRUE(decompressed->IsValid());
  auto mapping = std::make_unique<hpp::Mapping>(
      decompressed->GetAllocation()->GetMapping(),
      decompressed->GetAllocation()->GetSize(), [decompressed]() {
        // Mapping will be dropped on the floor.
      });

  auto context = GetHPPContext();
  ImpellerTextureDescriptor desc = {};
  desc.pixel_format = ImpellerPixelFormat::kImpellerPixelFormatRGBA8888;
  desc.size = {decompressed->GetSize().width, decompressed->GetSize().height};
  desc.mip_count = 1u;
  auto texture = hpp::Texture::WithContents(context, desc, std::move(mapping));
  ASSERT_TRUE(texture);

  auto dl = hpp::DisplayListBuilder{}
                .DrawTexture(texture, {100, 100},
                             kImpellerTextureSamplingLinear, hpp::Paint{})
                .Build();

  ASSERT_TRUE(
      OpenPlaygroundHere([&](const auto& context, const auto& surface) -> bool {
        hpp::Surface window(surface.GetC());
        window.Draw(dl);
        return true;
      }));
}

TEST_P(InteropPlaygroundTest, CanCreateOpenGLImage) {
  auto context = GetInteropContext();

  auto impeller_context = context->GetContext();

  if (impeller_context->GetBackendType() !=
      impeller::Context::BackendType::kOpenGLES) {
    GTEST_SKIP() << "This test works with OpenGL handles is only suitable for "
                    "that backend.";
    return;
  }

  const auto& gl_context = ContextGLES::Cast(*impeller_context);
  const auto& gl = gl_context.GetReactor()->GetProcTable();

  constexpr ISize external_texture_size = {200, 300};

  Allocation texture_data;
  ASSERT_TRUE(
      texture_data.Truncate(Bytes{external_texture_size.Area() * 4u}, false));

  const auto kClearColor = Color::Fuchsia().ToR8G8B8A8();

  for (size_t i = 0; i < external_texture_size.Area() * 4u; i += 4u) {
    memcpy(texture_data.GetBuffer() + i, kClearColor.data(), 4);
  }

  GLuint external_texture = GL_NONE;
  gl.GenTextures(1u, &external_texture);
  ASSERT_NE(external_texture, 0u);
  gl.BindTexture(GL_TEXTURE_2D, external_texture);
  gl.TexImage2D(GL_TEXTURE_2D,                 //
                0,                             //
                GL_RGBA,                       //
                external_texture_size.width,   //
                external_texture_size.height,  //
                0,                             //
                GL_RGBA,                       //
                GL_UNSIGNED_BYTE,              //
                texture_data.GetBuffer()       //
  );

  ImpellerTextureDescriptor desc = {};
  desc.pixel_format = ImpellerPixelFormat::kImpellerPixelFormatRGBA8888;
  desc.size = {external_texture_size.width, external_texture_size.height};
  desc.mip_count = 1u;
  auto texture = Adopt<Texture>(ImpellerTextureCreateWithOpenGLTextureHandleNew(
      context.GetC(),   //
      &desc,            //
      external_texture  //
      ));
  ASSERT_TRUE(texture);

  ASSERT_EQ(ImpellerTextureGetOpenGLHandle(texture.GetC()), external_texture);

  auto builder =
      Adopt<DisplayListBuilder>(ImpellerDisplayListBuilderNew(nullptr));
  ImpellerPoint point = {100, 100};
  ImpellerDisplayListBuilderDrawTexture(builder.GetC(), texture.GetC(), &point,
                                        kImpellerTextureSamplingLinear,
                                        nullptr);
  auto dl = Adopt<DisplayList>(
      ImpellerDisplayListBuilderCreateDisplayListNew(builder.GetC()));
  ASSERT_TRUE(
      OpenPlaygroundHere([&](const auto& context, const auto& surface) -> bool {
        ImpellerSurfaceDrawDisplayList(surface.GetC(), dl.GetC());
        return true;
      }));
}

TEST_P(InteropPlaygroundTest, ClearsOpenGLStancilStateAfterTransition) {
  auto context = GetInteropContext();
  auto impeller_context = context->GetContext();
  if (impeller_context->GetBackendType() !=
      impeller::Context::BackendType::kOpenGLES) {
    GTEST_SKIP() << "This test works with OpenGL handles is only suitable for "
                    "that backend.";
    return;
  }
  const auto& gl_context = ContextGLES::Cast(*impeller_context);
  const auto& gl = gl_context.GetReactor()->GetProcTable();
  auto builder =
      Adopt<DisplayListBuilder>(ImpellerDisplayListBuilderNew(nullptr));
  auto paint = Adopt<Paint>(ImpellerPaintNew());
  ImpellerColor color = {0.0, 0.0, 1.0, 1.0};
  ImpellerPaintSetColor(paint.GetC(), &color);
  ImpellerRect rect = {10, 20, 100, 200};
  ImpellerDisplayListBuilderDrawRect(builder.GetC(), &rect, paint.GetC());
  color = {1.0, 0.0, 0.0, 1.0};
  ImpellerPaintSetColor(paint.GetC(), &color);
  ImpellerDisplayListBuilderTranslate(builder.GetC(), 110, 210);
  ImpellerDisplayListBuilderClipRect(builder.GetC(), &rect,
                                     kImpellerClipOperationDifference);
  ImpellerDisplayListBuilderDrawRect(builder.GetC(), &rect, paint.GetC());
  auto dl = Adopt<DisplayList>(
      ImpellerDisplayListBuilderCreateDisplayListNew(builder.GetC()));
  ASSERT_TRUE(dl);
  ASSERT_TRUE(
      OpenPlaygroundHere([&](const auto& context, const auto& surface) -> bool {
        ImpellerSurfaceDrawDisplayList(surface.GetC(), dl.GetC());
        // OpenGL state is reset even though the operations above enable a
        // stencil check.
        GLboolean stencil_enabled = true;
        gl.GetBooleanv(GL_STENCIL_TEST, &stencil_enabled);
        return stencil_enabled == GL_FALSE;
      }));
}

TEST_P(InteropPlaygroundTest, CanCreateParagraphs) {
  // Create a typography context.
  hpp::TypographyContext type_context;
  ASSERT_TRUE(type_context);

  // Create a builder.
  hpp::ParagraphBuilder builder(type_context);
  ASSERT_TRUE(builder);

  // Create a paragraph style with the font size and foreground and background
  // colors.
  hpp::ParagraphStyle style;
  ASSERT_TRUE(style);
  style.SetFontSize(150.0f);
  style.SetHeight(2.0f);

  {
    hpp::Paint paint;
    ASSERT_TRUE(paint);
    paint.SetColor({1.0, 0.0, 0.0, 1.0});
    style.SetForeground(paint);
  }

  {
    hpp::Paint paint;
    paint.SetColor({1.0, 1.0, 1.0, 1.0});
    style.SetBackground(paint);
  }

  // Push the style onto the style stack.
  builder.PushStyle(style);
  std::string text = "the ⚡️ quick ⚡️ brown 🦊 fox jumps over the lazy dog 🐶.";

  // Add the paragraph text data.
  builder.AddText(text);

  // Layout and build the paragraph.
  auto paragraph = builder.Build(1200.0f);
  ASSERT_TRUE(paragraph);

  // Create a display list with just the paragraph drawn into it.
  hpp::DisplayListBuilder dl_builder;
  dl_builder.DrawParagraph(paragraph, {20, 20});

  // Build the display list.
  auto dl = dl_builder.Build();

  ASSERT_TRUE(
      OpenPlaygroundHere([&](const auto& context, const auto& surface) -> bool {
        hpp::Surface window(surface.GetC());
        window.Draw(dl);
        return true;
      }));
}

TEST_P(InteropPlaygroundTest, CanCreateDecorations) {
  hpp::TypographyContext context;
  auto para =
      hpp::ParagraphBuilder(context)
          .PushStyle(
              hpp::ParagraphStyle{}
                  .SetForeground(hpp::Paint{}.SetColor({1.0, 0.0, 0.0, 1.0}))
                  .SetFontSize(150.0f)
                  .SetTextDecoration(ImpellerTextDecoration{
                      .types = kImpellerTextDecorationTypeLineThrough |
                               kImpellerTextDecorationTypeUnderline,
                      .color = ImpellerColor{0.0, 1.0, 0.0, 0.75},
                      .style = kImpellerTextDecorationStyleWavy,
                      .thickness_multiplier = 1.5,
                  }))
          .AddText(std::string{"Holy text decorations Batman!"})
          .Build(900);
  auto dl = hpp::DisplayListBuilder{}.DrawParagraph(para, {100, 100}).Build();
  ASSERT_TRUE(
      OpenPlaygroundHere([&](const auto& context, const auto& surface) -> bool {
        hpp::Surface window(surface.GetC());
        window.Draw(dl);
        return true;
      }));
}

TEST_P(InteropPlaygroundTest, CanCreateShapes) {
  hpp::DisplayListBuilder builder;

  hpp::Paint red_paint;
  red_paint.SetColor({1.0, 0.0, 0.0, 1.0});
  red_paint.SetStrokeWidth(10.0);

  builder.Translate(10, 10);
  builder.DrawRect({0, 0, 100, 100}, red_paint);
  builder.Translate(100, 100);
  builder.DrawOval({0, 0, 100, 100}, red_paint);
  builder.Translate(100, 100);
  builder.DrawLine({0, 0}, {100, 100}, red_paint);

  builder.Translate(100, 100);
  ImpellerRoundingRadii radii = {};
  radii.top_left = {10, 10};
  radii.bottom_right = {10, 10};
  builder.DrawRoundedRect({0, 0, 100, 100}, radii, red_paint);

  builder.Translate(100, 100);
  builder.DrawPath(hpp::PathBuilder{}.AddOval({0, 0, 100, 100}).Build(),
                   red_paint);

  auto dl = builder.Build();
  ASSERT_TRUE(
      OpenPlaygroundHere([&](const auto& context, const auto& surface) -> bool {
        hpp::Surface window(surface.GetC());
        window.Draw(dl);
        return true;
      }));
}

TEST_P(InteropPlaygroundTest, CanCreateParagraphsWithCustomFont) {
  // Create a typography context.
  auto type_context = Adopt<TypographyContext>(ImpellerTypographyContextNew());
  ASSERT_TRUE(type_context);

  // Open the custom font file.
  std::unique_ptr<fml::Mapping> font_data =
      flutter::testing::OpenFixtureAsMapping("wtf.otf");
  ASSERT_NE(font_data, nullptr);
  ASSERT_GT(font_data->GetSize(), 0u);
  ImpellerMapping font_data_mapping = {
      .data = font_data->GetMapping(),
      .length = font_data->GetSize(),
      .on_release = [](auto ctx) {
        delete reinterpret_cast<fml::Mapping*>(ctx);
      }};
  auto registered =
      ImpellerTypographyContextRegisterFont(type_context.GetC(),  //
                                            &font_data_mapping,   //
                                            font_data.release(),  //
                                            nullptr               //
      );
  ASSERT_TRUE(registered);

  // Create a builder.
  auto builder =
      Adopt<ParagraphBuilder>(ImpellerParagraphBuilderNew(type_context.GetC()));
  ASSERT_TRUE(builder);

  // Create a paragraph style with the font size and foreground and background
  // colors.
  auto style = Adopt<ParagraphStyle>(ImpellerParagraphStyleNew());
  ASSERT_TRUE(style);
  ImpellerParagraphStyleSetFontSize(style.GetC(), 150.0f);
  ImpellerParagraphStyleSetFontFamily(style.GetC(), "WhatTheFlutter");

  {
    auto paint = Adopt<Paint>(ImpellerPaintNew());
    ASSERT_TRUE(paint);
    ImpellerColor color = {0.0, 1.0, 1.0, 1.0};
    ImpellerPaintSetColor(paint.GetC(), &color);
    ImpellerParagraphStyleSetForeground(style.GetC(), paint.GetC());
  }

  // Push the style onto the style stack.
  ImpellerParagraphBuilderPushStyle(builder.GetC(), style.GetC());
  std::string text = "0F0F0F0";

  // Add the paragraph text data.
  ImpellerParagraphBuilderAddText(builder.GetC(),
                                  reinterpret_cast<const uint8_t*>(text.data()),
                                  text.size());

  // Layout and build the paragraph.
  auto paragraph = Adopt<Paragraph>(
      ImpellerParagraphBuilderBuildParagraphNew(builder.GetC(), 1200.0f));
  ASSERT_TRUE(paragraph);

  // Create a display list with just the paragraph drawn into it.
  auto dl_builder =
      Adopt<DisplayListBuilder>(ImpellerDisplayListBuilderNew(nullptr));
  ImpellerPoint point = {20, 20};
  ImpellerDisplayListBuilderDrawParagraph(dl_builder.GetC(), paragraph.GetC(),
                                          &point);
  auto dl = Adopt<DisplayList>(
      ImpellerDisplayListBuilderCreateDisplayListNew(dl_builder.GetC()));

  ASSERT_TRUE(
      OpenPlaygroundHere([&](const auto& context, const auto& surface) -> bool {
        ImpellerSurfaceDrawDisplayList(surface.GetC(), dl.GetC());
        return true;
      }));
}  // namespace impeller::interop::testing

static void DrawTextFrame(const hpp::TypographyContext& tc,
                          hpp::DisplayListBuilder& builder,
                          hpp::ParagraphStyle& p_style,
                          const hpp::Paint& bg,
                          ImpellerColor color,
                          ImpellerTextAlignment align,
                          float x_offset) {
  const char text[] =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit.";

  hpp::Paint fg;

  // Draw a box.
  fg.SetColor(color);
  fg.SetDrawStyle(kImpellerDrawStyleStroke);
  ImpellerRect box_rect = {10 + x_offset, 10, 200, 200};
  builder.DrawRect(box_rect, fg);

  // Draw text.
  fg.SetDrawStyle(kImpellerDrawStyleFill);
  p_style.SetForeground(fg);
  p_style.SetBackground(bg);
  p_style.SetTextAlignment(align);

  hpp::ParagraphBuilder p_builder(tc);
  p_builder.PushStyle(p_style);
  p_builder.AddText(reinterpret_cast<const uint8_t*>(text), sizeof(text));

  auto left_p = p_builder.Build(box_rect.width - 20.0);
  ImpellerPoint pt = {20.0f + x_offset, 20.0f};
  float w = left_p.GetMaxWidth();
  float h = left_p.GetHeight();
  builder.DrawParagraph(left_p, pt);
  fg.SetDrawStyle(kImpellerDrawStyleStroke);

  // Draw an inner box around the paragraph layout.
  ImpellerRect inner_box_rect = {pt.x, pt.y, w, h};
  builder.DrawRect(inner_box_rect, fg);
}

TEST_P(InteropPlaygroundTest, CanRenderTextAlignments) {
  hpp::TypographyContext tc;

  hpp::DisplayListBuilder builder;
  hpp::Paint bg;
  hpp::ParagraphStyle p_style;
  p_style.SetFontFamily("Roboto");
  p_style.SetFontSize(24.0);
  p_style.SetFontWeight(kImpellerFontWeight400);

  // Clear the background to a white color.
  ImpellerColor clear_color = {1.0, 1.0, 1.0, 1.0};
  bg.SetColor(clear_color);
  builder.DrawPaint(bg);

  // Draw red, left-aligned text.
  ImpellerColor red = {1.0, 0.0, 0.0, 1.0};
  DrawTextFrame(tc, builder, p_style, bg, red, kImpellerTextAlignmentLeft, 0.0);

  // Draw green, centered text.
  ImpellerColor green = {0.0, 1.0, 0.0, 1.0};
  DrawTextFrame(tc, builder, p_style, bg, green, kImpellerTextAlignmentCenter,
                220.0);

  // Draw blue, right-aligned text.
  ImpellerColor blue = {0.0, 0.0, 1.0, 1.0};
  DrawTextFrame(tc, builder, p_style, bg, blue, kImpellerTextAlignmentRight,
                440.0);

  auto dl = builder.Build();

  ASSERT_TRUE(
      OpenPlaygroundHere([&](const auto& context, const auto& surface) -> bool {
        hpp::Surface window(surface.GetC());
        window.Draw(dl);
        return true;
      }));
}

TEST_P(InteropPlaygroundTest, CanRenderShadows) {
  hpp::DisplayListBuilder builder;
  {
    builder.DrawRect(ImpellerRect{0, 0, 400, 400},
                     hpp::Paint{}.SetColor(ImpellerColor{
                         0.0, 1.0, 0.0, 1.0, kImpellerColorSpaceSRGB}));
  }
  ImpellerRect box = {100, 100, 100, 100};
  {
    hpp::PathBuilder path_builder;
    path_builder.AddRect(box);
    ImpellerColor shadow_color = {0.0, 0.0, 0.0, 1.0, kImpellerColorSpaceSRGB};
    builder.DrawShadow(path_builder.Build(), shadow_color, 4.0f, false, 1.0f);
  }
  {
    hpp::Paint red_paint;
    red_paint.SetColor(
        ImpellerColor{1.0, 0.0, 0.0, 1.0, kImpellerColorSpaceSRGB});
    builder.DrawRect(box, red_paint);
  }
  auto dl = builder.Build();
  ASSERT_TRUE(
      OpenPlaygroundHere([&](const auto& context, const auto& surface) -> bool {
        hpp::Surface window(surface.GetC());
        window.Draw(dl);
        return true;
      }));
}

TEST_P(InteropPlaygroundTest, CanMeasureText) {
  hpp::TypographyContext type_context;
  hpp::ParagraphBuilder paragraph_builder(type_context);
  hpp::ParagraphStyle paragraph_style;
  paragraph_style.SetFontSize(50);
  paragraph_builder.PushStyle(paragraph_style);
  const std::string text =
      "🏁 Can 👨‍👨‍👦‍👦 Measure 🔍 Text\nAnd this is line "
      "two.\nWhoa! Three lines. How high does this go?\r\nI stopped counting.";
  const auto u16text = fml::Utf8ToUtf16(text);
  ASSERT_NE(text.size(), u16text.size());
  paragraph_builder.AddText(reinterpret_cast<const uint8_t*>(text.data()),
                            text.size());
  hpp::DisplayListBuilder builder;
  // Don't rely on implicit line breaks in this test to make it less brittle to
  // different fonts being picked.
  hpp::Paragraph paragraph = paragraph_builder.Build(FLT_MAX);
  const auto line_count = paragraph.GetLineCount();
  ASSERT_EQ(line_count, 4u);

  // Line Metrics.
  {
    auto metrics = paragraph.GetLineMetrics();
    ASSERT_GT(metrics.GetAscent(0), 0.0);
    ASSERT_GT(metrics.GetUnscaledAscent(0), 0.0);
    ASSERT_GT(metrics.GetDescent(0), 0.0);
    ASSERT_GT(metrics.GetBaseline(0), 0.0);
    ASSERT_TRUE(metrics.IsHardbreak(0));
    ASSERT_DOUBLE_EQ(metrics.GetLeft(0), 0.0);
    ASSERT_EQ(metrics.GetCodeUnitStartIndex(0), 0u);
    ASSERT_EQ(metrics.GetCodeUnitEndIndexIncludingNewline(0),
              metrics.GetCodeUnitEndIndex(0) + 1u);
    ASSERT_GT(metrics.GetCodeUnitStartIndex(1), 0u);
    // Last line should cover the entire range.
    ASSERT_EQ(metrics.GetCodeUnitEndIndex(3), u16text.size());
  }

  // Glyph info by code point.
  {
    auto glyph = paragraph.GlyphInfoAtCodeUnitIndex(0u);
    ASSERT_TRUE(glyph);
    ASSERT_EQ(glyph.GetGraphemeClusterCodeUnitRangeBegin(), 0u);
    ASSERT_EQ(glyph.GetGraphemeClusterCodeUnitRangeEnd(),
              fml::Utf8ToUtf16("🏁").size());
    auto bounds = glyph.GetGraphemeClusterBounds();
    ASSERT_GT(bounds.width, 0.0);
    ASSERT_GT(bounds.height, 0.0);
    ASSERT_FALSE(glyph.IsEllipsis());
    ASSERT_EQ(glyph.GetTextDirection(), kImpellerTextDirectionLTR);

    ImpellerRect bounds2 = {};
    ImpellerGlyphInfoGetGraphemeClusterBounds(glyph.Get(), &bounds2);
    ASSERT_EQ(bounds.width, bounds2.width);
    ASSERT_EQ(bounds.height, bounds2.height);
  }

  // Glyph info by coordinates.
  {
    auto glyph = paragraph.GlyphInfoAtParagraphCoordinates(0.0, 0.0);
    ASSERT_TRUE(glyph);
    ASSERT_EQ(glyph.GetGraphemeClusterCodeUnitRangeEnd(),
              fml::Utf8ToUtf16("🏁").size());
  }

  // Glyph Figure out word boundaries.
  {
    auto glyph = paragraph.GlyphInfoAtCodeUnitIndex(0u);
    ASSERT_TRUE(glyph);
    auto range =
        paragraph.GetWordBoundary(glyph.GetGraphemeClusterCodeUnitRangeEnd());
    ASSERT_GT(range.end, 0u);
    ImpellerRange range2 = {};
    ImpellerParagraphGetWordBoundary(
        paragraph.Get(), glyph.GetGraphemeClusterCodeUnitRangeEnd(), &range2);
    ASSERT_EQ(range.start, range2.start);
    ASSERT_EQ(range.end, range2.end);
  }

  builder.DrawParagraph(paragraph, ImpellerPoint{100, 100});
  auto dl = builder.Build();
  ASSERT_TRUE(
      OpenPlaygroundHere([&](const auto& context, const auto& surface) -> bool {
        hpp::Surface window(surface.GetC());
        window.Draw(dl);
        return true;
      }));
}

TEST_P(InteropPlaygroundTest, CanGetPathBounds) {
  const auto path =
      hpp::PathBuilder{}.MoveTo({100, 100}).LineTo({200, 200}).Build();
  const auto bounds = path.GetBounds();
  ASSERT_EQ(bounds.x, 100);
  ASSERT_EQ(bounds.y, 100);
  ASSERT_EQ(bounds.width, 100);
  ASSERT_EQ(bounds.height, 100);
}

TEST_P(InteropPlaygroundTest, CanControlEllipses) {
  hpp::TypographyContext context;
  auto style = hpp::ParagraphStyle{};
  style.SetFontSize(50);
  style.SetForeground(hpp::Paint{}.SetColor({.red = 1.0, .alpha = 1.0}));
  const auto text = std::string{"The quick brown fox jumped over the lazy dog"};
  style.SetEllipsis("🐶");
  auto para1 =
      hpp::ParagraphBuilder{context}.PushStyle(style).AddText(text).Build(250);
  style.SetForeground(hpp::Paint{}.SetColor({.green = 1.0, .alpha = 1.0}));
  style.SetEllipsis(nullptr);
  auto para2 =
      hpp::ParagraphBuilder{context}.PushStyle(style).AddText(text).Build(250);
  auto dl = hpp::DisplayListBuilder{}
                .DrawParagraph(para1, {100, 100})
                .DrawParagraph(para2, {100, 200})
                .Build();
  ASSERT_TRUE(
      OpenPlaygroundHere([&](const auto& context, const auto& surface) -> bool {
        hpp::Surface window(surface.GetC());
        window.Draw(dl);
        return true;
      }));
}

TEST_P(InteropPlaygroundTest, CanCreateFragmentProgramColorFilters) {
  auto iplr = OpenAssetAsHPPMapping("interop_runtime_stage_cs.frag.iplr");
  ASSERT_TRUE(!!iplr);
  auto program = hpp::FragmentProgram::WithData(std::move(iplr));
  ASSERT_TRUE(program);
  auto context = GetHPPContext();
  auto filter =
      hpp::ImageFilter::FragmentProgram(context, program, {}, nullptr);
  ASSERT_TRUE(filter);
  auto bay_bridge = OpenAssetAsHPPTexture("bay_bridge.jpg");
  ASSERT_TRUE(bay_bridge);

  float size_data[4] = {500, 500};
  auto uniform_data = hpp::Mapping{reinterpret_cast<const uint8_t*>(&size_data),
                                   sizeof(size_data), nullptr};

  auto dl = hpp::DisplayListBuilder{}
                .DrawRect({10, 10, 500, 500},
                          hpp::Paint{}
                              .SetColor({1.0, 1.0, 1.0, 1.0})
                              .SetColorSource(hpp::ColorSource::FragmentProgram(
                                  context,             //
                                  program,             //
                                  {bay_bridge.Get()},  // samplers
                                  &uniform_data        // uniform data
                                  )))
                .Build();
  ASSERT_TRUE(
      OpenPlaygroundHere([&](const auto& context, const auto& surface) -> bool {
        hpp::Surface window(surface.GetC());
        window.Draw(dl);
        return true;
      }));
}

TEST_P(InteropPlaygroundTest, MappingsReleaseTheirDataOnDestruction) {
  bool deleted = false;
  {
    hpp::Mapping mapping(nullptr, 0, [&deleted]() { deleted = true; });
  }
  ASSERT_TRUE(deleted);
}

}  // namespace impeller::interop::testing
