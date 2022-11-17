// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/material.h"

#include <memory>

namespace impeller {
namespace scene {

//------------------------------------------------------------------------------
/// Material
///

std::unique_ptr<UnlitMaterial> Material::MakeUnlit() {
  return std::make_unique<UnlitMaterial>();
}

std::unique_ptr<StandardMaterial> Material::MakeStandard() {
  return std::make_unique<StandardMaterial>();
}

void Material::SetBlendConfig(BlendConfig blend_config) {
  blend_config_ = blend_config;
}

void Material::SetStencilConfig(StencilConfig stencil_config) {
  stencil_config_ = stencil_config;
}

void Material::SetTranslucent(bool is_translucent) {
  is_translucent_ = is_translucent;
}

//------------------------------------------------------------------------------
/// UnlitMaterial
///

void UnlitMaterial::SetColor(Color color) {
  color_ = color;
}

//------------------------------------------------------------------------------
/// StandardMaterial
///

void StandardMaterial::SetAlbedo(Color albedo) {
  albedo_ = albedo;
}

void StandardMaterial::SetRoughness(Scalar roughness) {
  roughness_ = roughness;
}

void StandardMaterial::SetMetallic(Scalar metallic) {
  metallic_ = metallic;
}

void StandardMaterial::SetAlbedoTexture(
    std::shared_ptr<Texture> albedo_texture) {
  albedo_texture_ = std::move(albedo_texture);
}

void StandardMaterial::SetNormalTexture(
    std::shared_ptr<Texture> normal_texture) {
  normal_texture_ = std::move(normal_texture);
}

void StandardMaterial::SetOcclusionRoughnessMetallicTexture(
    std::shared_ptr<Texture> occlusion_roughness_metallic_texture) {
  occlusion_roughness_metallic_texture_ =
      std::move(occlusion_roughness_metallic_texture);
}

void StandardMaterial::SetEnvironmentMap(
    std::shared_ptr<Texture> environment_map) {
  environment_map_ = std::move(environment_map);
}

}  // namespace scene
}  // namespace impeller
