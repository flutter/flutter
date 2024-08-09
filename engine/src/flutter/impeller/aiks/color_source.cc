// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/color_source.h"

#include <memory>
#include <variant>
#include <vector>

#include "impeller/aiks/paint.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/entity/contents/conical_gradient_contents.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/linear_gradient_contents.h"
#include "impeller/entity/contents/radial_gradient_contents.h"
#include "impeller/entity/contents/runtime_effect_contents.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/contents/sweep_gradient_contents.h"
#include "impeller/entity/contents/tiled_texture_contents.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/scalar.h"
#include "impeller/runtime_stage/runtime_stage.h"

namespace impeller {

namespace {

struct CreateContentsVisitor {
  explicit CreateContentsVisitor(const Paint& p_paint) : paint(p_paint) {}

  const Paint& paint;

  std::shared_ptr<ColorSourceContents> operator()(
      const LinearGradientData& data) {
    auto contents = std::make_shared<LinearGradientContents>();
    contents->SetOpacityFactor(paint.color.alpha);
    contents->SetColors(data.colors);
    contents->SetStops(data.stops);
    contents->SetEndPoints(data.start_point, data.end_point);
    contents->SetTileMode(data.tile_mode);
    contents->SetEffectTransform(data.effect_transform);

    std::vector<Point> bounds{data.start_point, data.end_point};
    auto intrinsic_size = Rect::MakePointBounds(bounds.begin(), bounds.end());
    if (intrinsic_size.has_value()) {
      contents->SetColorSourceSize(intrinsic_size->GetSize());
    }
    return contents;
  }

  std::shared_ptr<ColorSourceContents> operator()(
      const RadialGradientData& data) {
    auto contents = std::make_shared<RadialGradientContents>();
    contents->SetOpacityFactor(paint.color.alpha);
    contents->SetColors(data.colors);
    contents->SetStops(data.stops);
    contents->SetCenterAndRadius(data.center, data.radius);
    contents->SetTileMode(data.tile_mode);
    contents->SetEffectTransform(data.effect_transform);

    auto radius_pt = Point(data.radius, data.radius);
    std::vector<Point> bounds{data.center + radius_pt, data.center - radius_pt};
    auto intrinsic_size = Rect::MakePointBounds(bounds.begin(), bounds.end());
    if (intrinsic_size.has_value()) {
      contents->SetColorSourceSize(intrinsic_size->GetSize());
    }
    return contents;
  }

  std::shared_ptr<ColorSourceContents> operator()(
      const ConicalGradientData& data) {
    std::shared_ptr<ConicalGradientContents> contents =
        std::make_shared<ConicalGradientContents>();
    contents->SetOpacityFactor(paint.color.alpha);
    contents->SetColors(data.colors);
    contents->SetStops(data.stops);
    contents->SetCenterAndRadius(data.center, data.radius);
    contents->SetTileMode(data.tile_mode);
    contents->SetEffectTransform(data.effect_transform);
    contents->SetFocus(data.focus_center, data.focus_radius);

    auto radius_pt = Point(data.radius, data.radius);
    std::vector<Point> bounds{data.center + radius_pt, data.center - radius_pt};
    auto intrinsic_size = Rect::MakePointBounds(bounds.begin(), bounds.end());
    if (intrinsic_size.has_value()) {
      contents->SetColorSourceSize(intrinsic_size->GetSize());
    }
    return contents;
  }

  std::shared_ptr<ColorSourceContents> operator()(
      const SweepGradientData& data) {
    auto contents = std::make_shared<SweepGradientContents>();
    contents->SetOpacityFactor(paint.color.alpha);
    contents->SetCenterAndAngles(data.center, data.start_angle, data.end_angle);
    contents->SetColors(data.colors);
    contents->SetStops(data.stops);
    contents->SetTileMode(data.tile_mode);
    contents->SetEffectTransform(data.effect_transform);

    return contents;
  }

  std::shared_ptr<ColorSourceContents> operator()(const ImageData& data) {
    auto contents = std::make_shared<TiledTextureContents>();
    contents->SetOpacityFactor(paint.color.alpha);
    contents->SetTexture(data.texture);
    contents->SetTileModes(data.x_tile_mode, data.y_tile_mode);
    contents->SetSamplerDescriptor(data.sampler_descriptor);
    contents->SetEffectTransform(data.effect_transform);
    if (paint.color_filter) {
      TiledTextureContents::ColorFilterProc filter_proc =
          [color_filter = paint.color_filter](FilterInput::Ref input) {
            return color_filter->WrapWithGPUColorFilter(
                std::move(input), ColorFilterContents::AbsorbOpacity::kNo);
          };
      contents->SetColorFilter(filter_proc);
    }
    contents->SetColorSourceSize(Size::Ceil(data.texture->GetSize()));
    return contents;
  }

  std::shared_ptr<ColorSourceContents> operator()(
      const RuntimeEffectData& data) {
    auto contents = std::make_shared<RuntimeEffectContents>();
    contents->SetOpacityFactor(paint.color.alpha);
    contents->SetRuntimeStage(data.runtime_stage);
    contents->SetUniformData(data.uniform_data);
    contents->SetTextureInputs(data.texture_inputs);
    return contents;
  }

  std::shared_ptr<ColorSourceContents> operator()(const std::monostate& data) {
    auto contents = std::make_shared<SolidColorContents>();
    contents->SetColor(paint.color);
    return contents;
  }
};
}  // namespace

ColorSource::ColorSource() noexcept : color_source_data_(std::monostate()) {}

ColorSource::~ColorSource() = default;

ColorSource ColorSource::MakeColor() {
  return {};
}

ColorSource ColorSource::MakeLinearGradient(Point start_point,
                                            Point end_point,
                                            std::vector<Color> colors,
                                            std::vector<Scalar> stops,
                                            Entity::TileMode tile_mode,
                                            Matrix effect_transform) {
  ColorSource result;
  result.type_ = Type::kLinearGradient;
  result.color_source_data_ =
      LinearGradientData{start_point,      end_point, std::move(colors),
                         std::move(stops), tile_mode, effect_transform};
  return result;
}

ColorSource ColorSource::MakeConicalGradient(Point center,
                                             Scalar radius,
                                             std::vector<Color> colors,
                                             std::vector<Scalar> stops,
                                             Point focus_center,
                                             Scalar focus_radius,
                                             Entity::TileMode tile_mode,
                                             Matrix effect_transform) {
  ColorSource result;
  result.type_ = Type::kConicalGradient;
  result.color_source_data_ = ConicalGradientData{
      center,       radius,       std::move(colors), std::move(stops),
      focus_center, focus_radius, tile_mode,         effect_transform};
  return result;
}

ColorSource ColorSource::MakeRadialGradient(Point center,
                                            Scalar radius,
                                            std::vector<Color> colors,
                                            std::vector<Scalar> stops,
                                            Entity::TileMode tile_mode,
                                            Matrix effect_transform) {
  ColorSource result;
  result.type_ = Type::kRadialGradient;
  result.color_source_data_ =
      RadialGradientData{center,           radius,    std::move(colors),
                         std::move(stops), tile_mode, effect_transform};
  return result;
}

ColorSource ColorSource::MakeSweepGradient(Point center,
                                           Degrees start_angle,
                                           Degrees end_angle,
                                           std::vector<Color> colors,
                                           std::vector<Scalar> stops,
                                           Entity::TileMode tile_mode,
                                           Matrix effect_transform) {
  ColorSource result;
  result.type_ = Type::kSweepGradient;
  result.color_source_data_ = SweepGradientData{
      center,           start_angle, end_angle,       std::move(colors),
      std::move(stops), tile_mode,   effect_transform};
  return result;
}

ColorSource ColorSource::MakeImage(std::shared_ptr<Texture> texture,
                                   Entity::TileMode x_tile_mode,
                                   Entity::TileMode y_tile_mode,
                                   SamplerDescriptor sampler_descriptor,
                                   Matrix effect_transform) {
  ColorSource result;
  result.type_ = Type::kImage;
  result.color_source_data_ =
      ImageData{std::move(texture), x_tile_mode, y_tile_mode,
                std::move(sampler_descriptor), effect_transform};
  return result;
}

ColorSource ColorSource::MakeRuntimeEffect(
    std::shared_ptr<RuntimeStage> runtime_stage,
    std::shared_ptr<std::vector<uint8_t>> uniform_data,
    std::vector<RuntimeEffectContents::TextureInput> texture_inputs) {
  ColorSource result;
  result.type_ = Type::kRuntimeEffect;
  result.color_source_data_ =
      RuntimeEffectData{std::move(runtime_stage), std::move(uniform_data),
                        std::move(texture_inputs)};
  return result;
}

ColorSource::Type ColorSource::GetType() const {
  return type_;
}

std::shared_ptr<ColorSourceContents> ColorSource::GetContents(
    const Paint& paint) const {
  return std::visit(CreateContentsVisitor{paint}, color_source_data_);
}

const ColorSourceData& ColorSource::GetData() const {
  return color_source_data_;
}

}  // namespace impeller
