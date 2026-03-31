// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/display_list/paint.h"

#include <memory>

#include "flutter/display_list/effects/dl_color_filter.h"
#include "flutter/display_list/effects/dl_color_sources.h"
#include "flutter/display_list/geometry/dl_path.h"
#include "fml/logging.h"
#include "impeller/display_list/color_filter.h"
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
#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

using DlScalar = flutter::DlScalar;
using DlPoint = flutter::DlPoint;
using DlRect = flutter::DlRect;
using DlIRect = flutter::DlIRect;
using DlPath = flutter::DlPath;

void Paint::ConvertStops(const flutter::DlGradientColorSourceBase* gradient,
                         std::vector<Color>& colors,
                         std::vector<float>& stops) {
  FML_DCHECK(gradient->stop_count() >= 2)
      << "stop_count:" << gradient->stop_count();

  auto* dl_colors = gradient->colors();
  auto* dl_stops = gradient->stops();
  if (dl_stops[0] != 0.0) {
    colors.emplace_back(skia_conversions::ToColor(dl_colors[0]));
    stops.emplace_back(0);
  }
  for (auto i = 0; i < gradient->stop_count(); i++) {
    colors.emplace_back(skia_conversions::ToColor(dl_colors[i]));
    stops.emplace_back(std::clamp(dl_stops[i], 0.0f, 1.0f));
  }
  if (dl_stops[gradient->stop_count() - 1] != 1.0) {
    colors.emplace_back(colors.back());
    stops.emplace_back(1.0);
  }
  for (auto i = 1; i < gradient->stop_count(); i++) {
    stops[i] = std::clamp(stops[i], stops[i - 1], stops[i]);
  }
}

std::shared_ptr<ColorSourceContents> Paint::CreateContents(
    const Geometry* geometry) const {
  if (color_source == nullptr) {
    auto contents = std::make_shared<SolidColorContents>(geometry);
    contents->SetColor(color);
    return contents;
  }

  switch (color_source->type()) {
    case flutter::DlColorSourceType::kLinearGradient: {
      const flutter::DlLinearGradientColorSource* linear =
          color_source->asLinearGradient();
      FML_DCHECK(linear);
      auto start_point = linear->start_point();
      auto end_point = linear->end_point();
      std::vector<Color> colors;
      std::vector<float> stops;
      ConvertStops(linear, colors, stops);

      auto tile_mode = static_cast<Entity::TileMode>(linear->tile_mode());
      auto effect_transform = linear->matrix();

      auto contents = std::make_shared<LinearGradientContents>(geometry);
      contents->SetOpacityFactor(color.alpha);
      contents->SetColors(std::move(colors));
      contents->SetStops(std::move(stops));
      contents->SetEndPoints(start_point, end_point);
      contents->SetTileMode(tile_mode);
      contents->SetEffectTransform(effect_transform);

      std::array<Point, 2> bounds{start_point, end_point};
      auto intrinsic_size = Rect::MakePointBounds(bounds.begin(), bounds.end());
      if (intrinsic_size.has_value()) {
        contents->SetColorSourceSize(intrinsic_size->GetSize().Max({1, 1}));
      }
      return contents;
    }
    case flutter::DlColorSourceType::kRadialGradient: {
      const flutter::DlRadialGradientColorSource* radialGradient =
          color_source->asRadialGradient();
      FML_DCHECK(radialGradient);
      auto center = radialGradient->center();
      auto radius = radialGradient->radius();
      std::vector<Color> colors;
      std::vector<float> stops;
      ConvertStops(radialGradient, colors, stops);

      auto tile_mode =
          static_cast<Entity::TileMode>(radialGradient->tile_mode());
      auto effect_transform = radialGradient->matrix();

      auto contents = std::make_shared<RadialGradientContents>(geometry);
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
        contents->SetColorSourceSize(intrinsic_size->GetSize().Max({1, 1}));
      }
      return contents;
    }
    case flutter::DlColorSourceType::kConicalGradient: {
      const flutter::DlConicalGradientColorSource* conical_gradient =
          color_source->asConicalGradient();
      FML_DCHECK(conical_gradient);
      Point center = conical_gradient->end_center();
      DlScalar radius = conical_gradient->end_radius();
      Point focus_center = conical_gradient->start_center();
      DlScalar focus_radius = conical_gradient->start_radius();
      std::vector<Color> colors;
      std::vector<float> stops;
      ConvertStops(conical_gradient, colors, stops);

      auto tile_mode =
          static_cast<Entity::TileMode>(conical_gradient->tile_mode());
      auto effect_transform = conical_gradient->matrix();

      auto contents = std::make_shared<ConicalGradientContents>(geometry);
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
        contents->SetColorSourceSize(intrinsic_size->GetSize().Max({1, 1}));
      }
      return contents;
    }
    case flutter::DlColorSourceType::kSweepGradient: {
      const flutter::DlSweepGradientColorSource* sweepGradient =
          color_source->asSweepGradient();
      FML_DCHECK(sweepGradient);

      auto center = sweepGradient->center();
      auto start_angle = Degrees(sweepGradient->start());
      auto end_angle = Degrees(sweepGradient->end());
      std::vector<Color> colors;
      std::vector<float> stops;
      ConvertStops(sweepGradient, colors, stops);

      auto tile_mode =
          static_cast<Entity::TileMode>(sweepGradient->tile_mode());
      auto effect_transform = sweepGradient->matrix();

      auto contents = std::make_shared<SweepGradientContents>(geometry);
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
      // See https://github.com/flutter/flutter/issues/165205
      flutter::DlMatrix effect_transform = image_color_source->matrix().To3x3();

      auto contents = std::make_shared<TiledTextureContents>(geometry);
      contents->SetOpacityFactor(color.alpha);
      contents->SetTexture(texture);
      contents->SetTileModes(x_tile_mode, y_tile_mode);
      contents->SetSamplerDescriptor(sampler_descriptor);
      contents->SetEffectTransform(effect_transform);
      if (color_filter || invert_colors) {
        TiledTextureContents::ColorFilterProc filter_proc =
            [color_filter = color_filter,
             invert_colors = invert_colors](const FilterInput::Ref& input) {
              if (invert_colors && color_filter) {
                std::shared_ptr<FilterContents> color_filter_output =
                    WrapWithGPUColorFilter(
                        color_filter, input,
                        ColorFilterContents::AbsorbOpacity::kNo);
                return WrapWithInvertColors(
                    FilterInput::Make(color_filter_output),
                    ColorFilterContents::AbsorbOpacity::kNo);
              }
              if (color_filter) {
                return WrapWithGPUColorFilter(
                    color_filter, input,
                    ColorFilterContents::AbsorbOpacity::kNo);
              }
              return WrapWithInvertColors(
                  input, ColorFilterContents::AbsorbOpacity::kNo);
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
          VALIDATION_LOG << "Runtime effect sampler is null";
          auto contents = std::make_shared<SolidColorContents>(geometry);
          contents->SetColor(Color::BlackTransparent());
          return contents;
        }
        auto* image = sampler->asImage();
        if (!sampler->asImage()) {
          VALIDATION_LOG << "Runtime effect sampler is not an image";
          auto contents = std::make_shared<SolidColorContents>(geometry);
          contents->SetColor(Color::BlackTransparent());
          return contents;
        }
        FML_DCHECK(image->image()->impeller_texture());
        texture_inputs.push_back({
            .sampler_descriptor =
                skia_conversions::ToSamplerDescriptor(image->sampling()),
            .texture = image->image()->impeller_texture(),
        });
      }

      auto contents = std::make_shared<RuntimeEffectContents>(geometry);
      contents->SetOpacityFactor(color.alpha);
      contents->SetRuntimeStage(std::move(runtime_stage));
      contents->SetUniformData(std::move(uniform_data));
      contents->SetTextureInputs(std::move(texture_inputs));
      return contents;
    }
  }
  FML_UNREACHABLE();
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
  auto filter = WrapInput(image_filter, FilterInput::Make(input));
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

  if (!color_filter && !invert_colors) {
    return input;
  }

  // Attempt to apply the color filter on the CPU first.
  // Note: This is not just an optimization; some color sources rely on
  //       CPU-applied color filters to behave properly.
  if (input->ApplyColorFilter([&](Color color) -> Color {
        if (color_filter) {
          color = GetCPUColorFilterProc(color_filter)(color);
        }
        if (invert_colors) {
          color = color.ApplyColorMatrix(kColorInversion);
        }
        return color;
      })) {
    return input;
  }

  if (color_filter) {
    input = WrapWithGPUColorFilter(color_filter, FilterInput::Make(input),
                                   absorb_opacity);
  }
  if (invert_colors) {
    input = WrapWithInvertColors(FilterInput::Make(input), absorb_opacity);
  }

  return input;
}

std::shared_ptr<FilterContents> Paint::MaskBlurDescriptor::CreateMaskBlur(
    std::shared_ptr<TextureContents> texture_contents,
    FillRectGeometry* rect_geom) const {
  Scalar expand_amount = GaussianBlurFilterContents::CalculateBlurRadius(
      GaussianBlurFilterContents::ScaleSigma(sigma.sigma));
  texture_contents->SetSourceRect(
      texture_contents->GetSourceRect().Expand(expand_amount, expand_amount));
  std::optional<Rect> coverage = texture_contents->GetCoverage({});
  Geometry* geometry = nullptr;
  if (coverage) {
    texture_contents->SetDestinationRect(
        coverage.value().Expand(expand_amount, expand_amount));
    *rect_geom = FillRectGeometry(coverage.value());
    geometry = rect_geom;
  }
  auto mask = std::make_shared<SolidColorContents>(geometry);
  mask->SetColor(Color::White());
  auto descriptor = texture_contents->GetSamplerDescriptor();
  texture_contents->SetSamplerDescriptor(descriptor);
  std::shared_ptr<FilterContents> blurred_mask =
      FilterContents::MakeGaussianBlur(
          FilterInput::Make(mask), sigma, sigma, Entity::TileMode::kDecal,
          /*bounds=*/std::nullopt, style, geometry);

  return ColorFilterContents::MakeBlend(
      BlendMode::kSrcIn,
      {FilterInput::Make(blurred_mask), FilterInput::Make(texture_contents)});
}

std::shared_ptr<Contents> Paint::MaskBlurDescriptor::CreateMaskBlur(
    const Paint& paint,
    const Geometry* geometry,
    std::shared_ptr<ColorSourceContents> contents,
    bool needs_color_filter,
    FillRectGeometry* out_geom) const {
  // If it's a solid color then we can just get  away with doing one Gaussian
  // blur. The color filter will always be applied on the CPU.
  if (contents->IsSolidColor()) {
    return FilterContents::MakeGaussianBlur(
        FilterInput::Make(contents), sigma, sigma, Entity::TileMode::kDecal,
        /*bounds=*/std::nullopt, style, geometry);
  }

  /// 1. Create an opaque white mask of the original geometry.
  auto mask = std::make_shared<SolidColorContents>(geometry);
  mask->SetColor(Color::White());

  /// 2. Blur the mask.
  auto blurred_mask = FilterContents::MakeGaussianBlur(
      FilterInput::Make(mask), sigma, sigma, Entity::TileMode::kDecal,
      /*bounds=*/std::nullopt, style, geometry);

  /// 3. Replace the geometry of the original color source with a rectangle that
  ///    covers the full region of the blurred mask. Note that geometry is in
  ///    local bounds.
  std::optional<Rect> expanded_local_bounds = blurred_mask->GetCoverage({});
  if (!expanded_local_bounds.has_value()) {
    expanded_local_bounds = Rect();
  }
  *out_geom = FillRectGeometry(expanded_local_bounds.value());

  std::shared_ptr<ColorSourceContents> expanded_contents =
      paint.CreateContents(out_geom);
  std::shared_ptr<Contents> final_contents = expanded_contents;

  /// 4. Apply the user set color filter on the GPU, if applicable.
  if (needs_color_filter) {
    if (paint.color_filter) {
      final_contents = WrapWithGPUColorFilter(
          paint.color_filter, FilterInput::Make(std::move(final_contents)),
          ColorFilterContents::AbsorbOpacity::kYes);
    }
    if (paint.invert_colors) {
      final_contents =
          WrapWithInvertColors(FilterInput::Make(std::move(final_contents)),
                               ColorFilterContents::AbsorbOpacity::kYes);
    }
  }

  /// 5. Composite the color source with the blurred mask.
  return ColorFilterContents::MakeBlend(
      BlendMode::kSrcIn,
      {FilterInput::Make(blurred_mask), FilterInput::Make(final_contents)});
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
    return FilterContents::MakeGaussianBlur(
        input, Sigma(blur_sigma.x), Sigma(blur_sigma.y),
        Entity::TileMode::kDecal, /*bounds=*/std::nullopt, style);
  }
  return FilterContents::MakeBorderMaskBlur(input, Sigma(blur_sigma.x),
                                            Sigma(blur_sigma.y), style);
}

bool Paint::HasColorFilter() const {
  return color_filter || invert_colors;
}

}  // namespace impeller
