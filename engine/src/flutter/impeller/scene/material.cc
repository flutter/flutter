// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/material.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/sampler_descriptor.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/scene/scene_context.h"
#include "impeller/scene/shaders/unlit.frag.h"

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

SceneContextOptions Material::GetContextOptions(const RenderPass& pass) const {
  // TODO(bdero): Pipeline blend and stencil config.
  return {.sample_count = pass.GetRenderTarget().GetSampleCount()};
}

//------------------------------------------------------------------------------
/// UnlitMaterial
///

void UnlitMaterial::SetColor(Color color) {
  color_ = color;
}

void UnlitMaterial::SetColorTexture(std::shared_ptr<Texture> color_texture) {
  color_texture_ = std::move(color_texture);
}

// |Material|
std::shared_ptr<Pipeline<PipelineDescriptor>> UnlitMaterial::GetPipeline(
    const SceneContext& scene_context,
    const RenderPass& pass) const {
  return scene_context.GetUnlitPipeline(GetContextOptions(pass));
}

// |Material|
void UnlitMaterial::BindToCommand(const SceneContext& scene_context,
                                  HostBuffer& buffer,
                                  Command& command) const {
  // Uniform buffer.
  UnlitPipeline::FragmentShader::FragInfo info;
  info.color = color_;
  UnlitPipeline::FragmentShader::BindFragInfo(command,
                                              buffer.EmplaceUniform(info));

  // Textures.
  SamplerDescriptor sampler_descriptor;
  sampler_descriptor.label = "Trilinear";
  sampler_descriptor.min_filter = MinMagFilter::kLinear;
  sampler_descriptor.mag_filter = MinMagFilter::kLinear;
  sampler_descriptor.mip_filter = MipFilter::kLinear;
  UnlitPipeline::FragmentShader::BindBaseColorTexture(
      command,
      color_texture_ ? color_texture_ : scene_context.GetPlaceholderTexture(),
      scene_context.GetContext()->GetSamplerLibrary()->GetSampler(
          sampler_descriptor));
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

// |Material|
std::shared_ptr<Pipeline<PipelineDescriptor>> StandardMaterial::GetPipeline(
    const SceneContext& scene_context,
    const RenderPass& pass) const {
  return nullptr;
}

// |Material|
void StandardMaterial::BindToCommand(const SceneContext& scene_context,
                                     HostBuffer& buffer,
                                     Command& command) const {}

}  // namespace scene
}  // namespace impeller
