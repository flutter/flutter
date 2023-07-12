// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/color_source.h"

#include <memory>
#include <vector>

#include "impeller/aiks/paint.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/entity/contents/conical_gradient_contents.h"
#include "impeller/entity/contents/linear_gradient_contents.h"
#include "impeller/entity/contents/radial_gradient_contents.h"
#include "impeller/entity/contents/runtime_effect_contents.h"
#include "impeller/entity/contents/scene_contents.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/contents/sweep_gradient_contents.h"
#include "impeller/entity/contents/tiled_texture_contents.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/scalar.h"
#include "impeller/runtime_stage/runtime_stage.h"
#include "impeller/scene/node.h"

namespace impeller {

ColorSource::ColorSource() noexcept
    : proc_([](const Paint& paint) -> std::shared_ptr<ColorSourceContents> {
        auto contents = std::make_shared<SolidColorContents>();
        contents->SetColor(paint.color);
        return contents;
      }){};

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
  result.proc_ = [start_point, end_point, colors = std::move(colors),
                  stops = std::move(stops), tile_mode,
                  effect_transform](const Paint& paint) {
    auto contents = std::make_shared<LinearGradientContents>();
    contents->SetOpacityFactor(paint.color.alpha);
    contents->SetColors(colors);
    contents->SetStops(stops);
    contents->SetEndPoints(start_point, end_point);
    contents->SetTileMode(tile_mode);
    contents->SetEffectTransform(effect_transform);

    std::vector<Point> bounds{start_point, end_point};
    auto intrinsic_size = Rect::MakePointBounds(bounds.begin(), bounds.end());
    if (intrinsic_size.has_value()) {
      contents->SetColorSourceSize(intrinsic_size->size);
    }
    return contents;
  };
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
  result.proc_ = [center, radius, colors = std::move(colors),
                  stops = std::move(stops), focus_center, focus_radius,
                  tile_mode, effect_transform](const Paint& paint) {
    std::shared_ptr<ConicalGradientContents> contents =
        std::make_shared<ConicalGradientContents>();
    contents->SetOpacityFactor(paint.color.alpha);
    contents->SetColors(colors);
    contents->SetStops(stops);
    contents->SetCenterAndRadius(center, radius);
    contents->SetTileMode(tile_mode);
    contents->SetEffectTransform(effect_transform);
    contents->SetFocus(focus_center, focus_radius);

    auto radius_pt = Point(radius, radius);
    std::vector<Point> bounds{center + radius_pt, center - radius_pt};
    auto intrinsic_size = Rect::MakePointBounds(bounds.begin(), bounds.end());
    if (intrinsic_size.has_value()) {
      contents->SetColorSourceSize(intrinsic_size->size);
    }
    return contents;
  };
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
  result.proc_ = [center, radius, colors = std::move(colors),
                  stops = std::move(stops), tile_mode,
                  effect_transform](const Paint& paint) {
    auto contents = std::make_shared<RadialGradientContents>();
    contents->SetOpacityFactor(paint.color.alpha);
    contents->SetColors(colors);
    contents->SetStops(stops);
    contents->SetCenterAndRadius(center, radius);
    contents->SetTileMode(tile_mode);
    contents->SetEffectTransform(effect_transform);

    auto radius_pt = Point(radius, radius);
    std::vector<Point> bounds{center + radius_pt, center - radius_pt};
    auto intrinsic_size = Rect::MakePointBounds(bounds.begin(), bounds.end());
    if (intrinsic_size.has_value()) {
      contents->SetColorSourceSize(intrinsic_size->size);
    }
    return contents;
  };
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
  result.proc_ = [center, start_angle, end_angle, colors = std::move(colors),
                  stops = std::move(stops), tile_mode,
                  effect_transform](const Paint& paint) {
    auto contents = std::make_shared<SweepGradientContents>();
    contents->SetOpacityFactor(paint.color.alpha);
    contents->SetCenterAndAngles(center, start_angle, end_angle);
    contents->SetColors(colors);
    contents->SetStops(stops);
    contents->SetTileMode(tile_mode);
    contents->SetEffectTransform(effect_transform);

    return contents;
  };
  return result;
}

ColorSource ColorSource::MakeImage(std::shared_ptr<Texture> texture,
                                   Entity::TileMode x_tile_mode,
                                   Entity::TileMode y_tile_mode,
                                   SamplerDescriptor sampler_descriptor,
                                   Matrix effect_transform) {
  ColorSource result;
  result.type_ = Type::kImage;
  result.proc_ = [texture = std::move(texture), x_tile_mode, y_tile_mode,
                  sampler_descriptor = std::move(sampler_descriptor),
                  effect_transform](const Paint& paint) {
    auto contents = std::make_shared<TiledTextureContents>();
    contents->SetOpacityFactor(paint.color.alpha);
    contents->SetTexture(texture);
    contents->SetTileModes(x_tile_mode, y_tile_mode);
    contents->SetSamplerDescriptor(sampler_descriptor);
    contents->SetEffectTransform(effect_transform);
    if (paint.color_filter) {
      TiledTextureContents::ColorFilterProc filter_proc =
          [color_filter = paint.color_filter](FilterInput::Ref input) {
            return color_filter->WrapWithGPUColorFilter(std::move(input),
                                                        false);
          };
      contents->SetColorFilter(filter_proc);
    }
    contents->SetColorSourceSize(Size::Ceil(texture->GetSize()));
    return contents;
  };
  return result;
}

ColorSource ColorSource::MakeRuntimeEffect(
    std::shared_ptr<RuntimeStage> runtime_stage,
    std::shared_ptr<std::vector<uint8_t>> uniform_data,
    std::vector<RuntimeEffectContents::TextureInput> texture_inputs) {
  ColorSource result;
  result.type_ = Type::kRuntimeEffect;
  result.proc_ = [runtime_stage = std::move(runtime_stage),
                  uniform_data = std::move(uniform_data),
                  texture_inputs =
                      std::move(texture_inputs)](const Paint& paint) {
    auto contents = std::make_shared<RuntimeEffectContents>();
    contents->SetOpacityFactor(paint.color.alpha);
    contents->SetRuntimeStage(runtime_stage);
    contents->SetUniformData(uniform_data);
    contents->SetTextureInputs(texture_inputs);
    return contents;
  };
  return result;
}

ColorSource ColorSource::MakeScene(std::shared_ptr<scene::Node> scene_node,
                                   Matrix camera_transform) {
  ColorSource result;
  result.type_ = Type::kScene;
  result.proc_ = [scene_node = std::move(scene_node),
                  camera_transform](const Paint& paint) {
    auto contents = std::make_shared<SceneContents>();
    contents->SetOpacityFactor(paint.color.alpha);
    contents->SetNode(scene_node);
    contents->SetCameraTransform(camera_transform);
    return contents;
  };
  return result;
}

ColorSource::Type ColorSource::GetType() const {
  return type_;
}

std::shared_ptr<ColorSourceContents> ColorSource::GetContents(
    const Paint& paint) const {
  return proc_(paint);
}

}  // namespace impeller
