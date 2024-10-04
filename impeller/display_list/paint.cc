// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/display_list/paint.h"

#include <memory>

#include "display_list/effects/dl_color_source.h"
#include "display_list/geometry/dl_path.h"
#include "fml/logging.h"
#include "impeller/display_list/skia_conversions.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/conical_gradient_contents.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/filters/gaussian_blur_filter_contents.h"
#include "impeller/entity/contents/linear_gradient_contents.h"
#include "impeller/entity/contents/radial_gradient_contents.h"
#include "impeller/entity/contents/runtime_effect_contents.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/contents/sweep_gradient_contents.h"
#include "impeller/entity/contents/tiled_texture_contents.h"
#include "impeller/entity/geometry/geometry.h"

namespace impeller {

using DlScalar = flutter::DlScalar;
using DlPoint = flutter::DlPoint;
using DlRect = flutter::DlRect;
using DlIRect = flutter::DlIRect;
using DlPath = flutter::DlPath;

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

std::shared_ptr<ColorSourceContents> Paint::CreateContents() const {
  if (color_source == nullptr) {
    auto contents = std::make_shared<SolidColorContents>();
    contents->SetColor(color);
    return contents;
  }

  switch (color_source->type()) {
    case flutter::DlColorSourceType::kLinearGradient: {
      const flutter::DlLinearGradientColorSource* linear =
          color_source->asLinearGradient();
      FML_DCHECK(linear);
      auto start_point = skia_conversions::ToPoint(linear->start_point());
      auto end_point = skia_conversions::ToPoint(linear->end_point());
      std::vector<Color> colors;
      std::vector<float> stops;
      skia_conversions::ConvertStops(linear, colors, stops);

      auto tile_mode = static_cast<Entity::TileMode>(linear->tile_mode());
      auto effect_transform = skia_conversions::ToMatrix(linear->matrix());

      auto contents = std::make_shared<LinearGradientContents>();
      contents->SetOpacityFactor(color.alpha);
      contents->SetColors(std::move(colors));
      contents->SetStops(std::move(stops));
      contents->SetEndPoints(start_point, end_point);
      contents->SetTileMode(tile_mode);
      contents->SetEffectTransform(effect_transform);

      std::array<Point, 2> bounds{start_point, end_point};
      auto intrinsic_size = Rect::MakePointBounds(bounds.begin(), bounds.end());
      if (intrinsic_size.has_value()) {
        contents->SetColorSourceSize(intrinsic_size->GetSize());
      }
      return contents;
    }
    case flutter::DlColorSourceType::kRadialGradient: {
      const flutter::DlRadialGradientColorSource* radialGradient =
          color_source->asRadialGradient();
      FML_DCHECK(radialGradient);
      auto center = skia_conversions::ToPoint(radialGradient->center());
      auto radius = radialGradient->radius();
      std::vector<Color> colors;
      std::vector<float> stops;
      skia_conversions::ConvertStops(radialGradient, colors, stops);

      auto tile_mode =
          static_cast<Entity::TileMode>(radialGradient->tile_mode());
      auto effect_transform =
          skia_conversions::ToMatrix(radialGradient->matrix());

      auto contents = std::make_shared<RadialGradientContents>();
      contents->SetOpacityFactor(color.alpha);
      contents->SetColors(std::move(colors));
      contents->SetStops(std::move(stops));
      contents->SetCenterAndRadius(center, radius);
      contents->SetTileMode(tile_mode);
      contents->SetEffectTransform(effect_transform);

      auto radius_pt = Point(radius, radius);
      std::array<Point, 2> bounds{center + radius_pt, center - radius_pt};
      auto intrinsic_size = Rect::MakePointBounds(bounds.begin(), bounds.end());
      if (intrinsic_size.has_value()) {
        contents->SetColorSourceSize(intrinsic_size->GetSize());
      }
      return contents;
    }
    case flutter::DlColorSourceType::kConicalGradient: {
      const flutter::DlConicalGradientColorSource* conical_gradient =
          color_source->asConicalGradient();
      FML_DCHECK(conical_gradient);
      Point center = skia_conversions::ToPoint(conical_gradient->end_center());
      DlScalar radius = conical_gradient->end_radius();
      Point focus_center =
          skia_conversions::ToPoint(conical_gradient->start_center());
      DlScalar focus_radius = conical_gradient->start_radius();
      std::vector<Color> colors;
      std::vector<float> stops;
      skia_conversions::ConvertStops(conical_gradient, colors, stops);

      auto tile_mode =
          static_cast<Entity::TileMode>(conical_gradient->tile_mode());
      auto effect_transform =
          skia_conversions::ToMatrix(conical_gradient->matrix());

      std::shared_ptr<ConicalGradientContents> contents =
          std::make_shared<ConicalGradientContents>();
      contents->SetOpacityFactor(color.alpha);
      contents->SetColors(std::move(colors));
      contents->SetStops(std::move(stops));
      contents->SetCenterAndRadius(center, radius);
      contents->SetTileMode(tile_mode);
      contents->SetEffectTransform(effect_transform);
      contents->SetFocus(focus_center, focus_radius);

      auto radius_pt = Point(radius, radius);
      std::array<Point, 2> bounds{center + radius_pt, center - radius_pt};
      auto intrinsic_size = Rect::MakePointBounds(bounds.begin(), bounds.end());
      if (intrinsic_size.has_value()) {
        contents->SetColorSourceSize(intrinsic_size->GetSize());
      }
      return contents;
    }
    case flutter::DlColorSourceType::kSweepGradient: {
      const flutter::DlSweepGradientColorSource* sweepGradient =
          color_source->asSweepGradient();
      FML_DCHECK(sweepGradient);

      auto center = skia_conversions::ToPoint(sweepGradient->center());
      auto start_angle = Degrees(sweepGradient->start());
      auto end_angle = Degrees(sweepGradient->end());
      std::vector<Color> colors;
      std::vector<float> stops;
      skia_conversions::ConvertStops(sweepGradient, colors, stops);

      auto tile_mode =
          static_cast<Entity::TileMode>(sweepGradient->tile_mode());
      auto effect_transform =
          skia_conversions::ToMatrix(sweepGradient->matrix());

      auto contents = std::make_shared<SweepGradientContents>();
      contents->SetOpacityFactor(color.alpha);
      contents->SetCenterAndAngles(center, start_angle, end_angle);
      contents->SetColors(std::move(colors));
      contents->SetStops(std::move(stops));
      contents->SetTileMode(tile_mode);
      contents->SetEffectTransform(effect_transform);

      return contents;
    }
    case flutter::DlColorSourceType::kImage: {
      const flutter::DlImageColorSource* image_color_source =
          color_source->asImage();
      FML_DCHECK(image_color_source &&
                 image_color_source->image()->impeller_texture());
      auto texture = image_color_source->image()->impeller_texture();
      auto x_tile_mode = static_cast<Entity::TileMode>(
          image_color_source->horizontal_tile_mode());
      auto y_tile_mode = static_cast<Entity::TileMode>(
          image_color_source->vertical_tile_mode());
      auto sampler_descriptor =
          skia_conversions::ToSamplerDescriptor(image_color_source->sampling());
      auto effect_transform =
          skia_conversions::ToMatrix(image_color_source->matrix());

      auto contents = std::make_shared<TiledTextureContents>();
      contents->SetOpacityFactor(color.alpha);
      contents->SetTexture(texture);
      contents->SetTileModes(x_tile_mode, y_tile_mode);
      contents->SetSamplerDescriptor(sampler_descriptor);
      contents->SetEffectTransform(effect_transform);
      if (color_filter) {
        TiledTextureContents::ColorFilterProc filter_proc =
            [color_filter = color_filter](FilterInput::Ref input) {
              return color_filter->WrapWithGPUColorFilter(
                  std::move(input), ColorFilterContents::AbsorbOpacity::kNo);
            };
        contents->SetColorFilter(filter_proc);
      }
      contents->SetColorSourceSize(Size::Ceil(texture->GetSize()));
      return contents;
    }
    case flutter::DlColorSourceType::kRuntimeEffect: {
      const flutter::DlRuntimeEffectColorSource* runtime_effect_color_source =
          color_source->asRuntimeEffect();
      auto runtime_stage =
          runtime_effect_color_source->runtime_effect()->runtime_stage();
      auto uniform_data = runtime_effect_color_source->uniform_data();
      auto samplers = runtime_effect_color_source->samplers();

      std::vector<RuntimeEffectContents::TextureInput> texture_inputs;

      for (auto& sampler : samplers) {
        if (sampler == nullptr) {
          return nullptr;
        }
        auto* image = sampler->asImage();
        if (!sampler->asImage()) {
          return nullptr;
        }
        FML_DCHECK(image->image()->impeller_texture());
        texture_inputs.push_back({
            .sampler_descriptor =
                skia_conversions::ToSamplerDescriptor(image->sampling()),
            .texture = image->image()->impeller_texture(),
        });
      }

      auto contents = std::make_shared<RuntimeEffectContents>();
      contents->SetOpacityFactor(color.alpha);
      contents->SetRuntimeStage(std::move(runtime_stage));
      contents->SetUniformData(std::move(uniform_data));
      contents->SetTextureInputs(std::move(texture_inputs));
      return contents;
    }
    case flutter::DlColorSourceType::kColor: {
      auto contents = std::make_shared<SolidColorContents>();
      contents->SetColor(color);
      return contents;
    }
  }
  FML_UNREACHABLE();
}

std::shared_ptr<Contents> Paint::CreateContentsForGeometry(
    const std::shared_ptr<Geometry>& geometry) const {
  auto contents = CreateContents();

  // Attempt to apply the color filter on the CPU first.
  // Note: This is not just an optimization; some color sources rely on
  //       CPU-applied color filters to behave properly.
  auto color_filter = GetColorFilter();
  bool needs_color_filter = !!color_filter;
  if (color_filter &&
      contents->ApplyColorFilter(color_filter->GetCPUColorFilterProc())) {
    needs_color_filter = false;
  }

  contents->SetGeometry(geometry);
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
      WithImageFilter(input, effect_transform,
                      Entity::RenderingMode::kSubpassPrependSnapshotTransform);
  if (image_filter) {
    input = image_filter;
  }
  input = WithColorFilter(input, ColorFilterContents::AbsorbOpacity::kYes);
  return input;
}

std::shared_ptr<Contents> Paint::WithMaskBlur(std::shared_ptr<Contents> input,
                                              bool is_solid_color,
                                              const Matrix& ctm) const {
  if (mask_blur_descriptor.has_value()) {
    input = mask_blur_descriptor->CreateMaskBlur(FilterInput::Make(input),
                                                 is_solid_color, ctm);
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
  if (color_source &&
      color_source->type() == flutter::DlColorSourceType::kImage) {
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
    std::shared_ptr<TextureContents> texture_contents) const {
  Scalar expand_amount = GaussianBlurFilterContents::CalculateBlurRadius(
      GaussianBlurFilterContents::ScaleSigma(sigma.sigma));
  texture_contents->SetSourceRect(
      texture_contents->GetSourceRect().Expand(expand_amount, expand_amount));
  auto mask = std::make_shared<SolidColorContents>();
  mask->SetColor(Color::White());
  std::optional<Rect> coverage = texture_contents->GetCoverage({});
  std::shared_ptr<Geometry> geometry;
  if (coverage) {
    texture_contents->SetDestinationRect(
        coverage.value().Expand(expand_amount, expand_amount));
    geometry = Geometry::MakeRect(coverage.value());
  }
  mask->SetGeometry(geometry);
  auto descriptor = texture_contents->GetSamplerDescriptor();
  texture_contents->SetSamplerDescriptor(descriptor);
  std::shared_ptr<FilterContents> blurred_mask =
      FilterContents::MakeGaussianBlur(FilterInput::Make(mask), sigma, sigma,
                                       Entity::TileMode::kDecal, style,
                                       geometry);

  return ColorFilterContents::MakeBlend(
      BlendMode::kSourceIn,
      {FilterInput::Make(blurred_mask), FilterInput::Make(texture_contents)});
}

std::shared_ptr<FilterContents> Paint::MaskBlurDescriptor::CreateMaskBlur(
    std::shared_ptr<ColorSourceContents> color_source_contents,
    const std::shared_ptr<ColorFilter>& color_filter) const {
  // If it's a solid color and there is no color filter, then we can just get
  // away with doing one Gaussian blur.
  if (color_source_contents->IsSolidColor() && !color_filter) {
    return FilterContents::MakeGaussianBlur(
        FilterInput::Make(color_source_contents), sigma, sigma,
        Entity::TileMode::kDecal, style, color_source_contents->GetGeometry());
  }

  /// 1. Create an opaque white mask of the original geometry.

  auto mask = std::make_shared<SolidColorContents>();
  mask->SetColor(Color::White());
  mask->SetGeometry(color_source_contents->GetGeometry());

  /// 2. Blur the mask.

  auto blurred_mask = FilterContents::MakeGaussianBlur(
      FilterInput::Make(mask), sigma, sigma, Entity::TileMode::kDecal, style,
      color_source_contents->GetGeometry());

  /// 3. Replace the geometry of the original color source with a rectangle that
  ///    covers the full region of the blurred mask. Note that geometry is in
  ///    local bounds.

  auto expanded_local_bounds = blurred_mask->GetCoverage({});
  if (!expanded_local_bounds.has_value()) {
    expanded_local_bounds = Rect();
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
    bool is_solid_color,
    const Matrix& ctm) const {
  Vector2 blur_sigma(sigma.sigma, sigma.sigma);
  if (!respect_ctm) {
    blur_sigma /=
        Vector2(ctm.GetBasisX().GetLength(), ctm.GetBasisY().GetLength());
  }
  if (is_solid_color) {
    return FilterContents::MakeGaussianBlur(input, Sigma(blur_sigma.x),
                                            Sigma(blur_sigma.y),
                                            Entity::TileMode::kDecal, style);
  }
  return FilterContents::MakeBorderMaskBlur(input, Sigma(blur_sigma.x),
                                            Sigma(blur_sigma.y), style);
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
