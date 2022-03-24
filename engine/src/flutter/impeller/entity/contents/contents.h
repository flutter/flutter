// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/geometry/rect.h"
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
  /// Represents a screen space texture and it's intended draw position.
  struct Snapshot {
    std::shared_ptr<Texture> texture;
    /// The offset from the origin where this texture is intended to be
    /// rendered.
    Vector2 position;
  };

  Contents();

  virtual ~Contents();

  virtual bool Render(const ContentContext& renderer,
                      const Entity& entity,
                      RenderPass& pass) const = 0;

  /// @brief Get the bounding rectangle that this contents modifies in screen
  ///        space.
  virtual Rect GetBounds(const Entity& entity) const;

  /// @brief Render this contents to a texture, respecting the entity's
  ///        transform, path, stencil depth, blend mode, etc.
  ///        The result texture size is always the size of `GetBounds(entity)`.
  virtual std::optional<Snapshot> RenderToTexture(
      const ContentContext& renderer,
      const Entity& entity) const;

  using SubpassCallback =
      std::function<bool(const ContentContext&, RenderPass&)>;
  static std::optional<std::shared_ptr<Texture>> MakeSubpass(
      const ContentContext& renderer,
      ISize texture_size,
      SubpassCallback subpass_callback);

 protected:

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(Contents);
};

}  // namespace impeller
