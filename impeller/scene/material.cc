// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/material.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/sampler_descriptor.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/scene/pipeline_key.h"
#include "impeller/scene/scene_context.h"
#include "impeller/scene/shaders/unlit.frag.h"

#include <memory>

namespace impeller {
namespace scene {

//------------------------------------------------------------------------------
/// Material
///

Material::~Material() = default;

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

SceneContextOptions Material::GetContextOptions(const RenderPass& pass) const {
  // TODO(bdero): Pipeline blend and stencil config.
  return {.sample_count = pass.GetRenderTarget().GetSampleCount()};
}

//------------------------------------------------------------------------------
/// UnlitMaterial
///

UnlitMaterial::~UnlitMaterial() = default;

void UnlitMaterial::SetColor(Color color) {
  color_ = color;
}

void UnlitMaterial::SetColorTexture(std::shared_ptr<Texture> color_texture) {
  color_texture_ = std::move(color_texture);
}

void UnlitMaterial::SetVertexColorWeight(Scalar weight) {
  vertex_color_weight_ = weight;
}

// |Material|
MaterialType UnlitMaterial::GetMaterialType() const {
  return MaterialType::kUnlit;
}

// |Material|
void UnlitMaterial::BindToCommand(const SceneContext& scene_context,
                                  HostBuffer& buffer,
                                  Command& command) const {
  // Uniform buffer.
  UnlitFragmentShader::FragInfo info;
  info.color = color_;
  info.vertex_color_weight = vertex_color_weight_;
  UnlitFragmentShader::BindFragInfo(command, buffer.EmplaceUniform(info));

  // Textures.
  SamplerDescriptor sampler_descriptor;
  sampler_descriptor.label = "Trilinear";
  sampler_descriptor.min_filter = MinMagFilter::kLinear;
  sampler_descriptor.mag_filter = MinMagFilter::kLinear;
  sampler_descriptor.mip_filter = MipFilter::kLinear;
  UnlitFragmentShader::BindBaseColorTexture(
      command,
      color_texture_ ? color_texture_ : scene_context.GetPlaceholderTexture(),
      scene_context.GetContext()->GetSamplerLibrary()->GetSampler(
          sampler_descriptor));
}

//------------------------------------------------------------------------------
/// StandardMaterial
///

StandardMaterial::~StandardMaterial() = default;

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

// |Material|
MaterialType StandardMaterial::GetMaterialType() const {
  // TODO(bdero): Replace this once a PBR shader has landed.
  return MaterialType::kUnlit;
}

// |Material|
void StandardMaterial::BindToCommand(const SceneContext& scene_context,
                                     HostBuffer& buffer,
                                     Command& command) const {}

}  // namespace scene
}  // namespace impeller
