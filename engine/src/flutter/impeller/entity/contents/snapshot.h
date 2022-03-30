// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/rect.h"
#include "impeller/renderer/texture.h"

namespace impeller {

class ContentContext;
class Entity;

/// Represents a texture and its intended draw position.
struct Snapshot {
  std::shared_ptr<Texture> texture;
  /// The offset from the origin where this texture is intended to be
  /// rendered.
  Vector2 position;

  /// Transform a texture by the given `entity`'s transformation matrix to a new
  /// texture.
  static std::optional<Snapshot> FromTransformedTexture(
      const ContentContext& renderer,
      const Entity& entity,
      std::shared_ptr<Texture> texture);
};

}  // namespace impeller
