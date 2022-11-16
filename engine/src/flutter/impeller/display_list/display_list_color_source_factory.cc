// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/display_list/display_list_color_source_factory.h"

#include <memory>

#include "flutter/display_list/display_list_color_source.h"
#include "impeller/display_list/conversion_utilities.h"
#include "impeller/entity/contents/linear_gradient_contents.h"
#include "impeller/entity/contents/radial_gradient_contents.h"
#include "impeller/entity/contents/runtime_effect_contents.h"
#include "impeller/entity/contents/sweep_gradient_contents.h"
#include "impeller/entity/contents/tiled_texture_contents.h"

namespace impeller {

//------------------------------------------------------------------------------
/// DlColorSourceFactory
///

DlColorSourceFactory::DlColorSourceFactory(
    const std::shared_ptr<flutter::DlColorSource>& dl_color_source)
    : dl_color_source_(dl_color_source){};

DlColorSourceFactory::~DlColorSourceFactory() = default;

//------------------------------------------------------------------------------
/// DlImageColorSourceFactory
///

DlImageColorSourceFactory::DlImageColorSourceFactory(
    const std::shared_ptr<flutter::DlColorSource>& dl_color_source)
    : DlColorSourceFactory(dl_color_source){};

DlImageColorSourceFactory::~DlImageColorSourceFactory() = default;

std::shared_ptr<ColorSourceFactory> DlImageColorSourceFactory::Make(
    const std::shared_ptr<flutter::DlColorSource>& dl_color_source) {
  if (!dl_color_source->asImage()) {
    return nullptr;
  }
  return std::shared_ptr<DlImageColorSourceFactory>(
      new DlImageColorSourceFactory(dl_color_source));
}

// |ColorSourceFactory|
std::shared_ptr<ColorSourceContents> DlImageColorSourceFactory::MakeContents() {
  const flutter::DlImageColorSource* image_color_source =
      dl_color_source_->asImage();
  FML_DCHECK(image_color_source &&
             image_color_source->image()->impeller_texture());

  auto texture = image_color_source->image()->impeller_texture();
  auto x_tile_mode = ToTileMode(image_color_source->horizontal_tile_mode());
  auto y_tile_mode = ToTileMode(image_color_source->vertical_tile_mode());
  auto desc = ToSamplerDescriptor(image_color_source->sampling());
  auto matrix = ToMatrix(image_color_source->matrix());

  auto contents = std::make_shared<TiledTextureContents>();
  contents->SetTexture(texture);
  contents->SetTileModes(x_tile_mode, y_tile_mode);
  contents->SetSamplerDescriptor(desc);
  contents->SetMatrix(matrix);
  return contents;
}

// |ColorSourceFactory|
ColorSourceFactory::ColorSourceType DlImageColorSourceFactory::GetType() {
  return ColorSourceFactory::ColorSourceType::kImage;
}

//------------------------------------------------------------------------------
/// DlLinearGradientColorSourceFactory
///

DlLinearGradientColorSourceFactory::DlLinearGradientColorSourceFactory(
    const std::shared_ptr<flutter::DlColorSource>& dl_color_source)
    : DlColorSourceFactory(dl_color_source){};

DlLinearGradientColorSourceFactory::~DlLinearGradientColorSourceFactory() =
    default;

std::shared_ptr<ColorSourceFactory> DlLinearGradientColorSourceFactory::Make(
    const std::shared_ptr<flutter::DlColorSource>& dl_color_source) {
  if (!dl_color_source->asImage()) {
    return nullptr;
  }
  return std::shared_ptr<ColorSourceFactory>(
      new DlLinearGradientColorSourceFactory(dl_color_source));
}

// |ColorSourceFactory|
std::shared_ptr<ColorSourceContents>
DlLinearGradientColorSourceFactory::MakeContents() {
  const flutter::DlLinearGradientColorSource* linear =
      dl_color_source_->asLinearGradient();
  FML_DCHECK(linear);

  auto start_point = ToPoint(linear->start_point());
  auto end_point = ToPoint(linear->end_point());
  std::vector<Color> colors;
  std::vector<float> stops;
  ConvertStops(linear, &colors, &stops);
  auto tile_mode = ToTileMode(linear->tile_mode());
  auto matrix = ToMatrix(linear->matrix());
  auto contents = std::make_shared<LinearGradientContents>();

  contents->SetColors(colors);
  contents->SetStops(stops);
  contents->SetEndPoints(start_point, end_point);
  contents->SetTileMode(tile_mode);
  contents->SetMatrix(matrix);
  return contents;
}

// |ColorSourceFactory|
ColorSourceFactory::ColorSourceType
DlLinearGradientColorSourceFactory::GetType() {
  return ColorSourceFactory::ColorSourceType::kLinearGradient;
}

//------------------------------------------------------------------------------
/// DlRadialGradientColorSourceFactory
///

DlRadialGradientColorSourceFactory::DlRadialGradientColorSourceFactory(
    const std::shared_ptr<flutter::DlColorSource>& dl_color_source)
    : DlColorSourceFactory(dl_color_source){};

DlRadialGradientColorSourceFactory::~DlRadialGradientColorSourceFactory() =
    default;

std::shared_ptr<ColorSourceFactory> DlRadialGradientColorSourceFactory::Make(
    const std::shared_ptr<flutter::DlColorSource>& dl_color_source) {
  if (!dl_color_source->asImage()) {
    return nullptr;
  }
  return std::shared_ptr<ColorSourceFactory>(
      new DlRadialGradientColorSourceFactory(dl_color_source));
}

// |ColorSourceFactory|
std::shared_ptr<ColorSourceContents>
DlRadialGradientColorSourceFactory::MakeContents() {
  const flutter::DlRadialGradientColorSource* radial_gradient =
      dl_color_source_->asRadialGradient();
  FML_DCHECK(radial_gradient);

  auto center = ToPoint(radial_gradient->center());
  auto radius = radial_gradient->radius();
  std::vector<Color> colors;
  std::vector<float> stops;
  ConvertStops(radial_gradient, &colors, &stops);
  auto tile_mode = ToTileMode(radial_gradient->tile_mode());
  auto matrix = ToMatrix(radial_gradient->matrix());
  auto contents = std::make_shared<RadialGradientContents>();

  contents->SetColors(colors);
  contents->SetStops(stops);
  contents->SetCenterAndRadius(center, radius);
  contents->SetTileMode(tile_mode);
  contents->SetMatrix(matrix);
  return contents;
}

// |ColorSourceFactory|
ColorSourceFactory::ColorSourceType
DlRadialGradientColorSourceFactory::GetType() {
  return ColorSourceFactory::ColorSourceType::kRadialGradient;
}

//------------------------------------------------------------------------------
/// DlSweepGradientColorSourceFactory
///

DlSweepGradientColorSourceFactory::DlSweepGradientColorSourceFactory(
    const std::shared_ptr<flutter::DlColorSource>& dl_color_source)
    : DlColorSourceFactory(dl_color_source){};

DlSweepGradientColorSourceFactory::~DlSweepGradientColorSourceFactory() =
    default;

std::shared_ptr<ColorSourceFactory> DlSweepGradientColorSourceFactory::Make(
    const std::shared_ptr<flutter::DlColorSource>& dl_color_source) {
  if (!dl_color_source->asImage()) {
    return nullptr;
  }
  return std::shared_ptr<ColorSourceFactory>(
      new DlSweepGradientColorSourceFactory(dl_color_source));
}

// |ColorSourceFactory|
std::shared_ptr<ColorSourceContents>
DlSweepGradientColorSourceFactory::MakeContents() {
  const flutter::DlSweepGradientColorSource* sweep_gradient =
      dl_color_source_->asSweepGradient();
  FML_DCHECK(sweep_gradient);

  auto center = ToPoint(sweep_gradient->center());
  auto start_angle = Degrees(sweep_gradient->start());
  auto end_angle = Degrees(sweep_gradient->end());
  std::vector<Color> colors;
  std::vector<float> stops;
  ConvertStops(sweep_gradient, &colors, &stops);
  auto tile_mode = ToTileMode(sweep_gradient->tile_mode());
  auto matrix = ToMatrix(sweep_gradient->matrix());

  auto contents = std::make_shared<SweepGradientContents>();
  contents->SetCenterAndAngles(center, start_angle, end_angle);
  contents->SetColors(colors);
  contents->SetStops(stops);
  contents->SetTileMode(tile_mode);
  contents->SetMatrix(matrix);
  return contents;
}

// |ColorSourceFactory|
ColorSourceFactory::ColorSourceType
DlSweepGradientColorSourceFactory::GetType() {
  return ColorSourceFactory::ColorSourceType::kSweepGradient;
}

//------------------------------------------------------------------------------
/// DlRuntimeEffectColorSourceFactory
///

DlRuntimeEffectColorSourceFactory::DlRuntimeEffectColorSourceFactory(
    const std::shared_ptr<flutter::DlColorSource>& dl_color_source)
    : DlColorSourceFactory(dl_color_source){};

DlRuntimeEffectColorSourceFactory::~DlRuntimeEffectColorSourceFactory() =
    default;

std::shared_ptr<ColorSourceFactory> DlRuntimeEffectColorSourceFactory::Make(
    const std::shared_ptr<flutter::DlColorSource>& dl_color_source) {
  if (!dl_color_source->asImage()) {
    return nullptr;
  }
  return std::shared_ptr<ColorSourceFactory>(
      new DlRuntimeEffectColorSourceFactory(dl_color_source));
}

// |ColorSourceFactory|
std::shared_ptr<ColorSourceContents>
DlRuntimeEffectColorSourceFactory::MakeContents() {
  const flutter::DlRuntimeEffectColorSource* runtime_effect_color_source =
      dl_color_source_->asRuntimeEffect();
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
      UNIMPLEMENTED;
      return nullptr;
    }
    FML_DCHECK(image->image()->impeller_texture());
    texture_inputs.push_back({
        .sampler_descriptor = ToSamplerDescriptor(image->sampling()),
        .texture = image->image()->impeller_texture(),
    });
  }

  auto contents = std::make_shared<RuntimeEffectContents>();
  contents->SetRuntimeStage(runtime_stage);
  contents->SetUniformData(uniform_data);
  contents->SetTextureInputs(texture_inputs);
  return contents;
}

// |ColorSourceFactory|
ColorSourceFactory::ColorSourceType
DlRuntimeEffectColorSourceFactory::GetType() {
  return ColorSourceFactory::ColorSourceType::kRuntimeEffect;
}

}  // namespace impeller
