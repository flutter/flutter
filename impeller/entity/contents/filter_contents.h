// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <variant>
#include <vector>

#include "impeller/entity/contents/contents.h"
#include "impeller/entity/entity.h"
#include "impeller/renderer/formats.h"

namespace impeller {

class Pipeline;

/*******************************************************************************
 ******* FilterContents
 ******************************************************************************/

class FilterContents : public Contents {
 public:
  using InputVariant =
      std::variant<std::shared_ptr<Texture>, std::shared_ptr<FilterContents>>;
  using InputTextures = std::vector<InputVariant>;

  static std::shared_ptr<FilterContents> MakeBlend(
      Entity::BlendMode blend_mode,
      InputTextures input_textures);

  FilterContents();

  ~FilterContents() override;

  /// @brief The input texture sources for this filter. All texture sources are
  ///        expected to have or produce premultiplied alpha colors.
  ///        Any input can either be a `Texture` or another `FilterContents`.
  ///
  ///        The number of required or optional textures depends on the
  ///        particular filter's implementation.
  void SetInputTextures(InputTextures input_textures);

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  /// @brief Renders dependency filters, creates a subpass, and calls the
  ///        `RenderFilter` defined by the subclasses.
  std::optional<std::shared_ptr<Texture>> RenderFilterToTexture(
      const ContentContext& renderer,
      const Entity& entity,
      RenderPass& pass) const;

 private:
  /// @brief Takes a set of zero or more input textures and writes to an output
  ///        texture.
  virtual bool RenderFilter(
      const std::vector<std::shared_ptr<Texture>>& input_textures,
      const ContentContext& renderer,
      RenderPass& pass) const = 0;

  /// @brief Determines the size of the output texture.
  virtual ISize GetOutputSize() const;

  InputTextures input_textures_;
  Rect destination_;

  FML_DISALLOW_COPY_AND_ASSIGN(FilterContents);
};

/*******************************************************************************
 ******* BlendFilterContents
 ******************************************************************************/

class BlendFilterContents : public FilterContents {
 public:
  using AdvancedBlendProc = std::function<bool(
      const std::vector<std::shared_ptr<Texture>>& input_textures,
      const ContentContext& renderer,
      RenderPass& pass)>;

  BlendFilterContents();

  ~BlendFilterContents() override;

  void SetBlendMode(Entity::BlendMode blend_mode);

 private:
  bool RenderFilter(const std::vector<std::shared_ptr<Texture>>& input_textures,
                    const ContentContext& renderer,
                    RenderPass& pass) const override;

  Entity::BlendMode blend_mode_;
  AdvancedBlendProc advanced_blend_proc_;

  FML_DISALLOW_COPY_AND_ASSIGN(BlendFilterContents);
};

}  // namespace impeller
