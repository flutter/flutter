// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_paint.h"
#include "flutter/display_list/display_list_sampling_options.h"
#include "flutter/display_list/display_list_tile_mode.h"
#include "flutter/display_list/display_list_vertices.h"
#include "flutter/display_list/types.h"
#include "gtest/gtest.h"
#include "include/core/SkSamplingOptions.h"

namespace flutter {
namespace testing {

TEST(DisplayListEnum, ToDlTileMode) {
  ASSERT_EQ(ToDl(SkTileMode::kClamp), DlTileMode::kClamp);
  ASSERT_EQ(ToDl(SkTileMode::kRepeat), DlTileMode::kRepeat);
  ASSERT_EQ(ToDl(SkTileMode::kMirror), DlTileMode::kMirror);
  ASSERT_EQ(ToDl(SkTileMode::kDecal), DlTileMode::kDecal);
}

TEST(DisplayListEnum, ToSkTileMode) {
  ASSERT_EQ(ToSk(DlTileMode::kClamp), SkTileMode::kClamp);
  ASSERT_EQ(ToSk(DlTileMode::kRepeat), SkTileMode::kRepeat);
  ASSERT_EQ(ToSk(DlTileMode::kMirror), SkTileMode::kMirror);
  ASSERT_EQ(ToSk(DlTileMode::kDecal), SkTileMode::kDecal);
}

TEST(DisplayListEnum, ToDlDrawStyle) {
  ASSERT_EQ(ToDl(SkPaint::Style::kFill_Style), DlDrawStyle::kFill);
  ASSERT_EQ(ToDl(SkPaint::Style::kStroke_Style), DlDrawStyle::kStroke);
  ASSERT_EQ(ToDl(SkPaint::Style::kStrokeAndFill_Style),
            DlDrawStyle::kStrokeAndFill);
}

TEST(DisplayListEnum, ToSkDrawStyle) {
  ASSERT_EQ(ToSk(DlDrawStyle::kFill), SkPaint::Style::kFill_Style);
  ASSERT_EQ(ToSk(DlDrawStyle::kStroke), SkPaint::Style::kStroke_Style);
  ASSERT_EQ(ToSk(DlDrawStyle::kStrokeAndFill),
            SkPaint::Style::kStrokeAndFill_Style);
}

TEST(DisplayListEnum, ToDlStrokeCap) {
  ASSERT_EQ(ToDl(SkPaint::Cap::kButt_Cap), DlStrokeCap::kButt);
  ASSERT_EQ(ToDl(SkPaint::Cap::kRound_Cap), DlStrokeCap::kRound);
  ASSERT_EQ(ToDl(SkPaint::Cap::kSquare_Cap), DlStrokeCap::kSquare);
}

TEST(DisplayListEnum, ToSkStrokeCap) {
  ASSERT_EQ(ToSk(DlStrokeCap::kButt), SkPaint::Cap::kButt_Cap);
  ASSERT_EQ(ToSk(DlStrokeCap::kRound), SkPaint::Cap::kRound_Cap);
  ASSERT_EQ(ToSk(DlStrokeCap::kSquare), SkPaint::Cap::kSquare_Cap);
}

TEST(DisplayListEnum, ToDlStrokeJoin) {
  ASSERT_EQ(ToDl(SkPaint::Join::kMiter_Join), DlStrokeJoin::kMiter);
  ASSERT_EQ(ToDl(SkPaint::Join::kRound_Join), DlStrokeJoin::kRound);
  ASSERT_EQ(ToDl(SkPaint::Join::kBevel_Join), DlStrokeJoin::kBevel);
}

TEST(DisplayListEnum, ToSkStrokeJoin) {
  ASSERT_EQ(ToSk(DlStrokeJoin::kMiter), SkPaint::Join::kMiter_Join);
  ASSERT_EQ(ToSk(DlStrokeJoin::kRound), SkPaint::Join::kRound_Join);
  ASSERT_EQ(ToSk(DlStrokeJoin::kBevel), SkPaint::Join::kBevel_Join);
}

TEST(DisplayListEnum, ToDlVertexMode) {
  ASSERT_EQ(ToDl(SkVertices::VertexMode::kTriangles_VertexMode),
            DlVertexMode::kTriangles);
  ASSERT_EQ(ToDl(SkVertices::VertexMode::kTriangleStrip_VertexMode),
            DlVertexMode::kTriangleStrip);
  ASSERT_EQ(ToDl(SkVertices::VertexMode::kTriangleFan_VertexMode),
            DlVertexMode::kTriangleFan);
}

TEST(DisplayListEnum, ToSkVertexMode) {
  ASSERT_EQ(ToSk(DlVertexMode::kTriangles),
            SkVertices::VertexMode::kTriangles_VertexMode);
  ASSERT_EQ(ToSk(DlVertexMode::kTriangleStrip),
            SkVertices::VertexMode::kTriangleStrip_VertexMode);
  ASSERT_EQ(ToSk(DlVertexMode::kTriangleFan),
            SkVertices::VertexMode::kTriangleFan_VertexMode);
}

TEST(DisplayListEnum, ToDlFilterMode) {
  ASSERT_EQ(ToDl(SkFilterMode::kLinear), DlFilterMode::kLinear);
  ASSERT_EQ(ToDl(SkFilterMode::kNearest), DlFilterMode::kNearest);
  ASSERT_EQ(ToDl(SkFilterMode::kLast), DlFilterMode::kLast);
}

TEST(DisplayListEnum, ToSkFilterMode) {
  ASSERT_EQ(ToSk(DlFilterMode::kLinear), SkFilterMode::kLinear);
  ASSERT_EQ(ToSk(DlFilterMode::kNearest), SkFilterMode::kNearest);
  ASSERT_EQ(ToSk(DlFilterMode::kLast), SkFilterMode::kLast);
}

TEST(DisplayListEnum, ToDlImageSampling) {
  ASSERT_EQ(ToDl(SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kNone)),
            DlImageSampling::kLinear);
  ASSERT_EQ(
      ToDl(SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kLinear)),
      DlImageSampling::kMipmapLinear);
  ASSERT_EQ(
      ToDl(SkSamplingOptions(SkFilterMode::kNearest, SkMipmapMode::kNone)),
      DlImageSampling::kNearestNeighbor);
  ASSERT_EQ(ToDl(SkSamplingOptions(SkCubicResampler{1 / 3.0f, 1 / 3.0f})),
            DlImageSampling::kCubic);
}

TEST(DisplayListEnum, ToSkSamplingOptions) {
  ASSERT_EQ(ToSk(DlImageSampling::kLinear),
            SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kNone));
  ASSERT_EQ(ToSk(DlImageSampling::kMipmapLinear),
            SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kLinear));
  ASSERT_EQ(ToSk(DlImageSampling::kNearestNeighbor),
            SkSamplingOptions(SkFilterMode::kNearest, SkMipmapMode::kNone));
  ASSERT_EQ(ToSk(DlImageSampling::kCubic),
            SkSamplingOptions(SkCubicResampler{1 / 3.0f, 1 / 3.0f}));
}

#define CHECK_TO_DLENUM(V) ASSERT_EQ(ToDl(SkBlendMode::V), DlBlendMode::V);
#define CHECK_TO_SKENUM(V) ASSERT_EQ(ToSk(DlBlendMode::V), SkBlendMode::V);

#define FOR_EACH_ENUM(FUNC) \
  FUNC(kSrc)                \
  FUNC(kClear)              \
  FUNC(kSrc)                \
  FUNC(kDst)                \
  FUNC(kSrcOver)            \
  FUNC(kDstOver)            \
  FUNC(kSrcIn)              \
  FUNC(kDstIn)              \
  FUNC(kSrcOut)             \
  FUNC(kDstOut)             \
  FUNC(kSrcATop)            \
  FUNC(kDstATop)            \
  FUNC(kXor)                \
  FUNC(kPlus)               \
  FUNC(kModulate)           \
  FUNC(kScreen)             \
  FUNC(kOverlay)            \
  FUNC(kDarken)             \
  FUNC(kLighten)            \
  FUNC(kColorDodge)         \
  FUNC(kColorBurn)          \
  FUNC(kHardLight)          \
  FUNC(kSoftLight)          \
  FUNC(kDifference)         \
  FUNC(kExclusion)          \
  FUNC(kMultiply)           \
  FUNC(kHue)                \
  FUNC(kSaturation)         \
  FUNC(kColor)              \
  FUNC(kLuminosity)         \
  FUNC(kLastCoeffMode)      \
  FUNC(kLastSeparableMode)  \
  FUNC(kLastMode)

TEST(DisplayListEnum, ToDlBlendMode){FOR_EACH_ENUM(CHECK_TO_DLENUM)}

TEST(DisplayListEnum, ToSkBlendMode) {
  FOR_EACH_ENUM(CHECK_TO_SKENUM)
}

#undef CHECK_TO_DLENUM
#undef CHECK_TO_SKENUM
#undef FOR_EACH_ENUM

}  // namespace testing
}  // namespace flutter
