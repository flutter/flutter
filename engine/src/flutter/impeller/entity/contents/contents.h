// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/rect.h"
#include "impeller/renderer/sampler_descriptor.h"
#include "impeller/renderer/snapshot.h"
#include "impeller/renderer/texture.h"

namespace impeller {

class ContentContext;
struct ContentContextOptions;
class Entity;
class Surface;
class RenderPass;

ContentContextOptions OptionsFromPass(const RenderPass& pass);

ContentContextOptions OptionsFromPassAndEntity(const RenderPass& pass,
                                               const Entity& entity);

class Contents {
 public:
  Contents();

  virtual ~Contents();

  struct StencilCoverage {
    enum class Type { kNone, kAppend, kRestore };

    Type type = Type::kNone;
    std::optional<Rect> coverage = std::nullopt;
  };

  /// @brief  Create an entity that renders a given snapshot.
  static std::optional<Entity> EntityFromSnapshot(
      const std::optional<Snapshot>& snapshot,
      BlendMode blend_mode = BlendMode::kSourceOver,
      uint32_t stencil_depth = 0);

  virtual bool Render(const ContentContext& renderer,
                      const Entity& entity,
                      RenderPass& pass) const = 0;

  /// @brief Get the screen space bounding rectangle that this contents affects.
  virtual std::optional<Rect> GetCoverage(const Entity& entity) const = 0;

  /// @brief Given the current screen space bounding rectangle of the stencil,
  ///        return the expected stencil coverage after this draw call. This
  ///        should only be implemented for contents that may write to the
  ///        stencil buffer.
  virtual StencilCoverage GetStencilCoverage(
      const Entity& entity,
      const std::optional<Rect>& current_stencil_coverage) const;

  /// @brief Render this contents to a snapshot, respecting the entity's
  ///        transform, path, stencil depth, and blend mode.
  ///        The result texture size is always the size of
  ///        `GetCoverage(entity)`.
  virtual std::optional<Snapshot> RenderToSnapshot(
      const ContentContext& renderer,
      const Entity& entity,
      const std::optional<SamplerDescriptor>& sampler_descriptor = std::nullopt,
      bool msaa_enabled = true) const;

  virtual bool ShouldRender(const Entity& entity,
                            const std::optional<Rect>& stencil_coverage) const;

 protected:

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(Contents);
};

}  // namespace impeller
