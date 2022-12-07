// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "impeller/geometry/scalar.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/texture.h"

namespace impeller {
namespace scene {

class SceneContext;
struct SceneContextOptions;
class Geometry;

class UnlitMaterial;
class StandardMaterial;

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

  static std::unique_ptr<UnlitMaterial> MakeUnlit();
  static std::unique_ptr<StandardMaterial> MakeStandard();

  void SetBlendConfig(BlendConfig blend_config);
  void SetStencilConfig(StencilConfig stencil_config);

  void SetTranslucent(bool is_translucent);

  virtual std::shared_ptr<Pipeline<PipelineDescriptor>> GetPipeline(
      const SceneContext& scene_context,
      const RenderPass& pass) const = 0;
  virtual void BindToCommand(const SceneContext& scene_context,
                             HostBuffer& buffer,
                             Command& command) const = 0;

 protected:
  SceneContextOptions GetContextOptions(const RenderPass& pass) const;

  BlendConfig blend_config_;
  StencilConfig stencil_config_;
  bool is_translucent_ = false;
};

class UnlitMaterial final : public Material {
 public:
  void SetColor(Color color);

  void SetColorTexture(std::shared_ptr<Texture> color_texture);

  void SetVertexColorWeight(Scalar weight);

  // |Material|
  std::shared_ptr<Pipeline<PipelineDescriptor>> GetPipeline(
      const SceneContext& scene_context,
      const RenderPass& pass) const override;

  // |Material|
  void BindToCommand(const SceneContext& scene_context,
                     HostBuffer& buffer,
                     Command& command) const override;

 private:
  Color color_ = Color::White();
  std::shared_ptr<Texture> color_texture_;
  Scalar vertex_color_weight_ = 1;
};

class StandardMaterial final : public Material {
 public:
  void SetAlbedo(Color albedo);
  void SetRoughness(Scalar roughness);
  void SetMetallic(Scalar metallic);

  void SetAlbedoTexture(std::shared_ptr<Texture> albedo_texture);
  void SetNormalTexture(std::shared_ptr<Texture> normal_texture);
  void SetOcclusionRoughnessMetallicTexture(
      std::shared_ptr<Texture> occlusion_roughness_metallic_texture);

  void SetEnvironmentMap(std::shared_ptr<Texture> environment_map);

  // |Material|
  std::shared_ptr<Pipeline<PipelineDescriptor>> GetPipeline(
      const SceneContext& scene_context,
      const RenderPass& pass) const override;

  // |Material|
  void BindToCommand(const SceneContext& scene_context,
                     HostBuffer& buffer,
                     Command& command) const override;

 private:
  Color albedo_ = Color::White();
  Scalar roughness_ = 0.5;
  Scalar metallic_ = 0.5;

  std::shared_ptr<Texture> albedo_texture_;
  std::shared_ptr<Texture> normal_texture_;
  std::shared_ptr<Texture> occlusion_roughness_metallic_texture_;

  std::shared_ptr<Texture> environment_map_;
};

}  // namespace scene
}  // namespace impeller
