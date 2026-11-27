// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_DISPLAY_LIST_PAINT_H_
#define FLUTTER_IMPELLER_DISPLAY_LIST_PAINT_H_

#include <memory>

#include "display_list/dl_paint.h"
#include "display_list/effects/dl_color_filter.h"
#include "display_list/effects/dl_color_sources.h"
#include "display_list/effects/dl_image_filter.h"
#include "impeller/display_list/color_filter.h"
#include "impeller/display_list/image_filter.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/stroke_parameters.h"
#include "impeller/renderer/context.h"

namespace impeller {

struct Paint {
  using ImageFilterProc = std::function<std::shared_ptr<FilterContents>(
      FilterInput::Ref,
      const Matrix& effect_transform,
      Entity::RenderingMode rendering_mode)>;
  using ColorSourceProc = std::function<std::shared_ptr<ColorSourceContents>()>;

  /// @brief Whether or not a save layer with the provided paint can perform the
  ///        opacity peephole optimization.
  static bool CanApplyOpacityPeephole(const Paint& paint) {
    return paint.blend_mode == BlendMode::kSrcOver &&
           paint.invert_colors == false &&
           !paint.mask_blur_descriptor.has_value() &&
           paint.image_filter == nullptr && paint.color_filter == nullptr;
  }

  enum class Style {
    kFill,
    kStroke,
  };

  struct MaskBlurDescriptor {
    FilterContents::BlurStyle style;
    Sigma sigma;
    /// Text mask blurs need to not apply the CTM to the blur kernel.
    /// See: https://github.com/flutter/flutter/issues/115112
    bool respect_ctm = true;

    std::shared_ptr<FilterContents> CreateMaskBlur(
        std::shared_ptr<TextureContents> texture_contents,
        FillRectGeometry* rect_geom) const;

    std::shared_ptr<FilterContents> CreateMaskBlur(
        const FilterInput::Ref& input,
        const Matrix& ctm) const;

    std::shared_ptr<Contents> CreateMaskBlur(
        const Paint& paint,
        ContentContext& renderer,
        const Geometry* geometry,
        std::shared_ptr<ColorSourceContents> contents,
        bool needs_color_filter,
        FillRectGeometry* out_geom) const;
  };

  Color color = Color::Black();
  const flutter::DlColorSource* color_source = nullptr;
  const flutter::DlColorFilter* color_filter = nullptr;
  const flutter::DlImageFilter* image_filter = nullptr;

  StrokeParameters stroke;
  Style style = Style::kFill;
  BlendMode blend_mode = BlendMode::kSrcOver;
  bool invert_colors = false;
  bool anti_alias = flutter::DlPaint::kDefaultAntiAlias;

  std::optional<MaskBlurDescriptor> mask_blur_descriptor;

  /// @brief   Return an optional StrokeParameters if this Paint is a stroked
  ///          Paint, otherwise return a nullopt.
  /// @return  An optional set of StrokeParameters
  std::optional<StrokeParameters> GetStroke() const {
    return (style == Style::kStroke) ? std::optional(stroke) : std::nullopt;
  }

  /// @brief      Wrap this paint's configured filters to the given contents.
  /// @param[in]  input           The contents to wrap with paint's filters.
  /// @return     The filter-wrapped contents. If there are no filters that need
  ///             to be wrapped for the current paint configuration, the
  ///             original contents is returned.
  std::shared_ptr<Contents> WithFilters(ContentContext& renderer,
                                        std::shared_ptr<Contents> input) const;

  /// @brief      Wrap this paint's configured filters to the given contents of
  ///             subpass target.
  /// @param[in]  input  The contents of subpass target to wrap with paint's
  ///                    filters.
  ///
  /// @return     The filter-wrapped contents. If there are no filters that need
  ///             to be wrapped for the current paint configuration, the
  ///             original contents is returned.
  std::shared_ptr<Contents> WithFiltersForSubpassTarget(
      ContentContext& renderer,
      std::shared_ptr<Contents> input,
      const Matrix& effect_transform = Matrix()) const;

  /// @brief   Whether this paint has a color filter that can apply opacity
  bool HasColorFilter() const;

  /// @brief      Create a `ColorSourceContents` representing this paint's
  ///             shader/colors.
  /// @param[in]  renderer            The content context renderer.
  /// @param[in]  geometry            The geometry the color source is drawn
  ///                                 onto.
  /// @param[in]  geometry_transform  An optional transform representing a
  ///                                 layout/positioning transform applied to
  ///                                 the geometry. If provided, this is used to
  ///                                 adjust the color source's effect transform
  ///                                 to align it with the geometry's coordinate
  ///                                 space.
  /// @return     The generated color source contents.
  std::shared_ptr<ColorSourceContents> CreateContents(
      ContentContext& renderer,
      const Geometry* geometry,
      const std::optional<Matrix>& geometry_transform = std::nullopt) const;

  std::shared_ptr<FilterContents> WithImageFilter(
      ContentContext& renderer,
      const FilterInput::Variant& input,
      const Matrix& effect_transform,
      Entity::RenderingMode rendering_mode) const;

  /// @brief Convert display list colors + stops into impeller colors and
  ///        stops that start at 0.0 and end at 1.0.
  ///
  /// The gradient's stops must already be in [0.0, 1.0] and non-decreasing,
  /// which the `DlColorSource` gradient factories guarantee.
  /// * If the first stop is not 0.0, a stop with the first color is inserted
  ///   at 0.0.
  /// * If the last stop is not 1.0, a stop with the last color is inserted at
  ///   1.0.
  static void ConvertStops(const flutter::DlGradientColorSourceBase* gradient,
                           std::vector<Color>& colors,
                           std::vector<float>& stops);

 private:
  std::shared_ptr<Contents> WithColorFilter(
      std::shared_ptr<Contents> input,
      ColorFilterContents::AbsorbOpacity absorb_opacity =
          ColorFilterContents::AbsorbOpacity::kNo) const;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_DISPLAY_LIST_PAINT_H_
