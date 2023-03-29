// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "impeller/core/formats.h"
#include "impeller/core/texture.h"
#include "impeller/geometry/scalar.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/scene/importer/scene_flatbuffers.h"
#include "impeller/scene/pipeline_key.h"

namespace impeller {
namespace scene {

class SceneContext;
struct SceneContextOptions;
class Geometry;

class UnlitMaterial;
class PhysicallyBasedMaterial;

class Material {
 public:
  struct BlendConfig {
    BlendOperation color_op = BlendOperation::kAdd;
    BlendFactor source_color_factor = BlendFactor::kOne;
    BlendFactor destination_color_factor = BlendFactor::kOneMinusSourceAlpha;
    BlendOperation alpha_op = BlendOperation::kAdd;
    BlendFactor source_alpha_factor = BlendFactor::kOne;
    BlendFactor destination_alpha_factor = BlendFactor::kOneMinusSourceAlpha;
  };

  struct StencilConfig {
    StencilOperation operation = StencilOperation::kKeep;
    CompareFunction compare = CompareFunction::kAlways;
  };

  static std::unique_ptr<Material> MakeFromFlatbuffer(
      const fb::Material& material,
      const std::vector<std::shared_ptr<Texture>>& textures);

  static std::unique_ptr<UnlitMaterial> MakeUnlit();
  static std::unique_ptr<PhysicallyBasedMaterial> MakePhysicallyBased();

  virtual ~Material();

  void SetVertexColorWeight(Scalar weight);
  void SetBlendConfig(BlendConfig blend_config);
  void SetStencilConfig(StencilConfig stencil_config);

  void SetTranslucent(bool is_translucent);

  SceneContextOptions GetContextOptions(const RenderPass& pass) const;

  virtual MaterialType GetMaterialType() const = 0;

  virtual void BindToCommand(const SceneContext& scene_context,
                             HostBuffer& buffer,
                             Command& command) const = 0;

 protected:
  Scalar vertex_color_weight_ = 1;
  BlendConfig blend_config_;
  StencilConfig stencil_config_;
  bool is_translucent_ = false;
};

class UnlitMaterial final : public Material {
 public:
  static std::unique_ptr<UnlitMaterial> MakeFromFlatbuffer(
      const fb::Material& material,
      const std::vector<std::shared_ptr<Texture>>& textures);

  ~UnlitMaterial();

  void SetColor(Color color);

  void SetColorTexture(std::shared_ptr<Texture> color_texture);

  // |Material|
  MaterialType GetMaterialType() const override;

  // |Material|
  void BindToCommand(const SceneContext& scene_context,
                     HostBuffer& buffer,
                     Command& command) const override;

 private:
  Color color_ = Color::White();
  std::shared_ptr<Texture> color_texture_;
};

class PhysicallyBasedMaterial final : public Material {
 public:
  static std::unique_ptr<PhysicallyBasedMaterial> MakeFromFlatbuffer(
      const fb::Material& material,
      const std::vector<std::shared_ptr<Texture>>& textures);

  ~PhysicallyBasedMaterial();

  void SetAlbedo(Color albedo);
  void SetRoughness(Scalar roughness);
  void SetMetallic(Scalar metallic);

  void SetAlbedoTexture(std::shared_ptr<Texture> albedo_texture);
  void SetMetallicRoughnessTexture(
      std::shared_ptr<Texture> metallic_roughness_texture);
  void SetNormalTexture(std::shared_ptr<Texture> normal_texture);
  void SetOcclusionTexture(std::shared_ptr<Texture> occlusion_texture);

  void SetEnvironmentMap(std::shared_ptr<Texture> environment_map);

  // |Material|
  MaterialType GetMaterialType() const override;

  // |Material|
  void BindToCommand(const SceneContext& scene_context,
                     HostBuffer& buffer,
                     Command& command) const override;

 private:
  Color albedo_ = Color::White();
  Scalar metallic_ = 0.5;
  Scalar roughness_ = 0.5;

  std::shared_ptr<Texture> albedo_texture_;
  std::shared_ptr<Texture> metallic_roughness_texture_;
  std::shared_ptr<Texture> normal_texture_;
  std::shared_ptr<Texture> occlusion_texture_;

  std::shared_ptr<Texture> environment_map_;
};

}  // namespace scene
}  // namespace impeller
