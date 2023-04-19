// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/geometry/path.h"

namespace impeller {

class Texture;

class TextureContents final : public Contents {
 public:
  TextureContents();

  ~TextureContents() override;

  /// @brief  A common case factory that marks the texture contents as having a
  ///         destination rectangle. In this situation, a subpass can be avoided
  ///         when image filters are applied.
  static std::shared_ptr<TextureContents> MakeRect(Rect destination);

  void SetLabel(std::string label);

  void SetRect(Rect rect);

  void SetTexture(std::shared_ptr<Texture> texture);

  std::shared_ptr<Texture> GetTexture() const;

  void SetSamplerDescriptor(SamplerDescriptor desc);

  const SamplerDescriptor& GetSamplerDescriptor() const;

  void SetSourceRect(const Rect& source_rect);

  const Rect& GetSourceRect() const;

  void SetOpacity(Scalar opacity);

  Scalar GetOpacity() const;

  void SetStencilEnabled(bool enabled);

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  std::optional<Snapshot> RenderToSnapshot(
      const ContentContext& renderer,
      const Entity& entity,
      const std::optional<SamplerDescriptor>& sampler_descriptor = std::nullopt,
      bool msaa_enabled = true,
      const std::string& label = "Texture Snapshot") const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  // |Contents|
  bool CanInheritOpacity(const Entity& entity) const override;

  // |Contents|
  void SetInheritedOpacity(Scalar opacity) override;

  void SetDeferApplyingOpacity(bool defer_applying_opacity);

 private:
  std::string label_;

  Rect rect_;
  bool stencil_enabled_ = true;

  std::shared_ptr<Texture> texture_;
  SamplerDescriptor sampler_descriptor_ = {};
  Rect source_rect_;
  Scalar opacity_ = 1.0f;
  Scalar inherited_opacity_ = 1.0f;
  bool defer_applying_opacity_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(TextureContents);
};

}  // namespace impeller
