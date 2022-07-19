// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_flags.h"
#include "flutter/display_list/display_list_path_effect.h"
namespace flutter {

const DisplayListSpecialGeometryFlags DisplayListAttributeFlags::WithPathEffect(
    const DlPathEffect* effect) const {
  if (is_geometric() && effect) {
    if (effect->asDash()) {
      // A dash effect has a very simple impact. It cannot introduce any
      // miter joins that weren't already present in the original path
      // and it does not grow the bounds of the path, but it can add
      // end caps to areas that might not have had them before so all
      // we need to do is to indicate the potential for diagonal
      // end caps and move on.
      return special_flags_.with(kMayHaveCaps_ | kMayHaveDiagonalCaps_);
    } else {
      // An arbitrary path effect can introduce joins at an arbitrary
      // angle and may change the geometry of the end caps
      return special_flags_.with(kMayHaveCaps_ | kMayHaveDiagonalCaps_ |
                                 kMayHaveJoins_ | kMayHaveAcuteJoins_);
    }
  }
  return special_flags_;
}

// clang-format off
// Flags common to all primitives that apply colors
#define PAINT_FLAGS (kUsesDither_ |      \
                     kUsesColor_ |       \
                     kUsesAlpha_ |       \
                     kUsesBlend_ |       \
                     kUsesShader_ |      \
                     kUsesColorFilter_ | \
                     kUsesImageFilter_)

// Flags common to all primitives that stroke or fill
#define STROKE_OR_FILL_FLAGS (kIsDrawnGeometry_ | \
                              kUsesAntiAlias_ |   \
                              kUsesMaskFilter_ |  \
                              kUsesPathEffect_)

// Flags common to primitives that stroke geometry
#define STROKE_FLAGS (kIsStrokedGeometry_ | \
                      kUsesAntiAlias_ |     \
                      kUsesMaskFilter_ |    \
                      kUsesPathEffect_)

// Flags common to primitives that render an image with paint attributes
#define IMAGE_FLAGS_BASE (kIsNonGeometric_ |  \
                          kUsesAlpha_ |       \
                          kUsesDither_ |      \
                          kUsesBlend_ |       \
                          kUsesColorFilter_ | \
                          kUsesImageFilter_)
// clang-format on

const DisplayListAttributeFlags DisplayListOpFlags::kSaveLayerFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags DisplayListOpFlags::kSaveLayerWithPaintFlags =
    DisplayListAttributeFlags(kIsNonGeometric_ |   //
                              kUsesAlpha_ |        //
                              kUsesBlend_ |        //
                              kUsesColorFilter_ |  //
                              kUsesImageFilter_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawColorFlags =
    DisplayListAttributeFlags(kFloodsSurface_ | kIgnoresPaint_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawPaintFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | kFloodsSurface_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawHVLineFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_FLAGS | kMayHaveCaps_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawLineFlags =
    kDrawHVLineFlags.with(kMayHaveDiagonalCaps_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawRectFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS |
                              kMayHaveJoins_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawOvalFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawCircleFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawRRectFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawDRRectFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawPathFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS |
                              kMayHaveCaps_ | kMayHaveDiagonalCaps_ |
                              kMayHaveJoins_ | kMayHaveAcuteJoins_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawArcNoCenterFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS |
                              kMayHaveCaps_ | kMayHaveDiagonalCaps_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawArcWithCenterFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS |
                              kMayHaveJoins_ | kMayHaveAcuteJoins_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawPointsAsPointsFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_FLAGS |  //
                              kMayHaveCaps_ | kButtCapIsSquare_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawPointsAsLinesFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_FLAGS |  //
                              kMayHaveCaps_ | kMayHaveDiagonalCaps_);

// Polygon mode just draws (count-1) separate lines, no joins
const DisplayListAttributeFlags DisplayListOpFlags::kDrawPointsAsPolygonFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_FLAGS |  //
                              kMayHaveCaps_ | kMayHaveDiagonalCaps_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawVerticesFlags =
    DisplayListAttributeFlags(kIsNonGeometric_ |   //
                              kUsesDither_ |       //
                              kUsesAlpha_ |        //
                              kUsesShader_ |       //
                              kUsesBlend_ |        //
                              kUsesColorFilter_ |  //
                              kUsesImageFilter_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawImageFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawImageWithPaintFlags =
    DisplayListAttributeFlags(IMAGE_FLAGS_BASE |  //
                              kUsesAntiAlias_ | kUsesMaskFilter_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawImageRectFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags
    DisplayListOpFlags::kDrawImageRectWithPaintFlags =
        DisplayListAttributeFlags(IMAGE_FLAGS_BASE |  //
                                  kUsesAntiAlias_ | kUsesMaskFilter_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawImageNineFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags
    DisplayListOpFlags::kDrawImageNineWithPaintFlags =
        DisplayListAttributeFlags(IMAGE_FLAGS_BASE);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawImageLatticeFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags
    DisplayListOpFlags::kDrawImageLatticeWithPaintFlags =
        DisplayListAttributeFlags(IMAGE_FLAGS_BASE);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawAtlasFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawAtlasWithPaintFlags =
    DisplayListAttributeFlags(IMAGE_FLAGS_BASE);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawPictureFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawPictureWithPaintFlags =
    kSaveLayerWithPaintFlags;

const DisplayListAttributeFlags DisplayListOpFlags::kDrawDisplayListFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawTextBlobFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS |
                              kMayHaveJoins_)
        .without(kUsesAntiAlias_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawShadowFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

#undef PAINT_FLAGS
#undef STROKE_OR_FILL_FLAGS
#undef STROKE_FLAGS
#undef IMAGE_FLAGS_BASE

}  // namespace flutter
