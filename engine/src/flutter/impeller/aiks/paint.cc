// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/paint.h"

#include <memory>

#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/geometry/geometry.h"

namespace impeller {

/// A color matrix which inverts colors.
// clang-format off
constexpr ColorMatrix kColorInversion = {
  .array = {
    -1.0,    0,    0, 1.0, 0, //
       0, -1.0,    0, 1.0, 0, //
       0,    0, -1.0, 1.0, 0, //
     1.0,  1.0,  1.0, 1.0, 0  //
  }
};
// clang-format on

std::shared_ptr<Contents> Paint::CreateContentsForEntity(const Path& path,
                                                         bool cover) const {
  std::unique_ptr<Geometry> geometry;
  switch (style) {
    case Style::kFill:
      geometry = cover ? Geometry::MakeCover() : Geometry::MakeFillPath(path);
      break;
    case Style::kStroke:
      geometry =
          cover ? Geometry::MakeCover()
                : Geometry::MakeStrokePath(path, stroke_width, stroke_miter,
                                           stroke_cap, stroke_join);
      break;
  }
  return CreateContentsForGeometry(std::move(geometry));
}

std::shared_ptr<Contents> Paint::CreateContentsForGeometry(
    std::shared_ptr<Geometry> geometry) const {
  auto contents = color_source.GetContents(*this);

  // Attempt to apply the color filter on the CPU first.
  // Note: This is not just an optimization; some color sources rely on
  //       CPU-applied color filters to behave properly.
  auto color_filter = GetColorFilter();
  bool needs_color_filter = !!color_filter;
  if (color_filter &&
      contents->ApplyColorFilter(color_filter->GetCPUColorFilterProc())) {
    needs_color_filter = false;
  }

  contents->SetGeometry(std::move(geometry));
  if (mask_blur_descriptor.has_value()) {
    // If there's a mask blur and we need to apply the color filter on the GPU,
    // we need to be careful to only apply the color filter to the source
    // colors. CreateMaskBlur is able to handle this case.
    return mask_blur_descriptor->CreateMaskBlur(
        contents, needs_color_filter ? color_filter : nullptr);
  }

  return contents;
}

std::shared_ptr<Contents> Paint::WithFilters(
    std::shared_ptr<Contents> input) const {
  input = WithColorFilter(input, ColorFilterContents::AbsorbOpacity::kYes);
  auto image_filter =
      WithImageFilter(input, Matrix(), Entity::RenderingMode::kDirect);
  if (image_filter) {
    input = image_filter;
  }
  return input;
}

std::shared_ptr<Contents> Paint::WithFiltersForSubpassTarget(
    std::shared_ptr<Contents> input,
    const Matrix& effect_transform) const {
  auto image_filter =
      WithImageFilter(input, effect_transform, Entity::RenderingMode::kSubpass);
  if (image_filter) {
    input = image_filter;
  }
  input = WithColorFilter(input, ColorFilterContents::AbsorbOpacity::kYes);
  return input;
}

std::shared_ptr<Contents> Paint::WithMaskBlur(std::shared_ptr<Contents> input,
                                              bool is_solid_color) const {
  if (mask_blur_descriptor.has_value()) {
    input = mask_blur_descriptor->CreateMaskBlur(FilterInput::Make(input),
                                                 is_solid_color);
  }
  return input;
}

std::shared_ptr<FilterContents> Paint::WithImageFilter(
    const FilterInput::Variant& input,
    const Matrix& effect_transform,
    Entity::RenderingMode rendering_mode) const {
  if (!image_filter) {
    return nullptr;
  }
  auto filter = image_filter->WrapInput(FilterInput::Make(input));
  filter->SetRenderingMode(rendering_mode);
  filter->SetEffectTransform(effect_transform);
  return filter;
}

std::shared_ptr<Contents> Paint::WithColorFilter(
    std::shared_ptr<Contents> input,
    ColorFilterContents::AbsorbOpacity absorb_opacity) const {
  // Image input types will directly set their color filter,
  // if any. See `TiledTextureContents.SetColorFilter`.
  if (color_source.GetType() == ColorSource::Type::kImage) {
    return input;
  }

  auto color_filter = GetColorFilter();
  if (!color_filter) {
    return input;
  }

  // Attempt to apply the color filter on the CPU first.
  // Note: This is not just an optimization; some color sources rely on
  //       CPU-applied color filters to behave properly.
  if (input->ApplyColorFilter(color_filter->GetCPUColorFilterProc())) {
    return input;
  }
  return color_filter->WrapWithGPUColorFilter(FilterInput::Make(input),
                                              absorb_opacity);
}

std::shared_ptr<FilterContents> Paint::MaskBlurDescriptor::CreateMaskBlur(
    std::shared_ptr<ColorSourceContents> color_source_contents,
    const std::shared_ptr<ColorFilter>& color_filter) const {
  // If it's a solid color and there is no color filter, then we can just get
  // away with doing one Gaussian blur.
  if (color_source_contents->IsSolidColor() && !color_filter) {
    return FilterContents::MakeGaussianBlur(
        FilterInput::Make(color_source_contents), sigma, sigma, style,
        Entity::TileMode::kDecal);
  }

  /// 1. Create an opaque white mask of the original geometry.

  auto mask = std::make_shared<SolidColorContents>();
  mask->SetColor(Color::White());
  mask->SetGeometry(color_source_contents->GetGeometry());

  /// 2. Blur the mask.

  auto blurred_mask = FilterContents::MakeGaussianBlur(
      FilterInput::Make(mask), sigma, sigma, style, Entity::TileMode::kDecal);

  /// 3. Replace the geometry of the original color source with a rectangle that
  ///    covers the full region of the blurred mask. Note that geometry is in
  ///    local bounds.

  auto expanded_local_bounds = blurred_mask->GetCoverage({});
  if (!expanded_local_bounds.has_value()) {
    return nullptr;
  }
  color_source_contents->SetGeometry(
      Geometry::MakeRect(*expanded_local_bounds));

  std::shared_ptr<Contents> color_contents = color_source_contents;

  /// 4. Apply the user set color filter on the GPU, if applicable.

  if (color_filter) {
    color_contents = color_filter->WrapWithGPUColorFilter(
        FilterInput::Make(color_source_contents),
        ColorFilterContents::AbsorbOpacity::kYes);
  }

  /// 5. Composite the color source with the blurred mask.

  return ColorFilterContents::MakeBlend(
      BlendMode::kSourceIn,
      {FilterInput::Make(blurred_mask), FilterInput::Make(color_contents)});
}

std::shared_ptr<FilterContents> Paint::MaskBlurDescriptor::CreateMaskBlur(
    const FilterInput::Ref& input,
    bool is_solid_color) const {
  if (is_solid_color) {
    return FilterContents::MakeGaussianBlur(input, sigma, sigma, style,
                                            Entity::TileMode::kDecal);
  }
  return FilterContents::MakeBorderMaskBlur(input, sigma, sigma, style);
}

std::shared_ptr<ColorFilter> Paint::GetColorFilter() const {
  if (invert_colors && color_filter) {
    auto filter = ColorFilter::MakeMatrix(kColorInversion);
    return ColorFilter::MakeComposed(filter, color_filter);
  }
  if (invert_colors) {
    return ColorFilter::MakeMatrix(kColorInversion);
  }
  if (color_filter) {
    return color_filter;
  }
  return nullptr;
}

bool Paint::HasColorFilter() const {
  return !!color_filter || invert_colors;
}

}  // namespace impeller
