// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/entity/contents/content_context.h"

namespace impeller {
namespace testing {

namespace {

// `ToKey` packs a single byte per enum, so these lists only need to cover the
// values that exist, not the full byte range.
constexpr SampleCount kSampleCounts[] = {SampleCount::kCount1,
                                         SampleCount::kCount4};

constexpr PrimitiveType kPrimitiveTypes[] = {
    PrimitiveType::kTriangle, PrimitiveType::kTriangleStrip,
    PrimitiveType::kLine,     PrimitiveType::kLineStrip,
    PrimitiveType::kPoint,    PrimitiveType::kTriangleFan};

constexpr CompareFunction kCompareFunctions[] = {
    CompareFunction::kNever,     CompareFunction::kAlways,
    CompareFunction::kLess,      CompareFunction::kEqual,
    CompareFunction::kLessEqual, CompareFunction::kGreater,
    CompareFunction::kNotEqual,  CompareFunction::kGreaterEqual};

constexpr ContentContextOptions::StencilMode kStencilModes[] = {
    ContentContextOptions::StencilMode::kIgnore,
    ContentContextOptions::StencilMode::kStencilNonZeroFill,
    ContentContextOptions::StencilMode::kStencilEvenOddFill,
    ContentContextOptions::StencilMode::kStencilIncrementAll,
    ContentContextOptions::StencilMode::kCoverCompare,
    ContentContextOptions::StencilMode::kCoverCompareInverted};

bool OptionsAreEqual(const ContentContextOptions& a,
                     const ContentContextOptions& b) {
  return a.sample_count == b.sample_count &&    //
         a.blend_mode == b.blend_mode &&        //
         a.depth_compare == b.depth_compare &&  //
         a.stencil_mode == b.stencil_mode &&    //
         a.primitive_type == b.primitive_type &&
         a.color_attachment_pixel_format == b.color_attachment_pixel_format &&
         a.has_depth_stencil_attachments == b.has_depth_stencil_attachments &&
         a.depth_write_enabled == b.depth_write_enabled &&
         a.is_for_rrect_blur_clear == b.is_for_rrect_blur_clear;
}

}  // namespace

TEST(ContentContextOptionsTest, DefaultOptionsRoundTripThroughKey) {
  ContentContextOptions options;
  EXPECT_TRUE(OptionsAreEqual(options,
                              ContentContextOptions::FromKey(options.ToKey())));
}

TEST(ContentContextOptionsTest, AllOptionsRoundTripThroughKey) {
  // `FromKey` is only useful if it is the exact inverse of `ToKey`. A variant
  // key that decodes to the wrong options would silently mislabel every entry
  // in the pipeline variant report.
  for (SampleCount sample_count : kSampleCounts) {
    for (PrimitiveType primitive_type : kPrimitiveTypes) {
      for (CompareFunction depth_compare : kCompareFunctions) {
        for (ContentContextOptions::StencilMode stencil_mode : kStencilModes) {
          for (bool flag : {false, true}) {
            ContentContextOptions options;
            options.sample_count = sample_count;
            options.primitive_type = primitive_type;
            options.depth_compare = depth_compare;
            options.stencil_mode = stencil_mode;
            options.has_depth_stencil_attachments = flag;
            options.depth_write_enabled = !flag;
            options.is_for_rrect_blur_clear = flag;
            options.blend_mode = BlendMode::kColorBurn;
            options.color_attachment_pixel_format =
                PixelFormat::kB8G8R8A8UNormInt;

            const ContentContextOptions decoded =
                ContentContextOptions::FromKey(options.ToKey());
            EXPECT_TRUE(OptionsAreEqual(options, decoded))
                << "Options did not survive a round trip through key "
                << options.ToKey();
            EXPECT_EQ(options.ToKey(), decoded.ToKey());
          }
        }
      }
    }
  }
}

TEST(ContentContextOptionsTest, EveryBlendModeRoundTripsThroughKey) {
  for (uint8_t i = 0; i <= static_cast<uint8_t>(BlendMode::kLastMode); i++) {
    ContentContextOptions options;
    options.blend_mode = static_cast<BlendMode>(i);
    const ContentContextOptions decoded =
        ContentContextOptions::FromKey(options.ToKey());
    EXPECT_EQ(options.blend_mode, decoded.blend_mode);
  }
}

TEST(ContentContextOptionsTest, DifferentOptionsProduceDifferentKeys) {
  // Variants are identified by this key, so two different configurations
  // colliding would merge two variants into one report entry.
  ContentContextOptions a;
  a.blend_mode = BlendMode::kSrcOver;

  ContentContextOptions b;
  b.blend_mode = BlendMode::kPlus;

  EXPECT_NE(a.ToKey(), b.ToKey());
}

}  // namespace testing
}  // namespace impeller
