// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/geometry/geometry.h"

namespace impeller {

/// @brief A geometry that is created from a vertices object.
class VerticesGeometry : public Geometry {
 public:
  virtual GeometryResult GetPositionColorBuffer(const ContentContext& renderer,
                                                const Entity& entity,
                                                RenderPass& pass) = 0;

  virtual bool HasVertexColors() const = 0;

  virtual bool HasTextureCoordinates() const = 0;

  virtual std::optional<Rect> GetTextureCoordinateCoverge() const = 0;
};

}  // namespace impeller
