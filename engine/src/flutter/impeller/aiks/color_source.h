// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_AIKS_COLOR_SOURCE_H_
#define FLUTTER_IMPELLER_AIKS_COLOR_SOURCE_H_

#include <functional>
#include <memory>
#include <variant>
#include <vector>

#include "impeller/entity/contents/runtime_effect_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/point.h"
#include "impeller/runtime_stage/runtime_stage.h"

namespace impeller {

struct Paint;

struct LinearGradientData {
  Point start_point;
  Point end_point;
  std::vector<Color> colors;
  std::vector<Scalar> stops;
  Entity::TileMode tile_mode;
  Matrix effect_transform;
};

struct RadialGradientData {
  Point center;
  Scalar radius;
  std::vector<Color> colors;
  std::vector<Scalar> stops;
  Entity::TileMode tile_mode;
  Matrix effect_transform;
};

struct ConicalGradientData {
  Point center;
  Scalar radius;
  std::vector<Color> colors;
  std::vector<Scalar> stops;
  Point focus_center;
  Scalar focus_radius;
  Entity::TileMode tile_mode;
  Matrix effect_transform;
};

struct SweepGradientData {
  Point center;
  Degrees start_angle;
  Degrees end_angle;
  std::vector<Color> colors;
  std::vector<Scalar> stops;
  Entity::TileMode tile_mode;
  Matrix effect_transform;
};

struct ImageData {
  std::shared_ptr<Texture> texture;
  Entity::TileMode x_tile_mode;
  Entity::TileMode y_tile_mode;
  SamplerDescriptor sampler_descriptor;
  Matrix effect_transform;
};

struct RuntimeEffectData {
  std::shared_ptr<RuntimeStage> runtime_stage;
  std::shared_ptr<std::vector<uint8_t>> uniform_data;
  std::vector<RuntimeEffectContents::TextureInput> texture_inputs;
};

using ColorSourceData = std::variant<LinearGradientData,
                                     RadialGradientData,
                                     ConicalGradientData,
                                     SweepGradientData,
                                     ImageData,
                                     RuntimeEffectData,
                                     std::monostate>;

class ColorSource {
 public:
  enum class Type {
    kColor,
    kImage,
    kLinearGradient,
    kRadialGradient,
    kConicalGradient,
    kSweepGradient,
    kRuntimeEffect,
  };

  ColorSource() noexcept;

  ~ColorSource();

  static ColorSource MakeColor();

  static ColorSource MakeLinearGradient(Point start_point,
                                        Point end_point,
                                        std::vector<Color> colors,
                                        std::vector<Scalar> stops,
                                        Entity::TileMode tile_mode,
                                        Matrix effect_transform);

  static ColorSource MakeConicalGradient(Point center,
                                         Scalar radius,
                                         std::vector<Color> colors,
                                         std::vector<Scalar> stops,
                                         Point focus_center,
                                         Scalar focus_radius,
                                         Entity::TileMode tile_mode,
                                         Matrix effect_transform);

  static ColorSource MakeRadialGradient(Point center,
                                        Scalar radius,
                                        std::vector<Color> colors,
                                        std::vector<Scalar> stops,
                                        Entity::TileMode tile_mode,
                                        Matrix effect_transform);

  static ColorSource MakeSweepGradient(Point center,
                                       Degrees start_angle,
                                       Degrees end_angle,
                                       std::vector<Color> colors,
                                       std::vector<Scalar> stops,
                                       Entity::TileMode tile_mode,
                                       Matrix effect_transform);

  static ColorSource MakeImage(std::shared_ptr<Texture> texture,
                               Entity::TileMode x_tile_mode,
                               Entity::TileMode y_tile_mode,
                               SamplerDescriptor sampler_descriptor,
                               Matrix effect_transform);

  static ColorSource MakeRuntimeEffect(
      std::shared_ptr<RuntimeStage> runtime_stage,
      std::shared_ptr<std::vector<uint8_t>> uniform_data,
      std::vector<RuntimeEffectContents::TextureInput> texture_inputs);

  Type GetType() const;

  std::shared_ptr<ColorSourceContents> GetContents(const Paint& paint) const;

  const ColorSourceData& GetData() const;

 private:
  Type type_ = Type::kColor;
  ColorSourceData color_source_data_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_AIKS_COLOR_SOURCE_H_
