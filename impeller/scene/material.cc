// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/material.h"
#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/scene/importer/conversions.h"
#include "impeller/scene/importer/scene_flatbuffers.h"
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

std::unique_ptr<Material> Material::MakeFromFlatbuffer(
    const fb::Material& material,
    const std::vector<std::shared_ptr<Texture>>& textures) {
  switch (material.type()) {
    case fb::MaterialType::kUnlit:
      return UnlitMaterial::MakeFromFlatbuffer(material, textures);
    case fb::MaterialType::kPhysicallyBased:
      return PhysicallyBasedMaterial::MakeFromFlatbuffer(material, textures);
  }
}

std::unique_ptr<UnlitMaterial> Material::MakeUnlit() {
  return std::make_unique<UnlitMaterial>();
}

std::unique_ptr<PhysicallyBasedMaterial> Material::MakePhysicallyBased() {
  return std::make_unique<PhysicallyBasedMaterial>();
}

void Material::SetVertexColorWeight(Scalar weight) {
  vertex_color_weight_ = weight;
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

std::unique_ptr<UnlitMaterial> UnlitMaterial::MakeFromFlatbuffer(
    const fb::Material& material,
    const std::vector<std::shared_ptr<Texture>>& textures) {
  if (material.type() != fb::MaterialType::kUnlit) {
    VALIDATION_LOG << "Cannot unpack unlit material because the ipscene "
                      "material type is not unlit.";
    return nullptr;
  }

  auto result = Material::MakeUnlit();

  if (material.base_color_factor()) {
    result->SetColor(importer::ToColor(*material.base_color_factor()));
  }

  if (material.base_color_texture() >= 0 &&
      material.base_color_texture() < static_cast<int32_t>(textures.size())) {
    result->SetColorTexture(textures[material.base_color_texture()]);
  }

  return result;
}

UnlitMaterial::~UnlitMaterial() = default;

void UnlitMaterial::SetColor(Color color) {
  color_ = color;
}

void UnlitMaterial::SetColorTexture(std::shared_ptr<Texture> color_texture) {
  color_texture_ = std::move(color_texture);
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

std::unique_ptr<PhysicallyBasedMaterial>
PhysicallyBasedMaterial::MakeFromFlatbuffer(
    const fb::Material& material,
    const std::vector<std::shared_ptr<Texture>>& textures) {
  if (material.type() != fb::MaterialType::kPhysicallyBased) {
    VALIDATION_LOG << "Cannot unpack unlit material because the ipscene "
                      "material type is not unlit.";
    return nullptr;
  }

  auto result = Material::MakePhysicallyBased();

  result->SetAlbedo(material.base_color_factor()
                        ? importer::ToColor(*material.base_color_factor())
                        : Color::White());
  result->SetRoughness(material.roughness_factor());
  result->SetMetallic(material.metallic_factor());

  if (material.base_color_texture() >= 0 &&
      material.base_color_texture() < static_cast<int32_t>(textures.size())) {
    result->SetAlbedoTexture(textures[material.base_color_texture()]);
    result->SetVertexColorWeight(0);
  }
  if (material.metallic_roughness_texture() >= 0 &&
      material.metallic_roughness_texture() <
          static_cast<int32_t>(textures.size())) {
    result->SetMetallicRoughnessTexture(
        textures[material.metallic_roughness_texture()]);
  }
  if (material.normal_texture() >= 0 &&
      material.normal_texture() < static_cast<int32_t>(textures.size())) {
    result->SetNormalTexture(textures[material.normal_texture()]);
  }
  if (material.occlusion_texture() >= 0 &&
      material.occlusion_texture() < static_cast<int32_t>(textures.size())) {
    result->SetOcclusionTexture(textures[material.occlusion_texture()]);
  }

  return result;
}

PhysicallyBasedMaterial::~PhysicallyBasedMaterial() = default;

void PhysicallyBasedMaterial::SetAlbedo(Color albedo) {
  albedo_ = albedo;
}

void PhysicallyBasedMaterial::SetRoughness(Scalar roughness) {
  roughness_ = roughness;
}

void PhysicallyBasedMaterial::SetMetallic(Scalar metallic) {
  metallic_ = metallic;
}

void PhysicallyBasedMaterial::SetAlbedoTexture(
    std::shared_ptr<Texture> albedo_texture) {
  albedo_texture_ = std::move(albedo_texture);
}

void PhysicallyBasedMaterial::SetMetallicRoughnessTexture(
    std::shared_ptr<Texture> metallic_roughness_texture) {
  metallic_roughness_texture_ = std::move(metallic_roughness_texture);
}

void PhysicallyBasedMaterial::SetNormalTexture(
    std::shared_ptr<Texture> normal_texture) {
  normal_texture_ = std::move(normal_texture);
}

void PhysicallyBasedMaterial::SetOcclusionTexture(
    std::shared_ptr<Texture> occlusion_texture) {
  occlusion_texture_ = std::move(occlusion_texture);
}

void PhysicallyBasedMaterial::SetEnvironmentMap(
    std::shared_ptr<Texture> environment_map) {
  environment_map_ = std::move(environment_map);
}

// |Material|
MaterialType PhysicallyBasedMaterial::GetMaterialType() const {
  // TODO(bdero): Replace this once a PBR shader has landed.
  return MaterialType::kUnlit;
}

// |Material|
void PhysicallyBasedMaterial::BindToCommand(const SceneContext& scene_context,
                                            HostBuffer& buffer,
                                            Command& command) const {}

}  // namespace scene
}  // namespace impeller
