// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/toolkit/interop/context.h"
#include "impeller/toolkit/interop/dl.h"
#include "impeller/toolkit/interop/dl_builder.h"
#include "impeller/toolkit/interop/formats.h"
#include "impeller/toolkit/interop/impeller.h"
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
INSTANTIATE_OPENGLES_PLAYGROUND_SUITE(InteropPlaygroundTest);

TEST_P(InteropPlaygroundTest, CanCreateContext) {
  auto context = CreateContext();
  ASSERT_TRUE(context);
}

TEST_P(InteropPlaygroundTest, CanCreateDisplayListBuilder) {
  auto builder = ImpellerDisplayListBuilderNew(nullptr);
  ASSERT_NE(builder, nullptr);
  ImpellerMatrix matrix;
  ImpellerDisplayListBuilderGetTransform(builder, &matrix);
  ASSERT_TRUE(ToImpellerType(matrix).IsIdentity());
  ASSERT_EQ(ImpellerDisplayListBuilderGetSaveCount(builder), 1u);
  ImpellerDisplayListBuilderSave(builder);
  ASSERT_EQ(ImpellerDisplayListBuilderGetSaveCount(builder), 2u);
  // ImpellerDisplayListBuilderSave(nullptr); <-- Compiler error.
  ImpellerDisplayListBuilderRestore(builder);
  ASSERT_EQ(ImpellerDisplayListBuilderGetSaveCount(builder), 1u);
  ImpellerDisplayListBuilderRelease(builder);
}

TEST_P(InteropPlaygroundTest, CanCreateSurface) {
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
  auto decompressed = compressed->Decode().ConvertToRGBA();
  ASSERT_TRUE(decompressed.IsValid());
  ImpellerMapping mapping = {};
  mapping.data = decompressed.GetAllocation()->GetMapping();
  mapping.length = decompressed.GetAllocation()->GetSize();

  auto context = GetInteropContext();
  ImpellerTextureDescriptor desc = {};
  desc.pixel_format = ImpellerPixelFormat::kImpellerPixelFormatRGBA8888;
  desc.size = {decompressed.GetSize().width, decompressed.GetSize().height};
  desc.mip_count = 1u;
  auto texture = Adopt<Texture>(ImpellerTextureCreateWithContentsNew(
      context.GetC(), &desc, &mapping, nullptr));
  ASSERT_TRUE(texture);
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

TEST_P(InteropPlaygroundTest, CanCreateParagraphs) {
  // Create a typography context.
  auto type_context = Adopt<TypographyContext>(ImpellerTypographyContextNew());
  ASSERT_TRUE(type_context);

  // Create a builder.
  auto builder =
      Adopt<ParagraphBuilder>(ImpellerParagraphBuilderNew(type_context.GetC()));
  ASSERT_TRUE(builder);

  // Create a paragraph style with the font size and foreground and background
  // colors.
  auto style = Adopt<ParagraphStyle>(ImpellerParagraphStyleNew());
  ASSERT_TRUE(style);
  ImpellerParagraphStyleSetFontSize(style.GetC(), 150.0f);

  {
    auto paint = Adopt<Paint>(ImpellerPaintNew());
    ASSERT_TRUE(paint);
    ImpellerColor color = {1.0, 0.0, 0.0, 1.0};
    ImpellerPaintSetColor(paint.GetC(), &color);
    ImpellerParagraphStyleSetForeground(style.GetC(), paint.GetC());
  }

  {
    auto paint = Adopt<Paint>(ImpellerPaintNew());
    ASSERT_TRUE(paint);
    ImpellerColor color = {1.0, 1.0, 1.0, 1.0};
    ImpellerPaintSetColor(paint.GetC(), &color);
    ImpellerParagraphStyleSetBackground(style.GetC(), paint.GetC());
  }

  // Push the style onto the style stack.
  ImpellerParagraphBuilderPushStyle(builder.GetC(), style.GetC());
  std::string text = "the ⚡️ quick ⚡️ brown 🦊 fox jumps over the lazy dog 🐶.";

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
}

}  // namespace impeller::interop::testing
