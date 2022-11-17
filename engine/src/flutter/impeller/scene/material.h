// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "impeller/geometry/scalar.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/texture.h"

namespace impeller {
namespace scene {

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

 protected:
  BlendConfig blend_config_;
  StencilConfig stencil_config_;
  bool is_translucent_ = false;
};

class UnlitMaterial final : public Material {
 public:
  void SetColor(Color color);

 private:
  Color color_;
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

 private:
  Color albedo_ = Color::CornflowerBlue();
  Scalar roughness_ = 0.5;
  Scalar metallic_ = 0.5;

  std::shared_ptr<Texture> albedo_texture_;
  std::shared_ptr<Texture> normal_texture_;
  std::shared_ptr<Texture> occlusion_roughness_metallic_texture_;

  std::shared_ptr<Texture> environment_map_;
};

}  // namespace scene
}  // namespace impeller
